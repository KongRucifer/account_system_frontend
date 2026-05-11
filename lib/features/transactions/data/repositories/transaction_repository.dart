import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final Dio _dio;

  TransactionRepository(this._dio);

  Future<PaginatedTransactions> getTransactionsByAccount(
    String accountId, {
    int page = 1,
    int limit = 10,
    String? txCode,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (txCode != null) params['txCode'] = txCode;
      final response = await _dio.get(
        ApiConstants.transactionsByAccount(accountId),
        queryParameters: params,
      );
      
      if (response.statusCode == 200) {
        return PaginatedTransactions.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load transactions: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to load transactions: ${e.message}');
    }
  }

  Future<PaginatedTransactions> getTransactionsByAccountAndYear(
    String accountId,
    int year, {
    int page = 1,
    int limit = 10,
    String? txCode,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (txCode != null) params['txCode'] = txCode;
      final response = await _dio.get(
        ApiConstants.transactionsByAccountAndYear(accountId, year),
        queryParameters: params,
      );
      
      if (response.statusCode == 200) {
        return PaginatedTransactions.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load transactions: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to load transactions: ${e.message}');
    }
  }
}
