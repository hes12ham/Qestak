import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
  File? _idImage;

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

  // ── Pick ID image ──
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 1200);
      if (picked != null) {
        setState(() => _idImage = File(picked.path));
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  void _showImagePicker() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.translate('pickIdImage'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _imageOptionBtn(
                      Icons.camera_alt_rounded, l10n.translate('camera'),
                      () { Navigator.pop(context); _pickImage(ImageSource.camera); },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _imageOptionBtn(
                      Icons.photo_library_rounded, l10n.translate('gallery'),
                      () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageOptionBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  // ── Save image locally ──
  Future<String?> _saveImageLocally() async {
    if (_idImage == null) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final idDir = Directory('${dir.path}/id_images');
      if (!await idDir.exists()) await idDir.create(recursive: true);
      final fileName = 'id_${_nidC.text.trim()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await _idImage!.copy('${idDir.path}/$fileName');
      return savedFile.path;
    } catch (e) {
      debugPrint('Save image error: $e');
      return null;
    }
  }

  // ── Send WhatsApp ──
  Future<void> _sendWhatsApp(String phone, String customerName) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminName = auth.currentAdmin?.displayName ?? 'قسطك';

    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final whatsappPhone = cleanPhone.startsWith('0') ? '2${cleanPhone}' : cleanPhone;

    final message = '''مرحباً $customerName 👋

تم تسجيل قسط باسمك في *$adminName*

للدخول على تطبيق *قسطك* ومتابعة أقساطك:
📞 رقم التليفون: $phone
🆔 الرقم القومي: ${_nidC.text.trim()}

حمّل التطبيق وسجّل دخولك بالبيانات دي 📱''';

    final encoded = Uri.encodeComponent(message);
    final url = 'https://wa.me/$whatsappPhone?text=$encoded';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('WhatsApp launch error: $e');
    }
  }

  // ── Save loan ──
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountC.text);
    final count = int.tryParse(_countC.text);
    if (amount == null || amount <= 0 || count == null || count <= 0) {
      _showError('تأكد من إدخال المبلغ وعدد الأقساط');
      return;
    }
    final installment = double.tryParse(_installmentC.text) ?? (amount / count);

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final admin = auth.currentAdmin!;

      // Save image locally
      final imagePath = await _saveImageLocally();

      await FirestoreService.addLoan(
        adminId: admin.id,
        adminName: admin.displayName,
        adminPhone: admin.phone,
        customerName: _nameC.text.trim(),
        customerPhone: _phoneC.text.trim(),
        customerNationalId: _nidC.text.trim(),
        loanAmount: amount,
        installmentValue: installment,
        totalInstallments: count,
        startDate: _startDate,
        notes: _notesC.text.trim().isNotEmpty ? _notesC.text.trim() : null,
        idImagePath: imagePath,
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        Provider.of<LoanProvider>(context, listen: false).loadLoans(admin.id);
        try { NotificationService.notifyLoanAdded(
            customerName: _nameC.text.trim(), amount: amount,
            currency: AppLocalizations.of(context).translate('currency'));
        } catch (_) {}

        setState(() => _isLoading = false);

        // Show success dialog with WhatsApp option
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('❌ addLoan error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(AppLocalizations.of(context).translate('firebaseError'));
      }
    }
  }

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 14),
            Text(l10n.translate('loanSaved'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(l10n.translate('sendWhatsAppQuestion'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  _sendWhatsApp(_phoneC.text.trim(), _nameC.text.trim());
                  Navigator.pop(context); // back to dashboard
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                icon: const Icon(Icons.message, color: Colors.white),
                label: Text(l10n.translate('sendViaWhatsApp'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // back to dashboard
              },
              child: Text(l10n.translate('skipForNow'),
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: AppColors.danger,
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

              // ── ID Image (optional) ──
              const SizedBox(height: 4),
              InkWell(
                onTap: _showImagePicker,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: _idImage != null ? AppColors.success : AppColors.divider,
                        width: _idImage != null ? 2 : 1.5,
                        style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(14),
                    color: _idImage != null
                        ? AppColors.success.withOpacity(0.04) : null,
                  ),
                  child: _idImage != null
                      ? Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_idImage!, height: 120,
                                  width: double.infinity, fit: BoxFit.cover),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: AppColors.success, size: 18),
                                const SizedBox(width: 6),
                                Text(l10n.translate('idImageSelected'),
                                    style: TextStyle(fontSize: 12, color: AppColors.success,
                                        fontWeight: FontWeight.w600)),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => setState(() => _idImage = null),
                                  child: Text(l10n.translate('delete'),
                                      style: TextStyle(fontSize: 12, color: AppColors.danger)),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.badge_rounded, color: AppColors.textHint, size: 22),
                            const SizedBox(width: 10),
                            Text(l10n.translate('addIdImage'),
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            const Spacer(),
                            Text('(${l10n.translate('optional')})',
                                style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 8),
              Text(l10n.translate('loanInfo'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              const SizedBox(height: 10),
              _field(_amountC, l10n.translate('loanAmount'), Icons.attach_money,
                  keyboard: TextInputType.number, onChanged: (_) => _calcInstallment()),
              _field(_countC, l10n.translate('totalInstallments'), Icons.numbers,
                  keyboard: TextInputType.number, onChanged: (_) => _calcInstallment()),
              SwitchListTile(
                value: _autoCalc,
                onChanged: (v) => setState(() => _autoCalc = v),
                title: Text(l10n.translate('autoCalcInstallment'),
                    style: const TextStyle(fontSize: 13)),
                contentPadding: EdgeInsets.zero, dense: true,
              ),
              _field(_installmentC, l10n.translate('installmentValue'),
                  Icons.monetization_on, keyboard: TextInputType.number,
                  enabled: !_autoCalc, isRequired: !_autoCalc),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(context: context,
                      initialDate: _startDate, firstDate: DateTime(2020),
                      lastDate: DateTime(2030));
                  if (d != null) setState(() => _startDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(l10n.translate('startDate'),
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const Spacer(),
                    Text(DateFormat('yyyy/MM/dd').format(_startDate),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              TextFormField(
                controller: _notesC,
                decoration: InputDecoration(
                  labelText: '${l10n.translate('notes')} (${l10n.translate('optional')})',
                  prefixIcon: const Icon(Icons.note)),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(l10n.translate('save'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, {
    TextInputType? keyboard, List<TextInputFormatter>? formatters,
    bool enabled = true, bool isRequired = true, Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20)),
        keyboardType: keyboard, inputFormatters: formatters,
        enabled: enabled, onChanged: onChanged,
        validator: isRequired
            ? (v) => (v?.trim().isEmpty ?? true) ? AppLocalizations.of(context).translate('required') : null
            : null,
      ),
    );
  }
}
