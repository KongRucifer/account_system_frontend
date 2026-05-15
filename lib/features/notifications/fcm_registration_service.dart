import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/storage_service.dart';
import 'notification_repository.dart';

class FcmRegistrationService {
  final NotificationRepository _repository;
  final StorageService _storage;

  FcmRegistrationService(this._repository, this._storage);

  /// Request permission and register FCM token with the backend.
  /// Call this once after a successful login.
  Future<void> registerToken() async {
    if (kIsWeb) return;

    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission (iOS / Web)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('⚠️ FCM permission denied by user');
        return;
      }

      // Get the device token
      final token = await messaging.getToken();
      if (token == null) {
        debugPrint('⚠️ FCM token is null');
        return;
      }

      debugPrint('📱 FCM token: $token');

      // Send token to backend
      await _sendTokenToBackend(token);

      // Listen for token refresh and re-register automatically
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 FCM token refreshed');
        await _sendTokenToBackend(newToken);
      });
    } catch (e) {
      debugPrint('❌ FCM registration error: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final userData = await _storage.getUser();
      final username = userData?['username'] as String?;
      if (username == null) {
        debugPrint('⚠️ Cannot register FCM token: no username in storage');
        return;
      }
      await _repository.updateFcmToken(username, token);
      debugPrint('✅ FCM token registered for $username');
    } catch (e) {
      debugPrint('❌ Failed to send FCM token to backend: $e');
    }
  }
}
