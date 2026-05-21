import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import 'device_id_service.dart';
import 'local_notification_service.dart';
import 'native_intent_service.dart';
import 'storage_service.dart';

/// Enum to track where a notification originated from — useful for debugging.
enum NotificationSource {
  fcmForeground,
  fcmBackground,
  terminatedLaunch,
  websocket,
  apiSync,
}

/// Top-level background message handler.
/// MUST be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📨 [BG HANDLER] Received background FCM: ${message.data}');

  // Initialize local notifications for background display
  await LocalNotificationService.initialize();

  final data = message.data;
  final notificationId = data['notificationId'] ?? '';
  final title = data['title'] ?? 'ແຈ້ງເຕືອນ';
  final body = data['body'] ?? '';

  if (notificationId.isEmpty) {
    debugPrint('⚠️ [BG HANDLER] No notificationId in data, skipping');
    return;
  }

  // Store the notification ID for deduplication when app resumes
  final prefs = await SharedPreferences.getInstance();
  final processed = prefs.getStringList('bg_processed_ids') ?? [];
  if (processed.contains(notificationId)) {
    debugPrint('⚠️ [BG HANDLER] Already processed: $notificationId');
    return;
  }
  processed.add(notificationId);
  // Keep only last 50 to prevent unbounded growth
  if (processed.length > 50) {
    processed.removeRange(0, processed.length - 50);
  }
  await prefs.setStringList('bg_processed_ids', processed);

  // Show notification with looping sound
  await LocalNotificationService.showWithLoopingSound(
    notificationId: notificationId,
    title: title,
    body: body,
  );
}

