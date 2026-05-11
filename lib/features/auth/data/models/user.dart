class User {
  final int id;
  final String userName;
  final String? accessToken;

  User({
    required this.id,
    required this.userName,
    this.accessToken,
  });

  // Backend login response:
  // { accessToken, tokenType, expiresIn, user: { id, username } }
  factory User.fromLoginResponse(Map<String, dynamic> json) {
    final userObj = json['user'] as Map<String, dynamic>;
    return User(
      id: (userObj['id'] as num).toInt(),
      userName: userObj['username'] as String,
      accessToken: json['accessToken'] as String?,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num).toInt(),
      userName: json['userName'] as String,
      accessToken: json['accessToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'accessToken': accessToken,
    };
  }
}
