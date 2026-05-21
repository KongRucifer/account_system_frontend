import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../features/notifications/notification_sound_service.dart';
import 'firebase_messaging_service.dart';

/// Service to handle native Android intent communication for terminated state notifications
class NativeIntentService {
  static const MethodChannel _channel = MethodChannel('com.example.frontend_account_system/notifications');
  static final NotificationSoundService _soundService = NotificationSoundService();
  
  /// Get pending notification ID from native Android intent
  /// This is called when app is opened from terminated state
  static Future<String?> getPendingNotificationId() async {
    try {
      debugPrint('🔍 CHECKING FOR PENDING NOTIFICATION FROM NATIVE INTENT...');
      final String? pendingId = await _channel.invokeMethod('getPendingNotificationId');
      
      if (pendingId != null && pendingId.isNotEmpty) {
        debugPrint('📨 FOUND PENDING NOTIFICATION FROM NATIVE: $pendingId');
        
        // 🔇 CRITICAL: Stop sound IMMEDIATELY before anything else
        // This prevents sound from continuing while app is loading
        debugPrint('🔇 Stopping sound immediately on terminated state launch...');
        await _soundService.stopNotificationSound();
        await LocalNotificationService.cancelRepeating();
        
        // 🧹 Clear pending notification from native side to prevent reprocessing
        await clearPendingNotificationId();
        
        return pendingId;
      } else {
        debugPrint('📨 NO PENDING NOTIFICATION FOUND IN NATIVE INTENT');
        return null;
      }
    } catch (e) {
      debugPrint('❌ ERROR GETTING PENDING NOTIFICATION: $e');
      return null;
    }
  }
  
  /// Clear pending notification ID from native side
  static Future<void> clearPendingNotificationId() async {
    try {
      await _channel.invokeMethod('clearPendingNotificationId');
      debugPrint('🧹 Cleared pending notification from native intent');
    } catch (e) {
      debugPrint('❌ Error clearing pending notification: $e');
    }
  }
}
