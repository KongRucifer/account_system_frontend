import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/audio_loop_service.dart';
import 'core/services/local_notification_service.dart';
import 'features/notifications/notification_provider.dart';
import 'features/notifications/notification_service.dart';
import 'routes/app_router.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  static ThemeData _lightTheme() => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );

  static ThemeData _darkTheme() => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey.shade900,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = AppRouter.router;
    final themeMode = ref.watch(themeProvider);

    return _AppLifecycleObserver(
      child: MaterialApp.router(
        title: 'Account System',
        debugShowCheckedModeBanner: false,
        theme: _lightTheme(),
        darkTheme: _darkTheme(),
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}

/// Static tracker for app lifecycle state.
/// Used by notification provider to skip showing local notifications when app is paused
/// (FCM background handler takes care of that case instead).
class AppLifecycleTracker {
  static bool _isInForeground = true;
  static bool get isInForeground => _isInForeground;

  static void _setForeground(bool value) {
    _isInForeground = value;
    debugPrint('📱 AppLifecycleTracker: isInForeground = $value');
  }
}

/// Observes app lifecycle to reconnect WebSocket and sync notifications on resume.
class _AppLifecycleObserver extends ConsumerStatefulWidget {
  final Widget child;
  const _AppLifecycleObserver({required this.child});

  @override
  ConsumerState<_AppLifecycleObserver> createState() =>
      _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<_AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        AppLifecycleTracker._setForeground(true);
        debugPrint('📱 App RESUMED — reconnecting WebSocket');
        // Reconnect WebSocket (it may have been paused/killed by OS)
        NotificationWebSocketService().reconnect();
        // Delay refresh to avoid racing with mark-as-read API call
        // (notification tap triggers mark-as-read, then app resumes)
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            debugPrint('📱 App RESUMED — delayed refresh');
            ref.read(notificationsProvider.notifier).refresh();
          }
        });
        break;
      case AppLifecycleState.paused:
        AppLifecycleTracker._setForeground(false);
        debugPrint('📱 App PAUSED');
        break;
      case AppLifecycleState.inactive:
        debugPrint('📱 App INACTIVE');
        break;
      case AppLifecycleState.detached:
        AppLifecycleTracker._setForeground(false);
        debugPrint('📱 App DETACHED');
        // Cleanup notifications and stop sound
        LocalNotificationService.cancelAll();
        AudioLoopService.stopLoop();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
