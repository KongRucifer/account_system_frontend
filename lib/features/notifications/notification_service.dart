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

  // Exponential backoff reconnection
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 10;
  static const _backoffDelays = [1, 2, 5, 10, 15, 20, 30, 30, 30, 30]; // seconds
  bool _manualDisconnect = false;

  void connect() async {
    _manualDisconnect = false;

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

      // Strip /api/v1 suffix — Socket.IO gateway is at root, not under /api/v1
      final rawUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:4000';
      final uri = Uri.parse(rawUrl);
      final baseUrl = '${uri.scheme}://${uri.host}:${uri.port}';
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
      // Reset backoff on successful connection
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
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
      debugPrint('📨 NOTIFICATION READ RECEIVED FROM OTHER DEVICE: $data');
      // FIX: Extract notificationId and put at root level for easier access
      final Map<String, dynamic> readData = data is Map<String, dynamic> ? data : {};
      _notificationController.add({
        'type': 'notification_read',
        'notificationId': readData['notificationId'] ?? readData['id']?.toString(),
        'data': readData,
      });
    });

    _socket?.on('all_notifications_read', (data) {
      debugPrint('📨 ALL NOTIFICATIONS READ RECEIVED FROM OTHER DEVICE: $data');
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
      // Auto-reconnect with exponential backoff (unless manually disconnected)
      if (!_manualDisconnect) {
        _scheduleReconnect();
      }
    });

    _socket?.onReconnect((_) {
      debugPrint('🔄 Reconnected to notification server');
      _reconnectAttempts = 0;
    });

    _socket?.onReconnectFailed((_) {
      debugPrint('❌ Socket.IO built-in reconnection failed, using custom backoff');
      _scheduleReconnect();
    });
  }

  /// Schedule a reconnection attempt with exponential backoff
  void _scheduleReconnect() {
    if (_manualDisconnect || _reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('⚠️ Max reconnect attempts reached or manually disconnected');
      return;
    }

    final delaySeconds = _backoffDelays[
        _reconnectAttempts.clamp(0, _backoffDelays.length - 1)];
    _reconnectAttempts++;

    debugPrint(
        '🔄 Scheduling reconnect attempt $_reconnectAttempts in ${delaySeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_manualDisconnect && !_isConnected) {
        debugPrint('🔄 Attempting reconnect #$_reconnectAttempts...');
        _socket?.dispose();
        _socket = null;
        connect();
      }
    });
  }

  void markAsRead(String notificationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('mark_as_read', {'notificationId': notificationId});
      debugPrint('✓ Emitted mark_as_read: $notificationId');
    } else {
      debugPrint('⚠️ Cannot mark as read: WebSocket not connected');
    }
  }

  void markAllAsRead() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('mark_all_as_read', {});
      debugPrint('✓ Emitted mark_all_as_read');
    } else {
      debugPrint('⚠️ Cannot mark all as read: WebSocket not connected');
    }
  }

  void ping() {
    _socket?.emit('ping');
  }

  void disconnect() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _connectionController.add(false);
    debugPrint('WebSocket disconnected manually');
  }

  /// Reconnect after manual disconnect (e.g., app resumed)
  void reconnect() {
    _manualDisconnect = false;
    _reconnectAttempts = 0;
    _socket?.dispose();
    _socket = null;
    connect();
  }

  void dispose() {
    disconnect();
    _notificationController.close();
    _connectionController.close();
  }
}
