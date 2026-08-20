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
    if (a > 0 && c > 0) _installmentC.text = (a / c).toStringAsFixed(2);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final admin = auth.currentAdmin!;
    final l10n = AppLocalizations.of(context);

    await FirestoreService.addLoan(
      adminId: admin.id,
      adminName: admin.displayName,
      adminPhone: admin.phone,
      customerName: _nameC.text.trim(),
      customerPhone: _phoneC.text.trim(),
      customerNationalId: _nidC.text.trim(),
      loanAmount: double.parse(_amountC.text),
      installmentValue: double.parse(_installmentC.text),
      totalInstallments: int.parse(_countC.text),
      startDate: _startDate,
      notes: _notesC.text.trim().isNotEmpty ? _notesC.text.trim() : null,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      Provider.of<LoanProvider>(context, listen: false).loadLoans(admin.id);
      NotificationService.notifyLoanAdded(
        customerName: _nameC.text.trim(),
        amount: double.parse(_amountC.text),
        currency: l10n.translate('currency'),
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.translate('loanSaved')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    }
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

              // Auto calc toggle
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
                  enabled: !_autoCalc),

              // Date
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

              // Notes
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
        validator: (v) =>
            (v?.trim().isEmpty ?? true) ? l10n.translate('required') : null,
      ),
    );
  }

  AppLocalizations get l10n => AppLocalizations.of(context);
}
