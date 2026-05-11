import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/login_request.dart';
import '../models/user.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<User> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return User.fromLoginResponse(data);
      } else {
        throw Exception('Login failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message;
      if (statusCode == 401 || statusCode == 403) {
        message = 'The username or password you entered is incorrect. Please try again.';
      } else if (statusCode != null) {
        message = 'Server error ($statusCode)';
      } else {
        message = 'Cannot connect to server. Please check your connection.';
      }
      throw Exception(message);
    }
  }
}
