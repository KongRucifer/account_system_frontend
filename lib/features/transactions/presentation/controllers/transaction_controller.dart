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
  final String? selectedTxCode;

  TransactionState({
    this.data,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.selectedYear,
    this.selectedTxCode,
  });

  TransactionState copyWith({
    PaginatedTransactions? data,
    bool? isLoading,
    String? error,
    int? currentPage,
    Object? selectedYear = _sentinel,
    Object? selectedTxCode = _sentinel,
  }) {
    return TransactionState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      selectedYear: selectedYear == _sentinel
          ? this.selectedYear
          : selectedYear as int?,
      selectedTxCode: selectedTxCode == _sentinel
          ? this.selectedTxCode
          : selectedTxCode as String?,
    );
  }
}

const Object _sentinel = Object();

// Controller
class TransactionController extends StateNotifier<TransactionState> {
  final TransactionRepository _repository;

  TransactionController(this._repository) : super(TransactionState());

  Future<void> loadTransactions(
    String accountId, {
    int page = 1,
    int? year,
    String? txCode,
  }) async {
    state = state.copyWith(isLoading: true, error: null, currentPage: page);
    
    try {
      PaginatedTransactions data;
      
      if (year != null) {
        data = await _repository.getTransactionsByAccountAndYear(
          accountId,
          year,
          page: page,
          txCode: txCode,
        );
      } else {
        data = await _repository.getTransactionsByAccount(
          accountId,
          page: page,
          txCode: txCode,
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

  void setTxCode(String? txCode) {
    state = state.copyWith(selectedTxCode: txCode);
  }

  Future<void> loadNextPage(String accountId) async {
    if (state.data?.pagination.hasNextPage ?? false) {
      await loadTransactions(
        accountId,
        page: state.currentPage + 1,
        year: state.selectedYear,
        txCode: state.selectedTxCode,
      );
    }
  }

  Future<void> loadPreviousPage(String accountId) async {
    if (state.data?.pagination.hasPreviousPage ?? false) {
      await loadTransactions(
        accountId,
        page: state.currentPage - 1,
        year: state.selectedYear,
        txCode: state.selectedTxCode,
      );
    }
  }
}

// Provider for TransactionController
final transactionControllerProvider = StateNotifierProvider<TransactionController, TransactionState>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionController(repository);
});
