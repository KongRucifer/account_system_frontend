import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../app.dart';
import '../../core/services/audio_loop_service.dart';
import '../../core/services/firebase_messaging_service.dart';
import '../../core/services/local_notification_service.dart';
import '../../core/services/native_intent_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/providers/core_providers.dart';
import 'notification_model.dart';
import 'notification_repository.dart';
import 'notification_service.dart';

part 'notification_provider.freezed.dart';

// Repository Provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return NotificationRepository(dioClient.dio);
});

// WebSocket Service Provider
final webSocketServiceProvider = Provider<NotificationWebSocketService>((ref) {
  return NotificationWebSocketService();
});

// Current username provider
final currentUsernameProvider = FutureProvider<String?>((ref) async {
  final userData = await StorageService().getUser();
  return userData?['username'] as String?;
});

// Notifications Provider (StateNotifier)
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<NotificationState>>((ref) {
  return NotificationsNotifier(
    repository: ref.watch(notificationRepositoryProvider),
    webSocketService: ref.watch(webSocketServiceProvider),
  );
});

// Notification State
@freezed
class NotificationState with _$NotificationState {
  const factory NotificationState({
    @Default([]) List<MeetingNotification> notifications,
    @Default(0) int unreadCount,
    @Default(false) bool isLoading,
    @Default(false) bool isWebSocketConnected,
    String? error,
    PaginationInfo? pagination,
    @Default(1) int currentPage,
  }) = _NotificationState;
}

class NotificationsNotifier extends StateNotifier<AsyncValue<NotificationState>> {
  final NotificationRepository _repository;
  final NotificationWebSocketService _webSocketService;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _fcmNotificationSubscription;
  StreamSubscription? _fcmReadSubscription;
  Timer? _pollingTimer;
  Timer? _retryTimer;
  Timer? _heartbeatTimer;
  String? _username;
  bool _isInitializing = false;
  bool _isDisposed = false;

  // Deduplication: track processed notification IDs
  final Set<String> _processedIds = {};

