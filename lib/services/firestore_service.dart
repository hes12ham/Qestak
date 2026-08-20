import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/loan.dart';
import '../models/admin_model.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  // ─────────── ADMIN AUTH ───────────

  /// Register a new admin (creditor)
  static Future<AdminModel?> registerAdmin({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String businessName = '',
  }) async {
    // Check if email already exists
    final existing = await _db
        .collection('admins')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return null; // email taken

    final docRef = _db.collection('admins').doc();
    final admin = AdminModel(
      id: docRef.id,
      name: name,
      email: email,
      phone: phone,
      businessName: businessName,
    );

    await docRef.set({
      ...admin.toMap(),
      'password': password, // PROTOTYPE ONLY
    });

    return admin;
  }

  /// Login admin by email + password
  static Future<AdminModel?> loginAdmin(
      String email, String password) async {
    final snap = await _db
        .collection('admins')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;

    final data = snap.docs.first.data();
    if (data['password'] != password) return null;

    return AdminModel.fromFirestore(snap.docs.first);
  }

  // ─────────── CUSTOMER AUTH ───────────

  /// Register a customer (just identity — loans are matched automatically)
  static Future<bool> registerCustomer({
    required String name,
    required String phone,
    required String nationalId,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final cleanNid = nationalId.replaceAll(RegExp(r'[^\d]'), '');

    // Check if already registered
    final existing = await _db
        .collection('customers')
        .where('phoneSearch', isEqualTo: cleanPhone)
        .where('nationalIdSearch', isEqualTo: cleanNid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return false; // already exists

    await _db.collection('customers').add({
      'name': name,
      'phone': phone,
      'nationalId': nationalId,
      'phoneSearch': cleanPhone,
      'nationalIdSearch': cleanNid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  /// Check if customer exists
  static Future<bool> customerExists(String phone, String nationalId) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final cleanNid = nationalId.replaceAll(RegExp(r'[^\d]'), '');
    final snap = await _db
        .collection('customers')
        .where('phoneSearch', isEqualTo: cleanPhone)
        .where('nationalIdSearch', isEqualTo: cleanNid)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Get customer name from record
  static Future<String?> getCustomerName(
      String phone, String nationalId) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final cleanNid = nationalId.replaceAll(RegExp(r'[^\d]'), '');
    final snap = await _db
        .collection('customers')
        .where('phoneSearch', isEqualTo: cleanPhone)
        .where('nationalIdSearch', isEqualTo: cleanNid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data()['name'] as String?;
  }

  /// Login customer by phone + nationalId → returns their loans
  static Future<List<Loan>> loginCustomer(
      String phone, String nationalId) async {
    final exists = await customerExists(phone, nationalId);
    if (!exists) return [];
    return await getLoansForCustomer(phone, nationalId);
  }

  // ─────────── LOANS ───────────

  /// Get loans for a customer (by phone + nationalId)
  static Future<List<Loan>> getLoansForCustomer(
      String phone, String nationalId) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final cleanNid = nationalId.replaceAll(RegExp(r'[^\d]'), '');

    final snap = await _db
        .collection('loans')
        .where('customerPhoneSearch', isEqualTo: cleanPhone)
        .where('customerNationalIdSearch', isEqualTo: cleanNid)
        .get();

    return snap.docs.map((d) => Loan.fromFirestore(d)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get loans created by a specific admin
  static Future<List<Loan>> getLoansForAdmin(String adminId) async {
    final snap = await _db
        .collection('loans')
        .where('adminId', isEqualTo: adminId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => Loan.fromFirestore(d)).toList();
  }

  /// Stream loans for admin (real-time)
  static Stream<List<Loan>> streamLoansForAdmin(String adminId) {
    return _db
        .collection('loans')
        .where('adminId', isEqualTo: adminId)
        .snapshots()
        .map((snap) {
      final loans = snap.docs.map((d) => Loan.fromFirestore(d)).toList();
      loans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return loans;
    });
  }

  /// Add a single loan
  static Future<Loan?> addLoan({
    required String adminId,
    required String adminName,
    String adminPhone = '',
    required String customerName,
    required String customerPhone,
    required String customerNationalId,
    required double loanAmount,
    required double installmentValue,
    required int totalInstallments,
    required DateTime startDate,
    String? notes,
  }) async {
    final dueDates = _generateDueDates(startDate, totalInstallments);
    final docRef = _db.collection('loans').doc();

    final loan = Loan(
      id: docRef.id,
      adminId: adminId,
      adminName: adminName,
      adminPhone: adminPhone,
      customerName: customerName,
      customerPhone: customerPhone,
      customerNationalId: customerNationalId,
      loanAmount: loanAmount,
      installmentValue: installmentValue,
      totalInstallments: totalInstallments,
      startDate: startDate,
      dueDates: dueDates,
      notes: notes,
    );

    await docRef.set(loan.toMap());
    return loan;
  }

  /// Bulk import loans from parsed Excel data (handles >500 rows)
  static Future<int> importLoansFromExcel({
    required String adminId,
    required String adminName,
    String adminPhone = '',
    required List<Map<String, dynamic>> rows,
  }) async {
    int imported = 0;
    WriteBatch batch = _db.batch();
    int batchCount = 0;

    for (final row in rows) {
      final name = (row['name'] ?? '').toString().trim();
      final phone = (row['phone'] ?? '').toString().trim();
      final nid = (row['nationalId'] ?? '').toString().trim();
      final amount = _parseDouble(row['loanAmount']);
      final installment = _parseDouble(row['installmentValue']);
      final count = _parseInt(row['totalInstallments']);
      final paid = _parseDouble(row['paidAmount']);
      final paidCount = _parseInt(row['paidInstallments']);
      final notes = (row['notes'] ?? '').toString().trim();

      if (name.isEmpty || phone.isEmpty || nid.isEmpty || amount <= 0) {
        continue; // skip invalid rows
      }

      DateTime startDate;
      if (row['startDate'] is DateTime) {
        startDate = row['startDate'];
      } else {
        startDate = DateTime.now();
      }

      final effectiveInstallment =
          installment > 0 ? installment : (count > 0 ? amount / count : amount);
      final effectiveCount =
          count > 0 ? count : (installment > 0 ? (amount / installment).ceil() : 1);

      final dueDates = _generateDueDates(startDate, effectiveCount);

      String status = 'active';
      if (paid >= amount) {
        status = 'completed';
      } else {
        // Check overdue
        for (int i = paidCount; i < dueDates.length; i++) {
          if (dueDates[i].isBefore(DateTime.now())) {
            status = 'overdue';
            break;
          }
        }
      }

      final docRef = _db.collection('loans').doc();
      final loan = Loan(
        id: docRef.id,
        adminId: adminId,
        adminName: adminName,
        adminPhone: adminPhone,
        customerName: name,
        customerPhone: phone,
        customerNationalId: nid,
        loanAmount: amount,
        installmentValue: effectiveInstallment,
        totalInstallments: effectiveCount,
        paidInstallments: paidCount,
        paidAmount: paid,
        startDate: startDate,
        dueDates: dueDates,
        status: status,
        notes: notes.isNotEmpty ? notes : null,
      );

      batch.set(docRef, loan.toMap());
      imported++;
      batchCount++;

      // Firestore batch limit is 500 writes
      if (batchCount >= 450) {
        await batch.commit();
        batch = _db.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) await batch.commit();
    return imported;
  }

  /// Update loan
  static Future<void> updateLoan(Loan loan) async {
    await _db.collection('loans').doc(loan.id).update(loan.toMap());
  }

  /// Delete loan
  static Future<void> deleteLoan(String loanId) async {
    await _db.collection('loans').doc(loanId).delete();
  }

  /// Record payment on a loan (with transaction for atomicity)
  static Future<Loan?> recordPayment({
    required String loanId,
    required double amount,
    required String method,
    String? notes,
  }) async {
    final docRef = _db.collection('loans').doc(loanId);

    return _db.runTransaction<Loan?>((txn) async {
      final snap = await txn.get(docRef);
      if (!snap.exists) return null;

      final loan = Loan.fromFirestore(snap);
      final newPaid = loan.paidAmount + amount;
      final newPaidInst = loan.paidInstallments + 1;
      String newStatus = loan.status;
      if (newPaid >= loan.loanAmount) {
        newStatus = 'completed';
      } else {
        newStatus = 'active';
      }

      final payment = Payment(
        id: _uuid.v4(),
        amount: amount,
        date: DateTime.now(),
        method: method,
        notes: notes,
      );

      final updatedPayments = [...loan.payments, payment];

      txn.update(docRef, {
        'paidAmount': newPaid,
        'paidInstallments': newPaidInst,
        'status': newStatus,
        'payments': updatedPayments.map((p) => p.toMap()).toList(),
      });

      // Audit log
      txn.set(_db.collection('payment_logs').doc(), {
        'loanId': loanId,
        'adminId': loan.adminId,
        'customerName': loan.customerName,
        'customerNationalId': loan.customerNationalId,
        'amount': amount,
        'method': method,
        'date': FieldValue.serverTimestamp(),
      });

      return loan.copyWith(
        paidAmount: newPaid,
        paidInstallments: newPaidInst,
        status: newStatus,
        payments: updatedPayments,
      );
    });
  }

  /// Search loans for admin
  static Future<List<Loan>> searchLoans(
      String adminId, String query) async {
    final all = await getLoansForAdmin(adminId);
    final q = query.toLowerCase();
    return all.where((l) {
      return l.customerName.toLowerCase().contains(q) ||
          l.customerPhone.contains(q) ||
          l.customerNationalId.contains(q);
    }).toList();
  }

  /// Statistics for admin
  static Future<Map<String, dynamic>> getAdminStatistics(
      String adminId) async {
    final loans = await getLoansForAdmin(adminId);

    int active = 0, completed = 0, overdue = 0;
    double totalLoaned = 0, totalCollected = 0;
    final uniqueCustomers = <String>{};

    for (final loan in loans) {
      uniqueCustomers.add(loan.customerNationalId);
      totalLoaned += loan.loanAmount;
      totalCollected += loan.paidAmount;

      if (loan.status == 'completed') {
        completed++;
      } else if (loan.isOverdue) {
        overdue++;
      } else {
        active++;
      }
    }

    return {
      'totalLoans': loans.length,
      'totalCustomers': uniqueCustomers.length,
      'activeLoans': active,
      'completedLoans': completed,
      'overdueLoans': overdue,
      'totalLoaned': totalLoaned,
      'totalCollected': totalCollected,
      'totalRemaining': totalLoaned - totalCollected,
      'collectionRate':
          totalLoaned > 0 ? (totalCollected / totalLoaned) * 100 : 0.0,
    };
  }

  // ─────────── HELPERS ───────────

  static List<DateTime> _generateDueDates(DateTime start, int count) {
    final dates = <DateTime>[];
    for (int i = 1; i <= count; i++) {
      dates.add(DateTime(start.year, start.month + i, start.day));
    }
    return dates;
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }
}
