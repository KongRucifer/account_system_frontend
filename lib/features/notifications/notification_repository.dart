import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import 'notification_model.dart';

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  /// ดึง notification ทั้งหมดของ user
  Future<NotificationResponse> getAllNotifications(String username, {int page = 1, int limit = 12}) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {
          'username': username,
          'page': page,
          'limit': limit,
        },
      );

      final List<dynamic> notificationsData = response.data['notifications'] ?? [];
      final notifications = notificationsData
          .map((json) => MeetingNotification.fromJson(json as Map<String, dynamic>))
          .toList();

      final paginationData = response.data['pagination'];
      final pagination = paginationData != null 
          ? PaginationInfo.fromJson(paginationData as Map<String, dynamic>)
          : null;

      return NotificationResponse(
        notifications: notifications,
        unreadCount: response.data['unreadCount'] ?? 0,
        pagination: pagination,
      );
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
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
      throw Exception('Failed to load unread notifications: $e');
    }
  }

  /// Mark notification ว่าอ่านแล้ว
  Future<void> markAsRead(String notificationId, String username) async {
    try {
      await _dio.post(
        '/notifications/$notificationId/read',
        data: {'username': username},
      );
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// ดู preview ของ meetings พรุ่งนี้ (สำหรับ testing)
  Future<Map<String, dynamic>> previewMeetings() async {
    try {
      final response = await _dio.get('/notifications/test/preview-meetings');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to preview meetings: $e');
    }
  }

  /// ບັນທຶກ FCM token ແລະ device ID ຂອງ user ໄວ້ໃນຖານຂໍ້ມູນ
  Future<void> updateFcmToken(String username, String deviceId, String fcmToken) async {
    try {
      await _dio.patch(
        ApiConstants.updateFcmToken,
        data: {
          'username': username,
          'deviceId': deviceId,
          'fcmToken': fcmToken,
        },
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
      throw Exception('Failed to trigger meeting reminder: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<int> markAllAsRead(String username) async {
    try {
      final response = await _dio.patch(
        '/notifications/mark-all-read',
        data: {'username': username},
      );
      return response.data['count'] as int;
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }
}
