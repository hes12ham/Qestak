import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/loan.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final loanProv = Provider.of<LoanProvider>(context, listen: false);
      if (auth.currentAdmin != null) {
        loanProv.startListening(auth.currentAdmin!.id);
        loanProv.loadStatistics(auth.currentAdmin!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final locale = Provider.of<LocaleProvider>(context);
    final fmt = NumberFormat('#,##0');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('adminDashboard')),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.language),
              onPressed: () => locale.toggleLocale()),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              switch (v) {
                case 'import': Navigator.pushNamed(context, AppRoutes.importExcel); break;
                case 'stats': Navigator.pushNamed(context, AppRoutes.statistics); break;
                case 'settings': Navigator.pushNamed(context, AppRoutes.settings); break;
                case 'logout':
                  auth.logout();
                  Navigator.pushReplacementNamed(context, AppRoutes.roleChoice);
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'import',
                  child: Row(children: [
                    const Icon(Icons.upload_file, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.translate('importExcel'))])),
              PopupMenuItem(value: 'stats',
                  child: Row(children: [
                    const Icon(Icons.bar_chart, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.translate('statistics'))])),
              PopupMenuItem(value: 'settings',
                  child: Row(children: [
                    const Icon(Icons.settings, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.translate('settings'))])),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'logout',
                  child: Row(children: [
                    Icon(Icons.logout, size: 20, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Text(l10n.translate('logout'),
                        style: TextStyle(color: AppColors.danger))])),
            ],
          ),
        ],
      ),
      body: Consumer<LoanProvider>(
        builder: (context, loanProv, _) {
          final stats = loanProv.statistics;
          final loans = loanProv.filteredLoans;

          return Column(
            children: [
              // Stats row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _statChip(
                        '${stats['totalLoans'] ?? loanProv.allLoans.length}',
                        l10n.translate('totalLoans'), AppColors.primary),
                    const SizedBox(width: 6),
                    _statChip(
                        '${stats['activeLoans'] ?? 0}',
                        l10n.translate('active'), AppColors.success),
                    const SizedBox(width: 6),
                    _statChip(
                        '${stats['overdueLoans'] ?? 0}',
                        l10n.translate('overdue'), AppColors.danger),
                    const SizedBox(width: 6),
                    _statChip(
                        '${stats['completedLoans'] ?? 0}',
                        l10n.translate('completed'), AppColors.info),
                  ],
                ),
              ),

              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => loanProv.setSearch(v),
                  decoration: InputDecoration(
                    hintText: l10n.translate('searchByNameOrPhone'),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.divider)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.divider)),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Filter chips
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _filterChip(l10n, loanProv, 'all', l10n.translate('all')),
                    _filterChip(l10n, loanProv, 'active', l10n.translate('active')),
                    _filterChip(l10n, loanProv, 'overdue', l10n.translate('overdue')),
                    _filterChip(l10n, loanProv, 'completed', l10n.translate('completed')),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Loan list
              Expanded(
                child: loans.isEmpty
                    ? Center(child: Text(l10n.translate('noData'),
                        style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: loans.length,
                        itemBuilder: (_, i) =>
                            _buildLoanItem(context, loans[i], l10n, fmt),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'import',
            backgroundColor: AppColors.accent,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.importExcel),
            child: const Icon(Icons.upload_file, size: 20),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addLoan),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanItem(BuildContext context, Loan loan,
      AppLocalizations l10n, NumberFormat fmt) {
    final statusColor = loan.status == 'completed'
        ? AppColors.info
        : loan.isOverdue ? AppColors.danger : AppColors.success;
    final statusLabel = loan.status == 'completed'
        ? l10n.translate('completed')
        : loan.isOverdue ? l10n.translate('overdue') : l10n.translate('active');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(context, AppRoutes.adminLoanDetails,
            arguments: loan),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    loan.customerName.isNotEmpty
                        ? loan.customerName.substring(0, 1)
                        : '?',
                    style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loan.customerName,
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(loan.customerPhone,
                        style: TextStyle(fontSize: 11,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: loan.progressPercentage,
                        minHeight: 5,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation(statusColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${fmt.format(loan.paidAmount)} ${l10n.translate('currency')}',
                      style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(fontSize: 10,
                            fontWeight: FontWeight.w600, color: statusColor)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.w700, color: color)),
            Text(label, style: TextStyle(fontSize: 9,
                color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(AppLocalizations l10n, LoanProvider prov,
      String status, String label) {
    final isActive = prov.filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary)),
        selected: isActive,
        onSelected: (_) => prov.setFilter(status),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        side: BorderSide(color: isActive ? AppColors.primary : AppColors.divider),
      ),
    );
  }
}
