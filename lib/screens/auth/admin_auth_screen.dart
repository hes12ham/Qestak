import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

class AdminAuthScreen extends StatefulWidget {
  const AdminAuthScreen({super.key});
  @override
  State<AdminAuthScreen> createState() => _AdminAuthScreenState();
}

class _AdminAuthScreenState extends State<AdminAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _businessController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context);
    bool success;

    if (_isLogin) {
      success = await auth.loginAsAdmin(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      success = await auth.registerAdmin(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        businessName: _businessController.text.trim(),
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
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
        title: Text(l10n.translate(_isLogin ? 'adminLogin' : 'adminRegister')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: AppColors.accent, size: 36),
                ),
              ),
              const SizedBox(height: 28),

              // Register-only fields
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
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('phone'),
                    prefixIcon: const Icon(Icons.phone_rounded),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _businessController,
                  decoration: InputDecoration(
                    labelText: '${l10n.translate('businessName')} (${l10n.translate('optional')})',
                    prefixIcon: const Icon(Icons.store_rounded),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n.translate('email'),
                  prefixIcon: const Icon(Icons.email_rounded),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? l10n.translate('required') : null,
              ),
              const SizedBox(height: 12),

              // Password
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.translate('password'),
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                obscureText: _obscure,
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return l10n.translate('required');
                  if (!_isLogin && (v?.length ?? 0) < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 24),

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

              const SizedBox(height: 20),

              // Back to customer login
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_rounded,
                      color: AppColors.textHint, size: 16),
                  label: Text(l10n.translate('enterAsCustomer'),
                      style: TextStyle(fontSize: 12,
                          color: AppColors.textHint)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
