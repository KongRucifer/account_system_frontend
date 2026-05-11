class User {
  final String id;
  final String bankbookNumber;
  final String? firstName;
  final String? lastName;
  final String? nickName;
  final String? vbCode;
  final String? accessToken;

  User({
    required this.id,
    required this.bankbookNumber,
    this.firstName,
    this.lastName,
    this.nickName,
    this.vbCode,
    this.accessToken,
  });

  String get displayName => nickName ?? '$firstName $lastName'.trim();

  // Backend login response:
  // { accessToken, tokenType, expiresIn, client: { id, bankbookNumber, firstName, lastName, nickName, vbCode } }
  factory User.fromLoginResponse(Map<String, dynamic> json) {
    final clientObj = json['client'] as Map<String, dynamic>;
    return User(
      id: clientObj['id'] as String,
      bankbookNumber: clientObj['bankbookNumber'] as String? ?? '',
      firstName: clientObj['firstName'] as String?,
      lastName: clientObj['lastName'] as String?,
      nickName: clientObj['nickName'] as String?,
      vbCode: clientObj['vbCode'] as String?,
      accessToken: json['accessToken'] as String?,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      bankbookNumber: json['bankbookNumber'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      nickName: json['nickName'] as String?,
      vbCode: json['vbCode'] as String?,
      accessToken: json['accessToken'] as String?,
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
    };
  }
}
