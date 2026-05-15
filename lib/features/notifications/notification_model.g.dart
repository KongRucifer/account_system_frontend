// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MeetingNotificationImpl _$$MeetingNotificationImplFromJson(
  Map<String, dynamic> json,
) => _$MeetingNotificationImpl(
  id: json['id'] as String,
  notificationId: json['notificationId'] as String,
  message: json['message'] as String,
  meetingDate: json['meetingDate'] as String,
  vbCode: json['vbCode'] as String,
  isRead: json['isRead'] as bool,
  readAt: json['readAt'] == null
      ? null
      : DateTime.parse(json['readAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$MeetingNotificationImplToJson(
  _$MeetingNotificationImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'notificationId': instance.notificationId,
  'message': instance.message,
  'meetingDate': instance.meetingDate,
  'vbCode': instance.vbCode,
  'isRead': instance.isRead,
  'readAt': instance.readAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
};

_$NotificationResponseImpl _$$NotificationResponseImplFromJson(
  Map<String, dynamic> json,
) => _$NotificationResponseImpl(
  notifications: (json['notifications'] as List<dynamic>)
      .map((e) => MeetingNotification.fromJson(e as Map<String, dynamic>))
      .toList(),
  unreadCount: (json['unreadCount'] as num).toInt(),
);

Map<String, dynamic> _$$NotificationResponseImplToJson(
  _$NotificationResponseImpl instance,
) => <String, dynamic>{
  'notifications': instance.notifications,
  'unreadCount': instance.unreadCount,
};
