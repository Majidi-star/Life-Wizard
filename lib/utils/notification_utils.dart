import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../database_initializer.dart';

class NotificationUtils {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Constants for shared preferences keys
  static const String _notificationsKey = 'scheduled_notifications';

  static Future<void> initialize([BuildContext? context]) async {
    if (_initialized) return;
    // Timezone setup
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    await requestPermissions();

    // Restore notifications that might have been lost due to app restart
    await restoreNotifications();
  }

  // Callback for when user taps on a notification
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');
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
    print('[DEBUG] Scheduling notification:');
    print('  ID: $id');
    print('  Title: $title');
    print('  Body: $body');
    print('  ScheduledTime: $scheduledTime');
    print('  Now: ${DateTime.now()}');
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
    print('[DEBUG] Notification scheduled (ID: $id)');

    // Save notification data for persistence
    await _saveNotificationData(id, title, body, scheduledTime);
  }

  /// Saves notification data to SharedPreferences for persistence
  static Future<void> _saveNotificationData(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing notifications
    final String? notificationsJson = prefs.getString(_notificationsKey);
    List<Map<String, dynamic>> notifications = [];

    if (notificationsJson != null) {
      notifications = List<Map<String, dynamic>>.from(
        jsonDecode(notificationsJson) as List,
      );
    }

    // Remove existing notification with same ID if exists
    notifications.removeWhere((notification) => notification['id'] == id);

    // Add new notification data
    notifications.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledTime': scheduledTime.millisecondsSinceEpoch,
    });

    // Filter out past notifications
    final now = DateTime.now().millisecondsSinceEpoch;
    notifications =
        notifications.where((notification) {
          return notification['scheduledTime'] > now;
        }).toList();

    // Save back to shared preferences
    await prefs.setString(_notificationsKey, jsonEncode(notifications));
  }

  /// Restores all saved notifications
  static Future<void> restoreNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsJson = prefs.getString(_notificationsKey);

    if (notificationsJson != null) {
      final List<Map<String, dynamic>> notifications =
          List<Map<String, dynamic>>.from(
            jsonDecode(notificationsJson) as List,
          );

      final now = DateTime.now().millisecondsSinceEpoch;

      // Filter out past notifications
      final futureNotifications =
          notifications.where((notification) {
            return notification['scheduledTime'] > now;
          }).toList();
      print('[DEBUG] Restoring notifications:');
      // Reschedule each notification
      for (final notification in futureNotifications) {
        final scheduledTime = DateTime.fromMillisecondsSinceEpoch(
          notification['scheduledTime'] as int,
        );
        print(
          '  [DEBUG] Restoring notification ID: ${notification['id']} at $scheduledTime',
        );
        // Only schedule if it's in the future
        if (scheduledTime.isAfter(DateTime.now())) {
          await _notificationsPlugin.zonedSchedule(
            notification['id'] as int,
            notification['title'] as String,
            notification['body'] as String,
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
              iOS: DarwinNotificationDetails(
                presentSound: true,
                sound: 'default',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
      }

      // Update the storage with only future notifications
      if (futureNotifications.length != notifications.length) {
        await prefs.setString(
          _notificationsKey,
          jsonEncode(futureNotifications),
        );
      }
    }
  }

  /// Cancels all notifications for a specific date
  /// Uses the date's day as part of the notification ID to identify which ones to cancel
  static Future<void> cancelNotificationsForDate(DateTime date) async {
    // Get the database instance
    final db = await DatabaseInitializer.database;
    final dateString = date.toIso8601String().split('T')[0];

    // Query all task IDs for this date
    final taskData = await db.query(
      'schedule',
      columns: ['id'],
      where: 'date = ?',
      whereArgs: [dateString],
    );
    print('[DEBUG] Cancelling notifications for date: $dateString');
    // Cancel each notification by its task ID
    for (final task in taskData) {
      final taskId = task['id'] as int;
      print('  [DEBUG] Cancelling notification with ID: $taskId');
      await _notificationsPlugin.cancel(taskId);
    }

    // Also remove from saved notifications
    // Remove all notifications whose IDs match any of the task IDs for this date
    await _removeNotificationsWithIdList(
      taskData.map((t) => t['id'] as int).toList(),
    );
  }

  // Add this helper method to your NotificationUtils class:
  static Future<void> _removeNotificationsWithIdList(List<int> idList) async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsJson = prefs.getString(_notificationsKey);

    if (notificationsJson != null) {
      final List<Map<String, dynamic>> notifications =
          List<Map<String, dynamic>>.from(
            jsonDecode(notificationsJson) as List,
          );

      // Filter out notifications with the given IDs
      final filteredNotifications =
          notifications.where((notification) {
            final id = notification['id'] as int;
            return !idList.contains(id);
          }).toList();

      // Save back to shared preferences
      await prefs.setString(
        _notificationsKey,
        jsonEncode(filteredNotifications),
      );
    }
  }

  /// Removes notifications with specific ID prefix from SharedPreferences
  static Future<void> _removeNotificationsWithIdPrefix(int idPrefix) async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsJson = prefs.getString(_notificationsKey);

    if (notificationsJson != null) {
      final List<Map<String, dynamic>> notifications =
          List<Map<String, dynamic>>.from(
            jsonDecode(notificationsJson) as List,
          );

      // Filter out notifications with the given prefix
      final filteredNotifications =
          notifications.where((notification) {
            final id = notification['id'] as int;
            return id < idPrefix || id >= idPrefix + 1000;
          }).toList();

      // Save back to shared preferences
      await prefs.setString(
        _notificationsKey,
        jsonEncode(filteredNotifications),
      );
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

    // Also clear saved notifications
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }
}
