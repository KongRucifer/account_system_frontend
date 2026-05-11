import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../services/storage_service.dart';

class DioClient {
  late Dio _dio;
  final StorageService _storage;
  bool _isRefreshing = false;
  final List<Function> _refreshQueue = [];

  DioClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
        // For web: allow cookies to be sent/received
        extra: kIsWeb ? {'withCredentials': true} : null,
      ),
    );

    _setupInterceptors();
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available (for mobile app)
          // For web, cookies are handled automatically by browser
          if (!kIsWeb) {
            final token = await _storage.getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) async {
          // Handle 401 - Token expired
          if (error.response?.statusCode == 401) {
            final errorData = error.response?.data;
            final isTokenExpired = errorData?['code'] == 'TOKEN_EXPIRED' ||
                errorData?['message']?.contains('expired') == true;

            if (isTokenExpired && !_isRefreshing) {
              _isRefreshing = true;

              try {
                // Attempt to refresh token
                final refreshed = await _refreshToken();

                if (refreshed) {
                  // Retry the original request
                  final opts = error.requestOptions;
                  final response = await _dio.request(
                    opts.path,
                    options: Options(
                      method: opts.method,
                      headers: opts.headers,
                    ),
                    data: opts.data,
                    queryParameters: opts.queryParameters,
                  );
                  return handler.resolve(response);
                } else {
                  // Refresh failed, clear storage and redirect to login
                  await _storage.clearAll();
                }
              } catch (e) {
                await _storage.clearAll();
              } finally {
                _isRefreshing = false;
              }
            } else if (isTokenExpired && _isRefreshing) {
              // Queue the request while refreshing
              _refreshQueue.add(() async {
                final opts = error.requestOptions;
                final response = await _dio.request(
                  opts.path,
                  options: Options(
                    method: opts.method,
                    headers: opts.headers,
                  ),
                  data: opts.data,
                  queryParameters: opts.queryParameters,
                );
                return handler.resolve(response);
              });
              return;
            } else {
              // Other 401 errors (not token expired)
              await _storage.clearAll();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final response = await _dio.post(ApiConstants.refresh);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newToken = data['accessToken'] as String?;

        if (newToken != null && !kIsWeb) {
          // Save new token for mobile app
          await _storage.saveToken(newToken);
        }

        // Process queued requests
        for (final callback in _refreshQueue) {
          await callback();
        }
        _refreshQueue.clear();

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
