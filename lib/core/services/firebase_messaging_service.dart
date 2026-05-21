import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import 'app_logger.dart';

// Global callback — registered by the app after Riverpod is ready
// Called when user taps a local notification (foreground or background)
typedef NotificationTapCallback = Future<void> Function(String notificationId);
NotificationTapCallback? _globalNotificationTapCallback;
String? _pendingNotificationId; // For notifications tapped before callback is ready

/// Public getter to check if there's a pending notification tap from terminated state
String? get pendingNotificationId => _pendingNotificationId;

/// Clear the pending notification ID after processing
void clearPendingNotificationId() {
  _pendingNotificationId = null;
}

void setNotificationTapCallback(NotificationTapCallback callback) {
  _globalNotificationTapCallback = callback;
  debugPrint('✅ Notification tap callback registered');
  
  // AGGRESSIVE: Stop any lingering sounds immediately when callback is set
  // This happens when app launches from terminated state
  debugPrint('� STOPPING ALL SOUNDS ON CALLBACK REGISTRATION');
  LocalNotificationService.cancelRepeating();
  LocalNotificationService.cancelAll();
  
  // Check if there was a pending notification tap from terminated state
  if (_pendingNotificationId != null) {
    debugPrint('👆 PROCESSING PENDING NOTIFICATION TAP: $_pendingNotificationId');
    final pendingId = _pendingNotificationId!;
    _pendingNotificationId = null;
    callback(pendingId);
  }
  debugPrint('👆 ===== PENDING NOTIFICATION PROCESSING COMPLETE =====');
}

// Must be a top-level function with @pragma so R8 does not strip it in release builds
@pragma('vm:entry-point')
void onNotificationTap(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null) return;
  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final notificationId = data['notificationId'] as String?;
    debugPrint('👆 NOTIFICATION TAPPED - notificationId: $notificationId');
    debugPrint('👆 STOPPING SOUND IMMEDIATELY...');
    
    // Stop sound - background timer will detect cancellation and stop itself
    LocalNotificationService.cancelRepeating();
    
    if (notificationId != null && _globalNotificationTapCallback != null) {
      debugPrint('👆 CALLING TAP CALLBACK: $notificationId');
      _globalNotificationTapCallback!(notificationId);
    } else {
      debugPrint('❌ NO CALLBACK OR notificationId IS NULL - storing for later');
      // Store for when callback is registered
      if (notificationId != null) {
        _pendingNotificationId = notificationId;
      }
    }
  } catch (e) {
    debugPrint('❌ Error parsing notification tap payload: $e');
  }
}

