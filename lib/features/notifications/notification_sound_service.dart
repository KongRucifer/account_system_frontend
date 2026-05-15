import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class NotificationSoundService {
  static final NotificationSoundService _instance = NotificationSoundService._internal();
  factory NotificationSoundService() => _instance;
  NotificationSoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentNotificationId;

  /// เริ่มเล่นเสียงแจ้งเตือนแบบวนลูป
  Future<void> playNotificationSound(String notificationId) async {
    try {
      // ถ้ากำลังเล่นอยู่แล้วสำหรับ notification เดียวกัน ไม่ต้องเล่นซ้ำ
      if (_isPlaying && _currentNotificationId == notificationId) {
        return;
      }

      _currentNotificationId = notificationId;
      _isPlaying = true;

      // ตั้งค่าให้เล่นวนลูป
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      // เล่นเสียงแจ้งเตือน (ใช้ระบบเสียงของ Android/iOS)
      // สามารถเปลี่ยนเป็นไฟล์เสียงที่กำหนดเองได้
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
      
      debugPrint('🔊 Playing notification sound for: $notificationId');
    } catch (e) {
      debugPrint('❌ Error playing notification sound: $e');
      // Fallback: เล่นเสียงระบบถ้าไม่มีไฟล์
      await _playSystemSound();
    }
  }

  /// หยุดเล่นเสียงแจ้งเตือน
  Future<void> stopNotificationSound() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        _isPlaying = false;
        _currentNotificationId = null;
        debugPrint('🔇 Stopped notification sound');
      }
    } catch (e) {
      debugPrint('❌ Error stopping notification sound: $e');
    }
  }

  /// เล่นเสียงสั้นๆ ครั้งเดียว (สำหรับกรณีที่ไม่ต้องการวนลูป)
  Future<void> playShortNotificationSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
      debugPrint('🔊 Played short notification sound');
    } catch (e) {
      debugPrint('❌ Error playing short sound: $e');
      await _playSystemSound();
    }
  }

  /// เล่นเสียงเมื่อ mark as read (เสียงสั้นๆ ยืนยัน)
  Future<void> playSuccessSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      debugPrint('🔊 Played success sound');
    } catch (e) {
      debugPrint('❌ Error playing success sound: $e');
    }
  }

  /// Fallback: เล่นเสียงระบบ
  Future<void> _playSystemSound() async {
    try {
      // ใช้เสียง default ของระบบ
      await _audioPlayer.play(UrlSource('system_sound'));
    } catch (e) {
      debugPrint('❌ Cannot play system sound: $e');
    }
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
