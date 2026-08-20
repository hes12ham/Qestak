import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

class CustomerAuthScreen extends StatefulWidget {
  const CustomerAuthScreen({super.key});
  @override
  State<CustomerAuthScreen> createState() => _CustomerAuthScreenState();
}

class _CustomerAuthScreenState extends State<CustomerAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nidController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nidController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context);
    bool success;

    if (_isLogin) {
      success = await auth.loginAsCustomer(
        _phoneController.text.trim(),
        _nidController.text.trim(),
      );
    } else {
      success = await auth.registerCustomer(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        nationalId: _nidController.text.trim(),
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.customerDashboard);
    } else if (mounted) {
      final errKey = auth.error ?? 'invalidCredentials';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.translate(errKey)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate(
            _isLogin ? 'customerLogin' : 'customerRegister')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Center(
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: AppColors.primary, size: 36),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text(l10n.translate('loginSubtitle'),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
              const SizedBox(height: 28),

              // Name (only for register)
              if (!_isLogin) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('fullName'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? l10n.translate('required') : null,
                ),
                const SizedBox(height: 12),
              ],

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: l10n.translate('phone'),
                  prefixIcon: const Icon(Icons.phone_rounded),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? l10n.translate('required') : null,
              ),
              const SizedBox(height: 12),

              // National ID
              TextFormField(
                controller: _nidController,
                decoration: InputDecoration(
                  labelText: l10n.translate('nationalId'),
                  prefixIcon: const Icon(Icons.badge_rounded),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? l10n.translate('required') : null,
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(l10n.translate(_isLogin ? 'login' : 'register'),
                          style: const TextStyle(fontSize: 16,
                              fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),

              // Toggle login/register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.translate(_isLogin ? 'noAccount' : 'haveAccount'),
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(l10n.translate(_isLogin ? 'register' : 'login'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
