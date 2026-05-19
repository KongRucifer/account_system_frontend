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

_$PaginationInfoImpl _$$PaginationInfoImplFromJson(Map<String, dynamic> json) =>
    _$PaginationInfoImpl(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      totalCount: (json['totalCount'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
      hasNext: json['hasNext'] as bool,
      hasPrev: json['hasPrev'] as bool,
    );

Map<String, dynamic> _$$PaginationInfoImplToJson(
  _$PaginationInfoImpl instance,
) => <String, dynamic>{
  'page': instance.page,
  'limit': instance.limit,
  'totalCount': instance.totalCount,
  'totalPages': instance.totalPages,
  'hasNext': instance.hasNext,
  'hasPrev': instance.hasPrev,
};

_$NotificationResponseImpl _$$NotificationResponseImplFromJson(
  Map<String, dynamic> json,
) => _$NotificationResponseImpl(
  notifications: (json['notifications'] as List<dynamic>)
      .map((e) => MeetingNotification.fromJson(e as Map<String, dynamic>))
      .toList(),
  unreadCount: (json['unreadCount'] as num).toInt(),
  pagination: json['pagination'] == null
      ? null
      : PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$NotificationResponseImplToJson(
  _$NotificationResponseImpl instance,
) => <String, dynamic>{
  'notifications': instance.notifications,
  'unreadCount': instance.unreadCount,
  'pagination': instance.pagination,
};
