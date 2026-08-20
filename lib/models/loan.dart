import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final double amount;
  final DateTime date;
  final String method; // cash, transfer, qr
  final String? confirmedBy;
  final String? notes;

  Payment({
    required this.id,
    required this.amount,
    required this.date,
    this.method = 'cash',
    this.confirmedBy,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'method': method,
        'confirmedBy': confirmedBy,
        'notes': notes,
      };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        method: map['method'] ?? 'cash',
        confirmedBy: map['confirmedBy'],
        notes: map['notes'],
      );
}

class Loan {
  final String id;

  // Creditor (admin) info
  final String adminId;
  final String adminName;
  final String adminPhone;

  // Customer info
  final String customerName;
  final String customerPhone;
  final String customerNationalId;

  // Loan details
  final double loanAmount;
  final double installmentValue;
  final int totalInstallments;
  final int paidInstallments;
  final double paidAmount;
  final DateTime startDate;
  final List<DateTime> dueDates;
  final List<Payment> payments;
  final String status; // active, completed, overdue
  final String? notes;
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
    this.dueDates = const [],
    this.payments = const [],
    this.status = 'active',
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get remainingAmount => loanAmount - paidAmount;
  double get progressPercentage =>
      loanAmount > 0 ? (paidAmount / loanAmount).clamp(0.0, 1.0) : 0.0;

  DateTime? get nextDueDate {
    final now = DateTime.now();
    for (int i = 0; i < dueDates.length; i++) {
      if (i >= paidInstallments && dueDates[i].isAfter(now)) {
        return dueDates[i];
      }
    }
    if (paidInstallments < dueDates.length) {
      return dueDates[paidInstallments];
    }
    return null;
  }

  bool get isOverdue {
    if (status == 'completed') return false;
    final next = nextDueDate;
    if (next != null && next.isBefore(DateTime.now())) return true;
    // Check if any unpaid installment is past due
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
        'adminId': adminId,
        'adminName': adminName,
        'adminPhone': adminPhone,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerNationalId': customerNationalId,
        'loanAmount': loanAmount,
        'installmentValue': installmentValue,
        'totalInstallments': totalInstallments,
        'paidInstallments': paidInstallments,
        'paidAmount': paidAmount,
        'startDate': Timestamp.fromDate(startDate),
        'dueDates': dueDates.map((d) => Timestamp.fromDate(d)).toList(),
        'payments': payments.map((p) => p.toMap()).toList(),
        'status': status,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
        'customerPhoneSearch': customerPhone.replaceAll(RegExp(r'[^\d]'), ''),
        'customerNationalIdSearch':
            customerNationalId.replaceAll(RegExp(r'[^\d]'), ''),
      };

  factory Loan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Loan(
      id: doc.id,
      adminId: data['adminId'] ?? '',
      adminName: data['adminName'] ?? '',
      adminPhone: data['adminPhone'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerNationalId: data['customerNationalId'] ?? '',
      loanAmount: (data['loanAmount'] ?? 0).toDouble(),
      installmentValue: (data['installmentValue'] ?? 0).toDouble(),
      totalInstallments: data['totalInstallments'] ?? 0,
      paidInstallments: data['paidInstallments'] ?? 0,
      paidAmount: (data['paidAmount'] ?? 0).toDouble(),
      startDate:
          (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDates: (data['dueDates'] as List<dynamic>?)
              ?.map((d) => (d as Timestamp).toDate())
              .toList() ??
          [],
      payments: (data['payments'] as List<dynamic>?)
              ?.map((p) => Payment.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      status: data['status'] ?? 'active',
      notes: data['notes'],
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Loan copyWith({
    String? id,
    String? adminId,
    String? adminName,
    String? adminPhone,
    String? customerName,
    String? customerPhone,
    String? customerNationalId,
    double? loanAmount,
    double? installmentValue,
    int? totalInstallments,
    int? paidInstallments,
    double? paidAmount,
    DateTime? startDate,
    List<DateTime>? dueDates,
    List<Payment>? payments,
    String? status,
    String? notes,
  }) {
    return Loan(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      adminPhone: adminPhone ?? this.adminPhone,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerNationalId: customerNationalId ?? this.customerNationalId,
      loanAmount: loanAmount ?? this.loanAmount,
      installmentValue: installmentValue ?? this.installmentValue,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      paidAmount: paidAmount ?? this.paidAmount,
      startDate: startDate ?? this.startDate,
      dueDates: dueDates ?? this.dueDates,
      payments: payments ?? this.payments,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
