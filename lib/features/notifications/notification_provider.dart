import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/services/storage_service.dart';
import 'notification_model.dart';
import 'notification_repository.dart';
import 'notification_service.dart';
import 'notification_sound_service.dart';

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

class NotificationState {
  final List<MeetingNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final bool isWebSocketConnected;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
    this.isWebSocketConnected = false,
  });

  NotificationState copyWith({
    List<MeetingNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool? isWebSocketConnected,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isWebSocketConnected: isWebSocketConnected ?? this.isWebSocketConnected,
    );
  }
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
      
      if (_username == null) {
        // ยังไม่ login - แสดง state ว่าง ไม่ใช่ error
        state = const AsyncValue.data(NotificationState(
          notifications: [],
          unreadCount: 0,
          isLoading: false,
        ));
        return;
      }

      // Load initial notifications
      await loadNotifications();

      // Connect WebSocket
      _connectWebSocket();

      // Start polling as fallback
      _startPolling();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _connectWebSocket() {
    _webSocketService.connect();

    // Listen to notifications
    _notificationSubscription = _webSocketService.notificationStream.listen((event) {
      if (event['type'] == 'new_notification') {
        _handleNewNotification(event['data']);
      } else if (event['type'] == 'notification_read') {
        _handleNotificationRead(event['data']);
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
      final notificationData = data['data'] as Map<String, dynamic>;
      final notification = MeetingNotification(
        id: notificationData['id'] ?? '',
        notificationId: notificationData['notificationId'] ?? '',
        message: notificationData['message'] ?? '',
        meetingDate: notificationData['meetingDate'] ?? '',
        vbCode: notificationData['vbCode'] ?? '',
        isRead: false,
        createdAt: DateTime.parse(notificationData['createdAt'] ?? DateTime.now().toIso8601String()),
      );

      final currentState = state.value ?? const NotificationState();
      final updatedNotifications = [notification, ...currentState.notifications];
      
      state = AsyncValue.data(currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount: currentState.unreadCount + 1,
      ));

      // 🔊 เล่นเสียงแจ้งเตือน
      _soundService.playNotificationSound(notification.id);
    } catch (e) {
      debugPrint('Error handling new notification: $e');
    }
  }

  void _handleNotificationRead(Map<String, dynamic> data) {
    final notificationId = data['notificationId'] as String?;
    if (notificationId == null) return;

    final currentState = state.value ?? const NotificationState();
    final updatedNotifications = currentState.notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true, readAt: DateTime.now());
      }
      return n;
    }).toList();

    final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = AsyncValue.data(currentState.copyWith(
      notifications: updatedNotifications,
      unreadCount: newUnreadCount,
    ));
  }

  void _startPolling() {
    // Polling ทุก 30 วินาทีเป็น fallback
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_webSocketService.isConnected && _username != null) {
        loadNotifications();
      }
    });
  }

  Future<void> loadNotifications() async {
    if (_username == null) return;

    try {
      final currentState = state.value ?? const NotificationState();
      state = AsyncValue.data(currentState.copyWith(isLoading: true));

      final response = await _repository.getAllNotifications(_username!);

      state = AsyncValue.data(currentState.copyWith(
        notifications: response.notifications,
        unreadCount: response.unreadCount,
        isLoading: false,
      ));
    } catch (e) {
      final currentState = state.value ?? const NotificationState();
      state = AsyncValue.data(currentState.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    if (_username == null) return;

    try {
      // Update WebSocket
      _webSocketService.markAsRead(notificationId);

      // Update API
      await _repository.markAsRead(notificationId, _username!);

      // Update local state
      _handleNotificationRead({'notificationId': notificationId});

      // 🔇 หยุดเสียงถ้ากำลังเล่นอยู่สำหรับ notification นี้
      if (_soundService.currentNotificationId == notificationId) {
        await _soundService.stopNotificationSound();
      }
      
      // 🔊 เล่นเสียงสำเร็จสั้นๆ
      await _soundService.playSuccessSound();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> refresh() async {
    await loadNotifications();
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
