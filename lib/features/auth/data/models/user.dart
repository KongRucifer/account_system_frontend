class User {
  final String id;
  final String bankbookNumber;
  final String? firstName;
  final String? lastName;
  final String? nickName;
  final String? vbCode;
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final DateTime? expiresAt;

  User({
    required this.id,
    required this.bankbookNumber,
    this.firstName,
    this.lastName,
    this.nickName,
    this.vbCode,
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.expiresAt,
  });

  String get displayName => nickName ?? '$firstName $lastName'.trim();

  // Backend login response:
  // { accessToken, refreshToken, tokenType, expiresIn, expiresAt, client: { id, bankbookNumber, firstName, lastName, nickName, vbCode } }
  factory User.fromLoginResponse(Map<String, dynamic> json) {
    final clientObj = json['client'] as Map<String, dynamic>?;
    final expiresAtStr = json['expiresAt'] as String?;
    
    return User(
      id: clientObj?['id'] as String? ?? '',
      bankbookNumber: clientObj?['bankbookNumber'] as String? ?? '',
      firstName: clientObj?['firstName'] as String?,
      lastName: clientObj?['lastName'] as String?,
      nickName: clientObj?['nickName'] as String?,
      vbCode: clientObj?['vbCode'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      expiresIn: json['expiresIn'] as int?,
      expiresAt: expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final expiresAtStr = json['expiresAt'] as String?;
    
    return User(
      id: json['id'] as String? ?? '',
      bankbookNumber: json['bankbookNumber'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      nickName: json['nickName'] as String?,
      vbCode: json['vbCode'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      expiresIn: json['expiresIn'] as int?,
      expiresAt: expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null,
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
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}
