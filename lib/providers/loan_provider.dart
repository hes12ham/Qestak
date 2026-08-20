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
    if (_filterStatus == 'active') {
      list = list.where((l) => l.status == 'active' && !l.isOverdue).toList();
    } else if (_filterStatus == 'overdue') {
      list = list.where((l) => l.isOverdue).toList();
    } else if (_filterStatus == 'completed') {
      list = list.where((l) => l.status == 'completed').toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((l) =>
          l.customerName.toLowerCase().contains(q) ||
          l.customerPhone.contains(q) ||
          l.customerNationalId.contains(q)).toList();
    }
    return list;
  }

  int get uniqueCustomerCount =>
      _loans.map((l) => l.customerNationalId).toSet().length;

  void setFilter(String status) { _filterStatus = status; notifyListeners(); }
  void setSearch(String query) { _searchQuery = query; notifyListeners(); }

  void startListening(String adminId) {
    _subscription?.cancel();
    try {
      _subscription = FirestoreService.streamLoansForAdmin(adminId).listen(
        (loans) { _loans = loans; notifyListeners(); },
        onError: (e) => debugPrint('Stream error: $e'),
      );
    } catch (e) {
      debugPrint('startListening error: $e');
    }
  }

  Future<void> loadLoans(String adminId) async {
    try {
      _loans = await FirestoreService.getLoansForAdmin(adminId);
      notifyListeners();
    } catch (e) {
      debugPrint('loadLoans error: $e');
    }
  }

  Future<void> loadStatistics(String adminId) async {
    try {
      _statistics = await FirestoreService.getAdminStatistics(adminId);
      notifyListeners();
    } catch (e) {
      debugPrint('loadStats error: $e');
    }
  }

  Future<Loan?> recordPayment({
    required String loanId,
    required double amount,
    required String method,
    String? notes,
  }) async {
    try {
      return await FirestoreService.recordPayment(
        loanId: loanId, amount: amount, method: method, notes: notes,
      );
    } catch (e) {
      debugPrint('recordPayment error: $e');
      return null;
    }
  }

  Future<void> deleteLoan(String loanId) async {
    try {
      await FirestoreService.deleteLoan(loanId);
    } catch (e) {
      debugPrint('deleteLoan error: $e');
    }
  }

  @override
  void dispose() { _subscription?.cancel(); super.dispose(); }
}
