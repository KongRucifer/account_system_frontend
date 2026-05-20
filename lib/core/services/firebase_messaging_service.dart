import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import 'app_logger.dart';

// Global callback — registered by the app after Riverpod is ready
// Called when user taps a local notification (foreground or background)
typedef NotificationTapCallback = Future<void> Function(String notificationId);
NotificationTapCallback? _globalNotificationTapCallback;

void setNotificationTapCallback(NotificationTapCallback callback) {
  _globalNotificationTapCallback = callback;
  debugPrint('✅ Notification tap callback registered');
}

// Must be a top-level function with @pragma so R8 does not strip it in release builds
@pragma('vm:entry-point')
void onNotificationTap(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null) return;
  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final notificationId = data['notificationId'] as String?;
    debugPrint('👆 Notification tapped, notificationId: $notificationId');
    if (notificationId != null && _globalNotificationTapCallback != null) {
      _globalNotificationTapCallback!(notificationId);
    }
  } catch (e) {
    debugPrint('❌ Error parsing notification tap payload: $e');
  }
}

// Background message handler - ต้องอยู่นอก class (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 BACKGROUND MESSAGE RECEIVED: ${message.messageId}');
  debugPrint('🔔 Title: ${message.notification?.title}');
  debugPrint('🔔 Body: ${message.notification?.body}');
  debugPrint('🔔 Data: ${message.data}');
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔔 Firebase initialized in background');

  // Initialize local notifications in background-safe mode (no permission request)
  await LocalNotificationService.initializeForBackground();
  debugPrint('🔔 Local notifications initialized in background');

  // ALWAYS show local notification - this is the only way notifications will appear now
  await LocalNotificationService.showNotification(message);
  debugPrint('🔔 Local notification shown in background');

  debugPrint('🔔 Background handler completed: ${message.messageId ?? 'unknown'}');
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;
  bool _isInitialized = false;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    // Track app lifecycle changes
    WidgetsBinding.instance.addObserver(AppLifecycleObserver());
    
    try {
      // Request permission for iOS (Android permission is handled in main.dart before this)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      AppLogger.log('🔔 FCM Permission status: ${settings.authorizationStatus}');

      // Get FCM token (but don't send to server here - FcmRegistrationService will do that after login)
      await _getFcmToken();

      // Listen to token refresh (note: token sending happens in FcmRegistrationService)
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token refreshed: $newToken');
        // Note: Token is sent to server by FcmRegistrationService after login
      });

      // DISABLED: Foreground presentation - we only want background notifications
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      // Re-enabled: Handle messages when app is in foreground (but treat them like background)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification click when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check if app was opened from notification (terminated state)
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      AppLogger.log('✅ Firebase Messaging service ready');
    } catch (e) {
      AppLogger.log('❌ Error initializing Firebase Messaging: $e');
    }
  }

  /// Get FCM Token
  Future<void> _getFcmToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      AppLogger.log('📱 FCM Token: $_fcmToken');
      // Note: Token is sent to server by FcmRegistrationService after login
    } catch (e) {
      AppLogger.log('❌ Error getting FCM token: $e');
    }
  }

  /// Get current FCM token (called by FcmRegistrationService to send to backend)
  Future<String?> getToken() async {
    if (_fcmToken == null) {
      _fcmToken = await _firebaseMessaging.getToken();
    }
    return _fcmToken;
  }

  
  /// Handle foreground messages (treat them like background notifications)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 FOREGROUND MESSAGE RECEIVED: ${message.messageId}');
    debugPrint('📩 Title: ${message.notification?.title}');
    debugPrint('📩 Body: ${message.notification?.body}');
    debugPrint('📩 Data: ${message.data}');

    // Show local notification even in foreground (with sound)
    LocalNotificationService.showNotification(message);
    debugPrint('📩 Local notification shown in foreground');
  }

  /// Handle notification click (app background → foreground, or terminated → open)
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('👆 FCM notification tapped: ${message.data}');
    final notificationId = message.data['notificationId'] as String?;
    if (notificationId != null && _globalNotificationTapCallback != null) {
      _globalNotificationTapCallback!(notificationId);
    }
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

/// Observer to track app lifecycle changes
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('🔄 APP LIFECYCLE CHANGED: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('📱 APP RESUMED (foreground)');
        break;
      case AppLifecycleState.inactive:
        debugPrint('📱 APP INACTIVE');
        break;
      case AppLifecycleState.paused:
        debugPrint('📱 APP PAUSED (background)');
        break;
      case AppLifecycleState.detached:
        debugPrint('📱 APP DETACHED');
        break;
      case AppLifecycleState.hidden:
        debugPrint('📱 APP HIDDEN');
        break;
    }
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
      'meeting_notifications_v6',
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
      'meeting_notifications_v6',
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
    AppLogger.log('🔔 showNotification called - IS BACKGROUND: ${WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused || WidgetsBinding.instance.lifecycleState == AppLifecycleState.inactive}');

    if (!_initialized) {
      AppLogger.log('🔔 Initializing local notifications (background-safe)...');
      await initializeForBackground();
    }

    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'ແຈ້ງເຕືອນ';
    final body = notification?.body ?? data['body'] ?? 'ມີການແຈ້ງເຕືອນໃໝ່';

    debugPrint('🔔 Notification title: $title');
    debugPrint('🔔 Notification body: $body');

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'meeting_notifications_v6',
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
        AppLogger.log('🔔 Notification shown (id: $currentId)');
      } catch (e) {
        AppLogger.log('🔔 ERROR showing notification: $e');
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
    debugPrint('🔇 CANCEL REPEATING STARTED');
    _sessionToken++; // invalidate any running timer session immediately
    debugPrint('🔇 Session token incremented to: $_sessionToken');
    
    _repeatTimer?.cancel();
    _repeatTimer = null;
    debugPrint('🔇 Timer cancelled and set to null');
    
    await _notificationsPlugin.cancelAll();
    debugPrint('🔇 All notifications cancelled');
    
    debugPrint('🔇 CANCEL REPEATING COMPLETED - Sound should stop now');
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
