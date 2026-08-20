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

  /// Group customer loans by creditor (admin)
  Map<String, List<Loan>> get loansByCreditor {
    final map = <String, List<Loan>>{};
    for (final loan in _customerLoans) {
      final key = loan.adminId;
      map.putIfAbsent(key, () => []);
      map[key]!.add(loan);
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
    final admin = await FirestoreService.registerAdmin(
      name: name,
      email: email,
      password: password,
      phone: phone,
      businessName: businessName,
    );
    if (admin == null) {
      _error = 'emailTaken';
      notifyListeners();
      return false;
    }
    _currentAdmin = admin;
    _role = UserRole.admin;
    notifyListeners();
    return true;
  }

  Future<bool> loginAsAdmin(String email, String password) async {
    _error = null;
    final admin = await FirestoreService.loginAdmin(email, password);
    if (admin == null) {
      _error = 'invalidCredentials';
      notifyListeners();
      return false;
    }
    _currentAdmin = admin;
    _role = UserRole.admin;
    notifyListeners();
    return true;
  }

  // ── Customer Auth ──

  Future<bool> registerCustomer({
    required String name,
    required String phone,
    required String nationalId,
  }) async {
    _error = null;
    final ok = await FirestoreService.registerCustomer(
      name: name,
      phone: phone,
      nationalId: nationalId,
    );
    if (!ok) {
      _error = 'accountExists';
      notifyListeners();
      return false;
    }
    // Auto-login after registration
    return loginAsCustomer(phone, nationalId, name: name);
  }

  Future<bool> loginAsCustomer(String phone, String nationalId,
      {String? name}) async {
    _error = null;

    // Verify customer is registered first
    final exists = await FirestoreService.customerExists(phone, nationalId);
    if (!exists) {
      _error = 'invalidCredentials';
      notifyListeners();
      return false;
    }

    final loans = await FirestoreService.getLoansForCustomer(phone, nationalId);
    _customerLoans = loans;
    _customerPhone = phone;
    _customerNationalId = nationalId;
    if (name != null) _customerName = name;
    if (_customerName.isEmpty) {
      // Try to get name from customer record
      final custName = await FirestoreService.getCustomerName(phone, nationalId);
      if (custName != null) _customerName = custName;
    }
    if (loans.isNotEmpty && _customerName.isEmpty) {
      _customerName = loans.first.customerName;
    }
    _role = UserRole.customer;
    notifyListeners();
    return true;
  }

  /// Refresh customer's loans
  Future<void> refreshCustomerLoans() async {
    if (_role != UserRole.customer) return;
    _customerLoans = await FirestoreService.getLoansForCustomer(
      _customerPhone,
      _customerNationalId,
    );
    notifyListeners();
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
