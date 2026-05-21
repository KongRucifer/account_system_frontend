import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Communicates with native Android code via MethodChannel.
/// Retrieves pending notification data when app is opened from terminated state.
class NativeIntentService {
  static const _channel = MethodChannel(
    'com.example.frontend_account_system/notifications',
  );

  /// Get the notification ID that launched the app from terminated state.
  /// Returns null if app was not launched from a notification.
  static Future<String?> getPendingNotificationId() async {
    try {
      final String? pendingId =
          await _channel.invokeMethod('getPendingNotificationId');
      if (pendingId != null) {
        debugPrint(
            '📨 NativeIntentService: Retrieved pending notification: $pendingId');
      }
      return pendingId;
    } on PlatformException catch (e) {
      debugPrint('⚠️ NativeIntentService: PlatformException: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('⚠️ NativeIntentService: Error: $e');
      return null;
    }
  }
}