// Background message handler - ต้องอยู่นอก class (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 BACKGROUND HANDLER TRIGGERED: ${message.messageId}');
  debugPrint('🔔 Title: ${message.notification?.title}');
  debugPrint('🔔 Body: ${message.notification?.body}');
  debugPrint('🔔 Data: ${message.data}');
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔔 Firebase initialized in background handler');

  // Initialize local notifications in background-safe mode (no permission request)
  await LocalNotificationService.initializeForBackground();
  debugPrint('🔔 Local notifications initialized in background handler');

  // ALWAYS show local notification - this handles ALL messages now
  await LocalNotificationService.showNotification(message);
  debugPrint('🔔 Local notification shown via background handler');

  debugPrint('🔔 Background handler completed: ${message.messageId ?? 'unknown'}');
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;
  bool _isInitialized = false;
  static bool _isGloballyInitialized = false;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('🔄 FirebaseMessagingService already initialized, skipping...');
      return;
    }
    _isInitialized = true;
    
    // CRITICAL: Clean up any orphaned sound sessions from previous terminated state
    await _cleanupOrphanedSoundSessions();
    
    if (_isGloballyInitialized) {
      debugPrint('🔄 FirebaseMessagingService globally initialized, skipping lifecycle observer...');
    } else {
      _isGloballyInitialized = true;
      debugPrint('🔄 First time initialization - adding lifecycle observer...');
      // Track app lifecycle changes
      WidgetsBinding.instance.addObserver(AppLifecycleObserver());
    }
    
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

      // DISABLED: Foreground message handler - user wants background-only notifications
      // FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      debugPrint('🔕 Foreground notifications disabled - background only mode');

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

  /// Get FCM Token with retry logic for transient errors
  Future<void> _getFcmToken({int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        _fcmToken = await _firebaseMessaging.getToken();
        if (_fcmToken != null) {
          AppLogger.log('📱 FCM Token: $_fcmToken');
          return;
        }
        // Token is null, retry
        attempts++;
        if (attempts < maxRetries) {
          final delay = Duration(seconds: attempts * 2); // Exponential backoff
          AppLogger.log('⏳ FCM token null, retrying in ${delay.inSeconds}s (attempt $attempts/$maxRetries)...');
          await Future.delayed(delay);
        }
      } catch (e) {
        attempts++;
        final isServiceNotAvailable = e.toString().contains('SERVICE_NOT_AVAILABLE');
        if (isServiceNotAvailable && attempts < maxRetries) {
          final delay = Duration(seconds: attempts * 3); // Longer backoff for service issues
          AppLogger.log('⏳ Google Play Services unavailable, retrying in ${delay.inSeconds}s (attempt $attempts/$maxRetries)...');
          await Future.delayed(delay);
        } else {
          // Log error only on final attempt or non-retryable error
          if (attempts >= maxRetries) {
            AppLogger.log('❌ Error getting FCM token after $maxRetries attempts: $e');
          }
          return;
        }
      }
    }
  }

  /// Get current FCM token (called by FcmRegistrationService to send to backend)
  Future<String?> getToken() async {
    if (_fcmToken == null) {
      _fcmToken = await _firebaseMessaging.getToken();
    }
    return _fcmToken;
  }

  
  /// Handle foreground messages - DISABLED (background only mode)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 FOREGROUND HANDLER: ${message.messageId} (notification suppressed - background only mode)');
    debugPrint('📩 Data: ${message.data}');
    
    // Only update UI state via WebSocket, do NOT show system notification
    // when app is in foreground (user requested background-only notifications)
    debugPrint('📩 Notification data received but not displayed (app is foreground)');
  }

  /// Handle notification click (app background → foreground, or terminated → open)
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('👆 ===== APP OPENED FROM NOTIFICATION =====');
    debugPrint('👆 Message data: ${message.data}');
    final notificationId = message.data['notificationId'] as String?;
    
    // CRITICAL: Stop sound immediately regardless of app state
    if (notificationId != null) {
      debugPrint('👆 TERMINATED STATE: STOPPING SOUND IMMEDIATELY...');
      LocalNotificationService.cancelRepeating();
      
      // Store for immediate processing when app initializes
      _pendingNotificationId = notificationId;
      
      debugPrint('👆 STORED PENDING NOTIFICATION: $notificationId');
    }
    debugPrint('👆 ===== NOTIFICATION OPEN HANDLING COMPLETE =====');
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

  /// CRITICAL: Clean up any orphaned sound sessions from previous terminated state
  Future<void> _cleanupOrphanedSoundSessions() async {
    debugPrint('🧹 ===== CLEANING UP ORPHANED SOUND SESSIONS =====');
    
    try {
      // AGGRESSIVE: Cancel timer multiple times to ensure it stops
      if (LocalNotificationService._repeatTimer != null) {
        LocalNotificationService._repeatTimer!.cancel();
        LocalNotificationService._repeatTimer = null;
        debugPrint('🧹 Cancelled foreground timer');
      }
      
      // Force cancel any repeating notifications that might be stuck
      await LocalNotificationService.cancelRepeating();
      await Future.delayed(const Duration(milliseconds: 100));
      await LocalNotificationService.cancelRepeating();
      debugPrint('🧹 Cancelled repeating notifications (x2)');
      
      // Cancel all local notifications - multiple times for safety
      await LocalNotificationService.cancelAll();
      await Future.delayed(const Duration(milliseconds: 100));
      await LocalNotificationService.cancelAll();
      debugPrint('🧹 Cancelled all local notifications (x2)');
      
      // Reset session tokens to invalidate any stuck timers
      LocalNotificationService._sessionToken = 999999;
      debugPrint('🧹 Reset session token to invalidate timers');
      
      debugPrint('🧹 ===== ORPHANED SOUND SESSION CLEANUP COMPLETE =====');
    } catch (e) {
      debugPrint('❌ ERROR DURING CLEANUP: $e');
    }
  }
}

