import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:io';

class NotificationUtils {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize([BuildContext? context]) async {
    if (_initialized) return;
    // Timezone setup
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(initSettings);
    _initialized = true;
    await requestPermissions();
  }

  static Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      // Android 13+ (API 33) requires runtime notification permission
      final androidPlugin =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      // Request notification permission
      await androidPlugin?.requestNotificationsPermission();

      // Request exact alarms permission
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'schedule_channel',
          'Schedule Notifications',
          channelDescription: 'Notifies about scheduled activities',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(presentSound: true, sound: 'default'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancels all notifications for a specific date
  /// Uses the date's day as part of the notification ID to identify which ones to cancel
  static Future<void> cancelNotificationsForDate(DateTime date) async {
    // Get all pending notifications
    final pendingNotifications =
        await _notificationsPlugin.pendingNotificationRequests();

    // The ID prefix for notifications of this date (day * 1000)
    final idPrefix = date.day * 1000;

    // Cancel each notification that matches the prefix
    for (var notification in pendingNotifications) {
      if (notification.id >= idPrefix && notification.id < idPrefix + 1000) {
        await _notificationsPlugin.cancel(notification.id);
      }
    }
  }

  /// Updates notifications for a schedule change
  /// This should be called whenever the schedule for a date is modified
  static Future<void> updateNotificationsForScheduleChange(
    DateTime date,
    List<Map<String, dynamic>> tasks,
  ) async {
    // First cancel all existing notifications for this date
    await cancelNotificationsForDate(date);

    // Then schedule new notifications for each task
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final startTimeStr = task['startTime'] as String;
      final taskName = task['activity'] as String? ?? 'Task';

      // Parse start time
      final startParts = startTimeStr.split(':');
      if (startParts.length == 2) {
        try {
          final hour = int.parse(startParts[0]);
          final minute = int.parse(startParts[1]);
          final scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            hour,
            minute,
          );

          // Only schedule if the time is in the future
          if (scheduledTime.isAfter(DateTime.now())) {
            await scheduleNotification(
              id: date.day * 1000 + i, // unique id per task per day
              title: 'Task Reminder',
              body:
                  'It\'s time! "$taskName" has just started. Check your schedule!',
              scheduledTime: scheduledTime,
            );
          }
        } catch (e) {
          // Handle parsing errors
          print('Error scheduling notification: $e');
        }
      }
    }
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
