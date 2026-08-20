import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.cardShadow,
                  blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.primary),
                title: Text(l10n.translate('language')),
                subtitle: Text(locale.isArabic ? 'العربية' : 'English'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(children: [
                  _langOpt('العربية', locale.isArabic,
                      () => locale.setLocale(const Locale('ar'))),
                  const SizedBox(width: 12),
                  _langOpt('English', !locale.isArabic,
                      () => locale.setLocale(const Locale('en'))),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.cardShadow,
                  blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(l10n.translate('about'),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 8),
                Text('${l10n.translate('version')} 2.0.0',
                    style: TextStyle(color: AppColors.textSecondary,
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text(l10n.isArabic
                    ? 'قسطك — تطبيق متعدد الدائنين لإدارة الأقساط والمدفوعات'
                    : 'Qestak — Multi-creditor installment tracking app',
                    style: TextStyle(color: AppColors.textSecondary,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _langOpt(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: active ? AppColors.primary : AppColors.divider,
                width: active ? 2 : 1),
            color: active ? AppColors.primary.withOpacity(0.06) : null,
          ),
          child: Center(child: Text(label,
              style: TextStyle(fontWeight: FontWeight.w600,
                  color: active ? AppColors.primary : AppColors.textSecondary))),
        ),
      ),
    );
  }
}
