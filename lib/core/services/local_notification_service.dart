import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Callback when user taps a notification. Must be top-level or static.
@pragma('vm:entry-point')
void onNotificationTapBackground(NotificationResponse response) {
  debugPrint('🔔 Notification tapped in background: ${response.payload}');
  // This will be handled by FirebaseMessagingService via the stream
  LocalNotificationService._tapController.add(response.payload ?? '');
}

/// Manages local notification display and looping sound.
///
/// Sound loops every 10 seconds by re-firing the notification until
/// explicitly cancelled (user tap, mark-as-read, or another device reads it).
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Stream for notification tap events
  static final StreamController<String> _tapController =
      StreamController<String>.broadcast();
  static Stream<String> get onTap => _tapController.stream;

  // Looping sound state
  static Timer? _loopTimer;
  static int _sessionToken = 0;
  static int _activeNotificationId = 0;
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

  /// Show a notification and start looping sound every 10 seconds.
  /// The notification re-fires every 10s to replay the channel sound.
  static Future<void> showWithLoopingSound({
    required String notificationId,
    required String title,
    required String body,
  }) async {
    // Increment session token to invalidate previous loops
    _sessionToken++;
    final currentSession = _sessionToken;
    _activeNotificationId = notificationId.hashCode.abs() % 100000;

    debugPrint(
        '🔊 Starting looping notification: $notificationId (session: $currentSession)');

    // Show first notification immediately
    await _showNotification(
      id: _activeNotificationId,
      title: title,
      body: body,
      payload: notificationId,
    );

    // Cancel any existing loop timer
    _loopTimer?.cancel();

    // Start 10-second loop
    _loopTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      // Stop if session changed (another notification took over or was cancelled)
      if (currentSession != _sessionToken) {
        timer.cancel();
        debugPrint('🔇 Loop cancelled: session expired ($currentSession != $_sessionToken)');
        return;
      }

      debugPrint('🔊 Re-firing notification sound (loop tick)');
      _showNotification(
        id: _activeNotificationId,
        title: title,
        body: body,
        payload: notificationId,
      );
    });
  }

  /// Cancel the looping sound and dismiss the notification.
  static Future<void> cancelRepeating() async {
    debugPrint('🔇 CANCEL REPEATING STARTED');
    _sessionToken++; // Invalidate current loop
    _loopTimer?.cancel();
    _loopTimer = null;

    if (_activeNotificationId != 0) {
      await _plugin.cancel(_activeNotificationId);
      _activeNotificationId = 0;
    }
    debugPrint('🔇 CANCEL REPEATING DONE');
  }

  /// Cancel all notifications.
  static Future<void> cancelAll() async {
    debugPrint('🔇 Cancelling ALL notifications');
    _sessionToken++;
    _loopTimer?.cancel();
    _loopTimer = null;
    _activeNotificationId = 0;
    await _plugin.cancelAll();
  }

  /// Cleanup orphaned sound sessions — called on app cold start.
  static Future<void> cleanupOrphanedSessions() async {
    debugPrint('🧹 ===== CLEANING UP ORPHANED SOUND SESSIONS =====');
    _loopTimer?.cancel();
    _loopTimer = null;
    _sessionToken = 999999; // Invalidate any background loops
    await _plugin.cancelAll();
    _activeNotificationId = 0;
    debugPrint('🧹 Cleanup done');
  }

  /// Whether a looping notification is currently active.
  static bool get isLooping => _loopTimer != null && _loopTimer!.isActive;

  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
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

    await _plugin.show(id, title, body, details, payload: payload);
  }
}
