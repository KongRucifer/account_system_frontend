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
      
      // Handle both String and List messages from backend
      dynamic rawMessage = errorData?['message'];
      String extractedMessage;
      if (rawMessage is List) {
        extractedMessage = rawMessage.join(', ');
      } else if (rawMessage is String) {
        extractedMessage = rawMessage;
      } else {
        extractedMessage = '';
      }
      
      if (statusCode == 401 || statusCode == 403) {
        message = extractedMessage.isNotEmpty ? extractedMessage : 'The username or password you entered is incorrect. Please try again.';
      } else if (statusCode != null) {
        message = extractedMessage.isNotEmpty ? extractedMessage : 'Server error ($statusCode)';
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

  Future<Map<String, dynamic>> register({
    required String bankbookNumber,
    required String password,
    required String confirmPassword,
    required String phoneNumber,
    required String vbCode,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'bankbookNumber': bankbookNumber,
          'password': password,
          'confirmPassword': confirmPassword,
          'phoneNumber': phoneNumber,
          'vbCode': vbCode,
        },
      );
      
      if (response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Registration failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final errorData = e.response?.data;
      String message;
      
      // Handle both String and List messages from backend
      dynamic rawMessage = errorData?['message'];
      String extractedMessage;
      if (rawMessage is List) {
        extractedMessage = rawMessage.join(', ');
      } else if (rawMessage is String) {
        extractedMessage = rawMessage;
      } else {
        extractedMessage = '';
      }
      
      if (statusCode == 400) {
        message = extractedMessage.isNotEmpty ? extractedMessage : 'Invalid input. Please check your information.';
      } else if (statusCode == 409) {
        message = extractedMessage.isNotEmpty ? extractedMessage : 'You already have an account. Please login.';
      } else if (statusCode != null) {
        message = extractedMessage.isNotEmpty ? extractedMessage : 'Server error ($statusCode)';
      } else {
        message = 'Cannot connect to server. Please check your connection.';
      }
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String phoneNumber,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.resetPassword,
        data: {
          'phoneNumber': phoneNumber,
          'newPassword': newPassword,
        },
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Reset password failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final errorData = e.response?.data;
      String message;
      
      // Handle both String and List messages from backend
      dynamic rawMessage = errorData?['message'];
      String extractedMessage;
      if (rawMessage is List) {
        extractedMessage = rawMessage.join(', ');
      } else if (rawMessage is String) {
        extractedMessage = rawMessage;
      } else {
        extractedMessage = '';
      }
      
      if (statusCode == 400) {
        message = extractedMessage.isNotEmpty ? extractedMessage : 'Phone number not found or account not found.';
      } else if (statusCode != null) {
        message = extractedMessage.isNotEmpty ? extractedMessage : 'Server error ($statusCode)';
      } else {
        message = 'Cannot connect to server. Please check your connection.';
      }
      throw Exception(message);
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
