import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides a unique, persistent device ID for FCM token management.
/// On Android, uses androidId. Falls back to a stored UUID.
class DeviceIdService {
  static const _key = 'device_unique_id';
  static String? _cachedId;

  static Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;

    try {
      if (!kIsWeb && Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        final androidId = info.id; // Build.ID — stable per device
        if (androidId.isNotEmpty) {
          _cachedId = androidId;
          return _cachedId!;
        }
      }
    } catch (e) {
      debugPrint('⚠️ DeviceIdService: Failed to get platform ID: $e');
    }

    // Fallback: use stored UUID
    final prefs = await SharedPreferences.getInstance();
    var stored = prefs.getString(_key);
    if (stored == null || stored.isEmpty) {
      stored = _generateUuid();
      await prefs.setString(_key, stored);
    }
    _cachedId = stored;
    return _cachedId!;
  }

  static String _generateUuid() {
    // Simple v4-like UUID without external package
    final now = DateTime.now().microsecondsSinceEpoch;
    return '${now.toRadixString(16)}-${now.hashCode.toRadixString(16)}-${Object().hashCode.toRadixString(16)}';
  }
}
