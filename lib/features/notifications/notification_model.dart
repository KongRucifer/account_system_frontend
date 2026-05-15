import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

@freezed
class MeetingNotification with _$MeetingNotification {
  const factory MeetingNotification({
    required String id,
    required String notificationId,
    required String message,
    required String meetingDate,
    required String vbCode,
    required bool isRead,
    DateTime? readAt,
    required DateTime createdAt,
  }) = _MeetingNotification;

  factory MeetingNotification.fromJson(Map<String, dynamic> json) =>
      _$MeetingNotificationFromJson(json);
}

@freezed
class NotificationResponse with _$NotificationResponse {
  const factory NotificationResponse({
    required List<MeetingNotification> notifications,
    required int unreadCount,
  }) = _NotificationResponse;

  factory NotificationResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationResponseFromJson(json);
}
