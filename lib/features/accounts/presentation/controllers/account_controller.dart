import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/models/account_model.dart';
import '../../data/repositories/account_repository.dart';

// Provider
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AccountRepository(dioClient.dio);
});

// State
class AccountState {
  final List<Account> accounts;
  final AccountOwnerInfo? accountOwner;
  final bool isLoading;
  final String? error;

  AccountState({
    this.accounts = const [],
    this.accountOwner,
    this.isLoading = false,
    this.error,
  });

  AccountState copyWith({
    List<Account>? accounts,
    AccountOwnerInfo? accountOwner,
    bool? isLoading,
    String? error,
  }) {
    return AccountState(
      accounts: accounts ?? this.accounts,
      accountOwner: accountOwner ?? this.accountOwner,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Controller
class AccountController extends StateNotifier<AccountState> {
  final AccountRepository _repository;

  AccountController(this._repository) : super(AccountState());

  Future<void> loadAccounts(String clientId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getAccountsByUser(clientId);
      state = AccountState(
        accounts: result.myAccounts,
        accountOwner: result.accountOwner,
        isLoading: false,
      ); 
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
}

// Provider for AccountController
final accountControllerProvider = StateNotifierProvider<AccountController, AccountState>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return AccountController(repository);
});
