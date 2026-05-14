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
  final String bankbookNumber;
  final String? vbCode;
  final String? username;
  final List<AccountOwnerInfo> accountOwners;
  final List<Account> savingsAccounts;
  final List<Account> loanAccounts;
  final bool isLoading;
  final String? error;

  AccountState({
    this.bankbookNumber = '',
    this.vbCode,
    this.username,
    this.accountOwners = const [],
    this.savingsAccounts = const [],
    this.loanAccounts = const [],
    this.isLoading = false,
    this.error,
  });

  List<Account> get accounts => [...savingsAccounts, ...loanAccounts];

  AccountState copyWith({
    String? bankbookNumber,
    String? vbCode,
    String? username,
    List<AccountOwnerInfo>? accountOwners,
    List<Account>? savingsAccounts,
    List<Account>? loanAccounts,
    bool? isLoading,
    String? error,
  }) {
    return AccountState(
      bankbookNumber: bankbookNumber ?? this.bankbookNumber,
      vbCode: vbCode ?? this.vbCode,
      username: username ?? this.username,
      accountOwners: accountOwners ?? this.accountOwners,
      savingsAccounts: savingsAccounts ?? this.savingsAccounts,
      loanAccounts: loanAccounts ?? this.loanAccounts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Controller
class AccountController extends StateNotifier<AccountState> {
  final AccountRepository _repository;

  AccountController(this._repository) : super(AccountState());

  Future<void> loadAccounts(String bankbookNumber, String vbCode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getAccountsByUser(bankbookNumber, vbCode);
      state = AccountState(
        bankbookNumber: result.bankbookNumber,
        vbCode: result.vbCode,
        username: result.username,
        accountOwners: result.accountOwners,
        savingsAccounts: result.savingsAccounts,
        loanAccounts: result.loanAccounts,
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
