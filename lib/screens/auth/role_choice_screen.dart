import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';

class RoleChoiceScreen extends StatelessWidget {
  const RoleChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Provider.of<LocaleProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Language toggle
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: TextButton.icon(
                  onPressed: () => locale.toggleLocale(),
                  icon: const Icon(Icons.language, size: 20),
                  label: Text(locale.isArabic ? 'EN' : 'عربي',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const Spacer(),
              // Logo
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 44),
              ),
              const SizedBox(height: 16),
              Text(l10n.translate('appName'),
                  style: const TextStyle(fontSize: 28,
                      fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 8),
              Text(l10n.translate('chooseRole'),
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 48),

              // Customer button
              _RoleButton(
                icon: Icons.person_rounded,
                title: l10n.translate('enterAsCustomer'),
                subtitle: l10n.isArabic
                    ? 'تابع أقساطك ومدفوعاتك'
                    : 'Track your installments & payments',
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, AppRoutes.customerLogin),
              ),
              const SizedBox(height: 16),

              // Admin button
              _RoleButton(
                icon: Icons.admin_panel_settings_rounded,
                title: l10n.translate('enterAsAdmin'),
                subtitle: l10n.isArabic
                    ? 'أدر عملاءك وأقساطهم'
                    : 'Manage your clients & loans',
                color: AppColors.accent,
                onTap: () => Navigator.pushNamed(context, AppRoutes.adminLogin),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleButton({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w700, color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12,
                      color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
