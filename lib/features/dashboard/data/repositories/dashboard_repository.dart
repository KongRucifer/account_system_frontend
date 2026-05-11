import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<DashboardData> getAccountDashboard(String accNumber) async {
    try {
      final response = await _dio.get(
        ApiConstants.accountDashboard(accNumber),
      );
      
      if (response.statusCode == 200) {
        return DashboardData.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load dashboard: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to load dashboard: ${e.message}');
    }
  }
}
