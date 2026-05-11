class LoginRequest {
  final String bankbookNumber;
  final String password;

  LoginRequest({
    required this.bankbookNumber,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'bankbookNumber': bankbookNumber,
      'password': password,
    };
  }
}
