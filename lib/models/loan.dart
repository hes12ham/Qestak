import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final double amount;
  final DateTime date;
  final String method;
  final String? confirmedBy;
  final String? notes;

  Payment({required this.id, required this.amount, required this.date,
    this.method = 'cash', this.confirmedBy, this.notes});

  Map<String, dynamic> toMap() => {
    'id': id, 'amount': amount, 'date': Timestamp.fromDate(date),
    'method': method, 'confirmedBy': confirmedBy, 'notes': notes,
  };

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
    id: m['id'] ?? '', amount: (m['amount'] ?? 0).toDouble(),
    date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    method: m['method'] ?? 'cash', confirmedBy: m['confirmedBy'], notes: m['notes'],
  );
}

class Loan {
  final String id;
  final String adminId;
  final String adminName;
  final String adminPhone;
  final String customerName;
  final String customerPhone;
  final String customerNationalId;
  final double loanAmount;
  final double installmentValue;
  final int totalInstallments;
  final int paidInstallments;
  final double paidAmount;
  final DateTime startDate;       // تاريخ البداية (يوم استلام المبلغ)
  final DateTime firstDueDate;    // تاريخ الاستحقاق (أول قسط)
  final List<DateTime> dueDates;
  final List<Payment> payments;
  final String status;
  final String? notes;
  final String? idImagePath;
  final DateTime createdAt;

  Loan({
    required this.id,
    required this.adminId,
    required this.adminName,
    this.adminPhone = '',
    required this.customerName,
    required this.customerPhone,
    required this.customerNationalId,
    required this.loanAmount,
    required this.installmentValue,
    required this.totalInstallments,
    this.paidInstallments = 0,
    this.paidAmount = 0,
    required this.startDate,
    DateTime? firstDueDate,
    this.dueDates = const [],
    this.payments = const [],
    this.status = 'active',
    this.notes,
    this.idImagePath,
    DateTime? createdAt,
  }) : firstDueDate = firstDueDate ?? startDate,
       createdAt = createdAt ?? DateTime.now();

  double get remainingAmount => loanAmount - paidAmount;
  double get progressPercentage =>
      loanAmount > 0 ? (paidAmount / loanAmount).clamp(0.0, 1.0) : 0.0;

  DateTime? get nextDueDate {
    final now = DateTime.now();
    for (int i = 0; i < dueDates.length; i++) {
      if (i >= paidInstallments && dueDates[i].isAfter(now)) return dueDates[i];
    }
    if (paidInstallments < dueDates.length) return dueDates[paidInstallments];
    return null;
  }

  bool get isOverdue {
    if (status == 'completed') return false;
    for (int i = paidInstallments; i < dueDates.length; i++) {
      if (dueDates[i].isBefore(DateTime.now())) return true;
    }
    return false;
  }

  int get overdueDays {
    if (!isOverdue) return 0;
    for (int i = paidInstallments; i < dueDates.length; i++) {
      if (dueDates[i].isBefore(DateTime.now())) {
        return DateTime.now().difference(dueDates[i]).inDays;
      }
    }
    return 0;
  }

  Map<String, dynamic> toMap() => {
    'adminId': adminId, 'adminName': adminName, 'adminPhone': adminPhone,
    'customerName': customerName, 'customerPhone': customerPhone,
    'customerNationalId': customerNationalId,
    'loanAmount': loanAmount, 'installmentValue': installmentValue,
    'totalInstallments': totalInstallments, 'paidInstallments': paidInstallments,
    'paidAmount': paidAmount,
    'startDate': Timestamp.fromDate(startDate),
    'firstDueDate': Timestamp.fromDate(firstDueDate),
    'dueDates': dueDates.map((d) => Timestamp.fromDate(d)).toList(),
    'payments': payments.map((p) => p.toMap()).toList(),
    'status': status, 'notes': notes, 'idImagePath': idImagePath,
    'createdAt': Timestamp.fromDate(createdAt),
    'customerPhoneSearch': customerPhone.replaceAll(RegExp(r'[^\d]'), ''),
    'customerNationalIdSearch': customerNationalId.replaceAll(RegExp(r'[^\d]'), ''),
  };

  factory Loan.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final start = (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    return Loan(
      id: doc.id,
      adminId: d['adminId'] ?? '', adminName: d['adminName'] ?? '',
      adminPhone: d['adminPhone'] ?? '',
      customerName: d['customerName'] ?? '', customerPhone: d['customerPhone'] ?? '',
      customerNationalId: d['customerNationalId'] ?? '',
      loanAmount: (d['loanAmount'] ?? 0).toDouble(),
      installmentValue: (d['installmentValue'] ?? 0).toDouble(),
      totalInstallments: d['totalInstallments'] ?? 0,
      paidInstallments: d['paidInstallments'] ?? 0,
      paidAmount: (d['paidAmount'] ?? 0).toDouble(),
      startDate: start,
      firstDueDate: (d['firstDueDate'] as Timestamp?)?.toDate() ?? start,
      dueDates: (d['dueDates'] as List<dynamic>?)
          ?.map((x) => (x as Timestamp).toDate()).toList() ?? [],
      payments: (d['payments'] as List<dynamic>?)
          ?.map((p) => Payment.fromMap(p as Map<String, dynamic>)).toList() ?? [],
      status: d['status'] ?? 'active', notes: d['notes'],
      idImagePath: d['idImagePath'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Loan copyWith({
    String? id, String? adminId, String? adminName, String? adminPhone,
    String? customerName, String? customerPhone, String? customerNationalId,
    double? loanAmount, double? installmentValue, int? totalInstallments,
    int? paidInstallments, double? paidAmount, DateTime? startDate,
    DateTime? firstDueDate, List<DateTime>? dueDates, List<Payment>? payments,
    String? status, String? notes, String? idImagePath,
  }) => Loan(
    id: id ?? this.id, adminId: adminId ?? this.adminId,
    adminName: adminName ?? this.adminName, adminPhone: adminPhone ?? this.adminPhone,
    customerName: customerName ?? this.customerName,
    customerPhone: customerPhone ?? this.customerPhone,
    customerNationalId: customerNationalId ?? this.customerNationalId,
    loanAmount: loanAmount ?? this.loanAmount,
    installmentValue: installmentValue ?? this.installmentValue,
    totalInstallments: totalInstallments ?? this.totalInstallments,
    paidInstallments: paidInstallments ?? this.paidInstallments,
    paidAmount: paidAmount ?? this.paidAmount,
    startDate: startDate ?? this.startDate,
    firstDueDate: firstDueDate ?? this.firstDueDate,
    dueDates: dueDates ?? this.dueDates, payments: payments ?? this.payments,
    status: status ?? this.status, notes: notes ?? this.notes,
    idImagePath: idImagePath ?? this.idImagePath, createdAt: createdAt,
  );
}
