import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/repositories/dashboard_repository.dart';

// Provider
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return DashboardRepository(dioClient.dio);
});

// State
class DashboardState {
  final DashboardData? data;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    DashboardData? data,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Controller
class DashboardController extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardController(this._repository) : super(DashboardState());

  Future<void> loadDashboard(String accNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final data = await _repository.getAccountDashboard(accNumber);
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
}

// Provider for DashboardController
final dashboardControllerProvider = StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return DashboardController(repository);
});
