import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class NotificationSoundService {
  static final NotificationSoundService _instance = NotificationSoundService._internal();
  factory NotificationSoundService() => _instance;
  NotificationSoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentNotificationId;

  /// เสียงแจ้งเตือนใช้ Android Notification Channel แทน (res/raw/meeting_sound.wav)
  /// method นี้คงไว้เพื่อ compatibility กับ notification_provider.dart
  Future<void> playNotificationSound(String notificationId) async {
    debugPrint('🔊 Sound handled by Android Notification Channel');
  }

  /// หยุดเสียง (no-op เพราะเสียงจัดการโดย OS notification channel)
  Future<void> stopNotificationSound() async {
    _isPlaying = false;
    _currentNotificationId = null;
    debugPrint('🔇 stopNotificationSound called (no-op)');
  }

  /// no-op — เสียงจัดการโดย OS notification channel
  Future<void> playShortNotificationSound() async {
    debugPrint('🔊 playShortNotificationSound called (no-op)');
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
