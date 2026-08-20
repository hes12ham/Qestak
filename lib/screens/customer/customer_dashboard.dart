import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/loan.dart';
import '../../widgets/payment_progress_ring.dart';
import '../../services/notification_service.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.refreshCustomerLoans();
      // Check for overdue and upcoming notifications
      if (auth.customerLoans.isNotEmpty) {
        NotificationService.checkOverdueLoans(auth.customerLoans);
        NotificationService.checkUpcomingDues(auth.customerLoans);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final locale = Provider.of<LocaleProvider>(context);
    final loans = auth.customerLoans;
    final loansByCreditor = auth.loansByCreditor;
    final fmt = NumberFormat('#,##0');

    // Totals across all creditors
    double totalOwed = 0, totalPaid = 0;
    for (final l in loans) {
      totalOwed += l.loanAmount;
      totalPaid += l.paidAmount;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('customerDashboard')),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.language),
              onPressed: () => locale.toggleLocale()),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () {
            auth.logout();
            Navigator.pushReplacementNamed(context, AppRoutes.roleChoice);
          }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => auth.refreshCustomerLoans(),
        child: loans.isEmpty
            ? _buildEmpty(l10n)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Welcome header
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${l10n.translate('welcome')} 👋',
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        Text(auth.customerName,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 20, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Overall summary
                  Row(
                    children: [
                      _summaryChip(l10n.translate('totalOwed'),
                          '${fmt.format(totalOwed)} ${l10n.translate('currency')}',
                          AppColors.primary),
                      const SizedBox(width: 8),
                      _summaryChip(l10n.translate('totalPaid'),
                          '${fmt.format(totalPaid)} ${l10n.translate('currency')}',
                          AppColors.success),
                      const SizedBox(width: 8),
                      _summaryChip(l10n.translate('totalRemaining'),
                          '${fmt.format(totalOwed - totalPaid)} ${l10n.translate('currency')}',
                          AppColors.danger),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section: My Loans
                  Text(l10n.translate('myLoans'),
                      style: const TextStyle(fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${loans.length} ${l10n.isArabic ? 'قسط من' : 'loan(s) from'} ${loansByCreditor.length} ${l10n.translate('creditor')}',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 14),

                  // Loans grouped by creditor
                  ...loansByCreditor.entries.map((entry) {
                    final creditorLoans = entry.value;
                    final creditorName = creditorLoans.first.adminName;
                    final creditorPhone = creditorLoans.first.adminPhone;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppColors.cardShadow,
                            blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          // Creditor header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.08),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.store_rounded,
                                      color: AppColors.accent, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(creditorName,
                                          style: const TextStyle(fontSize: 14,
                                              fontWeight: FontWeight.w700)),
                                      if (creditorPhone.isNotEmpty)
                                        Text(creditorPhone,
                                            style: TextStyle(fontSize: 11,
                                                color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Text('${creditorLoans.length} ${l10n.isArabic ? 'قسط' : 'loan(s)'}',
                                    style: TextStyle(fontSize: 11,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),

                          // Individual loans
                          ...creditorLoans.map((loan) =>
                              _buildLoanCard(context, loan, l10n, fmt)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  Widget _buildLoanCard(BuildContext context, Loan loan,
      AppLocalizations l10n, NumberFormat fmt) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final statusColor = loan.status == 'completed'
        ? AppColors.info
        : loan.isOverdue ? AppColors.danger : AppColors.success;
    final statusLabel = loan.status == 'completed'
        ? l10n.translate('completed')
        : loan.isOverdue ? l10n.translate('overdue') : l10n.translate('active');

    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.loanDetails,
          arguments: loan),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Mini progress ring
            SizedBox(
              width: 44, height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loan.progressPercentage,
                    strokeWidth: 4,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                  Text('${(loan.progressPercentage * 100).toInt()}%',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: statusColor)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${fmt.format(loan.loanAmount)} ${l10n.translate('currency')}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('${l10n.translate('installmentValue')}: ${fmt.format(loan.installmentValue)} • ${loan.paidInstallments}/${loan.totalInstallments}',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  if (loan.nextDueDate != null)
                    Text('${l10n.translate('nextDueDate')}: ${dateFormat.format(loan.nextDueDate!)}',
                        style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(statusLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      color: statusColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9,
                color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 80, color: AppColors.textHint),
            const SizedBox(height: 20),
            Text(l10n.translate('noLoansYet'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(l10n.translate('noLoansDescription'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
