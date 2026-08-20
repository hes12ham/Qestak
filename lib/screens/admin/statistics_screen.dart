import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminId = Provider.of<AuthProvider>(context, listen: false)
          .currentAdmin?.id;
      if (adminId != null) {
        Provider.of<LoanProvider>(context, listen: false)
            .loadStatistics(adminId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = NumberFormat('#,##0');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('statistics'))),
      body: Consumer<LoanProvider>(
        builder: (context, prov, _) {
          final s = prov.statistics;
          if (s.isEmpty) return const Center(child: CircularProgressIndicator());

          final totalLoans = s['totalLoans'] ?? 0;
          final active = s['activeLoans'] ?? 0;
          final overdue = s['overdueLoans'] ?? 0;
          final completed = s['completedLoans'] ?? 0;
          final totalLoaned = (s['totalLoaned'] ?? 0.0) as double;
          final totalCollected = (s['totalCollected'] ?? 0.0) as double;
          final totalRemaining = (s['totalRemaining'] ?? 0.0) as double;
          final rate = (s['collectionRate'] ?? 0.0) as double;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _card(l10n.translate('totalLoans'), '$totalLoans',
                      Icons.receipt_long, AppColors.primary),
                  const SizedBox(width: 10),
                  _card(l10n.translate('totalCustomers'),
                      '${s['totalCustomers'] ?? 0}',
                      Icons.people, AppColors.info),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _card(l10n.translate('activeLoans'), '$active',
                      Icons.trending_up, AppColors.success),
                  const SizedBox(width: 10),
                  _card(l10n.translate('overdueLoans'), '$overdue',
                      Icons.warning, AppColors.danger),
                ]),
                const SizedBox(height: 18),

                // Financial
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.cardShadow,
                        blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.translate('financialSummary'),
                          style: const TextStyle(fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      _finRow(l10n.translate('totalAmount'),
                          '${fmt.format(totalLoaned)} ${l10n.translate('currency')}',
                          AppColors.textPrimary),
                      _finRow(l10n.translate('totalCollected'),
                          '${fmt.format(totalCollected)} ${l10n.translate('currency')}',
                          AppColors.success),
                      _finRow(l10n.translate('totalRemaining'),
                          '${fmt.format(totalRemaining)} ${l10n.translate('currency')}',
                          AppColors.warning),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: rate / 100, minHeight: 10,
                            backgroundColor: AppColors.divider,
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.success),
                          ),
                        )),
                        const SizedBox(width: 10),
                        Text('${rate.toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.w700,
                                color: AppColors.success, fontSize: 15)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Pie chart
                if (totalLoans > 0) ...[
                  Text(l10n.translate('customerDistribution'),
                      style: const TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppColors.cardShadow,
                          blurRadius: 10)],
                    ),
                    child: Row(children: [
                      Expanded(child: PieChart(PieChartData(
                        sections: [
                          if (active > 0) PieChartSectionData(
                              value: active.toDouble(), color: AppColors.success,
                              title: '$active', radius: 45,
                              titleStyle: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          if (overdue > 0) PieChartSectionData(
                              value: overdue.toDouble(), color: AppColors.danger,
                              title: '$overdue', radius: 45,
                              titleStyle: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          if (completed > 0) PieChartSectionData(
                              value: completed.toDouble(), color: AppColors.info,
                              title: '$completed', radius: 45,
                              titleStyle: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                        centerSpaceRadius: 28, sectionsSpace: 3,
                      ))),
                      const SizedBox(width: 18),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _legend(AppColors.success, l10n.translate('active')),
                          const SizedBox(height: 6),
                          _legend(AppColors.danger, l10n.translate('overdue')),
                          const SizedBox(height: 6),
                          _legend(AppColors.info, l10n.translate('completed')),
                        ],
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 36, height: 36,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 24,
                fontWeight: FontWeight.w700, color: color)),
            Text(title, style: TextStyle(fontSize: 11,
                color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _finRow(String label, String value, Color color) {
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

  Widget _legend(Color color, String label) {
    return Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color,
              borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12,
          color: AppColors.textSecondary)),
    ]);
  }
}
