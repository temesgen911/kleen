import 'package:flutter/foundation.dart';

/// Modular Local Notification Service for Cleaning AI streak and reset motivation.
class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  bool _hasRequestedPermission = false;
  bool _isPermissionGranted = false;

  bool get hasRequestedPermission => _hasRequestedPermission;
  bool get isPermissionGranted => _isPermissionGranted;

  /// Contextual permission requester called after the first streak achievement.
  Future<bool> requestContextualPermission() async {
    if (_hasRequestedPermission) return _isPermissionGranted;
    _hasRequestedPermission = true;
    // In Flutter without native APNS push config, local in-app / system notification is simulated cleanly
    _isPermissionGranted = true;
    debugPrint('[NotificationService] Notification permission granted contextually.');
    return _isPermissionGranted;
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

  void _dispatchNotification({required String title, required String body}) {
    debugPrint('[NotificationService Notification] $title — $body');
  }
}
