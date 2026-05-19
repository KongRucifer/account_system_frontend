import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/services/storage_service.dart';

class NotificationWebSocketService {
  static final NotificationWebSocketService _instance = NotificationWebSocketService._internal();
  factory NotificationWebSocketService() => _instance;
  NotificationWebSocketService._internal();

  IO.Socket? _socket;
  final StorageService _storageService = StorageService();
  
  // Stream controllers for events
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  void connect() async {
    if (_socket != null && _socket!.connected) {
      debugPrint('WebSocket already connected');
      return;
    }

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('No token available for WebSocket connection');
        return;
      }

      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:4000';
      // Keep HTTP URL for Socket.IO, it will handle WebSocket upgrade automatically
      debugPrint('Connecting to WebSocket: $baseUrl/notifications');

      _socket = IO.io(
        '$baseUrl/notifications',
        IO.OptionBuilder()
          .setTransports(['websocket', 'polling']) // Allow fallback to polling
          .setAuth({'token': token})
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(10000) // Increase timeout
          .enableAutoConnect()
          .build(),
      );

      _setupEventHandlers();
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
    }
  }

  void _setupEventHandlers() {
    _socket?.onConnect((_) {
      debugPrint('✅ Connected to notification server');
      _isConnected = true;
      _connectionController.add(true);
    });

    _socket?.on('connected', (data) {
      debugPrint('Server confirmed: ${data['message']}');
    });

    _socket?.on('new_notification', (data) {
      debugPrint('📨 New notification received: $data');
      _notificationController.add({
        'type': 'new_notification',
        'data': data['data'] ?? data, // Handle both formats
      });
    });

    _socket?.on('notification_read', (data) {
      debugPrint('✓ Notification marked as read: $data');
      _notificationController.add({
        'type': 'notification_read',
        'data': data,
      });
    });

    _socket?.on('all_notifications_read', (data) {
      debugPrint('✓ All notifications marked as read: $data');
      _notificationController.add({
        'type': 'all_notifications_read',
        'data': data,
      });
    });

    _socket?.onError((error) {
      debugPrint('❌ WebSocket error: $error');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket?.onDisconnect((_) {
      debugPrint('🔌 Disconnected from notification server');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket?.onReconnect((_) {
      debugPrint('🔄 Reconnected to notification server');
    });
  }

  void markAsRead(String notificationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('mark_as_read', {'notificationId': notificationId});
      debugPrint('Marked notification as read: $notificationId');
    } else {
      debugPrint('Cannot mark as read: WebSocket not connected');
    }
  }

  void ping() {
    _socket?.emit('ping');
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
    _connectionController.add(false);
    debugPrint('WebSocket disconnected manually');
  }

  void dispose() {
    disconnect();
    _notificationController.close();
    _connectionController.close();
  }
}
