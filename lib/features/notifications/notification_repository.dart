import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import 'notification_model.dart';

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  /// ดึง notification ทั้งหมดของ user
  Future<NotificationResponse> getAllNotifications(String username) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'username': username},
      );

      final List<dynamic> notificationsData = response.data['notifications'] ?? [];
      final notifications = notificationsData
          .map((json) => MeetingNotification.fromJson(json as Map<String, dynamic>))
          .toList();

      return NotificationResponse(
        notifications: notifications,
        unreadCount: response.data['unreadCount'] ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to load notifications: \$e');
    }
  }

  /// ดึง notification ที่ยังไม่ได้อ่าน
  Future<NotificationResponse> getUnreadNotifications(String username) async {
    try {
      final response = await _dio.get(
        '/notifications/unread',
        queryParameters: {'username': username},
      );

      final List<dynamic> notificationsData = response.data['notifications'] ?? [];
      final notifications = notificationsData
          .map((json) => MeetingNotification.fromJson(json as Map<String, dynamic>))
          .toList();

      return NotificationResponse(
        notifications: notifications,
        unreadCount: response.data['unreadCount'] ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to load unread notifications: \$e');
    }
  }

  /// Mark notification ว่าอ่านแล้ว
  Future<void> markAsRead(String notificationId, String username) async {
    try {
      await _dio.post(
        '/notifications/\$notificationId/read',
        data: {'username': username},
      );
    } catch (e) {
      throw Exception('Failed to mark notification as read: \$e');
    }
  }

  /// ดู preview ของ meetings พรุ่งนี้ (สำหรับ testing)
  Future<Map<String, dynamic>> previewMeetings() async {
    try {
      final response = await _dio.get('/notifications/test/preview-meetings');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to preview meetings: \$e');
    }
  }

  /// บันทึก FCM token ของ user ไว้ในฐานข้อมูล
  Future<void> updateFcmToken(String username, String fcmToken) async {
    try {
      await _dio.patch(
        ApiConstants.updateFcmToken,
        data: {'username': username, 'fcmToken': fcmToken},
      );
    } catch (e) {
      throw Exception('Failed to update FCM token: $e');
    }
  }

  /// Trigger cron job ด้วยตนเอง (สำหรับ testing)
  Future<Map<String, dynamic>> triggerMeetingReminder() async {
    try {
      final response = await _dio.post('/notifications/test/trigger-meeting-reminder');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to trigger meeting reminder: \$e');
    }
  }
}
