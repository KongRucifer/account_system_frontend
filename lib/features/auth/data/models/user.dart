class ClientInfo {
  final String id;
  final String? bankbookNumber;
  final String? firstName;
  final String? lastName;
  final String? nickName;
  final String? vbCode;

  ClientInfo({
    required this.id,
    this.bankbookNumber,
    this.firstName,
    this.lastName,
    this.nickName,
    this.vbCode,
  });

  String get displayName => nickName?.isNotEmpty == true
      ? nickName!
      : '$firstName $lastName'.trim();

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      id: json['id'] as String? ?? '',
      bankbookNumber: json['bankbookNumber'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      nickName: json['nickName'] as String?,
      vbCode: json['vbCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bankbookNumber': bankbookNumber,
      'firstName': firstName,
      'lastName': lastName,
      'nickName': nickName,
      'vbCode': vbCode,
    };
  }
}

class User {
  final String bankbookNumber;
  final String? vbCode;
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final DateTime? expiresAt;
  final String username; // Actual username for FCM token registration
  final List<ClientInfo> clients;

  User({
    required this.bankbookNumber,
    required this.username,
    this.vbCode,
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.expiresAt,
    this.clients = const [],
  });

  ClientInfo? get primaryClient => clients.isNotEmpty ? clients.first : null;

  String get displayName => primaryClient?.displayName ?? bankbookNumber;

  // Backend login response:
  // { accessToken, refreshToken, tokenType, expiresIn, expiresAt, clients: [ { id, bankbookNumber, firstName, lastName, nickName, vbCode } ] }
  factory User.fromLoginResponse(Map<String, dynamic> json) {
    final expiresAtStr = json['expiresAt'] as String?;
    final clientsList = json['clients'] as List<dynamic>? ?? [];
    final firstClient = clientsList.isNotEmpty
        ? clientsList.first as Map<String, dynamic>?
        : null;

    return User(
      bankbookNumber: firstClient?['bankbookNumber'] as String? ?? '',
      username: json['username'] as String? ?? firstClient?['bankbookNumber'] as String? ?? '',
      vbCode: firstClient?['vbCode'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      expiresIn: json['expiresIn'] as int?,
      expiresAt: expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null,
      clients: clientsList
          .map((e) => ClientInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final expiresAtStr = json['expiresAt'] as String?;
    final clientsList = json['clients'] as List<dynamic>? ?? [];

    return User(
      bankbookNumber: json['bankbookNumber'] as String? ?? '',
      username: json['username'] as String? ?? json['bankbookNumber'] as String? ?? '',
      vbCode: json['vbCode'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      expiresIn: json['expiresIn'] as int?,
      expiresAt: expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null,
      clients: clientsList
          .map((e) => ClientInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankbookNumber': bankbookNumber,
      'username': username,
      'vbCode': vbCode,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'expiresAt': expiresAt?.toIso8601String(),
      'clients': clients.map((c) => c.toJson()).toList(),
    };
  }
}
