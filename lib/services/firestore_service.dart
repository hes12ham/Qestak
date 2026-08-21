import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/loan.dart';
import '../models/admin_model.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  // ─────────── ADMIN AUTH ───────────

  static Future<AdminModel?> registerAdmin({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String businessName = '',
  }) async {
    final existing = await _db
        .collection('admins')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return null;

    final docRef = _db.collection('admins').doc();
    final admin = AdminModel(
      id: docRef.id, name: name, email: email,
      phone: phone, businessName: businessName,
    );
    await docRef.set({...admin.toMap(), 'password': password});
    return admin;
  }

  static Future<AdminModel?> loginAdmin(String email, String password) async {
    final snap = await _db
        .collection('admins')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    if (snap.docs.first.data()['password'] != password) return null;
    return AdminModel.fromFirestore(snap.docs.first);
  }

  // ─────────── CUSTOMER AUTH ───────────
  // NOTE: queries use ONE where() + filter in code to avoid needing Firestore indexes

  static Future<bool> registerCustomer({
    required String name,
    required String phone,
    required String nationalId,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final cleanNid = nationalId.replaceAll(RegExp(r'[^\d]'), '');

    // Query by phone only, check nationalId in code
    final snap = await _db
        .collection('customers')
        .where('phoneSearch', isEqualTo: cleanPhone)
        .get();
    final exists = snap.docs.any((d) => d.data()['nationalIdSearch'] == cleanNid);
    if (exists) return false;

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

  static Future<bool> customerExists(String phone, String nationalId) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final cleanNid = nationalId.replaceAll(RegExp(r'[^\d]'), '');
    final snap = await _db
        .collection('customers')
        .where('phoneSearch', isEqualTo: cleanPhone)
        .get();
    return snap.docs.any((d) => d.data()['nationalIdSearch'] == cleanNid);
  }

  static Future<String?> getCustomerName(String phone, String nationalId) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final cleanNid = nationalId.replaceAll(RegExp(r'[^\d]'), '');
    final snap = await _db
        .collection('customers')
        .where('phoneSearch', isEqualTo: cleanPhone)
        .get();
    for (final doc in snap.docs) {
      if (doc.data()['nationalIdSearch'] == cleanNid) {
        return doc.data()['name'] as String?;
      }
    }
    return null;
  }

  static Future<List<Loan>> loginCustomer(String phone, String nationalId) async {
    final exists = await customerExists(phone, nationalId);
    if (!exists) return [];
    return await getLoansForCustomer(phone, nationalId);
  }

  // ─────────── LOANS ───────────

  static Future<List<Loan>> getLoansForCustomer(String phone, String nationalId) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final cleanNid = nationalId.replaceAll(RegExp(r'[^\d]'), '');

    // Query by phone, filter nationalId in code
    final snap = await _db
        .collection('loans')
        .where('customerPhoneSearch', isEqualTo: cleanPhone)
        .get();

    return snap.docs
        .where((d) => d.data()['customerNationalIdSearch'] == cleanNid)
        .map((d) => Loan.fromFirestore(d))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<List<Loan>> getLoansForAdmin(String adminId) async {
    final snap = await _db
        .collection('loans')
        .where('adminId', isEqualTo: adminId)
        .get();
    final loans = snap.docs.map((d) => Loan.fromFirestore(d)).toList();
    loans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return loans;
  }

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
    String? idImagePath,
  }) async {
    final dueDates = _generateDueDates(startDate, totalInstallments);
    final docRef = _db.collection('loans').doc();
    final loan = Loan(
      id: docRef.id, adminId: adminId, adminName: adminName, adminPhone: adminPhone,
      customerName: customerName, customerPhone: customerPhone,
      customerNationalId: customerNationalId, loanAmount: loanAmount,
      installmentValue: installmentValue, totalInstallments: totalInstallments,
      startDate: startDate, dueDates: dueDates, notes: notes,
      idImagePath: idImagePath,
    );
    await docRef.set(loan.toMap());
    return loan;
  }

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

      if (name.isEmpty || phone.isEmpty || nid.isEmpty || amount <= 0) continue;

      DateTime startDate = row['startDate'] is DateTime ? row['startDate'] : DateTime.now();
      final effInstallment = installment > 0 ? installment : (count > 0 ? amount / count : amount);
      final effCount = count > 0 ? count : (installment > 0 ? (amount / installment).ceil() : 1);
      final dueDates = _generateDueDates(startDate, effCount);

      String status = 'active';
      if (paid >= amount) {
        status = 'completed';
      } else {
        for (int i = paidCount; i < dueDates.length; i++) {
          if (dueDates[i].isBefore(DateTime.now())) { status = 'overdue'; break; }
        }
      }

      final docRef = _db.collection('loans').doc();
      batch.set(docRef, Loan(
        id: docRef.id, adminId: adminId, adminName: adminName, adminPhone: adminPhone,
        customerName: name, customerPhone: phone, customerNationalId: nid,
        loanAmount: amount, installmentValue: effInstallment, totalInstallments: effCount,
        paidInstallments: paidCount, paidAmount: paid, startDate: startDate,
        dueDates: dueDates, status: status, notes: notes.isNotEmpty ? notes : null,
      ).toMap());
      imported++;
      batchCount++;
      if (batchCount >= 450) { await batch.commit(); batch = _db.batch(); batchCount = 0; }
    }

    if (batchCount > 0) await batch.commit();
    return imported;
  }

  static Future<void> updateLoan(Loan loan) async =>
      await _db.collection('loans').doc(loan.id).update(loan.toMap());

  static Future<void> deleteLoan(String loanId) async =>
      await _db.collection('loans').doc(loanId).delete();

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
      final newStatus = newPaid >= loan.loanAmount ? 'completed' : 'active';
      final payment = Payment(id: _uuid.v4(), amount: amount, date: DateTime.now(), method: method, notes: notes);
      final updatedPayments = [...loan.payments, payment];
      txn.update(docRef, {
        'paidAmount': newPaid, 'paidInstallments': newPaidInst,
        'status': newStatus, 'payments': updatedPayments.map((p) => p.toMap()).toList(),
      });
      txn.set(_db.collection('payment_logs').doc(), {
        'loanId': loanId, 'adminId': loan.adminId, 'customerName': loan.customerName,
        'amount': amount, 'method': method, 'date': FieldValue.serverTimestamp(),
      });
      return loan.copyWith(paidAmount: newPaid, paidInstallments: newPaidInst, status: newStatus, payments: updatedPayments);
    });
  }

  static Future<Map<String, dynamic>> getAdminStatistics(String adminId) async {
    final loans = await getLoansForAdmin(adminId);
    int active = 0, completed = 0, overdue = 0;
    double totalLoaned = 0, totalCollected = 0;
    final uniqueCustomers = <String>{};
    for (final loan in loans) {
      uniqueCustomers.add(loan.customerNationalId);
      totalLoaned += loan.loanAmount;
      totalCollected += loan.paidAmount;
      if (loan.status == 'completed') { completed++; }
      else if (loan.isOverdue) { overdue++; }
      else { active++; }
    }
    return {
      'totalLoans': loans.length, 'totalCustomers': uniqueCustomers.length,
      'activeLoans': active, 'completedLoans': completed, 'overdueLoans': overdue,
      'totalLoaned': totalLoaned, 'totalCollected': totalCollected,
      'totalRemaining': totalLoaned - totalCollected,
      'collectionRate': totalLoaned > 0 ? (totalCollected / totalLoaned) * 100 : 0.0,
    };
  }

  // ─────────── HELPERS ───────────

  static List<DateTime> _generateDueDates(DateTime start, int count) {
    return List.generate(count, (i) => DateTime(start.year, start.month + i + 1, start.day));
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
