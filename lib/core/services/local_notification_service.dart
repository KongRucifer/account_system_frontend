import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Callback when user taps a notification. Must be top-level or static.
@pragma('vm:entry-point')
void onNotificationTapBackground(NotificationResponse response) {
  debugPrint('🔔 Notification tapped in background: ${response.payload}');
  LocalNotificationService._tapController.add(response.payload ?? '');
}

/// Manages local notification display.
/// Shows a single notification with sound (no looping).
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Stream for notification tap events
  static final StreamController<String> _tapController =
      StreamController<String>.broadcast();
  static Stream<String> get onTap => _tapController.stream;

  static bool _isInitialized = false;

  // Channel config matching native MainActivity.kt
  static const _channelId = 'meeting_notifications_v6';
  static const _channelName = 'Meeting Notifications';
  static const _channelDescription =
      'Notifications for upcoming village bank meetings';

  static Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('🔔 Notification tapped (foreground): ${response.payload}');
        _tapController.add(response.payload ?? '');
      },
      onDidReceiveBackgroundNotificationResponse: onNotificationTapBackground,
    );

    _isInitialized = true;
    debugPrint('✅ LocalNotificationService initialized');
  }

  /// Show a single notification with sound (plays once via Android channel).
  static Future<void> showSingleNotification({
    required String notificationId,
    required String title,
    required String body,
  }) async {
    final id = notificationId.hashCode.abs() % 100000;
    debugPrint('� [SHOW] Showing notification: id=$notificationId, androidNotifId=$id');

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('meeting_sound'),
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
    );

    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details, payload: notificationId);
  }

  /// Cancel all notifications and dismiss from tray.
  static Future<void> cancelAll() async {
    debugPrint('🔇 Cancelling ALL notifications');
    await _plugin.cancelAll();
  }
}
