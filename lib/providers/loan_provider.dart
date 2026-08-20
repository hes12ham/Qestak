import 'dart:async';
import 'package:flutter/material.dart';
import '../models/loan.dart';
import '../services/firestore_service.dart';

class LoanProvider extends ChangeNotifier {
  List<Loan> _loans = [];
  Map<String, dynamic> _statistics = {};
  String _searchQuery = '';
  String _filterStatus = 'all';
  StreamSubscription? _subscription;

  List<Loan> get allLoans => _loans;
  Map<String, dynamic> get statistics => _statistics;
  String get searchQuery => _searchQuery;
  String get filterStatus => _filterStatus;

  List<Loan> get filteredLoans {
    var list = _loans;

    // Filter by status
    if (_filterStatus == 'active') {
      list = list.where((l) => l.status == 'active' && !l.isOverdue).toList();
    } else if (_filterStatus == 'overdue') {
      list = list.where((l) => l.isOverdue).toList();
    } else if (_filterStatus == 'completed') {
      list = list.where((l) => l.status == 'completed').toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((l) {
        return l.customerName.toLowerCase().contains(q) ||
            l.customerPhone.contains(q) ||
            l.customerNationalId.contains(q);
      }).toList();
    }

    return list;
  }

  /// Unique customers
  int get uniqueCustomerCount {
    return _loans.map((l) => l.customerNationalId).toSet().length;
  }

  void setFilter(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Start listening to admin's loans
  void startListening(String adminId) {
    _subscription?.cancel();
    _subscription = FirestoreService.streamLoansForAdmin(adminId).listen(
      (loans) {
        _loans = loans;
        notifyListeners();
      },
    );
  }

  /// Load loans (one-time)
  Future<void> loadLoans(String adminId) async {
    _loans = await FirestoreService.getLoansForAdmin(adminId);
    notifyListeners();
  }

  /// Load statistics
  Future<void> loadStatistics(String adminId) async {
    _statistics = await FirestoreService.getAdminStatistics(adminId);
    notifyListeners();
  }

  /// Record payment
  Future<Loan?> recordPayment({
    required String loanId,
    required double amount,
    required String method,
    String? notes,
  }) async {
    return FirestoreService.recordPayment(
      loanId: loanId,
      amount: amount,
      method: method,
      notes: notes,
    );
  }

  /// Delete loan
  Future<void> deleteLoan(String loanId) async {
    await FirestoreService.deleteLoan(loanId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
