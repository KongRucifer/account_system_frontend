import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/providers/core_providers.dart';
import 'notification_model.dart';
import 'notification_repository.dart';
import 'notification_service.dart';
import 'notification_sound_service.dart';
import '../../../../core/services/firebase_messaging_service.dart';

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
  String? _username;

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
    try {
      final userData = await StorageService().getUser();
      _username = userData?['username'] as String?;
      
      debugPrint('🔔 NotificationProvider: userData = $userData');
      debugPrint('🔔 NotificationProvider: _username = $_username');
      
      if (_username == null) {
        // ยังไม่ login - แสดง state ว่าง ไม่ใช่ error
        debugPrint('❌ NotificationProvider: username is null, user not logged in');
        state = const AsyncValue.data(NotificationState(
          notifications: [],
          unreadCount: 0,
          isLoading: false,
        ));
        
        // Retry after 1 second in case user just logged in (faster retry)
        Future.delayed(const Duration(seconds: 1), () {
          debugPrint('🔄 NotificationProvider: Retrying to get user data...');
          _initialize();
        });
        return;
      }

      debugPrint('✅ NotificationProvider: username = $_username, loading notifications');
      // Load initial notifications
      await loadNotifications();

      // Register tap callback: tapping the toast notification marks it as read
      setNotificationTapCallback((notificationId) async {
        debugPrint('👆 Toast tapped: $notificationId — marking as read');
        await markAsRead(notificationId);
      });

      // Connect WebSocket
      _connectWebSocket();

      // Start polling as fallback
      _startPolling();
    } catch (e, stack) {
      debugPrint('❌ NotificationProvider initialization error: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  void _connectWebSocket() {
    _webSocketService.connect();

    // Listen to notifications
    _notificationSubscription = _webSocketService.notificationStream.listen((event) async {
      if (event['type'] == 'new_notification') {
        _handleNewNotification(event['data']);
      } else if (event['type'] == 'notification_read') {
        await _handleNotificationRead(event['data']);
      } else if (event['type'] == 'all_notifications_read') {
        await _handleAllNotificationsRead(event['data']);
      }
    });

    // Listen to connection status
    _connectionSubscription = _webSocketService.connectionStream.listen((isConnected) {
      final currentState = state.value ?? const NotificationState();
      state = AsyncValue.data(currentState.copyWith(isWebSocketConnected: isConnected));
    });
  }

  void _handleNewNotification(Map<String, dynamic> data) {
    try {
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
      
      final updatedNotifications = [notification, ...currentState.notifications];
      final newUnreadCount = currentState.unreadCount + 1;
      
      // Immediate state update for count
      state = AsyncValue.data(currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      ));

      debugPrint('🔔 Added new notification, unread count: $newUnreadCount');

      // 🔊 Play loop sound for new notification
      _soundService.playNotificationSound(notification.id);
      
      // Force UI update by ensuring state is set immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Trigger a rebuild to ensure count updates immediately
          state = AsyncValue.data(state.value!);
        }
      });
    } catch (e) {
      debugPrint('Error handling new notification: $e');
    }
  }

  Future<void> _handleNotificationRead(Map<String, dynamic> data) async {
    final notificationId = data['notificationId'] as String?;
    if (notificationId == null) return;

    // 🔇 Stop sound/timer immediately on ALL devices (A, B, C all stop when any one reads)
    await LocalNotificationService.cancelRepeating();
    await _soundService.stopNotificationSound();

    final currentState = state.value ?? const NotificationState();
    final updatedNotifications = currentState.notifications.map((n) {
      return n.id == notificationId 
          ? n.copyWith(isRead: true, readAt: DateTime.now())
          : n;
    }).toList();

    final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

    debugPrint('🔔 Notification read: $notificationId, unread: $newUnreadCount');
    debugPrint('🔇 Sound stopped on all devices');

    state = AsyncValue.data(currentState.copyWith(
      notifications: updatedNotifications,
      unreadCount: newUnreadCount,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        state = AsyncValue.data(state.value!);
      }
    });
  }

  Future<void> _handleAllNotificationsRead(Map<String, dynamic> data) async {
    final currentState = state.value ?? const NotificationState();
    final updatedNotifications = currentState.notifications.map((n) => 
      n.copyWith(isRead: true, readAt: DateTime.now())
    ).toList();

    debugPrint('🔔 All notifications marked as read via WebSocket');

    state = AsyncValue.data(currentState.copyWith(
      notifications: updatedNotifications,
      unreadCount: 0,
    ));

    // 🔇 Stop all sounds on this device
    await LocalNotificationService.cancelRepeating();
    await _soundService.stopNotificationSound();
    debugPrint('🔇 Stopped notification sound - all notifications read via WebSocket');
  }

  void _startPolling() {
    // Polling ทุก 30 วินาทีเป็น fallback
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
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
    // Always stop sound/timer regardless of username state
    await LocalNotificationService.cancelRepeating();
    await _soundService.stopNotificationSound();

    if (_username == null) return;

    try {
      // Update WebSocket
      _webSocketService.markAsRead(notificationId);

      // Update API
      await _repository.markAsRead(notificationId, _username!);

      // Update local state
      await _handleNotificationRead({'notificationId': notificationId});

    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> refresh() async {
    // Try to get username again in case it was null before
    final userData = await StorageService().getUser();
    final newUsername = userData?['username'] as String?;
    
    if (newUsername != null && newUsername != _username) {
      debugPrint('🔄 NotificationProvider: Got new username $newUsername, updating...');
      _username = newUsername;
    }
    
    await loadNotifications();
  }

  Future<void> markAllAsRead() async {
    // Always stop sound/timer regardless of username state
    await LocalNotificationService.cancelRepeating();
    await _soundService.stopNotificationSound();

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
      
      state = AsyncValue.data(currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
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
    final userData = await StorageService().getUser();
    final newUsername = userData?['username'] as String?;
    
    if (newUsername == null) return;
    
    // Update username and reinitialize
    _username = newUsername;
    await loadNotifications();
    _connectWebSocket();
    _startPolling();
  }

  void reconnectWebSocket() {
    _webSocketService.disconnect();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _pollingTimer?.cancel();
    _soundService.stopNotificationSound(); // 🔇 หยุดเสียงเมื่อ dispose
    _soundService.dispose();
    _webSocketService.dispose();
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
