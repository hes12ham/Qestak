import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/loan.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../widgets/payment_progress_ring.dart';
import '../../services/notification_service.dart';

class AdminLoanDetailsScreen extends StatefulWidget {
  final Loan loan;
  const AdminLoanDetailsScreen({super.key, required this.loan});
  @override
  State<AdminLoanDetailsScreen> createState() => _AdminLoanDetailsScreenState();
}

class _AdminLoanDetailsScreenState extends State<AdminLoanDetailsScreen> {
  late Loan _loan;

  @override
  void initState() {
    super.initState();
    _loan = widget.loan;
  }

  void _showPaymentSheet() {
    final l10n = AppLocalizations.of(context);
    final amountC = TextEditingController(
        text: _loan.installmentValue.toStringAsFixed(0));
    String method = 'cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.translate('recordPayment'),
                  style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: amountC,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.translate('paymentAmount'),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.translate('paymentMethod'),
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _methodChip('cash', l10n.translate('cash'),
                      Icons.payments, method,
                      (v) => setSheetState(() => method = v)),
                  const SizedBox(width: 8),
                  _methodChip('transfer', l10n.translate('transfer'),
                      Icons.account_balance, method,
                      (v) => setSheetState(() => method = v)),
                  const SizedBox(width: 8),
                  _methodChip('qr', l10n.translate('qr'),
                      Icons.qr_code_2, method,
                      (v) => setSheetState(() => method = v)),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountC.text) ?? 0;
                  if (amount <= 0) return;
                  Navigator.pop(ctx);
                  final prov = Provider.of<LoanProvider>(context,
                      listen: false);
                  final updated = await prov.recordPayment(
                    loanId: _loan.id,
                    amount: amount,
                    method: method,
                  );
                  if (updated != null) {
                    setState(() => _loan = updated);
                    NotificationService.notifyPaymentRecorded(
                      customerName: _loan.customerName,
                      amount: amount,
                      currency: l10n.translate('currency'),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(l10n.translate('paymentRecorded')),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  }
                },
                child: Text(l10n.translate('confirm'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQR() {
    final qrData = 'qestak:${_loan.id}|${_loan.customerName}|${_loan.installmentValue}';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loan.customerName,
                  style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              QrImageView(data: qrData, size: 200,
                  backgroundColor: Colors.white),
              const SizedBox(height: 12),
              Text(qrData, style: TextStyle(fontSize: 10,
                  color: AppColors.textHint)),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullImage(String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(path)),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.translate('confirmDelete')),
        content: Text(l10n.translate('deleteWarning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await Provider.of<LoanProvider>(context, listen: false)
                  .deleteLoan(_loan.id);
              if (mounted) Navigator.pop(context); // back to dashboard
            },
            child: Text(l10n.translate('delete'),
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = NumberFormat('#,##0');
    final dateFmt = DateFormat('yyyy/MM/dd');
    final timeFmt = DateFormat('yyyy/MM/dd - HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('loanDetails')),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_2),
              onPressed: _showQR),
          IconButton(icon: Icon(Icons.delete, color: AppColors.danger),
              onPressed: _confirmDelete),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Customer header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.cardShadow,
                    blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text(
                        _loan.customerName.isNotEmpty
                            ? _loan.customerName.substring(0, 1) : '?',
                        style: const TextStyle(fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_loan.customerName,
                            style: const TextStyle(fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        Text(_loan.customerPhone,
                            style: TextStyle(fontSize: 12,
                                color: AppColors.textSecondary)),
                        Text(_loan.customerNationalId,
                            style: TextStyle(fontSize: 11,
                                color: AppColors.textHint)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ID Card Image (if exists)
            if (_loan.idImagePath != null && File(_loan.idImagePath!).existsSync())
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.badge_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.translate('pickIdImage'),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _showFullImage(_loan.idImagePath!),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        child: Image.file(File(_loan.idImagePath!),
                            width: double.infinity, height: 180, fit: BoxFit.cover),
                      ),
                    ),
                  ],
                ),
              ),

            // Progress
            PaymentProgressRing(
              progress: _loan.progressPercentage,
              paidAmount: _loan.paidAmount,
              totalAmount: _loan.loanAmount,
              currency: l10n.translate('currency'),
              label: l10n.translate('collectionRate'),
            ),
            const SizedBox(height: 14),

            // Financial details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
              ),
              child: Column(
                children: [
                  _row(l10n.translate('loanAmount'),
                      '${fmt.format(_loan.loanAmount)} ${l10n.translate('currency')}'),
                  _row(l10n.translate('installmentValue'),
                      '${fmt.format(_loan.installmentValue)} ${l10n.translate('currency')}'),
                  _row(l10n.translate('paidAmount'),
                      '${fmt.format(_loan.paidAmount)} ${l10n.translate('currency')}',
                      color: AppColors.success),
                  _row(l10n.translate('remainingAmount'),
                      '${fmt.format(_loan.remainingAmount)} ${l10n.translate('currency')}',
                      color: AppColors.danger),
                  _row(l10n.translate('paidInstallments'),
                      '${_loan.paidInstallments} / ${_loan.totalInstallments}'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Due dates
            if (_loan.dueDates.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.translate('dueDates'),
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...List.generate(_loan.dueDates.length, (i) {
                      final d = _loan.dueDates[i];
                      final isPaid = i < _loan.paidInstallments;
                      final isOverdue = !isPaid && d.isBefore(DateTime.now());
                      final isCurrent = i == _loan.paidInstallments;
                      final color = isPaid ? AppColors.success
                          : isOverdue ? AppColors.danger
                          : isCurrent ? AppColors.accent : AppColors.divider;
                      final label = isPaid ? '✅' : isOverdue ? '⚠️'
                          : isCurrent ? '⏳' : '';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(children: [
                          Container(width: 10, height: 10,
                              decoration: BoxDecoration(color: color,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Text(dateFmt.format(d), style: TextStyle(
                              fontSize: 12, color: isPaid
                                  ? AppColors.textHint : null)),
                          const Spacer(),
                          Text(label, style: const TextStyle(fontSize: 12)),
                        ]),
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 14),

            // Payments
            if (_loan.payments.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.translate('paymentHistory'),
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...(_loan.payments.reversed.map((p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Icon(p.method == 'transfer'
                            ? Icons.account_balance
                            : p.method == 'qr' ? Icons.qr_code_2
                            : Icons.payments,
                            size: 18, color: AppColors.success),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.translate(p.method),
                                style: const TextStyle(fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            Text(timeFmt.format(p.date),
                                style: TextStyle(fontSize: 10,
                                    color: AppColors.textHint)),
                          ],
                        )),
                        Text('+${fmt.format(p.amount)} ${l10n.translate('currency')}',
                            style: const TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success)),
                      ]),
                    ))),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Record payment button
            if (_loan.status != 'completed')
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _showPaymentSheet,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent),
                  icon: const Icon(Icons.add_card),
                  label: Text(l10n.translate('recordPayment'),
                      style: const TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? color}) {
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

  Widget _methodChip(String value, String label, IconData icon,
      String current, Function(String) onSelect) {
    final isActive = current == value;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isActive ? AppColors.primary : AppColors.divider,
                width: isActive ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20,
                  color: isActive ? AppColors.primary : AppColors.textHint),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.primary : AppColors.textHint)),
            ],
          ),
        ),
      ),
    );
  }
}
