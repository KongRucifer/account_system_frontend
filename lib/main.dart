import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/providers/core_providers.dart';
import 'core/services/storage_service.dart';
import 'core/services/app_logger.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    AppLogger.log('🚀 Starting app initialization...');

    // Load .env FIRST so API_BASE_URL is available for everything below
    await dotenv.load(fileName: '.env');
    AppLogger.log('✅ Environment loaded: ${dotenv.env['API_BASE_URL']}');
    
    // Initialize Storage Service
    final storage = StorageService();
    await storage.init();
    AppLogger.log('✅ Storage initialized');
    
    // Set instance for provider to use (singleton pattern)
    setStorageServiceInstance(storage);
    
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

