import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/storage_service.dart';
import 'notification_repository.dart';

class FcmRegistrationService {
  final NotificationRepository _repository;
  final StorageService _storage;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  FcmRegistrationService(this._repository, this._storage);

  /// Get unique device ID
  Future<String> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return 'android_${androidInfo.id}_${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return 'ios_${iosInfo.identifierForVendor ?? iosInfo.name}_${iosInfo.model}';
      }
      return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('❌ Error getting device ID: $e');
      return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

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

      // Get device ID
      final deviceId = await _getDeviceId();
      debugPrint('📱 Device ID: $deviceId');

      // Send token to backend
      await _sendTokenToBackend(deviceId, token);

      // Listen for token refresh and re-register automatically
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 FCM token refreshed');
        await _sendTokenToBackend(deviceId, newToken);
      });
    } catch (e) {
      debugPrint('❌ FCM registration error: $e');
    }
  }

  Future<void> _sendTokenToBackend(String deviceId, String token) async {
    try {
      final userData = await _storage.getUser();
      final username = userData?['username'] as String?;
      if (username == null) {
        debugPrint('⚠️ Cannot register FCM token: no username in storage');
        return;
      }
      await _repository.updateFcmToken(username, deviceId, token);
      debugPrint('✅ FCM token registered for $username (device: $deviceId)');
    } catch (e) {
      debugPrint('❌ Failed to send FCM token to backend: $e');
    }
  }

  /// ເອີ້ນຕອນ logout — ຕັ້ງ isActive=false ໃຫ້ device ນີ້
  /// device ອື່ນ (B, C) ຂອງ account ດຽວກັນຍັງ isActive=true ຢູ່
  Future<void> deactivateToken() async {
    if (kIsWeb) return;
    try {
      final userData = await _storage.getUser();
      final username = userData?['username'] as String?;
      if (username == null) return;

      final deviceId = await _getDeviceId();
      await _repository.deactivateFcmToken(username, deviceId);
      debugPrint('✅ FCM token deactivated for $username (device: $deviceId)');
    } catch (e) {
      debugPrint('❌ Failed to deactivate FCM token: $e');
    }
  }
}
