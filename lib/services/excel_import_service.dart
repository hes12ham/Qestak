import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

/// Parses an Excel file into a list of maps for loan import.
///
/// Expected columns (Arabic or English):
/// اسم العميل / Customer Name
/// رقم التليفون / Phone
/// الرقم القومي / National ID
/// مبلغ القرض / Loan Amount
/// قيمة القسط / Installment Value
/// عدد الأقساط / Total Installments
/// المدفوع / Paid Amount (optional)
/// الأقساط المدفوعة / Paid Installments (optional)
/// تاريخ البداية / Start Date (optional)
/// ملاحظات / Notes (optional)
class ExcelImportService {
  // Column name mappings (Arabic → key)
  static const _columnMappings = {
    // Arabic
    'اسم العميل': 'name',
    'الاسم': 'name',
    'اسم': 'name',
    'رقم التليفون': 'phone',
    'التليفون': 'phone',
    'الموبايل': 'phone',
    'رقم الموبايل': 'phone',
    'الرقم القومي': 'nationalId',
    'رقم قومي': 'nationalId',
    'مبلغ القرض': 'loanAmount',
    'المبلغ': 'loanAmount',
    'إجمالي القرض': 'loanAmount',
    'قيمة القسط': 'installmentValue',
    'القسط': 'installmentValue',
    'عدد الأقساط': 'totalInstallments',
    'المدفوع': 'paidAmount',
    'المبلغ المدفوع': 'paidAmount',
    'الأقساط المدفوعة': 'paidInstallments',
    'عدد الأقساط المدفوعة': 'paidInstallments',
    'تاريخ البداية': 'startDate',
    'التاريخ': 'startDate',
    'ملاحظات': 'notes',
    // English
    'customer name': 'name',
    'name': 'name',
    'phone': 'phone',
    'phone number': 'phone',
    'mobile': 'phone',
    'national id': 'nationalId',
    'nationalid': 'nationalId',
    'nid': 'nationalId',
    'loan amount': 'loanAmount',
    'amount': 'loanAmount',
    'installment value': 'installmentValue',
    'installment': 'installmentValue',
    'total installments': 'totalInstallments',
    'installments': 'totalInstallments',
    'count': 'totalInstallments',
    'paid amount': 'paidAmount',
    'paid': 'paidAmount',
    'paid installments': 'paidInstallments',
    'start date': 'startDate',
    'date': 'startDate',
    'notes': 'notes',
  };

  /// Parse an Excel file from path → list of row maps
  static Future<ExcelImportResult> parseExcelFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ExcelImportResult(
          success: false,
          error: 'File not found',
          rows: [],
        );
      }

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // Use first sheet
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      if (sheet.rows.isEmpty) {
        return ExcelImportResult(
          success: false,
          error: 'Empty sheet',
          rows: [],
        );
      }

      // Parse header row
      final headerRow = sheet.rows.first;
      final columnMap = <int, String>{}; // colIndex → fieldKey

      for (int i = 0; i < headerRow.length; i++) {
        final cell = headerRow[i];
        if (cell == null) continue;
        final headerText = cell.value.toString().trim().toLowerCase();
        final key = _columnMappings[headerText];
        if (key != null) {
          columnMap[i] = key;
        }
      }

      // Verify required columns
      final foundKeys = columnMap.values.toSet();
      if (!foundKeys.contains('name') ||
          !foundKeys.contains('phone') ||
          !foundKeys.contains('nationalId') ||
          !foundKeys.contains('loanAmount')) {
        return ExcelImportResult(
          success: false,
          error:
              'Missing required columns: name, phone, nationalId, loanAmount',
          rows: [],
          detectedColumns: foundKeys.toList(),
        );
      }

      // Parse data rows
      final rows = <Map<String, dynamic>>[];
      int skipped = 0;

      for (int r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        final map = <String, dynamic>{};
        bool hasData = false;

        for (final entry in columnMap.entries) {
          final colIdx = entry.key;
          final fieldKey = entry.value;

          if (colIdx >= row.length || row[colIdx] == null) {
            map[fieldKey] = null;
            continue;
          }

          final cellValue = row[colIdx]!.value;
          hasData = true;

          if (fieldKey == 'startDate') {
            map[fieldKey] = _parseDate(cellValue);
          } else if (['loanAmount', 'installmentValue', 'paidAmount']
              .contains(fieldKey)) {
            map[fieldKey] = _toDouble(cellValue);
          } else if (['totalInstallments', 'paidInstallments']
              .contains(fieldKey)) {
            map[fieldKey] = _toInt(cellValue);
          } else {
            map[fieldKey] = cellValue.toString().trim();
          }
        }

        if (hasData && (map['name']?.toString().trim().isNotEmpty ?? false)) {
          rows.add(map);
        } else {
          skipped++;
        }
      }

      return ExcelImportResult(
        success: true,
        rows: rows,
        skippedRows: skipped,
        detectedColumns: foundKeys.toList(),
      );
    } catch (e) {
      return ExcelImportResult(
        success: false,
        error: e.toString(),
        rows: [],
      );
    }
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    if (val is double) {
      // Excel serial date
      return DateTime(1899, 12, 30).add(Duration(days: val.toInt()));
    }
    final s = val.toString().trim();
    for (final fmt in [
      'yyyy/MM/dd', 'yyyy-MM-dd', 'dd/MM/yyyy', 'dd-MM-yyyy',
      'MM/dd/yyyy',
    ]) {
      try {
        return DateFormat(fmt).parse(s);
      } catch (_) {}
    }
    return null;
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString().replaceAll(',', '')) ?? 0;
  }

  static int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    return int.tryParse(val.toString().replaceAll(',', '')) ?? 0;
  }
}

class ExcelImportResult {
  final bool success;
  final String? error;
  final List<Map<String, dynamic>> rows;
  final int skippedRows;
  final List<String>? detectedColumns;

  ExcelImportResult({
    required this.success,
    this.error,
    required this.rows,
    this.skippedRows = 0,
    this.detectedColumns,
  });
}
