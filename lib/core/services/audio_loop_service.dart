import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Controls the native Android SoundLoopService via MethodChannel.
/// The service plays meeting_sound.wav in a loop as a Foreground Service,
/// so it works in both foreground and background states.
///
/// Sound stops ONLY when:
/// - User taps the notification toast
/// - User clicks "mark all read" button in notification page
class AudioLoopService {
  static const _channel = MethodChannel(
    'com.example.frontend_account_system/notifications',
  );

  static bool _isPlaying = false;
  static bool get isPlaying => _isPlaying;

  /// Start looping the meeting sound via native Foreground Service.
  /// If already playing, does nothing.
  static Future<void> startLoop() async {
    if (_isPlaying) {
      debugPrint('🔊 [AUDIO] Already playing, skipping startLoop');
      return;
    }

    debugPrint('🔊 [AUDIO] Starting native sound loop service...');
    try {
      await _channel.invokeMethod('startSoundLoop');
      _isPlaying = true;
      debugPrint('🔊 [AUDIO] Native sound loop started');
    } catch (e) {
      debugPrint('❌ [AUDIO] Failed to start loop: $e');
    }
  }

  /// Stop the looping sound by stopping the native Foreground Service.
  /// Always sends stop command to native side, because the service may have
  /// been started by MyFirebaseMessagingService (native) without Flutter knowing.
  static Future<void> stopLoop() async {
    debugPrint('🔇 [AUDIO] Stopping native sound loop service...');
    try {
      await _channel.invokeMethod('stopSoundLoop');
      _isPlaying = false;
      debugPrint('🔇 [AUDIO] Native sound loop stopped');
    } catch (e) {
      debugPrint('❌ [AUDIO] Failed to stop loop: $e');
    }
  }
}
