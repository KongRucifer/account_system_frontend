import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../services/storage_service.dart';

// Storage Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Dio Client Provider
final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return DioClient(storage);
});
