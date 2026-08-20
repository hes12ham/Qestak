import 'package:flutter/material.dart';
import '../models/admin_model.dart';
import '../models/loan.dart';
import '../services/firestore_service.dart';

enum UserRole { none, admin, customer }

class AuthProvider extends ChangeNotifier {
  UserRole _role = UserRole.none;
  AdminModel? _currentAdmin;
  List<Loan> _customerLoans = [];
  String _customerPhone = '';
  String _customerNationalId = '';
  String _customerName = '';
  String? _error;

  UserRole get role => _role;
  AdminModel? get currentAdmin => _currentAdmin;
  List<Loan> get customerLoans => _customerLoans;
  String get customerPhone => _customerPhone;
  String get customerNationalId => _customerNationalId;
  String get customerName => _customerName;
  String? get error => _error;

  Map<String, List<Loan>> get loansByCreditor {
    final map = <String, List<Loan>>{};
    for (final loan in _customerLoans) {
      map.putIfAbsent(loan.adminId, () => []);
      map[loan.adminId]!.add(loan);
    }
    return map;
  }

  // ── Admin Auth ──

  Future<bool> registerAdmin({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String businessName = '',
  }) async {
    _error = null;
    try {
      final admin = await FirestoreService.registerAdmin(
        name: name, email: email, password: password,
        phone: phone, businessName: businessName,
      ).timeout(const Duration(seconds: 15));
      if (admin == null) {
        _error = 'emailTaken';
        notifyListeners();
        return false;
      }
      _currentAdmin = admin;
      _role = UserRole.admin;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'firebaseError';
      debugPrint('❌ registerAdmin: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginAsAdmin(String email, String password) async {
    _error = null;
    try {
      final admin = await FirestoreService.loginAdmin(email, password)
          .timeout(const Duration(seconds: 15));
      if (admin == null) {
        _error = 'invalidCredentials';
        notifyListeners();
        return false;
      }
      _currentAdmin = admin;
      _role = UserRole.admin;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'firebaseError';
      debugPrint('❌ loginAdmin: $e');
      notifyListeners();
      return false;
    }
  }

  // ── Customer Auth ──

  Future<bool> registerCustomer({
    required String name,
    required String phone,
    required String nationalId,
  }) async {
    _error = null;
    try {
      final ok = await FirestoreService.registerCustomer(
        name: name, phone: phone, nationalId: nationalId,
      ).timeout(const Duration(seconds: 15));
      if (!ok) {
        _error = 'accountExists';
        notifyListeners();
        return false;
      }
      _customerName = name;
      _customerPhone = phone;
      _customerNationalId = nationalId;
      // Fetch any existing loans for this customer
      try {
        _customerLoans = await FirestoreService.getLoansForCustomer(phone, nationalId)
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        _customerLoans = [];
      }
      _role = UserRole.customer;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'firebaseError';
      debugPrint('❌ registerCustomer: $e');
      notifyListeners();
      return false;
    }
  }

  /// Customer login:
  /// 1. Check if registered in customers collection
  /// 2. If not, check if loans exist with this phone+nationalId
  /// 3. If loans found, auto-register and login
  /// 4. If nothing found, reject
  Future<bool> loginAsCustomer(String phone, String nationalId,
      {String? name}) async {
    _error = null;
    try {
      // Step 1: Try to find loans for this customer
      final loans = await FirestoreService.getLoansForCustomer(phone, nationalId)
          .timeout(const Duration(seconds: 15));

      // Step 2: Check if customer record exists
      final exists = await FirestoreService.customerExists(phone, nationalId)
          .timeout(const Duration(seconds: 10));

      // Step 3: If loans exist but no customer record → auto-register
      if (!exists && loans.isNotEmpty) {
        final customerName = name ?? loans.first.customerName;
        await FirestoreService.registerCustomer(
          name: customerName,
          phone: phone,
          nationalId: nationalId,
        ).timeout(const Duration(seconds: 10));
      }

      // Step 4: If no loans AND no customer record → reject
      if (!exists && loans.isEmpty) {
        _error = 'noLoansFound';
        notifyListeners();
        return false;
      }

      // Step 5: Login successful
      _customerLoans = loans;
      _customerPhone = phone;
      _customerNationalId = nationalId;
      if (name != null) _customerName = name;
      if (_customerName.isEmpty) {
        try {
          final custName = await FirestoreService.getCustomerName(phone, nationalId)
              .timeout(const Duration(seconds: 10));
          if (custName != null) _customerName = custName;
        } catch (_) {}
      }
      if (loans.isNotEmpty && _customerName.isEmpty) {
        _customerName = loans.first.customerName;
      }
      _role = UserRole.customer;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'firebaseError';
      debugPrint('❌ loginCustomer: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshCustomerLoans() async {
    if (_role != UserRole.customer) return;
    try {
      _customerLoans = await FirestoreService.getLoansForCustomer(
        _customerPhone, _customerNationalId,
      ).timeout(const Duration(seconds: 15));
      notifyListeners();
    } catch (e) {
      debugPrint('❌ refreshLoans: $e');
    }
  }

  void logout() {
    _role = UserRole.none;
    _currentAdmin = null;
    _customerLoans = [];
    _customerPhone = '';
    _customerNationalId = '';
    _customerName = '';
    _error = null;
    notifyListeners();
  }
}
