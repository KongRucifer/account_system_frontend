import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../services/storage_service.dart';

class DioClient {
  late Dio _dio;
  final StorageService _storage;

  DioClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) {
          // Handle 401 - Unauthorized
          if (error.response?.statusCode == 401) {
            // Token expired, clear storage
            _storage.clearToken();
          }
          return handler.next(error);
        },
      ),
    );
  }
}
