import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:4000/api/v1';
  
  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  
  // Accounts
  static const String accounts = '/accounts';
  static String accountsByUser(String userId) => '/accounts/user/$userId';
  static String accountDetail(String accNumber) => '/accounts/$accNumber/detail';
  
  // Dashboard
  static const String dashboard = '/dashboard';
  static String accountDashboard(String accNumber) => '/dashboard/account/$accNumber';
  static String accountQuickSummary(String accNumber) => '/dashboard/account/$accNumber/quick-summary';
  
  // Transactions
  static const String transactions = '/transactions';
  static String transactionsByAccount(String accountId) => '/transactions/account/$accountId';
  static String transactionsByAccountAndYear(String accountId, int year) => 
      '/transactions/account/$accountId/year/$year';
}
