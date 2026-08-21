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
    required String name, required String email, required String password,
    String phone = '', String businessName = '',
  }) async {
    _error = null;
    try {
      final admin = await FirestoreService.registerAdmin(
        name: name, email: email, password: password,
        phone: phone, businessName: businessName,
      ).timeout(const Duration(seconds: 15));
      if (admin == null) { _error = 'emailTaken'; notifyListeners(); return false; }
      _currentAdmin = admin; _role = UserRole.admin; notifyListeners(); return true;
    } catch (e) {
      _error = 'firebaseError'; debugPrint('❌ registerAdmin: $e');
      notifyListeners(); return false;
    }
  }

  Future<bool> loginAsAdmin(String email, String password) async {
    _error = null;
    try {
      final admin = await FirestoreService.loginAdmin(email, password)
          .timeout(const Duration(seconds: 15));
      if (admin == null) { _error = 'invalidCredentials'; notifyListeners(); return false; }
      _currentAdmin = admin; _role = UserRole.admin; notifyListeners(); return true;
    } catch (e) {
      _error = 'firebaseError'; debugPrint('❌ loginAdmin: $e');
      notifyListeners(); return false;
    }
  }

  // ── Customer Auth (phone + password) ──

  Future<bool> loginAsCustomer(String phone, String password) async {
    _error = null;
    try {
      // Login with phone + password
      final customerData = await FirestoreService.loginCustomerWithPassword(phone, password)
          .timeout(const Duration(seconds: 15));

      if (customerData == null) {
        _error = 'invalidCredentials';
        notifyListeners();
        return false;
      }

      _customerPhone = phone;
      _customerName = customerData['name'] ?? '';
      _customerNationalId = customerData['nationalId'] ?? '';

      // Fetch loans
      try {
        _customerLoans = await FirestoreService.getLoansForCustomerByPhone(phone)
            .timeout(const Duration(seconds: 15));
      } catch (_) {
        _customerLoans = [];
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
      _customerLoans = await FirestoreService.getLoansForCustomerByPhone(_customerPhone)
          .timeout(const Duration(seconds: 15));
      notifyListeners();
    } catch (e) {
      debugPrint('❌ refreshLoans: $e');
    }
  }

  void logout() {
    _role = UserRole.none; _currentAdmin = null; _customerLoans = [];
    _customerPhone = ''; _customerNationalId = ''; _customerName = ''; _error = null;
    notifyListeners();
  }
}
