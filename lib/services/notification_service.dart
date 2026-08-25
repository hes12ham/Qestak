import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/loan.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ─────────── INIT ───────────

  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone for scheduled notifications
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Request permission (Android 13+)
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    _initialized = true;
  }

  // ─────────── IMMEDIATE NOTIFICATIONS ───────────

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
    const details =
        NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
    await _plugin.show(id, title, body, details, payload: payload);
  }

  static Future<void> notifyPaymentRecorded({
    required String customerName,
    required double amount,
    required String currency,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'تم تسجيل دفعة ✅',
      body: '$customerName — ${amount.toStringAsFixed(0)} $currency',
    );
  }

  static Future<void> notifyLoanAdded({
    required String customerName,
    required double amount,
    required String currency,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'تم إضافة قسط جديد 📋',
      body: '$customerName — ${amount.toStringAsFixed(0)} $currency',
    );
  }

  static Future<void> notifyImportComplete(int count) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'تم استيراد البيانات ✅',
      body: 'تم استيراد $count سجل بنجاح',
    );
  }

  // ─────────── SCHEDULED NOTIFICATIONS ───────────

  /// Schedule a notification at a specific date/time
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Don't schedule for past dates
    if (scheduledDate.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'qestak_reminders',
      'تذكيرات الأقساط',
      channelDescription: 'تذكيرات بمواعيد استحقاق الأقساط',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      color: Color(0xFF0D7377),
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    );
    const details =
        NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: null,
        payload: payload,
      );
      debugPrint('📅 Scheduled: "$title" at $scheduledDate');
    } catch (e) {
      debugPrint('❌ Schedule error: $e');
    }
  }

  /// Schedule all reminders for a customer's loans
  /// Called when customer logs in or refreshes loans
  static Future<void> scheduleAllReminders(List<Loan> loans) async {
    // Cancel old scheduled notifications first
    await cancelAllScheduled();

    int notifId = 5000; // Start from 5000 to avoid conflicts with immediate notifs

    for (final loan in loans) {
      if (loan.status == 'completed') continue;

      for (int i = loan.paidInstallments; i < loan.dueDates.length; i++) {
        final dueDate = loan.dueDates[i];

        // Skip past dates
        if (dueDate.isBefore(DateTime.now())) {
          // Show immediate overdue notification
          if (loan.isOverdue) {
            await showNotification(
              id: loan.id.hashCode + i,
              title: 'قسط متأخر! ⚠️',
              body:
                  'لديك قسط متأخر منذ ${DateTime.now().difference(dueDate).inDays} يوم من ${loan.adminName}',
              payload: 'overdue:${loan.id}',
            );
          }
          continue;
        }

        // ── Schedule reminder 3 days before ──
        final threeDaysBefore = dueDate.subtract(const Duration(days: 3));
        if (threeDaysBefore.isAfter(DateTime.now())) {
          await _scheduleNotification(
            id: notifId++,
            title: 'تذكير بموعد القسط 🔔',
            body:
                'قسطك من ${loan.adminName} مستحق بعد 3 أيام (${loan.installmentValue.toStringAsFixed(0)} ج.م)',
            scheduledDate: DateTime(
                threeDaysBefore.year, threeDaysBefore.month, threeDaysBefore.day, 9, 0),
            payload: 'reminder3:${loan.id}',
          );
        }

        // ── Schedule reminder 1 day before ──
        final oneDayBefore = dueDate.subtract(const Duration(days: 1));
        if (oneDayBefore.isAfter(DateTime.now())) {
          await _scheduleNotification(
            id: notifId++,
            title: 'قسطك بكرة! ⏰',
            body:
                'قسطك من ${loan.adminName} مستحق بكرة (${loan.installmentValue.toStringAsFixed(0)} ج.م)',
            scheduledDate:
                DateTime(oneDayBefore.year, oneDayBefore.month, oneDayBefore.day, 9, 0),
            payload: 'reminder1:${loan.id}',
          );
        }

        // ── Schedule on due date ──
        if (dueDate.isAfter(DateTime.now())) {
          await _scheduleNotification(
            id: notifId++,
            title: 'موعد القسط اليوم! 📌',
            body:
                'قسطك من ${loan.adminName} مستحق اليوم (${loan.installmentValue.toStringAsFixed(0)} ج.م)',
            scheduledDate: DateTime(dueDate.year, dueDate.month, dueDate.day, 10, 0),
            payload: 'due:${loan.id}',
          );
        }

        // ── Schedule overdue reminder (1 day after) ──
        final oneDayAfter = dueDate.add(const Duration(days: 1));
        if (oneDayAfter.isAfter(DateTime.now())) {
          await _scheduleNotification(
            id: notifId++,
            title: 'قسط متأخر! ⚠️',
            body:
                'لديك قسط متأخر من ${loan.adminName} (${loan.installmentValue.toStringAsFixed(0)} ج.م)',
            scheduledDate:
                DateTime(oneDayAfter.year, oneDayAfter.month, oneDayAfter.day, 10, 0),
            payload: 'overdue:${loan.id}',
          );
        }

        // Only schedule for next 3 upcoming installments (to avoid too many)
        if (notifId > 5000 + (loans.length * 12)) break;
      }
    }

    debugPrint('📅 Total scheduled: ${notifId - 5000} notifications');
  }

  // ─────────── CHECK IMMEDIATE ───────────

  static Future<void> checkOverdueLoans(List<Loan> loans) async {
    for (final loan in loans) {
      if (loan.isOverdue && loan.status != 'completed') {
        await showNotification(
          id: loan.id.hashCode,
          title: 'قسط متأخر! ⚠️',
          body: 'لديك قسط متأخر منذ ${loan.overdueDays} يوم من ${loan.adminName}',
          payload: 'overdue:${loan.id}',
        );
      }
    }
  }

  static Future<void> checkUpcomingDues(List<Loan> loans) async {
    final now = DateTime.now();
    for (final loan in loans) {
      if (loan.status == 'completed') continue;
      final next = loan.nextDueDate;
      if (next == null) continue;
      final diff = next.difference(now).inDays;
      if (diff >= 0 && diff <= 3) {
        await showNotification(
          id: loan.id.hashCode + 1000,
          title: 'تذكير بموعد القسط 🔔',
          body:
              'قسطك من ${loan.adminName} مستحق بعد $diff يوم (${loan.installmentValue.toStringAsFixed(0)} ج.م)',
          payload: 'reminder:${loan.id}',
        );
      }
    }
  }

  // ─────────── CANCEL ───────────

  static Future<void> cancelAllScheduled() async {
    await _plugin.cancelAll();
  }

  /// Get count of pending notifications (for debug)
  static Future<int> getPendingCount() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }
}
