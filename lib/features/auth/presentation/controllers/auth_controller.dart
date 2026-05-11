import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/models/login_request.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRepository(dioClient.dio);
});

// Auth State
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Auth Controller
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final StorageService _storage;

  AuthController(this._repository, this._storage) : super(AuthState());

  Future<bool> login(String bankbookNumber, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final request = LoginRequest(
        bankbookNumber: bankbookNumber,
        password: password,
      );
      
      final user = await _repository.login(request);
      
      // Save tokens for mobile app (web uses cookies)
      if (!kIsWeb) {
        if (user.accessToken != null) {
          await _storage.saveToken(user.accessToken!);
        }
        if (user.refreshToken != null) {
          await _storage.saveRefreshToken(user.refreshToken!);
        }
      }
      
      // Save user data
      await _storage.saveUser(user.toJson());
      
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      final raw = e.toString();
      final msg = raw.startsWith('Exception: ') ? raw.substring(11) : raw;
      state = state.copyWith(error: msg, isLoading: false);
      return false;
    }
  }

  Future<void> logout() async {
    // Call logout endpoint to revoke refresh token on server
    await _repository.logout();
    
    // Clear local storage
    await _storage.clearAll();
    state = AuthState();
  }

  Future<bool> refreshToken() async {
    try {
      final user = await _repository.refreshToken();
      
      if (user != null) {
        // Save new tokens for mobile app
        if (!kIsWeb) {
          if (user.accessToken != null) {
            await _storage.saveToken(user.accessToken!);
          }
          if (user.refreshToken != null) {
            await _storage.saveRefreshToken(user.refreshToken!);
          }
        }
        
        // Update user data
        await _storage.saveUser(user.toJson());
        state = state.copyWith(user: user);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> checkAuth() async {
    final userData = await _storage.getUser();
    if (userData != null) {
      state = state.copyWith(user: User.fromJson(userData));
    }
  }
}

// Provider for AuthController
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthController(repository, storage);
});
