import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../database_initializer.dart';

class NotificationUtils {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Constants for shared preferences keys
  static const String _notificationsKey = 'scheduled_notifications';

  static bool get _isMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> initialize([BuildContext? context]) async {
    if (_initialized) return;
    if (kIsWeb) return;

    // Timezone setup
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Could not set local timezone, using default: $e');
      }
    }

    if (!_isMobilePlatform) {
      _initialized = true;
      return;
    }

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
    await cleanupOldNotifications();
  }

  static Future<void> cancelAllNotifications() async {
    if (!kIsWeb && _isMobilePlatform) {
      await _notificationsPlugin.cancelAll();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }

  // Callback for when user taps on a notification
  static void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('Notification tapped: ${response.payload}');
    }
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb) return;
    if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final androidPlugin =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (kIsWeb || !_isMobilePlatform) return;
    if (!await areNotificationsEnabled()) {
      return;
    }

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
    );

    await _saveNotificationData(id, title, body, scheduledTime);
  }

  // Checking if the notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications') ?? true;
  }

  static Future<List<Map<String, dynamic>>> _readSavedNotifications(
    SharedPreferences prefs,
  ) async {
    final String? notificationsJson = prefs.getString(_notificationsKey);
    if (notificationsJson == null || notificationsJson.isEmpty) {
      return [];
    }
    try {
      return List<Map<String, dynamic>>.from(
        jsonDecode(notificationsJson) as List,
      );
    } catch (_) {
      return [];
    }
  }

  /// Saves notification data to SharedPreferences for persistence
  static Future<void> _saveNotificationData(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await _readSavedNotifications(prefs);
    final dateString = DatabaseInitializer.formatDateOnly(scheduledTime);

    notifications.removeWhere((notification) => notification['id'] == id);
    notifications.add({
      'id': id,
      'title': title,
      'body': body,
      'date': dateString,
      'scheduledTime': scheduledTime.millisecondsSinceEpoch,
    });

    final now = DateTime.now().millisecondsSinceEpoch;
    final activeNotifications =
        notifications
            .where((n) => (n['scheduledTime'] as int? ?? 0) > now)
            .toList();

    await prefs.setString(_notificationsKey, jsonEncode(activeNotifications));
  }

  /// Restores all saved notifications
  static Future<void> restoreNotifications() async {
    if (kIsWeb || !_isMobilePlatform) return;
    if (!await areNotificationsEnabled()) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final notifications = await _readSavedNotifications(prefs);
    if (notifications.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final futureNotifications =
        notifications
            .where((n) => (n['scheduledTime'] as int? ?? 0) > now)
            .toList();

    for (final notification in futureNotifications) {
      final scheduledTime = DateTime.fromMillisecondsSinceEpoch(
        notification['scheduledTime'] as int,
      );
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
        );
      }
    }

    if (futureNotifications.length != notifications.length) {
      await prefs.setString(
        _notificationsKey,
        jsonEncode(futureNotifications),
      );
    }
  }

  /// Cancels a single notification by its schedule ID and removes it from saved storage.
  static Future<void> cancelNotificationById(int id) async {
    if (!kIsWeb && _isMobilePlatform) {
      await _notificationsPlugin.cancel(id);
    }
    await _removeNotificationsWithIdList([id]);
  }

  /// Cancels all notifications for a specific date using both the saved list in
  /// SharedPreferences and current database schedule IDs.
  static Future<void> cancelNotificationsForDate(DateTime date) async {
    if (kIsWeb) return;
    final dateString = DatabaseInitializer.formatDateOnly(date);
    final prefs = await SharedPreferences.getInstance();
    final savedNotifications = await _readSavedNotifications(prefs);

    final Set<int> idsToCancel = {};
    for (final notification in savedNotifications) {
      final id = notification['id'];
      if (id is! int) continue;
      final savedDate = notification['date'] as String?;
      final scheduledMs = notification['scheduledTime'] as int?;
      final matchesSavedDate = savedDate == dateString;
      final matchesTimestampDate =
          scheduledMs != null &&
          DatabaseInitializer.formatDateOnly(
                DateTime.fromMillisecondsSinceEpoch(scheduledMs),
              ) ==
              dateString;
      if (matchesSavedDate || matchesTimestampDate) {
        idsToCancel.add(id);
      }
    }

    // Also include any DB schedule IDs for this date.
    final db = await DatabaseInitializer.database;
    final taskData = await db.query(
      'schedule',
      columns: ['id'],
      where: 'date = ?',
      whereArgs: [dateString],
    );
    for (final task in taskData) {
      final id = task['id'];
      if (id is int) {
        idsToCancel.add(id);
      }
    }

    if (_isMobilePlatform) {
      for (final taskId in idsToCancel) {
        await _notificationsPlugin.cancel(taskId);
      }
    }

    if (idsToCancel.isNotEmpty) {
      await _removeNotificationsWithIdList(idsToCancel.toList());
    }
  }

  static Future<void> _removeNotificationsWithIdList(List<int> idList) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await _readSavedNotifications(prefs);
    if (notifications.isEmpty) return;

    final idSet = idList.toSet();
    final filteredNotifications =
        notifications
            .where((n) => !idSet.contains(n['id'] as int? ?? -1))
            .toList();

    await prefs.setString(
      _notificationsKey,
      jsonEncode(filteredNotifications),
    );
  }

  /// Updates notifications for a schedule change using schedule.id as the single ID scheme.
  static Future<void> updateNotificationsForScheduleChange(
    DateTime date,
    List<Map<String, dynamic>> tasks,
  ) async {
    await cancelNotificationsForDate(date);

    for (final task in tasks) {
      final taskId = task['id'] as int?;
      if (taskId == null) continue;
      final startTimeStr = task['startTime'] as String? ?? '';
      final taskName = task['activity'] as String? ?? 'Task';

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

          if (scheduledTime.isAfter(DateTime.now())) {
            await scheduleNotification(
              id: taskId,
              title: 'Task Reminder',
              body:
                  'It\'s time! "$taskName" has just started. Check your schedule!',
              scheduledTime: scheduledTime,
            );
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error scheduling notification: $e');
          }
        }
      }
    }
  }

  static Future<void> cancelAll() async {
    await cancelAllNotifications();
  }

  static Future<void> cleanupOldNotifications() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final notifications = await _readSavedNotifications(prefs);
    if (notifications.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final validNotifications =
        notifications
            .where((n) => (n['scheduledTime'] as int? ?? 0) > now)
            .toList();

    if (validNotifications.length != notifications.length) {
      await prefs.setString(
        _notificationsKey,
        jsonEncode(validNotifications),
      );
    }
  }
}
