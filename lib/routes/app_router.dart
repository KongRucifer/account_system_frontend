import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/accounts/presentation/pages/accounts_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/transactions/presentation/pages/transactions_page.dart';
import '../features/debug/log_viewer_page.dart';
import '../features/notifications/notifications_page.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: '/accounts',
        name: 'accounts',
        builder: (context, state) => const AccountsPage(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) {
          final extra = state.extra;
          String? accNumber;
          String? accountType;
          if (extra is Map) {
            accNumber = extra['accNumber'] as String?;
            accountType = extra['accountType'] as String?;
          } else if (extra is String) {
            accNumber = extra;
          }
          if (accNumber == null) {
            return const Scaffold(
              body: Center(child: Text('Account number required')),
            );
          }
          return DashboardPage(accNumber: accNumber, accountType: accountType);
        },
      ),
      GoRoute(
        path: '/transactions',
        name: 'transactions',
        builder: (context, state) {
          final extra = state.extra;
          String? accNumber;
          String? accountType;
          if (extra is Map) {
            accNumber = extra['accNumber'] as String?;
            accountType = extra['accountType'] as String?;
          } else if (extra is String) {
            accNumber = extra;
          }
          if (accNumber == null) {
            return const Scaffold(
              body: Center(child: Text('Account number required')),
            );
          }
          return TransactionsPage(accNumber: accNumber, accountType: accountType);
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/logs',
        name: 'logs',
        builder: (context, state) => const LogViewerPage(),
      ),
    ],
    redirect: (context, state) {
      // You can add auth redirect logic here
      // For now, we allow all navigation
      return null;
    },
  );
}
