import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../api_client.dart';

/// Handles local notifications for the app (currently: engineer daily report reminder).
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _dailyReportChannelId = 'daily_report_reminder';
  static const String _dailyReportChannelName = 'Daily Report Reminder';
  static const String _dailyReportChannelDescription =
      'Reminds engineers to submit their daily report at 17:00 on weekdays.';

  // Fixed ID so we can easily cancel/update the scheduled reminder.
  static const int _dailyReportNotificationId = 1001;

  /// Global navigator key used to handle navigation from notification taps.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Must be called before runApp.
  static Future<void> initialize() async {
    // Initialize timezone data once.
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(tz.local.name));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response);
      },
    );

    // Request notification permissions where needed.
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    // Android 13+ runtime notification permission
    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // iOS/macOS permissions
    final iosImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static void _handleNotificationTap(NotificationResponse response) {
    // We only have one type of notification for now, so always navigate
    // to the engineer daily report creation screen.
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushNamed('/engineer/reports/create');
  }

  /// Cancel any scheduled engineer daily report reminders.
  static Future<void> cancelEngineerDailyReportReminder() async {
    await _plugin.cancel(_dailyReportNotificationId);
  }

  /// Schedule a weekday 17:00 reminder for engineers, with a pre-check
  /// against today's report.
  ///
  /// This should be called when:
  /// - the app starts and the authenticated user is an engineer
  /// - after successful engineer login
  static Future<void> scheduleEngineerDailyReportReminderIfNeeded() async {
    final now = DateTime.now();

    // Only schedule for Monday-Friday.
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      await cancelEngineerDailyReportReminder();
      return;
    }

    // Check if today's report already exists.
    final hasReportToday = await _hasEngineerReportForDate(now);
    if (hasReportToday) {
      // Nothing to remind today.
      await cancelEngineerDailyReportReminder();
      return;
    }

    // Compute the next 17:00 today (or skip if already past and let
    // the next app start schedule again for the next day).
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      17,
      0,
    );

    if (scheduledTime.isBefore(now)) {
      // It's already past 17:00 today; don't schedule until the next app start.
      await cancelEngineerDailyReportReminder();
      return;
    }

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      _dailyReportChannelId,
      _dailyReportChannelName,
      channelDescription: _dailyReportChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.zonedSchedule(
      _dailyReportNotificationId,
      'Daily Report Reminder',
      'Have you completed your daily report for today?\nTap to submit your report before the end of the workday.',
      tzTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: 'engineer_daily_report',
    );
  }

  /// Helper: check if the engineer has a report for the given date
  /// using GET /engineer/reports?date=YYYY-MM-DD.
  static Future<bool> _hasEngineerReportForDate(DateTime date) async {
    try {
      final response = await ApiClient.getEngineerReportsByDate(date);
      if (response == null) {
        // Treat as "unknown" - don't schedule to avoid spamming.
        return true;
      }

      if (response.statusCode != 200) {
        return true;
      }

      final body = response.body;
      if (body.trim().isEmpty) {
        return false;
      }

      // Expecting either [] or [ { ... } ]
      if (body.trim().startsWith('[')) {
        // A simple and safe check without decoding: non-empty list will contain '{'.
        return body.contains('{');
      }

      return false;
    } catch (_) {
      // On error, be conservative and avoid sending the reminder.
      return true;
    }
  }
}


