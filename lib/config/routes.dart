import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/role_choice_screen.dart';
import '../screens/auth/customer_auth_screen.dart';
import '../screens/auth/admin_auth_screen.dart';
import '../screens/customer/customer_dashboard.dart';
import '../screens/customer/loan_details_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/add_loan_screen.dart';
import '../screens/admin/admin_loan_details_screen.dart';
import '../screens/admin/import_excel_screen.dart';
import '../screens/admin/statistics_screen.dart';
import '../screens/settings_screen.dart';
import '../models/loan.dart';

class AppRoutes {
  static const String splash = '/';
  static const String roleChoice = '/role-choice';
  static const String customerLogin = '/customer-login';
  static const String adminLogin = '/admin-login';
  static const String customerDashboard = '/customer-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String loanDetails = '/loan-details';
  static const String adminLoanDetails = '/admin-loan-details';
  static const String addLoan = '/add-loan';
  static const String importExcel = '/import-excel';
  static const String statistics = '/statistics';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings s) {
    switch (s.name) {
      case splash:
        return _r(const SplashScreen(), s);
      case roleChoice:
        return _r(const RoleChoiceScreen(), s);
      case customerLogin:
        return _r(const CustomerAuthScreen(), s);
      case adminLogin:
        return _r(const AdminAuthScreen(), s);
      case customerDashboard:
        return _r(const CustomerDashboard(), s);
      case adminDashboard:
        return _r(const AdminDashboard(), s);
      case loanDetails:
        return _r(LoanDetailsScreen(loan: s.arguments as Loan), s);
      case adminLoanDetails:
        return _r(AdminLoanDetailsScreen(loan: s.arguments as Loan), s);
      case addLoan:
        return _r(const AddLoanScreen(), s);
      case importExcel:
        return _r(const ImportExcelScreen(), s);
      case statistics:
        return _r(const StatisticsScreen(), s);
      case settings:
        return _r(const SettingsScreen(), s);
      default:
        return _r(const SplashScreen(), s);
    }
  }

  static MaterialPageRoute _r(Widget page, RouteSettings s) =>
      MaterialPageRoute(builder: (_) => page, settings: s);
}
