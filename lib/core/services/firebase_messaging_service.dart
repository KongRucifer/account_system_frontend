import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';

// Must be a top-level function with @pragma so R8 does not strip it in release builds
@pragma('vm:entry-point')
void onNotificationTap(NotificationResponse response) {
  final payload = response.payload;
  if (payload != null) {
    final data = jsonDecode(payload);
    debugPrint('👆 Notification tapped with data: $data');
  }
}

// Background message handler - ต้องอยู่นอก class (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize local notifications in background-safe mode (no permission request)
  await LocalNotificationService.initializeForBackground();

  // Only show local notification for data-only messages.
  // If message.notification != null the OS already displayed it — skip to avoid duplicates.
  if (message.notification == null) {
    await LocalNotificationService.showNotification(message);
  }

  debugPrint('🔔 Background handler done: ${message.messageId ?? 'unknown'}');
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

  /// Public getter for accessing the plugin from other files
  static FlutterLocalNotificationsPlugin get notificationsPlugin => _notificationsPlugin;

  static bool _initialized = false;
  static Timer? _repeatTimer;
  static int _sessionToken = 0;
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
      onDidReceiveNotificationResponse: onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onNotificationTap,
    );

    // Create notification channel for Android
    // Channel ID bumped to v4 to force recreation with meeting_sound.wav
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'meeting_notifications_v5',
      'Meeting Notifications',
      description: 'Notifications for upcoming village bank meetings',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('meeting_sound'),
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);

    // Request POST_NOTIFICATIONS permission on Android 13+ (API 33+)
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
    debugPrint('✅ Local Notification Service initialized');
  }

  /// Initialize for background isolate (no permission request - UI operations not allowed)
  static Future<void> initializeForBackground() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Channel ID bumped to v4 to force recreation with meeting_sound.wav
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'meeting_notifications_v5',
      'Meeting Notifications',
      description: 'Notifications for upcoming village bank meetings',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('meeting_sound'),
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Show notification and repeat every 5s until cancelRepeating() is called
  static Future<void> showNotification(RemoteMessage message) async {
    debugPrint('🔔 showNotification called');

    if (!_initialized) {
      debugPrint('🔔 Initializing local notifications (background-safe)...');
      await initializeForBackground();
    }

    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'ແຈ້ງເຕືອນ';
    final body = notification?.body ?? data['body'] ?? 'ມີການແຈ້ງເຕືອນໃໝ່';

    debugPrint('🔔 Notification title: $title');
    debugPrint('🔔 Notification body: $body');

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'meeting_notifications_v5',
      'Meeting Notifications',
      channelDescription: 'Notifications for upcoming village bank meetings',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('meeting_sound'),
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

    // Cancel any running timer immediately — invalidate old session
    _repeatTimer?.cancel();
    _repeatTimer = null;
    await _notificationsPlugin.cancelAll();

    // Create a unique session token for this notification
    _sessionToken++;
    final myToken = _sessionToken;

    // A/B alternating IDs force Android to treat each repeat as NEW — required for sound
    final baseId = message.hashCode.abs() % 100000;
    final idA = baseId;
    final idB = baseId + 100000;
    int localToggle = 0;

    Future<void> showOnce() async {
      final currentId = localToggle.isEven ? idA : idB;
      final previousId = localToggle.isEven ? idB : idA;
      localToggle++;
      try {
        await _notificationsPlugin.cancel(previousId);
        await _notificationsPlugin.show(
          currentId,
          title,
          body,
          details,
          payload: jsonEncode(data),
        );
        debugPrint('🔔 Notification shown (id: $currentId)');
      } catch (e) {
        debugPrint('🔔 ERROR showing notification: $e');
      }
    }

    // Show immediately
    await showOnce();

    // Repeat every 5 seconds — stop if session token changed (cancelled or new notification)
    _repeatTimer = Timer.periodic(const Duration(seconds: 5), (t) async {
      if (_sessionToken != myToken) {
        t.cancel();
        return;
      }
      await showOnce();
    });

    debugPrint('🔁 Started repeat notification timer (session: $myToken, A/B: $idA/$idB)');
  }

  /// Cancel repeating notification — call this when user reads the notification
  static Future<void> cancelRepeating() async {
    _sessionToken++; // invalidate any running timer session immediately
    _repeatTimer?.cancel();
    _repeatTimer = null;
    await _notificationsPlugin.cancelAll();
    debugPrint('🔇 Cancelled repeating notification (all cleared)');
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