  NotificationsNotifier({
    required NotificationRepository repository,
    required NotificationWebSocketService webSocketService,
  })  : _repository = repository,
        _webSocketService = webSocketService,
        super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitializing) {
      debugPrint('🔄 NotificationProvider: Initialization already in progress, skipping...');
      return;
    }
    
    _retryTimer?.cancel();
    _retryTimer = null;
    _isInitializing = true;
    
    try {
      if (_isDisposed) return;
      
      final userData = await StorageService().getUser();
      _username = userData?['username'] as String?;
      
      debugPrint('🔔 NotificationProvider: userData = $userData');
      debugPrint('🔔 NotificationProvider: _username = $_username');
      
      if (_username == null) {
        debugPrint('❌ NotificationProvider: username is null, user not logged in');
        if (!_isDisposed) {
          state = const AsyncValue.data(NotificationState(
            notifications: [],
            unreadCount: 0,
            isLoading: false,
          ));
        }
        
        _retryTimer = Timer(const Duration(seconds: 3), () {
          if (!_isDisposed && !_isInitializing) {
            debugPrint('🔄 NotificationProvider: Retrying to get user data...');
            _initialize();
          }
        });
        return;
      }

      debugPrint('✅ NotificationProvider: username = $_username, loading notifications');
      
      if (_isDisposed) return;

      // Check for terminated state notification FIRST
      await _checkForTerminatedStateNotification();

      if (_isDisposed) return;
      
      await loadNotifications();

      if (_isDisposed) return;
      
      _connectWebSocket();
      _startPolling();
      _startHeartbeat();
      _listenToFcmStreams();
    } catch (e, stack) {
      debugPrint('❌ NotificationProvider initialization error: $e');
      if (!_isDisposed) {
        state = AsyncValue.error(e, stack);
      }
    } finally {
      _isInitializing = false;
    }
  }

  void _connectWebSocket() {
    _notificationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _notificationSubscription = null;
    _connectionSubscription = null;
    
    _webSocketService.connect();

    _notificationSubscription = _webSocketService.notificationStream.listen((event) async {
      if (_isDisposed) return;
      if (event['type'] == 'new_notification') {
        await _handleNewNotification(event['data']);
      } else if (event['type'] == 'notification_read') {
        await _handleNotificationRead(event);
      } else if (event['type'] == 'all_notifications_read') {
        await _handleAllNotificationsRead(event['data']);
      }
    });

    _connectionSubscription = _webSocketService.connectionStream.listen((isConnected) {
      if (_isDisposed) return;
      final currentState = state.value ?? const NotificationState();
      state = AsyncValue.data(currentState.copyWith(isWebSocketConnected: isConnected));
    });
  }

  /// Check and process notifications from terminated state launch
  Future<void> _checkForTerminatedStateNotification() async {
    debugPrint('🔍 ===== CHECKING FOR TERMINATED STATE NOTIFICATION =====');

    // Check native intent first
    final pendingId = await NativeIntentService.getPendingNotificationId();
    if (pendingId != null && pendingId.isNotEmpty) {
      debugPrint('📨 FOUND TERMINATED STATE NOTIFICATION: $pendingId');
      await LocalNotificationService.cancelAll();
      if (_username != null) {
        await _markAsReadInternal(pendingId);
      }
      return;
    }

    // Check FCM service for pending
    final fcmPendingId = FirebaseMessagingService.consumePendingNotificationId();
    if (fcmPendingId != null && fcmPendingId.isNotEmpty) {
      debugPrint('📨 FOUND TERMINATED STATE NOTIFICATION (FCM): $fcmPendingId');
      await LocalNotificationService.cancelAll();
      if (_username != null) {
        await _markAsReadInternal(fcmPendingId);
      }
    }
  }

  /// Listen to FCM streams for foreground notifications and tap events
  void _listenToFcmStreams() {
    _fcmNotificationSubscription?.cancel();
    _fcmReadSubscription?.cancel();

    // When FCM delivers a new notification in foreground
    _fcmNotificationSubscription = FirebaseMessagingService.onNotification.listen((event) {
      if (_isDisposed) return;
      final notificationId = event['notificationId'] as String? ?? '';
      if (notificationId.isNotEmpty) {
        // Mark as processed for deduplication with WebSocket
        FirebaseMessagingService.markAsProcessed(notificationId);
        // Refresh from API to get accurate count (API = authoritative)
        loadNotifications();
      }
    });

    // When user taps a notification (foreground or background)
    _fcmReadSubscription = FirebaseMessagingService.onMarkAsRead.listen((notificationId) {
      if (_isDisposed) return;
      debugPrint('🔔 [FCM_READ_STREAM] Received tap event for: $notificationId');
      debugPrint('🔔 [FCM_READ_STREAM] _username = $_username, _isDisposed = $_isDisposed');
      markAsRead(notificationId);
    });
  }

  /// Heartbeat ping to detect dead WebSocket connections
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isDisposed) return;
      if (_webSocketService.isConnected) {
        _webSocketService.ping();
      }
    });
  }

  Future<void> _handleNewNotification(Map<String, dynamic> data) async {
    try {
      if (_isDisposed) return;
      
      debugPrint('🔔 Handling new notification (WS): $data');

      final id = data['id'] ?? '';

      // Deduplication: skip if already processed by FCM
      if (_processedIds.contains(id) || FirebaseMessagingService.isAlreadyProcessed(id)) {
        debugPrint('🔔 Notification already processed (dedup), skipping: $id');
        return;
      }
      _processedIds.add(id);
      _trimProcessedIds();
      
      final notification = MeetingNotification(
        id: id,
        notificationId: data['notificationId'] ?? '',
        message: data['message'] ?? '',
        meetingDate: data['meetingDate'] ?? '',
        vbCode: data['vbCode'] ?? '',
        isRead: false,
        createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      );

      final currentState = state.value ?? const NotificationState();
      
      if (currentState.notifications.any((n) => n.id == notification.id)) {
        debugPrint('🔔 Notification already in list, skipping');
        return;
      }
      
      final maxNotifications = 100;
      final updatedNotifications = [notification, ...currentState.notifications];
      final trimmedNotifications = updatedNotifications.length > maxNotifications 
          ? updatedNotifications.sublist(0, maxNotifications) 
          : updatedNotifications;
      final newUnreadCount = currentState.unreadCount + 1;
      
      state = AsyncValue.data(currentState.copyWith(
        notifications: trimmedNotifications,
        unreadCount: newUnreadCount,
      ));

      // Start looping sound (works in foreground AND background via native service)
      AudioLoopService.startLoop();

      // Show local notification toast only if in foreground
      if (AppLifecycleTracker.isInForeground) {
        debugPrint('🔔 App is FOREGROUND → showing notification');
        await LocalNotificationService.showSingleNotification(
          notificationId: id,
          title: 'ແຈ້ງເຕືອນການປະຊຸມ',
          body: notification.message,
        );
      } else {
        debugPrint('🔔 App is BACKGROUND → FCM handles notification toast');
      }

      debugPrint('🔔 Added new notification, unread count: $newUnreadCount');
    } catch (e) {
      debugPrint('Error handling new notification: $e');
    }
  }

  Future<void> _handleNotificationRead(Map<String, dynamic> data) async {
    final notificationId = data['notificationId'] as String? ?? 
                         data['data']?['notificationId'] as String? ??
                         data['data']?['id']?.toString();
    if (notificationId == null) {
      debugPrint('❌ _handleNotificationRead: notificationId is null, data: $data');
      return;
    }

    debugPrint('🔔 ===== NOTIFICATION READ FROM WEB SOCKET =====');
    debugPrint('🔔 Notification ID: $notificationId');

    // NOTE: Sound does NOT stop here. Sound stops only when user explicitly
    // taps notification toast or clicks "mark all read" button.

    final currentState = state.value ?? const NotificationState();
    final updatedNotifications = currentState.notifications.map((n) {
      return n.id == notificationId 
          ? n.copyWith(isRead: true, readAt: DateTime.now())
          : n;
    }).toList();

    final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

    debugPrint('🔔 Updated unread count: $newUnreadCount');
    debugPrint(' ===== NOTIFICATION READ COMPLETED =====');

    state = AsyncValue.data(NotificationState(
      notifications: updatedNotifications,
      unreadCount: newUnreadCount,
      isWebSocketConnected: currentState.isWebSocketConnected,
    ));
  }

  Future<void> _handleAllNotificationsRead(Map<String, dynamic> data) async {
    debugPrint('🔔 ===== ALL NOTIFICATIONS READ FROM WEB SOCKET =====');

    // CRITICAL: Stop looping sound when another device marks all as read
    await LocalNotificationService.cancelAll();

    final currentState = state.value ?? const NotificationState();
    final updatedNotifications = currentState.notifications.map((n) => 
      n.copyWith(isRead: true, readAt: DateTime.now())
    ).toList();

    debugPrint('🔔 Updated all notifications to read status');

    state = AsyncValue.data(NotificationState(
      notifications: updatedNotifications,
      unreadCount: 0,
      isWebSocketConnected: currentState.isWebSocketConnected,
    ));

    debugPrint(' ===== ALL NOTIFICATIONS READ COMPLETED =====');
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_isDisposed) return;
      if (!_webSocketService.isConnected && _username != null) {
        loadNotifications();
      }
    });
  }

  Future<void> loadNotifications({int page = 1}) async {
    if (_username == null) {
      debugPrint('❌ loadNotifications: username is null');
      return;
    }

    try {
      debugPrint('🔔 loadNotifications: loading for $_username, page $page');
      final currentState = state.value ?? const NotificationState();
      state = AsyncValue.data(currentState.copyWith(isLoading: true));

      final response = await _repository.getAllNotifications(_username!, page: page);
      
      debugPrint('🔔 loadNotifications: got ${response.notifications.length} notifications');
      debugPrint('🔔 loadNotifications: unread count: ${response.unreadCount}');

      state = AsyncValue.data(currentState.copyWith(
        notifications: response.notifications,
        unreadCount: response.unreadCount,
        pagination: response.pagination,
        currentPage: page,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('❌ loadNotifications error: $e');
      final currentState = state.value ?? const NotificationState();
      state = AsyncValue.data(currentState.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    debugPrint('🔔 MARK AS READ STARTED: $notificationId');

    // Stop looping sound and dismiss notifications
    await AudioLoopService.stopLoop();
    await LocalNotificationService.cancelAll();

    if (_username == null) {
      debugPrint('❌ CANNOT MARK AS READ - USERNAME IS NULL');
      return;
    }

    await _markAsReadInternal(notificationId);
  }

  /// Internal mark-as-read logic (reusable for terminated state + normal flow)
  Future<void> _markAsReadInternal(String notificationId) async {
    try {
      debugPrint('🔔 UPDATING WEBSOCKET...');
      _webSocketService.markAsRead(notificationId);

      debugPrint('🔔 UPDATING API...');
      await _repository.markAsRead(notificationId, _username!);

      debugPrint('🔔 UPDATING LOCAL STATE...');
      await _handleNotificationRead({'notificationId': notificationId});

      debugPrint('✅ MARK AS READ COMPLETED: $notificationId');
    } catch (e) {
      debugPrint('❌ ERROR MARKING NOTIFICATION AS READ: $e');
    }
  }

  Future<void> refresh() async {
    final userData = await StorageService().getUser();
    final newUsername = userData?['username'] as String?;
    
    if (newUsername != null && newUsername != _username) {
      debugPrint('🔄 NotificationProvider: Got new username $newUsername, updating...');
      _username = newUsername;
    }
    
    if (_username != null) {
      await loadNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    debugPrint('🔔 MARK ALL AS READ: Starting...');

    // Stop looping sound and dismiss all notifications
    await AudioLoopService.stopLoop();
    await LocalNotificationService.cancelAll();

    if (_username == null) return;

    try {
      debugPrint('🔔 Marking all notifications as read for $_username');
      
      _webSocketService.markAllAsRead();

      final count = await _repository.markAllAsRead(_username!);
      
      final currentState = state.value ?? const NotificationState();
      final updatedNotifications = currentState.notifications.map((n) => n.copyWith(isRead: true, readAt: DateTime.now())).toList();
      
      state = AsyncValue.data(NotificationState(
        notifications: updatedNotifications,
        unreadCount: 0,
        isWebSocketConnected: currentState.isWebSocketConnected,
      ));

      debugPrint('✅ Marked $count notifications as read');
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }

  Future<void> loadNextPage() async {
    debugPrint('📄 Next page functionality temporarily disabled');
  }

  Future<void> loadPreviousPage() async {
    debugPrint('📄 Previous page functionality temporarily disabled');
  }

  Future<void> refreshAfterLogin() async {
    if (_isDisposed) return;
    
    final userData = await StorageService().getUser();
    final newUsername = userData?['username'] as String?;
    
    if (newUsername == null) return;
    
    if (newUsername != _username) {
      _username = newUsername;
      debugPrint('🔄 NotificationProvider: Username changed to $newUsername, reinitializing...');
      _isInitializing = false;
      await _initialize();
    } else {
      debugPrint('🔄 NotificationProvider: Same username, just reloading notifications');
      await loadNotifications();
    }
  }

  void reconnectWebSocket() {
    _webSocketService.disconnect();
    _connectWebSocket();
  }

  /// Keep processed IDs set bounded
  void _trimProcessedIds() {
    if (_processedIds.length > 100) {
      final list = _processedIds.toList();
      _processedIds.clear();
      _processedIds.addAll(list.sublist(list.length - 50));
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isInitializing = false;
    
    _retryTimer?.cancel();
    _retryTimer = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _fcmNotificationSubscription?.cancel();
    _fcmNotificationSubscription = null;
    _fcmReadSubscription?.cancel();
    _fcmReadSubscription = null;
    
    _webSocketService.disconnect();
    
    super.dispose();
  }
}

// Provider สำหรับ unread count อย่างเดียว (ใช้สำหรับ badge)
final unreadCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.when(
    data: (state) => state.unreadCount,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
