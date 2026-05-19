import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Access Token
  Future<void> saveToken(String token) async {
    await _prefs?.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    return _prefs?.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    await _prefs?.remove(_tokenKey);
  }

  // Refresh Token (for mobile apps - web uses cookies)
  Future<void> saveRefreshToken(String token) async {
    await _prefs?.setString(_refreshTokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    return _prefs?.getString(_refreshTokenKey);
  }

  Future<void> clearRefreshToken() async {
    await _prefs?.remove(_refreshTokenKey);
  }

  // User Data
  Future<void> saveUser(Map<String, dynamic> userData) async {
    await _prefs?.setString(_userKey, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final userStr = _prefs?.getString(_userKey);
    print('🔍 StorageService: userStr = $userStr');
    if (userStr != null) {
      final userData = jsonDecode(userStr) as Map<String, dynamic>;
      print('🔍 StorageService: userData = $userData');
      return userData;
    }
    print('🔍 StorageService: No user data found');
    return null;
  }

  Future<void> clearUser() async {
    await _prefs?.remove(_userKey);
  }

  // Clear all
  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
