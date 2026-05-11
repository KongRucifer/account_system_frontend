import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/accounts/presentation/pages/accounts_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/transactions/presentation/pages/transactions_page.dart';

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
        path: '/accounts',
        name: 'accounts',
        builder: (context, state) => const AccountsPage(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) {
          final accNumber = state.extra as String?;
          if (accNumber == null) {
            return const Scaffold(
              body: Center(child: Text('Account number required')),
            );
          }
          return DashboardPage(accNumber: accNumber);
        },
      ),
      GoRoute(
        path: '/transactions',
        name: 'transactions',
        builder: (context, state) {
          final accNumber = state.extra as String?;
          if (accNumber == null) {
            return const Scaffold(
              body: Center(child: Text('Account number required')),
            );
          }
          return TransactionsPage(accNumber: accNumber);
        },
      ),
    ],
    redirect: (context, state) {
      // You can add auth redirect logic here
      // For now, we allow all navigation
      return null;
    },
  );
}
