import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/loan.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Initialize notification system — call once in main()
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Request Android 13+ notification permission
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    _initialized = true;
  }

  /// Show an immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'qestak_channel',
      'قسطك إشعارات',
      channelDescription: 'إشعارات مواعيد الأقساط والمدفوعات',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      color: Color(0xFF0D7377),
      enableVibration: true,
      playSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// Show notification when payment is recorded
  static Future<void> notifyPaymentRecorded({
    required String customerName,
    required double amount,
    required String currency,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'تم تسجيل دفعة ✅',
      body: '$customerName — ${amount.toStringAsFixed(0)} $currency',
      payload: 'payment',
    );
  }

  /// Show notification when loan is added
  static Future<void> notifyLoanAdded({
    required String customerName,
    required double amount,
    required String currency,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'تم إضافة قسط جديد 📋',
      body: '$customerName — ${amount.toStringAsFixed(0)} $currency',
      payload: 'loan_added',
    );
  }

  /// Show notification when Excel import completes
  static Future<void> notifyImportComplete(int count) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'تم استيراد البيانات ✅',
      body: 'تم استيراد $count سجل بنجاح',
      payload: 'import',
    );
  }

  /// Show overdue notification for customer
  static Future<void> notifyOverdue({
    required String loanId,
    required String creditorName,
    required int overdueDays,
  }) async {
    await showNotification(
      id: loanId.hashCode,
      title: 'قسط متأخر! ⚠️',
      body: 'لديك قسط متأخر منذ $overdueDays يوم من $creditorName',
      payload: 'overdue:$loanId',
    );
  }

  /// Check all customer loans and show overdue notifications
  static Future<void> checkOverdueLoans(List<Loan> loans) async {
    for (final loan in loans) {
      if (loan.isOverdue && loan.status != 'completed') {
        await notifyOverdue(
          loanId: loan.id,
          creditorName: loan.adminName,
          overdueDays: loan.overdueDays,
        );
      }
    }
  }

  /// Show upcoming due date reminder
  static Future<void> notifyUpcoming({
    required String loanId,
    required String creditorName,
    required int daysUntil,
    required double amount,
    required String currency,
  }) async {
    await showNotification(
      id: loanId.hashCode + 1000,
      title: 'تذكير بموعد القسط 🔔',
      body: 'قسطك من $creditorName مستحق بعد $daysUntil يوم (${amount.toStringAsFixed(0)} $currency)',
      payload: 'reminder:$loanId',
    );
  }

  /// Check upcoming dues and notify (within 3 days)
  static Future<void> checkUpcomingDues(List<Loan> loans) async {
    final now = DateTime.now();
    for (final loan in loans) {
      if (loan.status == 'completed') continue;
      final next = loan.nextDueDate;
      if (next == null) continue;
      final diff = next.difference(now).inDays;
      if (diff >= 0 && diff <= 3) {
        await notifyUpcoming(
          loanId: loan.id,
          creditorName: loan.adminName,
          daysUntil: diff,
          amount: loan.installmentValue,
          currency: 'ج.م',
        );
      }
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
