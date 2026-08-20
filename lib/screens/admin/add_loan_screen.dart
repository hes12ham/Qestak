import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

class AddLoanScreen extends StatefulWidget {
  const AddLoanScreen({super.key});
  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _nidC = TextEditingController();
  final _amountC = TextEditingController();
  final _installmentC = TextEditingController();
  final _countC = TextEditingController();
  final _notesC = TextEditingController();

  DateTime _startDate = DateTime.now();
  bool _isLoading = false;
  bool _autoCalc = true;

  @override
  void dispose() {
    _nameC.dispose(); _phoneC.dispose(); _nidC.dispose();
    _amountC.dispose(); _installmentC.dispose();
    _countC.dispose(); _notesC.dispose();
    super.dispose();
  }

  void _calcInstallment() {
    if (!_autoCalc) return;
    final a = double.tryParse(_amountC.text) ?? 0;
    final c = int.tryParse(_countC.text) ?? 0;
    if (a > 0 && c > 0) {
      _installmentC.text = (a / c).toStringAsFixed(2);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Extra validation
    final amount = double.tryParse(_amountC.text);
    final count = int.tryParse(_countC.text);
    final installment = double.tryParse(_installmentC.text);

    if (amount == null || amount <= 0 || count == null || count <= 0) {
      _showError('تأكد من إدخال المبلغ وعدد الأقساط بشكل صحيح');
      return;
    }

    final effectiveInstallment = installment ?? (amount / count);

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final admin = auth.currentAdmin!;

      await FirestoreService.addLoan(
        adminId: admin.id,
        adminName: admin.displayName,
        adminPhone: admin.phone,
        customerName: _nameC.text.trim(),
        customerPhone: _phoneC.text.trim(),
        customerNationalId: _nidC.text.trim(),
        loanAmount: amount,
        installmentValue: effectiveInstallment,
        totalInstallments: count,
        startDate: _startDate,
        notes: _notesC.text.trim().isNotEmpty ? _notesC.text.trim() : null,
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        Provider.of<LoanProvider>(context, listen: false).loadLoans(admin.id);
        try {
          NotificationService.notifyLoanAdded(
            customerName: _nameC.text.trim(),
            amount: amount,
            currency: AppLocalizations.of(context).translate('currency'),
          );
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).translate('loanSaved')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ addLoan error: $e');
      if (mounted) {
        _showError(AppLocalizations.of(context).translate('firebaseError'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('addLoan'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.translate('personalInfo'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              const SizedBox(height: 10),
              _field(_nameC, l10n.translate('customerName'), Icons.person_outline),
              _field(_phoneC, l10n.translate('phone'), Icons.phone,
                  keyboard: TextInputType.phone,
                  formatters: [FilteringTextInputFormatter.digitsOnly]),
              _field(_nidC, l10n.translate('nationalId'), Icons.badge,
                  keyboard: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly]),

              const SizedBox(height: 16),
              Text(l10n.translate('loanInfo'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              const SizedBox(height: 10),
              _field(_amountC, l10n.translate('loanAmount'), Icons.attach_money,
                  keyboard: TextInputType.number,
                  onChanged: (_) => _calcInstallment()),
              _field(_countC, l10n.translate('totalInstallments'), Icons.numbers,
                  keyboard: TextInputType.number,
                  onChanged: (_) => _calcInstallment()),

              SwitchListTile(
                value: _autoCalc,
                onChanged: (v) => setState(() => _autoCalc = v),
                title: Text(l10n.translate('autoCalcInstallment'),
                    style: const TextStyle(fontSize: 13)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),

              _field(_installmentC, l10n.translate('installmentValue'),
                  Icons.monetization_on,
                  keyboard: TextInputType.number,
                  enabled: !_autoCalc,
                  isRequired: !_autoCalc),

              InkWell(
                onTap: () async {
                  final d = await showDatePicker(context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030));
                  if (d != null) setState(() => _startDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Text(l10n.translate('startDate'),
                          style: TextStyle(fontSize: 13,
                              color: AppColors.textSecondary)),
                      const Spacer(),
                      Text(DateFormat('yyyy/MM/dd').format(_startDate),
                          style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),

              TextFormField(
                controller: _notesC,
                decoration: InputDecoration(
                  labelText: '${l10n.translate('notes')} (${l10n.translate('optional')})',
                  prefixIcon: const Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(l10n.translate('save'),
                      style: const TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, {
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    bool enabled = true,
    bool isRequired = true,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
        ),
        keyboardType: keyboard,
        inputFormatters: formatters,
        enabled: enabled,
        onChanged: onChanged,
        validator: isRequired
            ? (v) => (v?.trim().isEmpty ?? true) ? AppLocalizations.of(context).translate('required') : null
            : null,
      ),
    );
  }
}
