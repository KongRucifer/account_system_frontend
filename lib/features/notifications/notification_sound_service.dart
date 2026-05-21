import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class NotificationSoundService {
  static final NotificationSoundService _instance = NotificationSoundService._internal();
  factory NotificationSoundService() => _instance;
  NotificationSoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentNotificationId;

  /// Play notification sound for foreground state
  /// Background sound is handled by OS notification channel
  Future<void> playNotificationSound(String notificationId) async {
    if (_isPlaying && _currentNotificationId == notificationId) return;
    
    try {
      _currentNotificationId = notificationId;
      _isPlaying = true;
      
      // Set loop mode for continuous sound
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Play sound from assets (ensure meeting_sound.wav exists in assets/sounds/)
      await _audioPlayer.play(AssetSource('sounds/meeting_sound.wav'));
      
      debugPrint('🔊 [SoundService] Started playing sound for: $notificationId');
    } catch (e) {
      debugPrint('❌ [SoundService] Error playing sound: $e');
      _isPlaying = false;
    }
  }

  /// Stop notification sound immediately
  Future<void> stopNotificationSound() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentNotificationId = null;
      debugPrint('🔇 [SoundService] Sound stopped');
    } catch (e) {
      debugPrint('❌ [SoundService] Error stopping sound: $e');
    }
  }

  /// Play short notification sound (single play)
  Future<void> playShortNotificationSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.play(AssetSource('sounds/meeting_sound.wav'));
      debugPrint('🔊 [SoundService] Short notification sound played');
    } catch (e) {
      debugPrint('❌ [SoundService] Error playing short sound: $e');
    }
  }

  /// หยุดเสียงเมื่อ mark as read (ไม่เล่นเสียงเพิ่ม)
  Future<void> playSuccessSound() async {
    await stopNotificationSound();
    debugPrint('� Sound stopped on mark-as-read');
  }

  /// ตรวจสอบว่ากำลังเล่นเสียงอยู่หรือไม่
  bool get isPlaying => _isPlaying;

  /// ดู notification ID ที่กำลังเล่นเสียงอยู่
  String? get currentNotificationId => _currentNotificationId;

  /// หยุดทั้งหมดและ dispose
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    _isPlaying = false;
    _currentNotificationId = null;
  }
}
