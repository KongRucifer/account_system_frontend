import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        options: kIsWeb ? Options(extra: {'withCredentials': true}) : null,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return User.fromLoginResponse(data);
      } else {
        throw Exception('Login failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final errorData = e.response?.data;
      String message;
      
      if (statusCode == 401 || statusCode == 403) {
        message = errorData?['message'] ?? 'The username or password you entered is incorrect. Please try again.';
      } else if (statusCode != null) {
        message = errorData?['message'] ?? 'Server error ($statusCode)';
      } else {
        message = 'Cannot connect to server. Please check your connection.';
      }
      throw Exception(message);
    }
  }

  Future<bool> logout() async {
    try {
      final response = await _dio.post(
        ApiConstants.logout,
        options: kIsWeb ? Options(extra: {'withCredentials': true}) : null,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<User?> refreshToken() async {
    try {
      final response = await _dio.post(
        ApiConstants.refresh,
        options: kIsWeb ? Options(extra: {'withCredentials': true}) : null,
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return User.fromLoginResponse(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
