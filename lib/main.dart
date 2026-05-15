import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/providers/core_providers.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/storage_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    debugPrint('🚀 Starting app initialization...');
    
    // Initialize Storage Service
    final storage = StorageService();
    await storage.init();
    debugPrint('✅ Storage initialized');
    
    // Set instance for provider to use (singleton pattern)
    setStorageServiceInstance(storage);
    
    // Initialize Firebase (core only)
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');
    
    // Set background message handler (required for background notifications)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('✅ Background handler set');
    
    // Initialize local notifications
    await LocalNotificationService.initialize();
    debugPrint('✅ Local notifications initialized');
    
    await dotenv.load(fileName: '.env');
    debugPrint('✅ Environment loaded');
    
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
