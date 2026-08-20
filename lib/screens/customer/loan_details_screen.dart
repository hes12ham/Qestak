import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/loan.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/payment_progress_ring.dart';

class LoanDetailsScreen extends StatelessWidget {
  final Loan loan;
  const LoanDetailsScreen({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = NumberFormat('#,##0');
    final dateFmt = DateFormat('yyyy/MM/dd');
    final timeFmt = DateFormat('yyyy/MM/dd - HH:mm');
    final isAdmin =
        Provider.of<AuthProvider>(context, listen: false).role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('loanDetails'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress ring
            PaymentProgressRing(
              progress: loan.progressPercentage,
              paidAmount: loan.paidAmount,
              totalAmount: loan.loanAmount,
              currency: l10n.translate('currency'),
              label: l10n.translate(isAdmin ? 'customerName' : 'loanFrom'),
            ),
            const SizedBox(height: 16),

            // Creditor / Customer info
            _infoCard(
              icon: isAdmin ? Icons.person_rounded : Icons.store_rounded,
              color: AppColors.accent,
              title: isAdmin
                  ? loan.customerName
                  : loan.adminName,
              subtitle: isAdmin
                  ? '${loan.customerPhone}\n${loan.customerNationalId}'
                  : loan.adminPhone.isNotEmpty
                      ? loan.adminPhone
                      : l10n.translate('creditor'),
              l10n: l10n,
              headerLabel: l10n.translate(
                  isAdmin ? 'personalInfo' : 'creditorInfo'),
            ),
            const SizedBox(height: 12),

            // Financial details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.cardShadow,
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.translate('loanInfo'),
                      style: const TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const Divider(height: 20),
                  _detailRow(l10n.translate('loanAmount'),
                      '${fmt.format(loan.loanAmount)} ${l10n.translate('currency')}'),
                  _detailRow(l10n.translate('installmentValue'),
                      '${fmt.format(loan.installmentValue)} ${l10n.translate('currency')}'),
                  _detailRow(l10n.translate('paidAmount'),
                      '${fmt.format(loan.paidAmount)} ${l10n.translate('currency')}',
                      color: AppColors.success),
                  _detailRow(l10n.translate('remainingAmount'),
                      '${fmt.format(loan.remainingAmount)} ${l10n.translate('currency')}',
                      color: AppColors.danger),
                  _detailRow(l10n.translate('paidInstallments'),
                      '${loan.paidInstallments} / ${loan.totalInstallments}'),
                  _detailRow(l10n.translate('startDate'),
                      dateFmt.format(loan.startDate)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Due dates timeline
            if (loan.dueDates.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.cardShadow,
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.translate('dueDates'),
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    ...List.generate(loan.dueDates.length, (i) {
                      final date = loan.dueDates[i];
                      final isPaid = i < loan.paidInstallments;
                      final isCurrent = i == loan.paidInstallments;
                      final isOverdue =
                          !isPaid && date.isBefore(DateTime.now());

                      Color dotColor = AppColors.divider;
                      String label = '';
                      if (isPaid) {
                        dotColor = AppColors.success;
                        label = l10n.translate('paid');
                      } else if (isOverdue) {
                        dotColor = AppColors.danger;
                        label = l10n.translate('overdue');
                      } else if (isCurrent) {
                        dotColor = AppColors.accent;
                        label = l10n.translate('upcoming');
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                                boxShadow: isCurrent
                                    ? [BoxShadow(color: dotColor.withOpacity(0.4),
                                        blurRadius: 6)]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(dateFmt.format(date),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isCurrent
                                      ? FontWeight.w700 : FontWeight.w400,
                                  color: isPaid
                                      ? AppColors.textHint
                                      : AppColors.textPrimary,
                                )),
                            const Spacer(),
                            if (label.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: dotColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(label,
                                    style: TextStyle(fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: dotColor)),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Payment history
            if (loan.payments.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.cardShadow,
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.translate('paymentHistory'),
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    ...loan.payments.reversed.map((p) {
                      IconData icon;
                      switch (p.method) {
                        case 'transfer': icon = Icons.account_balance; break;
                        case 'qr': icon = Icons.qr_code_2; break;
                        default: icon = Icons.payments_rounded;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, color: AppColors.success,
                                  size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.translate(p.method),
                                      style: const TextStyle(fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  Text(timeFmt.format(p.date),
                                      style: TextStyle(fontSize: 10,
                                          color: AppColors.textHint)),
                                ],
                              ),
                            ),
                            Text('+${fmt.format(p.amount)} ${l10n.translate('currency')}',
                                style: const TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required AppLocalizations l10n,
    required String headerLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.cardShadow,
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headerLabel, style: const TextStyle(fontSize: 14,
              fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w700)),
                    Text(subtitle, style: TextStyle(fontSize: 12,
                        color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13,
              color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
