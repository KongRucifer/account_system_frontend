import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

// Provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return TransactionRepository(dioClient.dio);
});

// State
class TransactionState {
  final PaginatedTransactions? data;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int? selectedYear;

  TransactionState({
    this.data,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.selectedYear,
  });

  TransactionState copyWith({
    PaginatedTransactions? data,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? selectedYear,
  }) {
    return TransactionState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      selectedYear: selectedYear ?? this.selectedYear,
    );
  }
}

// Controller
class TransactionController extends StateNotifier<TransactionState> {
  final TransactionRepository _repository;

  TransactionController(this._repository) : super(TransactionState());

  Future<void> loadTransactions(
    String accountId, {
    int page = 1,
    int? year,
  }) async {
    state = state.copyWith(isLoading: true, error: null, currentPage: page);
    
    try {
      PaginatedTransactions data;
      
      if (year != null) {
        data = await _repository.getTransactionsByAccountAndYear(
          accountId,
          year,
          page: page,
        );
      } else {
        data = await _repository.getTransactionsByAccount(
          accountId,
          page: page,
        );
      }
      
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  void setYear(int? year) {
    state = state.copyWith(selectedYear: year);
  }

  Future<void> loadNextPage(String accountId) async {
    if (state.data?.pagination.hasNextPage ?? false) {
      await loadTransactions(
        accountId,
        page: state.currentPage + 1,
        year: state.selectedYear,
      );
    }
  }
}

// Provider for TransactionController
final transactionControllerProvider = StateNotifierProvider<TransactionController, TransactionState>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionController(repository);
});
