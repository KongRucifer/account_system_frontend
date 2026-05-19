import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/providers/core_providers.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/storage_service.dart';
import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    debugPrint('🚀 Starting app initialization...');

    // Load .env FIRST so API_BASE_URL is available for everything below
    await dotenv.load(fileName: '.env');
    debugPrint('✅ Environment loaded: ${dotenv.env['API_BASE_URL']}');
    
    // Initialize Storage Service
    final storage = StorageService();
    await storage.init();
    debugPrint('✅ Storage initialized');
    
    // Set instance for provider to use (singleton pattern)
    setStorageServiceInstance(storage);
    
    // Initialize Firebase with explicit options (required for release builds)
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('✅ Firebase initialized');
    
    // Set background message handler (required for background notifications)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('✅ Background handler set');
    
    // Initialize local notifications
    await LocalNotificationService.initialize();
    debugPrint('✅ Local notifications initialized');

    // Explicitly request notification permission (shows dialog on Android 13+)
    await _requestNotificationPermission();
    
    debugPrint('🎬 Running app...');
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('❌ FATAL ERROR during initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

/// Request notification permission explicitly (shows dialog on Android 13+)
Future<void> _requestNotificationPermission() async {
  try {
    final androidPlugin = LocalNotificationService.notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // For Android 13+ (API 33+), this shows the permission dialog
      final granted = await androidPlugin.requestNotificationsPermission();
      debugPrint('🔔 Notification permission dialog shown');
      debugPrint('🔔 Permission result: ${granted == true ? 'GRANTED' : 'DENIED'}');
    }
  } catch (e) {
    debugPrint('❌ Error requesting notification permission: $e');
  }
}
