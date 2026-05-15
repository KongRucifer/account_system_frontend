import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../services/storage_service.dart';

// Storage singleton instance (initialized in main.dart)
StorageService? _storageServiceInstance;

void setStorageServiceInstance(StorageService instance) {
  _storageServiceInstance = instance;
}

// Storage Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  // Return the initialized instance from main.dart
  if (_storageServiceInstance != null) {
    return _storageServiceInstance!;
  }
  // Fallback: create and init new instance (shouldn't happen in normal flow)
  final storage = StorageService();
  storage.init();
  _storageServiceInstance = storage;
  return storage;
});

// Dio Client Provider
final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return DioClient(storage);
});
