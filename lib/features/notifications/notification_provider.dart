import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/native_intent_service.dart';
import '../../core/providers/core_providers.dart';
import 'notification_model.dart';
import 'notification_repository.dart';
import 'notification_service.dart';
import 'notification_sound_service.dart';
import '../../core/services/firebase_messaging_service.dart';

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

// Sound Service Provider
final soundServiceProvider = Provider<NotificationSoundService>((ref) {
  return NotificationSoundService();
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
    soundService: ref.watch(soundServiceProvider),
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
  final NotificationSoundService _soundService;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _connectionSubscription;
  Timer? _pollingTimer;
  Timer? _retryTimer;
  String? _username;
  bool _isInitializing = false;
  bool _isDisposed = false;

  NotificationsNotifier({
    required NotificationRepository repository,
    required NotificationWebSocketService webSocketService,
    NotificationSoundService? soundService,
  })  : _repository = repository,
        _webSocketService = webSocketService,
        _soundService = soundService ?? NotificationSoundService(),
        super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Prevent concurrent initialization
    if (_isInitializing) {
      debugPrint('🔄 NotificationProvider: Initialization already in progress, skipping...');
      return;
    }
    
    // Cancel any pending retry timer
    _retryTimer?.cancel();
    _retryTimer = null;
    
    _isInitializing = true;
    
    try {
      // Check if disposed before proceeding
      if (_isDisposed) return;
      
      final userData = await StorageService().getUser();
      _username = userData?['username'] as String?;
      
      debugPrint('🔔 NotificationProvider: userData = $userData');
      debugPrint('🔔 NotificationProvider: _username = $_username');
      
      if (_username == null) {
        // ยังไม่ login - แสดง state ว่าง ไม่ใช่ error
        debugPrint('❌ NotificationProvider: username is null, user not logged in');
        if (!_isDisposed) {
          state = const AsyncValue.data(NotificationState(
            notifications: [],
            unreadCount: 0,
            isLoading: false,
          ));
        }
        
        // Retry after 3 seconds (slower to reduce memory churn)
        _retryTimer = Timer(const Duration(seconds: 3), () {
          if (!_isDisposed && !_isInitializing) {
            debugPrint('🔄 NotificationProvider: Retrying to get user data...');
            _initialize();
          }
        });
        return;
      }

      debugPrint('✅ NotificationProvider: username = $_username, loading notifications');
      
      // CRITICAL: Clear any old stop signals and lingering notifications on fresh start
      await LocalNotificationService.clearStopSignal();
      await LocalNotificationService.cancelAll();
      
      // CRITICAL: Check for terminated state notification before loading notifications
      await _checkForTerminatedStateNotification();
      
      if (_isDisposed) return;
      
      // Load initial notifications
      await loadNotifications();

      if (_isDisposed) return;
      
      // Register tap callback: tapping the toast notification marks it as read
      setNotificationTapCallback((notificationId) async {
        debugPrint('👆 Toast tapped: $notificationId — marking as read');
        await markAsRead(notificationId);
      });

      // Connect WebSocket (cancels existing first)
      _connectWebSocket();

      // Start polling as fallback (cancels existing first)
      _startPolling();
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
    // Cancel existing subscriptions before creating new ones
    _notificationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _notificationSubscription = null;
    _connectionSubscription = null;
    
    _webSocketService.connect();

    // Listen to notifications
    _notificationSubscription = _webSocketService.notificationStream.listen((event) async {
      if (_isDisposed) return;
      if (event['type'] == 'new_notification') {
        await _handleNewNotification(event['data']);
      } else if (event['type'] == 'notification_read') {
        await _handleNotificationRead(event['data']);
      } else if (event['type'] == 'all_notifications_read') {
        await _handleAllNotificationsRead(event['data']);
      }
    });

    // Listen to connection status
    _connectionSubscription = _webSocketService.connectionStream.listen((isConnected) {
      if (_isDisposed) return;
      final currentState = state.value ?? const NotificationState();
      state = AsyncValue.data(currentState.copyWith(isWebSocketConnected: isConnected));
    });
  }

  Future<void> _handleNewNotification(Map<String, dynamic> data) async {
    try {
      if (_isDisposed) return;
      
      debugPrint('🔔 Handling new notification: $data');
      
      final notification = MeetingNotification(
        id: data['id'] ?? '',
        notificationId: data['notificationId'] ?? '',
        message: data['message'] ?? '',
        meetingDate: data['meetingDate'] ?? '',
        vbCode: data['vbCode'] ?? '',
        isRead: false,
        createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      );

      final currentState = state.value ?? const NotificationState();
      
      // Check if notification already exists to avoid duplicates
      if (currentState.notifications.any((n) => n.id == notification.id)) {
        debugPrint('🔔 Notification already exists, skipping');
        return;
      }
      
      // Limit notifications list size to prevent memory bloat
      final maxNotifications = 100;
      final updatedNotifications = [notification, ...currentState.notifications];
      final trimmedNotifications = updatedNotifications.length > maxNotifications 
          ? updatedNotifications.sublist(0, maxNotifications) 
          : updatedNotifications;
      final newUnreadCount = currentState.unreadCount + 1;
      
      // Immediate state update for count
      state = AsyncValue.data(currentState.copyWith(
        notifications: trimmedNotifications,
        unreadCount: newUnreadCount,
      ));

      debugPrint('🔔 Added new notification, unread count: $newUnreadCount');

      // 🔊 Show toast notification ONLY when app is in foreground
      // Background notifications are handled by FCM background handler (single source of truth)
      final isForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
      if (isForeground) {
        await LocalNotificationService.showNotificationFromData(
          title: 'ແຈ້ງເຕືອນການປະຊຸມ',
          body: notification.message,
          payload: {
            'notificationId': notification.notificationId,
            'id': notification.id,
            'message': notification.message,
          },
        );
      } else {
        debugPrint('🔔 App in background - skipping WebSocket toast (FCM handles it)');
      }
      
      _soundService.playNotificationSound(notification.id);
    } catch (e) {
      debugPrint('Error handling new notification: $e');
    }
  }

  Future<void> _handleNotificationRead(Map<String, dynamic> data) async {
    // FIX: Extract notificationId from both root level and nested data structure
    // WebSocket sends: { type: 'notification_read', data: { notificationId: '...' } }
    final rawData = data['data'] as Map<String, dynamic>?;
    final notificationId = data['notificationId'] as String? ?? 
                         rawData?['notificationId'] as String? ??
                         rawData?['id']?.toString();
    if (notificationId == null) {
      debugPrint('❌ _handleNotificationRead: notificationId is null, data: $data');
      return;
    }

    debugPrint('� ===== NOTIFICATION READ FROM WEB SOCKET =====');
    debugPrint('🔔 Notification ID: $notificationId');
    
    // 🔇 STOP SOUND IMMEDIATELY ON THIS DEVICE
    debugPrint('🔇 STOPPING SOUND ON THIS DEVICE...');
    await LocalNotificationService.cancelRepeating();
    await _soundService.stopNotificationSound();
    debugPrint('🔇 SOUND STOPPED ON THIS DEVICE');

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        state = AsyncValue.data(state.value!);
      }
    });
  }

  Future<void> _handleAllNotificationsRead(Map<String, dynamic> data) async {
    debugPrint('🔔 ===== ALL NOTIFICATIONS READ FROM WEB SOCKET =====');
    
    // 🔇 STOP SOUND IMMEDIATELY ON THIS DEVICE
    debugPrint('🔇 STOPPING ALL SOUNDS ON THIS DEVICE...');
    await LocalNotificationService.cancelRepeating();
    await LocalNotificationService.cancelAll();
    await _soundService.stopNotificationSound();
    debugPrint('🔇 ALL SOUNDS STOPPED ON THIS DEVICE');

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
    // Cancel existing timer before creating new one
    _pollingTimer?.cancel();
    _pollingTimer = null;
    
    // Polling ทุก 60 วินาทีเป็น fallback (reduced from 30s to save battery)
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
    debugPrint('🔇 MARK AS READ STARTED: $notificationId');
    
    // Always stop sound/timer regardless of username state
    debugPrint('🔇 STOPPING SOUND AND TIMER...');
    await LocalNotificationService.cancelRepeating();
    await LocalNotificationService.cancelAll();
    await _soundService.stopNotificationSound();
    debugPrint('🔇 SOUND AND TIMER STOPPED');

    if (_username == null) {
      debugPrint('❌ CANNOT MARK AS READ - USERNAME IS NULL');
      return;
    }

    try {
      debugPrint('🔇 UPDATING WEBSOCKET...');
      // Update WebSocket
      _webSocketService.markAsRead(notificationId);

      debugPrint('🔇 UPDATING API...');
      // Update API
      await _repository.markAsRead(notificationId, _username!);

      debugPrint('🔇 UPDATING LOCAL STATE...');
      // Update local state
      await _handleNotificationRead({'notificationId': notificationId});

      debugPrint('✅ MARK AS READ COMPLETED: $notificationId');
    } catch (e) {
      debugPrint('❌ ERROR MARKING NOTIFICATION AS READ: $e');
    }
  }

  /// CRITICAL: Check for terminated state notification from native Android intent
  /// Also checks the global _pendingNotificationId from onNotificationTap callback
  Future<void> _checkForTerminatedStateNotification() async {
    debugPrint('🔍 ===== CHECKING FOR TERMINATED STATE NOTIFICATION =====');
    
    String? pendingId;
    
    try {
      // First check NativeIntentService
      pendingId = await NativeIntentService.getPendingNotificationId();
      
      if (pendingId != null) {
        debugPrint('📨 FOUND TERMINATED STATE NOTIFICATION (NativeIntentService): $pendingId');
      }
    } catch (e) {
      debugPrint('❌ ERROR CHECKING NativeIntentService: $e');
    }
    
    // If no pending ID from native, check global variable (set by onNotificationTap)
    if (pendingId == null) {
      pendingId = pendingNotificationId;
      if (pendingId != null) {
        debugPrint('📨 FOUND TERMINATED STATE NOTIFICATION (global): $pendingId');
        // Clear it so we don't process again
        clearPendingNotificationId();
      }
    }
    
    if (pendingId != null) {
      debugPrint('📨 MARKING AS READ IMMEDIATELY...');
      
      // Stop sound immediately
      await LocalNotificationService.cancelRepeating();
      await _soundService.stopNotificationSound();
      
      // Mark as read via API
      if (_username != null) {
        await markAsRead(pendingId);
      } else {
        debugPrint('⚠️ USERNAME NULL - CANNOT MARK AS READ');
      }
      
      debugPrint('✅ TERMINATED STATE NOTIFICATION PROCESSED');
    } else {
      debugPrint('📨 NO TERMINATED STATE NOTIFICATION FOUND');
    }
    
    debugPrint('🔍 ===== TERMINATED STATE CHECK COMPLETE =====');
  }

  Future<void> refresh() async {
    // Try to get username again in case it was null before
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
    // Stop ALL sounds and notifications
    debugPrint('🔇 MARK ALL AS READ: Stopping sounds...');
    await LocalNotificationService.cancelRepeating();
    await LocalNotificationService.cancelAll();
    await _soundService.stopNotificationSound();
    debugPrint('🔇 MARK ALL AS READ: Sounds stopped');

    if (_username == null) return;

    try {
      debugPrint('🔔 Marking all notifications as read for $_username');
      
      // Notify all other devices via WebSocket
      _webSocketService.markAllAsRead();

      // Update API
      final count = await _repository.markAllAsRead(_username!);
      
      // Update local state
      final currentState = state.value ?? const NotificationState();
      final updatedNotifications = currentState.notifications.map((n) => n.copyWith(isRead: true, readAt: DateTime.now())).toList();
      
      // 🚀 [UI REFRESH FIX]: Create new NotificationState object to force Riverpod rebuild
      state = AsyncValue.data(NotificationState(
        notifications: updatedNotifications,
        unreadCount: 0,
        isWebSocketConnected: currentState.isWebSocketConnected,
      ));

      debugPrint('🔇 Cancelled repeating notification - all read');
      
      debugPrint('✅ Marked $count notifications as read');
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }

  Future<void> loadNextPage() async {
    // Pagination functionality temporarily removed due to state structure changes
    // This can be re-implemented when pagination is added back to NotificationState
    debugPrint('📄 Next page functionality temporarily disabled');
  }

  Future<void> loadPreviousPage() async {
    // Pagination functionality temporarily removed due to state structure changes
    // This can be re-implemented when pagination is added back to NotificationState
    debugPrint('📄 Previous page functionality temporarily disabled');
  }

  /// Refresh after login - reinitialize with new username
  Future<void> refreshAfterLogin() async {
    if (_isDisposed) return;
    
    final userData = await StorageService().getUser();
    final newUsername = userData?['username'] as String?;
    
    if (newUsername == null) return;
    
    // Update username and reinitialize if changed
    if (newUsername != _username) {
      _username = newUsername;
      debugPrint('🔄 NotificationProvider: Username changed to $newUsername, reinitializing...');
      // Full reinitialization
      _isInitializing = false; // Reset flag to allow new init
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

  @override
  void dispose() {
    _isDisposed = true;
    _isInitializing = false;
    
    // Cancel all timers
    _retryTimer?.cancel();
    _retryTimer = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    
    // Cancel all subscriptions
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    
    // Stop and dispose sound service
    _soundService.stopNotificationSound();
    _soundService.dispose();
    
    // Disconnect WebSocket
    _webSocketService.disconnect();
    
    super.dispose();
  }

  /// หยุดเสียงแจ้งเตือนทั้งหมด (เรียกจากภายนอกเมื่อ user เข้าไปดู notifications)
  Future<void> stopAllSounds() async {
    await _soundService.stopNotificationSound();
  }

  /// ตรวจสอบว่ากำลังเล่นเสียงอยู่หรือไม่
  bool get isPlayingSound => _soundService.isPlaying;
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