/// Manages Firebase Cloud Messaging lifecycle.
///
/// Responsibilities:
/// - Request notification permission (Android 13+)
/// - Get/refresh FCM token and register with backend
/// - Handle foreground, background, and terminated notifications
/// - Deduplication and race-condition protection
/// - Sound loop management
class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _isInitialized = false;
  static bool _isProcessing = false;

  // Deduplication: track processed notification IDs
  static final Set<String> _processedIds = {};

  // Pending notification from terminated state
  static String? _pendingNotificationId;
  static bool _isFromTerminatedNotification = false;

  // Stream for notifying providers about new notifications
  static final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get onNotification =>
      _notificationController.stream;

  // Stream for notification-read events triggered by tap
  static final StreamController<String> _readController =
      StreamController<String>.broadcast();
  static Stream<String> get onMarkAsRead => _readController.stream;

  /// Initialize FCM — call after Firebase.initializeApp()
  static Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🔥 FirebaseMessagingService: Initializing...');

    // Request permission (Android 13+ requires runtime permission)
    await _requestPermission();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was launched from a terminated-state notification
    await _checkTerminatedLaunch();

    // Cleanup any orphaned sound sessions from previous runs
    await LocalNotificationService.cleanupOrphanedSessions();

    // Listen for local notification taps
    LocalNotificationService.onTap.listen(_handleNotificationTap);

    // Load previously processed IDs from background handler
    await _loadBackgroundProcessedIds();

    _isInitialized = true;
    debugPrint('✅ FirebaseMessagingService: Initialized');
  }

  /// Request notification permission (Android 13+)
  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
        '🔔 FCM Permission: ${settings.authorizationStatus}');
  }

  /// Get current FCM token
  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('🔑 FCM Token: ${token?.substring(0, 20)}...');
      return token;
    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
      return null;
    }
  }

  /// Register FCM token with backend after login.
  /// Also sets up token refresh listener.
  static Future<void> registerToken(String username) async {
    try {
      final fcmToken = await getToken();
      final deviceId = await DeviceIdService.getDeviceId();

      if (fcmToken == null) {
        debugPrint('⚠️ Cannot register: FCM token is null');
        return;
      }

      await _sendTokenToBackend(username, deviceId, fcmToken);

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM token refreshed, updating backend...');
        _sendTokenToBackend(username, deviceId, newToken);
      });

      debugPrint('✅ FCM token registered for $username on device $deviceId');
    } catch (e) {
      debugPrint('❌ Failed to register FCM token: $e');
    }
  }

  /// Deactivate FCM token on logout
  static Future<void> deactivateToken(String username) async {
    try {
      final deviceId = await DeviceIdService.getDeviceId();
      final storage = StorageService();
      final token = await storage.getToken();

      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:4000/api/v1';
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      ));

      await dio.patch(
        '/notifications/fcm-token/deactivate',
        data: {
          'username': username,
          'deviceId': deviceId,
        },
      );

      debugPrint('✅ FCM token deactivated for $username on device $deviceId');
    } catch (e) {
      debugPrint('❌ Failed to deactivate FCM token: $e');
    }
  }

  /// Handle foreground FCM message
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📨 [FOREGROUND] FCM message received: ${message.data}');

    final data = message.data;
    final notificationId = data['notificationId'] ?? '';
    final title = data['title'] ?? 'ແຈ້ງເຕືອນ';
    final body = data['body'] ?? '';

    if (notificationId.isEmpty) return;

    // Deduplication check
    if (_processedIds.contains(notificationId)) {
      debugPrint('⚠️ [FOREGROUND] Already processed: $notificationId, skipping');
      return;
    }

    // Race-condition lock
    if (_isProcessing) {
      debugPrint('⚠️ [FOREGROUND] Already processing another notification, queuing');
      // Simple queue: just wait a bit
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _isProcessing = true;
    try {
      _processedIds.add(notificationId);
      _trimProcessedIds();

      // Show local notification with looping sound
      await LocalNotificationService.showWithLoopingSound(
        notificationId: notificationId,
        title: title,
        body: body,
      );

      // Notify providers about new notification
      _notificationController.add({
        'source': NotificationSource.fcmForeground.name,
        'notificationId': notificationId,
        'title': title,
        'body': body,
        'data': data,
      });

      debugPrint('✅ [FOREGROUND] Notification displayed: $notificationId');
    } finally {
      _isProcessing = false;
    }
  }

  /// Handle notification tap when app was in background
  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('👆 ===== APP OPENED FROM NOTIFICATION (BACKGROUND) =====');

    final data = message.data;
    final notificationId = data['notificationId'] ?? '';

    if (notificationId.isNotEmpty) {
      // CRITICAL: Stop sound immediately
      LocalNotificationService.cancelRepeating();
      _readController.add(notificationId);
      debugPrint('✅ Marked for read: $notificationId');
    }
  }

  /// Check if app was launched from terminated state via notification tap
  static Future<void> _checkTerminatedLaunch() async {
    debugPrint('🔍 ===== CHECKING FOR TERMINATED STATE NOTIFICATION =====');

    // Method 1: Check FirebaseMessaging getInitialMessage
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final notificationId = initialMessage.data['notificationId'] ?? '';
      if (notificationId.isNotEmpty) {
        debugPrint(
            '📨 FOUND TERMINATED STATE NOTIFICATION (FCM): $notificationId');
        _pendingNotificationId = notificationId;
        _isFromTerminatedNotification = true;
        // Stop sound immediately
        await LocalNotificationService.cancelRepeating();
        _readController.add(notificationId);
        return;
      }
    }

    // Method 2: Check native intent (Android)
    final nativeId = await NativeIntentService.getPendingNotificationId();
    if (nativeId != null && nativeId.isNotEmpty) {
      debugPrint(
          '📨 FOUND TERMINATED STATE NOTIFICATION (Native): $nativeId');
      _pendingNotificationId = nativeId;
      _isFromTerminatedNotification = true;
      await LocalNotificationService.cancelRepeating();
      _readController.add(nativeId);
    }
  }

  /// Handle local notification tap
  static void _handleNotificationTap(String payload) {
    debugPrint('👆 Notification tapped, payload: $payload');
    if (payload.isNotEmpty) {
      // Stop looping sound
      LocalNotificationService.cancelRepeating();
      // Emit mark-as-read event
      _readController.add(payload);
    }
  }

  /// Load IDs that were processed by the background handler
  static Future<void> _loadBackgroundProcessedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bgIds = prefs.getStringList('bg_processed_ids') ?? [];
      _processedIds.addAll(bgIds);
      debugPrint('📋 Loaded ${bgIds.length} background-processed IDs');
    } catch (e) {
      debugPrint('⚠️ Failed to load background processed IDs: $e');
    }
  }

  /// Keep processed IDs set bounded
  static void _trimProcessedIds() {
    if (_processedIds.length > 100) {
      final list = _processedIds.toList();
      _processedIds.clear();
      _processedIds.addAll(list.sublist(list.length - 50));
    }
  }

  /// Send FCM token to backend
  static Future<void> _sendTokenToBackend(
    String username,
    String deviceId,
    String fcmToken,
  ) async {
    try {
      final storage = StorageService();
      final authToken = await storage.getToken();

      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'http://localhost:4000/api/v1';
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers:
            authToken != null ? {'Authorization': 'Bearer $authToken'} : null,
      ));

      await dio.patch(
        ApiConstants.updateFcmToken,
        data: {
          'username': username,
          'deviceId': deviceId,
          'fcmToken': fcmToken,
        },
      );

      debugPrint('✅ FCM token sent to backend');
    } catch (e) {
      debugPrint('❌ Failed to send FCM token to backend: $e');
    }
  }

  /// Whether the app was launched from a terminated notification
  static bool get isFromTerminatedNotification => _isFromTerminatedNotification;

  /// Get and clear the pending notification ID
  static String? consumePendingNotificationId() {
    final id = _pendingNotificationId;
    _pendingNotificationId = null;
    _isFromTerminatedNotification = false;
    return id;
  }

  /// Check if a notification was already processed (for deduplication)
  static bool isAlreadyProcessed(String notificationId) {
    return _processedIds.contains(notificationId);
  }

  /// Mark a notification ID as processed (called by WebSocket handler)
  static void markAsProcessed(String notificationId) {
    _processedIds.add(notificationId);
    _trimProcessedIds();
  }
}
