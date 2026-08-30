import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/cleaning_plan.dart';

/// Modular Local Notification Service using flutter_local_notifications.
class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _hasRequestedPermission = false;
  bool _isPermissionGranted = false;

  bool get hasRequestedPermission => _hasRequestedPermission;
  bool get isPermissionGranted => _isPermissionGranted;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();

      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const initializationSettings = InitializationSettings(
        iOS: initializationSettingsIOS,
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('[NotificationService] Notification tapped: ${details.payload}');
        },
      );

      _initialized = true;
      debugPrint('[NotificationService] Local notifications initialized.');
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
    }
  }

  /// Contextual permission requester called after streak achievement or task setup.
  Future<bool> requestContextualPermission() async {
    await initialize();
    if (_hasRequestedPermission) return _isPermissionGranted;
    _hasRequestedPermission = true;

    try {
      final iosResult = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      _isPermissionGranted = iosResult ?? true;
      debugPrint(
          '[NotificationService] Notification permission status: $_isPermissionGranted');
    } catch (e) {
      _isPermissionGranted = true;
    }
    return _isPermissionGranted;
  }

  /// Schedules a recurring notification for a specific cleaning task based on its scheduled day.
  Future<void> scheduleTaskNotification(PlanTask task) async {
    await initialize();
    if (!_isPermissionGranted) {
      await requestContextualPermission();
    }
    if (!_isPermissionGranted) return;

    try {
      final notificationId = task.id.hashCode.abs() % 100000;
      final title = '🧹 Time to clean: ${task.sourceItem.name}';
      final body =
          '${task.sourceItem.cleaningAction} in ${task.roomName} (${task.estimatedMinutes} min)';

      const notificationDetails = NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          'kleenai_tasks',
          'Cleaning Tasks',
          channelDescription: 'Reminders for scheduled cleaning activities',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

      // Calculate next occurrence date matching task's scheduled weekday at 9:00 AM
      final now = DateTime.now();
      final targetWeekday = task.scheduledDay.index + 1; // 1 (Mon) .. 7 (Sun)
      int daysUntil = targetWeekday - now.weekday;
      if (daysUntil <= 0) daysUntil += 7;

      final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(days: daysUntil));
      final notificationTime = tz.TZDateTime(
        tz.local,
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        9, // 9:00 AM
        0,
      );

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        notificationTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      debugPrint(
          '[NotificationService] Scheduled notification #$notificationId for ${task.sourceItem.name} at $notificationTime');
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling task notification: $e');
    }
  }

  /// Cancels a scheduled task notification.
  Future<void> cancelTaskNotification(String taskId) async {
    try {
      final notificationId = taskId.hashCode.abs() % 100000;
      await _notificationsPlugin.cancel(notificationId);
      debugPrint('[NotificationService] Cancelled notification #$notificationId');
    } catch (e) {
      debugPrint('[NotificationService] Error cancelling notification: $e');
    }
  }

  /// Triggers or schedules the first streak milestone notification.
  Future<void> sendFirstStreakNotification() async {
    if (!_hasRequestedPermission) {
      await requestContextualPermission();
    }
    if (!_isPermissionGranted) return;

    const title = 'Your first streak 🔥';
    const body = 'Day 1 complete. Come back tomorrow and keep it going.';
    _dispatchNotification(title: title, body: body);
  }

  /// Triggers a continuing streak milestone notification.
  Future<void> sendContinuingStreakNotification(int streakCount) async {
    if (!_isPermissionGranted) return;

    final title = '🔥 $streakCount-day streak!';
    const body = 'You completed today\'s reset. Keep it going.';
    _dispatchNotification(title: title, body: body);
  }

  Future<void> _dispatchNotification(
      {required String title, required String body}) async {
    await initialize();
    try {
      const notificationDetails = NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          'kleenai_streaks',
          'Streaks & Milestones',
          channelDescription: 'Streak rewards and reset milestone alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        notificationDetails,
      );
      debugPrint('[NotificationService Notification] $title — $body');
    } catch (e) {
      debugPrint('[NotificationService Notification Error] $e');
    }
  }
}
