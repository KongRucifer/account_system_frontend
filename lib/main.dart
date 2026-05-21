import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/providers/core_providers.dart';
import 'core/services/app_logger.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/storage_service.dart';
import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    AppLogger.log('🚀 Starting app initialization...');

    // 1. Load .env FIRST so API_BASE_URL is available for everything below
    await dotenv.load(fileName: '.env');
    AppLogger.log('✅ Environment loaded: ${dotenv.env['API_BASE_URL']}');

    // 2. Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.log('✅ Firebase initialized');

    // 3. Register background message handler (must be top-level function)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 4. Initialize Local Notifications
    await LocalNotificationService.initialize();
    AppLogger.log('✅ Local notifications initialized');

    // 5. Initialize Storage Service
    final storage = StorageService();
    await storage.init();
    AppLogger.log('✅ Storage initialized');
    
    // Set instance for provider to use (singleton pattern)
    setStorageServiceInstance(storage);

    // 6. Initialize Firebase Messaging Service (FCM handlers + permission)
    await FirebaseMessagingService.initialize();
    AppLogger.log('✅ Firebase Messaging Service initialized');
    
    AppLogger.log('🎬 Running app...');
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    AppLogger.log('❌ FATAL ERROR during initialization: $e');
    AppLogger.log('Stack trace: $stackTrace');
    rethrow;
  }
}

