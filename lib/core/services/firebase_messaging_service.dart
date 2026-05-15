import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Background message handler - ต้องอยู่นอก class (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 Background message received: ${message.messageId}');
  
  // Show local notification
  await LocalNotificationService.showNotification(message);
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      // Request permission (iOS)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('🔔 FCM Permission status: ${settings.authorizationStatus}');

      // Get FCM token (but don't send to server here - FcmRegistrationService will do that after login)
      await _getFcmToken();

      // Listen to token refresh (note: token sending happens in FcmRegistrationService)
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token refreshed: $newToken');
        // Note: Token is sent to server by FcmRegistrationService after login
      });

      // Set foreground notification presentation options
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification click when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check if app was opened from notification (terminated state)
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      debugPrint('✅ Firebase Messaging initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Messaging: $e');
    }
  }

  /// Get FCM Token
  Future<void> _getFcmToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token: $_fcmToken');
      // Note: Token is sent to server by FcmRegistrationService after login
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// Get current FCM token (called by FcmRegistrationService to send to backend)
  Future<String?> getToken() async {
    if (_fcmToken == null) {
      _fcmToken = await _firebaseMessaging.getToken();
    }
    return _fcmToken;
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Foreground message received:');
    debugPrint('  Title: ${message.notification?.title}');
    debugPrint('  Body: ${message.notification?.body}');
    debugPrint('  Data: ${message.data}');

    // Show local notification
    LocalNotificationService.showNotification(message);
  }

  /// Handle notification click
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('👆 Notification clicked: ${message.data}');
    
    // Navigate to notifications page or specific screen
    final notificationId = message.data['notificationId'];
    final type = message.data['type'];
    
    // TODO: Implement navigation logic
    // Navigator.pushNamed(context, '/notifications', arguments: notificationId);
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('📌 Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('📌 Unsubscribed from topic: $topic');
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Delete FCM token (logout)
  Future<void> deleteToken() async {
    await _firebaseMessaging.deleteToken();
    _fcmToken = null;
    debugPrint('🗑️ FCM token deleted');
  }
}

/// Local Notification Service for showing notifications
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize local notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
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
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'meeting_notifications', // id
      'Meeting Notifications', // title
      description: 'Notifications for upcoming village bank meetings',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
    debugPrint('✅ Local Notification Service initialized');
  }

  /// Show notification
  static Future<void> showNotification(RemoteMessage message) async {
    if (!_initialized) {
      await initialize();
    }

    final notification = message.notification;
    final data = message.data;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'meeting_notifications',
      'Meeting Notifications',
      channelDescription: 'Notifications for upcoming village bank meetings',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      ticker: 'New notification',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      message.hashCode, // notification id
      notification?.title ?? 'ແຈ້ງເຕືອນ', // ຫัวข้อ (Notification)
      notification?.body ?? 'ມີການແຈ້ງເຕືອນໃໝ່', // ข้อความ (New notification)
      details,
      payload: jsonEncode(data),
    );
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      final data = jsonDecode(payload);
      debugPrint('👆 Notification tapped with data: $data');
      
      // TODO: Navigate to notifications page
      // Navigator.pushNamed(context, '/notifications');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Cancel specific notification
  static Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