/// Observer to track app lifecycle changes - optimized for performance
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Simple log - no complex switch needed
    final isBackground = state != AppLifecycleState.resumed;
    debugPrint('� APP: $state | BACKGROUND: $isBackground');
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

  /// Show notification with LOOPING sound for background handler
  static Future<void> showNotificationBackground(RemoteMessage message) async {
    AppLogger.log('🔔 BACKGROUND NOTIFICATION: With repeating sound loop');
    
    if (!_initialized) {
      AppLogger.log('🔔 Initializing local notifications for background...');
      await initializeForBackground();
    }

    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'ແຈ້ງເຕືອນ';
    final body = notification?.body ?? data['body'] ?? 'ມີການແຈ້ງເຕືອນໃໝ່';

    debugPrint('🔔 Notification title: $title');
    debugPrint('🔔 Notification body: $body');

    // For background: use notification channel sound with repeating timer
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
      // Use fullScreenIntent to ensure sound plays
      fullScreenIntent: true,
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

    // Cancel any existing notifications and timers first
    _repeatTimer?.cancel();
    _repeatTimer = null;
    await _notificationsPlugin.cancelAll();

    // Reset session token for new notification
    _sessionToken++;
    final myToken = _sessionToken;
    AppLogger.log('🔔 Background session token: $myToken');

    // A/B alternating IDs for repeating notifications
    final baseId = message.hashCode.abs() % 100000;
    final idA = baseId;
    final idB = baseId + 100000;
    int localToggle = 0;
    int consecutiveFailures = 0;

    Future<bool> showOnce() async {
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
        AppLogger.log('🔔 Background notification shown (id: $currentId)');
        consecutiveFailures = 0; // Reset on success
        return true;
      } catch (e) {
        AppLogger.log('🔔 ERROR showing background notification: $e');
        consecutiveFailures++;
        return false;
      }
    }

    // Show immediately
    await showOnce();

    // CRITICAL: Reset stop signal to 0 before starting new timer
    // This ensures old stop signals don't immediately kill the new timer
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefStopSignalKey, 0);
    
    // Repeat every 10 seconds (loop once, wait 10s, loop again)
    int iterationCount = 0;
    const maxIterations = 18; // 3 minutes max (18 * 10 seconds)
    
    _repeatTimer = Timer.periodic(const Duration(seconds: 10), (t) async {
      iterationCount++;
      
      // Stop after max iterations (safety limit)
      if (iterationCount > maxIterations) {
        AppLogger.log('🔔 Background timer stopped - reached max iterations');
        t.cancel();
        return;
      }
      
      // CRITICAL: Check stop signal from SharedPreferences (cross-isolate communication)
      // If activeStopSignal != 0, it means main isolate sent a stop command
      final currentPrefs = await SharedPreferences.getInstance();
      final activeStopSignal = currentPrefs.getInt(_prefStopSignalKey) ?? 0;
      if (activeStopSignal != 0 || _sessionToken != myToken) {
        AppLogger.log('🛑 Background timer stopped - stop signal detected ($activeStopSignal)');
        t.cancel();
        _repeatTimer = null;
        await _notificationsPlugin.cancelAll();
        return;
      }
      
      // Check if session token changed (cancelled from same isolate)
      if (_sessionToken != myToken) {
        AppLogger.log('🔔 Background timer stopped - session token changed');
        t.cancel();
        return;
      }
      
      // Check if app is in foreground - stop timer if so
      try {
        final currentState = WidgetsBinding.instance.lifecycleState;
        if (currentState == AppLifecycleState.resumed) {
          AppLogger.log('🔔 Background timer stopped - app in foreground');
          t.cancel();
          return;
        }
      } catch (e) {
        // WidgetsBinding may not be available in background isolate
      }
      
      // Show notification (sound plays via notification channel)
      final success = await showOnce();
      
      // Stop timer on first failure (notification was cancelled by user)
      if (!success && consecutiveFailures >= 1) {
        AppLogger.log('🔔 Background timer stopped - notification cancelled by user');
        t.cancel();
        return;
      }
    });

    AppLogger.log('🔁 Background repeating timer started (session: $myToken, A/B: $idA/$idB, max: $maxIterations iterations)');
  }

  /// Show notification - BACKGROUND ONLY MODE
  /// When app is in foreground: NO system notification (WebSocket handles UI)
  /// When app is in background/terminated: Show notification with looping sound
  static Future<void> showNotification(RemoteMessage message) async {
    // Immediate background detection - no delays
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    final isBackground = lifecycleState != AppLifecycleState.resumed;
    
    AppLogger.log('🔔 NOTIFICATION: $lifecycleState | BACKGROUND: $isBackground');
    
    // BACKGROUND ONLY: Only show notification when app is not in foreground
    if (isBackground) {
      AppLogger.log('🔔 Using background notification mode with looping sound');
      await showNotificationBackground(message);
      return;
    }
    
    // FOREGROUND: Do NOT show system notification - WebSocket handles UI updates
    AppLogger.log('🔔 FOREGROUND: Skipping system notification (WebSocket handles UI)');
    // Data is still logged but no toast/sound shown
    final data = message.data;
    AppLogger.log('🔔 FCM Data received in foreground: ${data['notificationId']}');
  }

  /// SharedPreferences key for cross-isolate stop signal
  static const String _prefStopSignalKey = 'notification_stop_signal_token';
  
  /// Send stop signal to all isolates via SharedPreferences
  static Future<void> _sendStopSignal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final signal = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_prefStopSignalKey, signal);
      debugPrint('📝 [NotificationService] Sent stop signal: $signal');
    } catch (e) {
      debugPrint('❌ [NotificationService] Failed to send stop signal: $e');
    }
  }
  
  /// Clear stop signal (call on app start)
  static Future<void> clearStopSignal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefStopSignalKey);
      debugPrint('📝 [NotificationService] Cleared stop signal');
    } catch (e) {
      debugPrint('❌ [NotificationService] Failed to clear stop signal: $e');
    }
  }

  /// Cancel repeating notification — call this when user reads the notification
  static Future<void> cancelRepeating() async {
    debugPrint('🔇 ===== CANCEL REPEATING STARTED =====');
    
    // Send stop signal to all isolates FIRST
    await _sendStopSignal();
    
    // Increment session token to invalidate timers in THIS isolate
    _sessionToken++;
    debugPrint('🔇 Session token incremented to: $_sessionToken');
    
    // Cancel timer in this isolate
    if (_repeatTimer != null) {
      _repeatTimer!.cancel();
      _repeatTimer = null;
      debugPrint('🔇 Timer cancelled in this isolate');
    }
    
    // Cancel all notifications
    await _notificationsPlugin.cancelAll();
    debugPrint('🔇 All notifications cancelled');
    
    // Brief delay then cancel once more
    await Future.delayed(const Duration(milliseconds: 100));
    await _notificationsPlugin.cancelAll();
    debugPrint('🔇 Cancellation confirmed');
    
    debugPrint('🔇 ===== CANCEL REPEATING COMPLETED =====');
  }


  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Cancel specific notification
  static Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Show notification from WebSocket data (simpler version without RemoteMessage)
  static Future<void> showNotificationFromData({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    if (!_initialized) {
      await initializeForBackground();
    }

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

    // Cancel any running timer and notifications
    _repeatTimer?.cancel();
    _repeatTimer = null;
    await _notificationsPlugin.cancelAll();

    // Create session token
    _sessionToken++;
    final myToken = _sessionToken;

    // A/B alternating IDs
    final baseId = title.hashCode.abs() % 100000;
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
          payload: jsonEncode(payload),
        );
        AppLogger.log('🔔 WebSocket notification shown (id: $currentId)');
      } catch (e) {
        AppLogger.log('🔔 ERROR showing WebSocket notification: $e');
      }
    }

    // Show immediately
    await showOnce();

    // Repeat every 5 seconds
    _repeatTimer = Timer.periodic(const Duration(seconds: 5), (t) async {
      if (_sessionToken != myToken) {
        t.cancel();
        return;
      }
      await showOnce();
    });

    debugPrint('🔁 Started WebSocket notification timer (session: $myToken)');
  }
}
