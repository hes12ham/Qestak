import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';

class CustomerAuthScreen extends StatefulWidget {
  const CustomerAuthScreen({super.key});
  @override
  State<CustomerAuthScreen> createState() => _CustomerAuthScreenState();
}

class _CustomerAuthScreenState extends State<CustomerAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context);

    final success = await auth.loginAsCustomer(
      _phoneController.text.trim(),
      _passwordController.text,
    );

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
    final locale = Provider.of<LocaleProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: TextButton.icon(
                    onPressed: () => locale.toggleLocale(),
                    icon: const Icon(Icons.language, size: 18),
                    label: Text(locale.isArabic ? 'EN' : 'عربي',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: AppColors.primary,
                      borderRadius: BorderRadius.circular(22)),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 40),
                )),
                const SizedBox(height: 14),
                Center(child: Text(l10n.translate('appName'),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                        color: AppColors.primary))),
                const SizedBox(height: 6),
                Center(child: Text(l10n.translate('loginSubtitle'),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                const SizedBox(height: 32),

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
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? l10n.translate('required') : null,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(l10n.translate('login'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 40),

                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withOpacity(0.15)),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.adminLogin),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.admin_panel_settings_rounded, color: AppColors.accent, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.translate('enterAsAdmin'),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                color: AppColors.accent)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
