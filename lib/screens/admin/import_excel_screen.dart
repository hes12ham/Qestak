import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../services/excel_import_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

class ImportExcelScreen extends StatefulWidget {
  const ImportExcelScreen({super.key});
  @override
  State<ImportExcelScreen> createState() => _ImportExcelScreenState();
}

class _ImportExcelScreenState extends State<ImportExcelScreen> {
  ExcelImportResult? _result;
  bool _isLoading = false;
  bool _isImporting = false;
  String? _fileName;

  Future<void> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (picked == null || picked.files.isEmpty) return;

    setState(() {
      _isLoading = true;
      _fileName = picked.files.first.name;
    });

    final path = picked.files.first.path;
    if (path == null) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await ExcelImportService.parseExcelFile(path);
    setState(() {
      _result = result;
      _isLoading = false;
    });
  }

  Future<void> _confirmImport() async {
    if (_result == null || _result!.rows.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final admin = auth.currentAdmin!;
    final l10n = AppLocalizations.of(context);

    setState(() => _isImporting = true);

    final count = await FirestoreService.importLoansFromExcel(
      adminId: admin.id,
      adminName: admin.displayName,
      adminPhone: admin.phone,
      rows: _result!.rows,
    );

    setState(() => _isImporting = false);

    if (mounted) {
      // Refresh admin loans
      Provider.of<LoanProvider>(context, listen: false)
          .loadLoans(admin.id);
      Provider.of<LoanProvider>(context, listen: false)
          .loadStatistics(admin.id);

      NotificationService.notifyImportComplete(count);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.translate('importSuccess')
            .replaceAll('{count}', '$count')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('importExcel'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.translate('excelInstructions'),
                          style: TextStyle(fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.translate('requiredColumns'),
                      style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  _columnTag(l10n.isArabic ? 'اسم العميل' : 'Customer Name', true),
                  _columnTag(l10n.isArabic ? 'رقم التليفون' : 'Phone', true),
                  _columnTag(l10n.isArabic ? 'الرقم القومي' : 'National ID', true),
                  _columnTag(l10n.isArabic ? 'مبلغ القرض' : 'Loan Amount', true),
                  const SizedBox(height: 8),
                  Text(l10n.translate('optionalColumns'),
                      style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  _columnTag(l10n.isArabic ? 'قيمة القسط' : 'Installment Value', false),
                  _columnTag(l10n.isArabic ? 'عدد الأقساط' : 'Total Installments', false),
                  _columnTag(l10n.isArabic ? 'المدفوع' : 'Paid Amount', false),
                  _columnTag(l10n.isArabic ? 'تاريخ البداية' : 'Start Date', false),
                  _columnTag(l10n.isArabic ? 'ملاحظات' : 'Notes', false),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pick file button
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _pickFile,
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_file, size: 22),
              label: Text(_fileName ?? l10n.translate('selectFile'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            const SizedBox(height: 16),

            // Results
            if (_result != null && !_result!.success)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_result!.error ?? 'Unknown error',
                        style: TextStyle(fontSize: 12,
                            color: AppColors.danger))),
                  ],
                ),
              ),

            if (_result != null && _result!.success) ...[
              // Summary
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.translate('rowsDetected')
                        .replaceAll('{count}', '${_result!.rows.length}'),
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Preview table
              Text(l10n.translate('previewData'),
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                          AppColors.primary.withOpacity(0.06)),
                      dataRowMinHeight: 36,
                      dataRowMaxHeight: 44,
                      columnSpacing: 16,
                      horizontalMargin: 12,
                      columns: [
                        DataColumn(label: Text(l10n.isArabic ? 'الاسم' : 'Name',
                            style: _headerStyle)),
                        DataColumn(label: Text(l10n.isArabic ? 'التليفون' : 'Phone',
                            style: _headerStyle)),
                        DataColumn(label: Text(l10n.isArabic ? 'المبلغ' : 'Amount',
                            style: _headerStyle)),
                      ],
                      rows: _result!.rows.take(5).map((row) => DataRow(
                        cells: [
                          DataCell(Text('${row['name'] ?? ''}',
                              style: _cellStyle)),
                          DataCell(Text('${row['phone'] ?? ''}',
                              style: _cellStyle)),
                          DataCell(Text('${row['loanAmount'] ?? ''}',
                              style: _cellStyle)),
                        ],
                      )).toList(),
                    ),
                  ),
                ),
              ),
              if (_result!.rows.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '... +${_result!.rows.length - 5} ${l10n.isArabic ? 'صفوف أخرى' : 'more rows'}',
                    style: TextStyle(fontSize: 11,
                        color: AppColors.textHint),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),

              // Import button
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isImporting ? null : _confirmImport,
                  icon: _isImporting
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_upload),
                  label: Text(l10n.translate('confirmImport'),
                      style: const TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _columnTag(String name, bool required) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(required ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 14,
              color: required ? AppColors.success : AppColors.textHint),
          const SizedBox(width: 6),
          Text(name, style: TextStyle(fontSize: 12,
              color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => const TextStyle(fontSize: 11,
      fontWeight: FontWeight.w700);
  TextStyle get _cellStyle => const TextStyle(fontSize: 11);
}
