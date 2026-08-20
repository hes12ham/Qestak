import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('ar'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isArabic => locale.languageCode == 'ar';

  String translate(String key) {
    final map = isArabic ? _ar : _en;
    return map[key] ?? key;
  }

  static const Map<String, String> _ar = {
    // General
    'appName': 'قسطك',
    'currency': 'ج.م',
    'save': 'حفظ',
    'cancel': 'إلغاء',
    'delete': 'حذف',
    'edit': 'تعديل',
    'confirm': 'تأكيد',
    'close': 'إغلاق',
    'loading': 'جاري التحميل...',
    'error': 'خطأ',
    'success': 'تم بنجاح',
    'noData': 'لا توجد بيانات',
    'search': 'بحث',
    'back': 'رجوع',
    'next': 'التالي',
    'yes': 'نعم',
    'no': 'لا',
    'required': 'مطلوب',
    'optional': 'اختياري',
    'version': 'الإصدار',
    'about': 'حول التطبيق',

    // Auth - Shared
    'login': 'تسجيل الدخول',
    'register': 'إنشاء حساب',
    'logout': 'تسجيل الخروج',
    'phone': 'رقم التليفون',
    'nationalId': 'الرقم القومي',
    'invalidCredentials': 'بيانات الدخول غير صحيحة',
    'loginSubtitle': 'سجّل دخولك لمتابعة أقساطك',
    'noAccount': 'ليس لديك حساب؟',
    'haveAccount': 'لديك حساب بالفعل؟',
    'enterAsAdmin': 'دخول كمسؤول',
    'enterAsCustomer': 'دخول كعميل',
    'chooseRole': 'اختر طريقة الدخول',

    // Auth - Customer
    'customerLogin': 'دخول العميل',
    'customerRegister': 'تسجيل عميل جديد',
    'fullName': 'الاسم بالكامل',
    'registerSuccess': 'تم إنشاء الحساب بنجاح',
    'accountExists': 'هذا الحساب مسجل بالفعل',

    // Auth - Admin
    'adminLogin': 'دخول المسؤول',
    'adminRegister': 'تسجيل مسؤول جديد',
    'email': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    'businessName': 'اسم النشاط / الشركة',
    'emailTaken': 'البريد الإلكتروني مستخدم بالفعل',

    // Customer Dashboard
    'customerDashboard': 'لوحة العميل',
    'welcome': 'مرحباً',
    'myLoans': 'أقساطي',
    'noLoansYet': 'لا توجد أقساط مسجلة حتى الآن',
    'noLoansDescription': 'عندما يقوم الدائن بإضافة بياناتك، ستظهر هنا تلقائياً',
    'creditor': 'الدائن',
    'loanFrom': 'قسط من',
    'viewDetails': 'عرض التفاصيل',
    'totalOwed': 'إجمالي المطلوب',
    'totalPaid': 'إجمالي المدفوع',
    'totalRemaining': 'إجمالي المتبقي',

    // Loan Details
    'loanDetails': 'تفاصيل القسط',
    'loanAmount': 'مبلغ القرض',
    'installmentValue': 'قيمة القسط',
    'paidAmount': 'المبلغ المدفوع',
    'remainingAmount': 'المبلغ المتبقي',
    'totalInstallments': 'عدد الأقساط',
    'paidInstallments': 'الأقساط المدفوعة',
    'startDate': 'تاريخ البداية',
    'nextDueDate': 'القسط القادم',
    'daysUntilDue': 'يوم للاستحقاق',
    'daysOverdue': 'يوم تأخير',
    'dueDates': 'مواعيد الاستحقاق',
    'creditorInfo': 'معلومات الدائن',

    // Payment
    'recordPayment': 'تسجيل دفعة',
    'paymentHistory': 'سجل المدفوعات',
    'paymentAmount': 'مبلغ الدفعة',
    'paymentMethod': 'طريقة الدفع',
    'cash': 'نقدي',
    'transfer': 'تحويل',
    'qr': 'QR',
    'noPayments': 'لا توجد مدفوعات',
    'paymentRecorded': 'تم تسجيل الدفعة بنجاح',

    // Status
    'active': 'نشط',
    'overdue': 'متأخر',
    'completed': 'مكتمل',
    'paid': 'مدفوع',
    'upcoming': 'قادم',
    'all': 'الكل',

    // Admin Dashboard
    'adminDashboard': 'لوحة الإدارة',
    'totalCustomers': 'إجمالي العملاء',
    'totalLoans': 'إجمالي القروض',
    'activeLoans': 'قروض نشطة',
    'overdueLoans': 'قروض متأخرة',
    'completedLoans': 'قروض مكتملة',
    'searchByNameOrPhone': 'بحث بالاسم أو التليفون...',

    // Admin - Add/Edit
    'addLoan': 'إضافة قسط جديد',
    'editLoan': 'تعديل القسط',
    'personalInfo': 'البيانات الشخصية',
    'loanInfo': 'تفاصيل القرض',
    'autoCalcInstallment': 'حساب القسط تلقائياً',
    'notes': 'ملاحظات',
    'customerName': 'اسم العميل',
    'loanSaved': 'تم حفظ القسط بنجاح',
    'confirmDelete': 'هل أنت متأكد من الحذف؟',
    'deleteWarning': 'سيتم حذف هذا القسط وجميع بياناته نهائياً.',

    // Admin - Excel Import
    'uploadExcel': 'رفع ملف Excel',
    'importExcel': 'استيراد من Excel',
    'importData': 'استيراد البيانات',
    'selectFile': 'اختر ملف',
    'importing': 'جاري الاستيراد...',
    'importSuccess': 'تم استيراد {count} سجل بنجاح',
    'importError': 'خطأ في الاستيراد',
    'downloadTemplate': 'تحميل نموذج Excel',
    'excelInstructions': 'قم برفع ملف Excel يحتوي على أعمدة: اسم العميل، رقم التليفون، الرقم القومي، مبلغ القرض',
    'requiredColumns': 'الأعمدة المطلوبة',
    'optionalColumns': 'الأعمدة الاختيارية',
    'rowsDetected': 'تم اكتشاف {count} صف',
    'previewData': 'معاينة البيانات',
    'confirmImport': 'تأكيد الاستيراد',

    // Admin - Export
    'exportExcel': 'تصدير Excel',
    'exportCsv': 'تصدير CSV',
    'exportSuccess': 'تم التصدير بنجاح',

    // Statistics
    'statistics': 'الإحصائيات',
    'financialSummary': 'الملخص المالي',
    'totalAmount': 'الإجمالي',
    'totalCollected': 'المُحصّل',
    'collectionRate': 'نسبة التحصيل',
    'customerDistribution': 'توزيع القروض',

    // QR
    'qrCode': 'رمز QR',
    'generateQr': 'إنشاء QR',

    // Settings
    'settings': 'الإعدادات',
    'language': 'اللغة',

    // Notifications
    'reminderTitle': 'تذكير بموعد القسط',
    'reminderBody': 'قسطك مستحق بعد {days} أيام',
    'overdueTitle': 'قسط متأخر!',
    'overdueBody': 'لديك قسط متأخر منذ {days} يوم',
  };

  static const Map<String, String> _en = {
    // General
    'appName': 'Qestak',
    'currency': 'EGP',
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'edit': 'Edit',
    'confirm': 'Confirm',
    'close': 'Close',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'noData': 'No data',
    'search': 'Search',
    'back': 'Back',
    'next': 'Next',
    'yes': 'Yes',
    'no': 'No',
    'required': 'Required',
    'optional': 'Optional',
    'version': 'Version',
    'about': 'About',

    // Auth - Shared
    'login': 'Login',
    'register': 'Register',
    'logout': 'Logout',
    'phone': 'Phone Number',
    'nationalId': 'National ID',
    'invalidCredentials': 'Invalid credentials',
    'loginSubtitle': 'Login to track your installments',
    'noAccount': "Don't have an account?",
    'haveAccount': 'Already have an account?',
    'enterAsAdmin': 'Enter as Admin',
    'enterAsCustomer': 'Enter as Customer',
    'chooseRole': 'Choose login type',

    // Auth - Customer
    'customerLogin': 'Customer Login',
    'customerRegister': 'Register as Customer',
    'fullName': 'Full Name',
    'registerSuccess': 'Account created successfully',
    'accountExists': 'This account already exists',

    // Auth - Admin
    'adminLogin': 'Admin Login',
    'adminRegister': 'Register as Admin',
    'email': 'Email',
    'password': 'Password',
    'businessName': 'Business Name',
    'emailTaken': 'This email is already in use',

    // Customer Dashboard
    'customerDashboard': 'My Dashboard',
    'welcome': 'Welcome',
    'myLoans': 'My Installments',
    'noLoansYet': 'No installments found',
    'noLoansDescription': 'When a creditor adds your data, it will appear here automatically',
    'creditor': 'Creditor',
    'loanFrom': 'Loan from',
    'viewDetails': 'View Details',
    'totalOwed': 'Total Owed',
    'totalPaid': 'Total Paid',
    'totalRemaining': 'Total Remaining',

    // Loan Details
    'loanDetails': 'Loan Details',
    'loanAmount': 'Loan Amount',
    'installmentValue': 'Installment Value',
    'paidAmount': 'Paid Amount',
    'remainingAmount': 'Remaining Amount',
    'totalInstallments': 'Total Installments',
    'paidInstallments': 'Paid Installments',
    'startDate': 'Start Date',
    'nextDueDate': 'Next Due Date',
    'daysUntilDue': 'days until due',
    'daysOverdue': 'days overdue',
    'dueDates': 'Due Dates',
    'creditorInfo': 'Creditor Info',

    // Payment
    'recordPayment': 'Record Payment',
    'paymentHistory': 'Payment History',
    'paymentAmount': 'Payment Amount',
    'paymentMethod': 'Payment Method',
    'cash': 'Cash',
    'transfer': 'Transfer',
    'qr': 'QR',
    'noPayments': 'No payments',
    'paymentRecorded': 'Payment recorded successfully',

    // Status
    'active': 'Active',
    'overdue': 'Overdue',
    'completed': 'Completed',
    'paid': 'Paid',
    'upcoming': 'Upcoming',
    'all': 'All',

    // Admin Dashboard
    'adminDashboard': 'Admin Dashboard',
    'totalCustomers': 'Total Customers',
    'totalLoans': 'Total Loans',
    'activeLoans': 'Active Loans',
    'overdueLoans': 'Overdue Loans',
    'completedLoans': 'Completed Loans',
    'searchByNameOrPhone': 'Search by name or phone...',

    // Admin - Add/Edit
    'addLoan': 'Add New Loan',
    'editLoan': 'Edit Loan',
    'personalInfo': 'Personal Information',
    'loanInfo': 'Loan Details',
    'autoCalcInstallment': 'Auto-calculate installment',
    'notes': 'Notes',
    'customerName': 'Customer Name',
    'loanSaved': 'Loan saved successfully',
    'confirmDelete': 'Are you sure?',
    'deleteWarning': 'This loan and all its data will be permanently deleted.',

    // Admin - Excel Import
    'uploadExcel': 'Upload Excel File',
    'importExcel': 'Import from Excel',
    'importData': 'Import Data',
    'selectFile': 'Select File',
    'importing': 'Importing...',
    'importSuccess': '{count} records imported successfully',
    'importError': 'Import error',
    'downloadTemplate': 'Download Template',
    'excelInstructions': 'Upload an Excel file with columns: Customer Name, Phone, National ID, Loan Amount',
    'requiredColumns': 'Required Columns',
    'optionalColumns': 'Optional Columns',
    'rowsDetected': '{count} rows detected',
    'previewData': 'Preview Data',
    'confirmImport': 'Confirm Import',

    // Admin - Export
    'exportExcel': 'Export Excel',
    'exportCsv': 'Export CSV',
    'exportSuccess': 'Export successful',

    // Statistics
    'statistics': 'Statistics',
    'financialSummary': 'Financial Summary',
    'totalAmount': 'Total Amount',
    'totalCollected': 'Total Collected',
    'collectionRate': 'Collection Rate',
    'customerDistribution': 'Loan Distribution',

    // QR
    'qrCode': 'QR Code',
    'generateQr': 'Generate QR',

    // Settings
    'settings': 'Settings',
    'language': 'Language',

    // Notifications
    'reminderTitle': 'Installment Reminder',
    'reminderBody': 'Your installment is due in {days} days',
    'overdueTitle': 'Overdue Installment!',
    'overdueBody': 'You have an installment overdue by {days} days',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}
