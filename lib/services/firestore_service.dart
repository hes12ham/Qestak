import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/loan.dart';
import '../models/admin_model.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  // ─────────── ADMIN AUTH ───────────

  static Future<AdminModel?> registerAdmin({
    required String name, required String email, required String password,
    String phone = '', String businessName = '',
  }) async {
    final existing = await _db.collection('admins')
        .where('email', isEqualTo: email).limit(1).get();
    if (existing.docs.isNotEmpty) return null;
    final docRef = _db.collection('admins').doc();
    final admin = AdminModel(id: docRef.id, name: name, email: email,
        phone: phone, businessName: businessName);
    await docRef.set({...admin.toMap(), 'password': password});
    return admin;
  }

  static Future<AdminModel?> loginAdmin(String email, String password) async {
    final snap = await _db.collection('admins')
        .where('email', isEqualTo: email).limit(1).get();
    if (snap.docs.isEmpty) return null;
    if (snap.docs.first.data()['password'] != password) return null;
    return AdminModel.fromFirestore(snap.docs.first);
  }

  // ─────────── CUSTOMER AUTH (phone + password) ───────────

  static Future<bool> registerCustomer({
    required String name, required String phone,
    required String nationalId, required String password,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    // Check if phone already registered
    final snap = await _db.collection('customers')
        .where('phoneSearch', isEqualTo: cleanPhone).get();
    if (snap.docs.isNotEmpty) return false;
    await _db.collection('customers').add({
      'name': name, 'phone': phone, 'nationalId': nationalId,
      'password': password,
      'phoneSearch': cleanPhone,
      'nationalIdSearch': nationalId.replaceAll(RegExp(r'[^\d]'), ''),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  /// Login customer by phone + password
  static Future<Map<String, dynamic>?> loginCustomerWithPassword(
      String phone, String password) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final snap = await _db.collection('customers')
        .where('phoneSearch', isEqualTo: cleanPhone).get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    if (doc.data()['password'] != password) return null;
    return doc.data();
  }

  static Future<bool> customerExists(String phone, String nationalId) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final snap = await _db.collection('customers')
        .where('phoneSearch', isEqualTo: cleanPhone).get();
    return snap.docs.isNotEmpty;
  }

  static Future<bool> customerExistsByPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final snap = await _db.collection('customers')
        .where('phoneSearch', isEqualTo: cleanPhone).get();
    return snap.docs.isNotEmpty;
  }

  static Future<String?> getCustomerName(String phone, String nationalId) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final snap = await _db.collection('customers')
        .where('phoneSearch', isEqualTo: cleanPhone).get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data()['name'] as String?;
  }

  // ─────────── LOANS ───────────

  static Future<List<Loan>> getLoansForCustomer(String phone, String nationalId) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final cleanNid = nationalId.replaceAll(RegExp(r'[^\d]'), '');
    final snap = await _db.collection('loans')
        .where('customerPhoneSearch', isEqualTo: cleanPhone).get();
    return snap.docs
        .where((d) => d.data()['customerNationalIdSearch'] == cleanNid)
        .map((d) => Loan.fromFirestore(d)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<List<Loan>> getLoansForCustomerByPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final snap = await _db.collection('loans')
        .where('customerPhoneSearch', isEqualTo: cleanPhone).get();
    return snap.docs.map((d) => Loan.fromFirestore(d)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<List<Loan>> getLoansForAdmin(String adminId) async {
    final snap = await _db.collection('loans')
        .where('adminId', isEqualTo: adminId).get();
    final loans = snap.docs.map((d) => Loan.fromFirestore(d)).toList();
    loans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return loans;
  }

  static Stream<List<Loan>> streamLoansForAdmin(String adminId) {
    return _db.collection('loans').where('adminId', isEqualTo: adminId)
        .snapshots().map((snap) {
      final loans = snap.docs.map((d) => Loan.fromFirestore(d)).toList();
      loans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return loans;
    });
  }

  static Future<Loan?> addLoan({
    required String adminId, required String adminName, String adminPhone = '',
    required String customerName, required String customerPhone,
    required String customerNationalId, required double loanAmount,
    required double installmentValue, required int totalInstallments,
    required DateTime startDate, required DateTime firstDueDate,
    String? notes, String? idImagePath, String? customerPassword,
  }) async {
    // Generate due dates from firstDueDate (not startDate)
    final dueDates = _generateDueDates(firstDueDate, totalInstallments);
    final docRef = _db.collection('loans').doc();
    final loan = Loan(
      id: docRef.id, adminId: adminId, adminName: adminName, adminPhone: adminPhone,
      customerName: customerName, customerPhone: customerPhone,
      customerNationalId: customerNationalId, loanAmount: loanAmount,
      installmentValue: installmentValue, totalInstallments: totalInstallments,
      startDate: startDate, firstDueDate: firstDueDate,
      dueDates: dueDates, notes: notes, idImagePath: idImagePath,
    );
    await docRef.set(loan.toMap());

    // Auto-register customer if not exists
    final exists = await customerExistsByPhone(customerPhone);
    if (!exists && customerPassword != null && customerPassword.isNotEmpty) {
      await registerCustomer(
        name: customerName, phone: customerPhone,
        nationalId: customerNationalId, password: customerPassword,
      );
    }

    return loan;
  }

  static Future<int> importLoansFromExcel({
    required String adminId, required String adminName, String adminPhone = '',
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
      final effInst = installment > 0 ? installment : (count > 0 ? amount / count : amount);
      final effCount = count > 0 ? count : (installment > 0 ? (amount / installment).ceil() : 1);
      final dueDates = _generateDueDates(startDate, effCount);
      String status = 'active';
      if (paid >= amount) { status = 'completed'; }
      else { for (int i = paidCount; i < dueDates.length; i++) {
        if (dueDates[i].isBefore(DateTime.now())) { status = 'overdue'; break; }
      }}
      final docRef = _db.collection('loans').doc();
      batch.set(docRef, Loan(id: docRef.id, adminId: adminId, adminName: adminName,
        adminPhone: adminPhone, customerName: name, customerPhone: phone,
        customerNationalId: nid, loanAmount: amount, installmentValue: effInst,
        totalInstallments: effCount, paidInstallments: paidCount, paidAmount: paid,
        startDate: startDate, firstDueDate: startDate, dueDates: dueDates,
        status: status, notes: notes.isNotEmpty ? notes : null,
      ).toMap());
      imported++; batchCount++;
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
    required String loanId, required double amount,
    required String method, String? notes,
  }) async {
    final docRef = _db.collection('loans').doc(loanId);
    return _db.runTransaction<Loan?>((txn) async {
      final snap = await txn.get(docRef);
      if (!snap.exists) return null;
      final loan = Loan.fromFirestore(snap);
      final newPaid = loan.paidAmount + amount;
      final newPaidInst = loan.paidInstallments + 1;
      final newStatus = newPaid >= loan.loanAmount ? 'completed' : 'active';
      final payment = Payment(id: _uuid.v4(), amount: amount,
          date: DateTime.now(), method: method, notes: notes);
      final updatedPayments = [...loan.payments, payment];
      txn.update(docRef, {
        'paidAmount': newPaid, 'paidInstallments': newPaidInst,
        'status': newStatus, 'payments': updatedPayments.map((p) => p.toMap()).toList(),
      });
      txn.set(_db.collection('payment_logs').doc(), {
        'loanId': loanId, 'adminId': loan.adminId, 'customerName': loan.customerName,
        'amount': amount, 'method': method, 'date': FieldValue.serverTimestamp(),
      });
      return loan.copyWith(paidAmount: newPaid, paidInstallments: newPaidInst,
          status: newStatus, payments: updatedPayments);
    });
  }

  static Future<Map<String, dynamic>> getAdminStatistics(String adminId) async {
    final loans = await getLoansForAdmin(adminId);
    int active = 0, completed = 0, overdue = 0;
    double totalLoaned = 0, totalCollected = 0;
    final uniqueCustomers = <String>{};
    for (final l in loans) {
      uniqueCustomers.add(l.customerNationalId);
      totalLoaned += l.loanAmount; totalCollected += l.paidAmount;
      if (l.status == 'completed') completed++;
      else if (l.isOverdue) overdue++;
      else active++;
    }
    return {
      'totalLoans': loans.length, 'totalCustomers': uniqueCustomers.length,
      'activeLoans': active, 'completedLoans': completed, 'overdueLoans': overdue,
      'totalLoaned': totalLoaned, 'totalCollected': totalCollected,
      'totalRemaining': totalLoaned - totalCollected,
      'collectionRate': totalLoaned > 0 ? (totalCollected / totalLoaned) * 100 : 0.0,
    };
  }

  static List<DateTime> _generateDueDates(DateTime firstDue, int count) =>
      List.generate(count, (i) => DateTime(firstDue.year, firstDue.month + i, firstDue.day));

  static double _parseDouble(dynamic v) {
    if (v == null) return 0; if (v is double) return v; if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
  static int _parseInt(dynamic v) {
    if (v == null) return 0; if (v is int) return v; if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
