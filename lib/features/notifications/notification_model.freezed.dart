// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MeetingNotification _$MeetingNotificationFromJson(Map<String, dynamic> json) {
  return _MeetingNotification.fromJson(json);
}

/// @nodoc
mixin _$MeetingNotification {
  String get id => throw _privateConstructorUsedError;
  String get notificationId => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  String get meetingDate => throw _privateConstructorUsedError;
  String get vbCode => throw _privateConstructorUsedError;
  bool get isRead => throw _privateConstructorUsedError;
  DateTime? get readAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this MeetingNotification to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MeetingNotification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MeetingNotificationCopyWith<MeetingNotification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MeetingNotificationCopyWith<$Res> {
  factory $MeetingNotificationCopyWith(
    MeetingNotification value,
    $Res Function(MeetingNotification) then,
  ) = _$MeetingNotificationCopyWithImpl<$Res, MeetingNotification>;
  @useResult
  $Res call({
    String id,
    String notificationId,
    String message,
    String meetingDate,
    String vbCode,
    bool isRead,
    DateTime? readAt,
    DateTime createdAt,
  });
}

/// @nodoc
class _$MeetingNotificationCopyWithImpl<$Res, $Val extends MeetingNotification>
    implements $MeetingNotificationCopyWith<$Res> {
  _$MeetingNotificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MeetingNotification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? notificationId = null,
    Object? message = null,
    Object? meetingDate = null,
    Object? vbCode = null,
    Object? isRead = null,
    Object? readAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            notificationId: null == notificationId
                ? _value.notificationId
                : notificationId // ignore: cast_nullable_to_non_nullable
                      as String,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            meetingDate: null == meetingDate
                ? _value.meetingDate
                : meetingDate // ignore: cast_nullable_to_non_nullable
                      as String,
            vbCode: null == vbCode
                ? _value.vbCode
                : vbCode // ignore: cast_nullable_to_non_nullable
                      as String,
            isRead: null == isRead
                ? _value.isRead
                : isRead // ignore: cast_nullable_to_non_nullable
                      as bool,
            readAt: freezed == readAt
                ? _value.readAt
                : readAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MeetingNotificationImplCopyWith<$Res>
    implements $MeetingNotificationCopyWith<$Res> {
  factory _$$MeetingNotificationImplCopyWith(
    _$MeetingNotificationImpl value,
    $Res Function(_$MeetingNotificationImpl) then,
  ) = __$$MeetingNotificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String notificationId,
    String message,
    String meetingDate,
    String vbCode,
    bool isRead,
    DateTime? readAt,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$MeetingNotificationImplCopyWithImpl<$Res>
    extends _$MeetingNotificationCopyWithImpl<$Res, _$MeetingNotificationImpl>
    implements _$$MeetingNotificationImplCopyWith<$Res> {
  __$$MeetingNotificationImplCopyWithImpl(
    _$MeetingNotificationImpl _value,
    $Res Function(_$MeetingNotificationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MeetingNotification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? notificationId = null,
    Object? message = null,
    Object? meetingDate = null,
    Object? vbCode = null,
    Object? isRead = null,
    Object? readAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$MeetingNotificationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        notificationId: null == notificationId
            ? _value.notificationId
            : notificationId // ignore: cast_nullable_to_non_nullable
                  as String,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        meetingDate: null == meetingDate
            ? _value.meetingDate
            : meetingDate // ignore: cast_nullable_to_non_nullable
                  as String,
        vbCode: null == vbCode
            ? _value.vbCode
            : vbCode // ignore: cast_nullable_to_non_nullable
                  as String,
        isRead: null == isRead
            ? _value.isRead
            : isRead // ignore: cast_nullable_to_non_nullable
                  as bool,
        readAt: freezed == readAt
            ? _value.readAt
            : readAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MeetingNotificationImpl implements _MeetingNotification {
  const _$MeetingNotificationImpl({
    required this.id,
    required this.notificationId,
    required this.message,
    required this.meetingDate,
    required this.vbCode,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory _$MeetingNotificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$MeetingNotificationImplFromJson(json);

  @override
  final String id;
  @override
  final String notificationId;
  @override
  final String message;
  @override
  final String meetingDate;
  @override
  final String vbCode;
  @override
  final bool isRead;
  @override
  final DateTime? readAt;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'MeetingNotification(id: $id, notificationId: $notificationId, message: $message, meetingDate: $meetingDate, vbCode: $vbCode, isRead: $isRead, readAt: $readAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MeetingNotificationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.notificationId, notificationId) ||
                other.notificationId == notificationId) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.meetingDate, meetingDate) ||
                other.meetingDate == meetingDate) &&
            (identical(other.vbCode, vbCode) || other.vbCode == vbCode) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            (identical(other.readAt, readAt) || other.readAt == readAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    notificationId,
    message,
    meetingDate,
    vbCode,
    isRead,
    readAt,
    createdAt,
  );

  /// Create a copy of MeetingNotification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MeetingNotificationImplCopyWith<_$MeetingNotificationImpl> get copyWith =>
      __$$MeetingNotificationImplCopyWithImpl<_$MeetingNotificationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MeetingNotificationImplToJson(this);
  }
}

abstract class _MeetingNotification implements MeetingNotification {
  const factory _MeetingNotification({
    required final String id,
    required final String notificationId,
    required final String message,
    required final String meetingDate,
    required final String vbCode,
    required final bool isRead,
    final DateTime? readAt,
    required final DateTime createdAt,
  }) = _$MeetingNotificationImpl;

  factory _MeetingNotification.fromJson(Map<String, dynamic> json) =
      _$MeetingNotificationImpl.fromJson;

  @override
  String get id;
  @override
  String get notificationId;
  @override
  String get message;
  @override
  String get meetingDate;
  @override
  String get vbCode;
  @override
  bool get isRead;
  @override
  DateTime? get readAt;
  @override
  DateTime get createdAt;

  /// Create a copy of MeetingNotification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MeetingNotificationImplCopyWith<_$MeetingNotificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NotificationResponse _$NotificationResponseFromJson(Map<String, dynamic> json) {
  return _NotificationResponse.fromJson(json);
}

/// @nodoc
mixin _$NotificationResponse {
  List<MeetingNotification> get notifications =>
      throw _privateConstructorUsedError;
  int get unreadCount => throw _privateConstructorUsedError;

  /// Serializes this NotificationResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NotificationResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationResponseCopyWith<NotificationResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationResponseCopyWith<$Res> {
  factory $NotificationResponseCopyWith(
    NotificationResponse value,
    $Res Function(NotificationResponse) then,
  ) = _$NotificationResponseCopyWithImpl<$Res, NotificationResponse>;
  @useResult
  $Res call({List<MeetingNotification> notifications, int unreadCount});
}

/// @nodoc
class _$NotificationResponseCopyWithImpl<
  $Res,
  $Val extends NotificationResponse
>
    implements $NotificationResponseCopyWith<$Res> {
  _$NotificationResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? notifications = null, Object? unreadCount = null}) {
    return _then(
      _value.copyWith(
            notifications: null == notifications
                ? _value.notifications
                : notifications // ignore: cast_nullable_to_non_nullable
                      as List<MeetingNotification>,
            unreadCount: null == unreadCount
                ? _value.unreadCount
                : unreadCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NotificationResponseImplCopyWith<$Res>
    implements $NotificationResponseCopyWith<$Res> {
  factory _$$NotificationResponseImplCopyWith(
    _$NotificationResponseImpl value,
    $Res Function(_$NotificationResponseImpl) then,
  ) = __$$NotificationResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<MeetingNotification> notifications, int unreadCount});
}

/// @nodoc
class __$$NotificationResponseImplCopyWithImpl<$Res>
    extends _$NotificationResponseCopyWithImpl<$Res, _$NotificationResponseImpl>
    implements _$$NotificationResponseImplCopyWith<$Res> {
  __$$NotificationResponseImplCopyWithImpl(
    _$NotificationResponseImpl _value,
    $Res Function(_$NotificationResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? notifications = null, Object? unreadCount = null}) {
    return _then(
      _$NotificationResponseImpl(
        notifications: null == notifications
            ? _value._notifications
            : notifications // ignore: cast_nullable_to_non_nullable
                  as List<MeetingNotification>,
        unreadCount: null == unreadCount
            ? _value.unreadCount
            : unreadCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationResponseImpl implements _NotificationResponse {
  const _$NotificationResponseImpl({
    required final List<MeetingNotification> notifications,
    required this.unreadCount,
  }) : _notifications = notifications;

  factory _$NotificationResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationResponseImplFromJson(json);

  final List<MeetingNotification> _notifications;
  @override
  List<MeetingNotification> get notifications {
    if (_notifications is EqualUnmodifiableListView) return _notifications;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_notifications);
  }

  @override
  final int unreadCount;

  @override
  String toString() {
    return 'NotificationResponse(notifications: $notifications, unreadCount: $unreadCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationResponseImpl &&
            const DeepCollectionEquality().equals(
              other._notifications,
              _notifications,
            ) &&
            (identical(other.unreadCount, unreadCount) ||
                other.unreadCount == unreadCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_notifications),
    unreadCount,
  );

  /// Create a copy of NotificationResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationResponseImplCopyWith<_$NotificationResponseImpl>
  get copyWith =>
      __$$NotificationResponseImplCopyWithImpl<_$NotificationResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationResponseImplToJson(this);
  }
}

abstract class _NotificationResponse implements NotificationResponse {
  const factory _NotificationResponse({
    required final List<MeetingNotification> notifications,
    required final int unreadCount,
  }) = _$NotificationResponseImpl;

  factory _NotificationResponse.fromJson(Map<String, dynamic> json) =
      _$NotificationResponseImpl.fromJson;

  @override
  List<MeetingNotification> get notifications;
  @override
  int get unreadCount;

  /// Create a copy of NotificationResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationResponseImplCopyWith<_$NotificationResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}
