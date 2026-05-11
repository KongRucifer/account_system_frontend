import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/account_model.dart';

class AccountRepository {
  final Dio _dio;

  AccountRepository(this._dio);

  Future<List<Account>> getAccountsByUser(String clientId) async {
    try {
      final response = await _dio.get(
        ApiConstants.accountsByUser(clientId),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        // findByUser returns a plain array
        if (data is List) {
          return data.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
        }
        // fallback: paginated response
        if (data is Map && data.containsKey('results')) {
          final List<dynamic> results = data['results'];
          return results.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load accounts: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to load accounts: ${e.message}');
    }
  }
}
