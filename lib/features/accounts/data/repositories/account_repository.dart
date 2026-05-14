import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/account_model.dart';

class AccountRepository {
  final Dio _dio;

  AccountRepository(this._dio);

  Future<AccountsResponse> getAccountsByUser(String bankbookNumber, String vbCode) async {
    try {
      final response = await _dio.get(
        ApiConstants.accountsByUser(bankbookNumber, vbCode),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return AccountsResponse.fromJson(data);
        }
        return AccountsResponse();
      } else {
        throw Exception('Failed to load accounts: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to load accounts: ${e.message}');
    }
  }
}
