import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/lang_toggle_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/account_model.dart';
import '../controllers/account_controller.dart';

class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  @override
  void initState() {
    super.initState();
    // Load accounts when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).user;
      if (user != null) {
        ref.read(accountControllerProvider.notifier).loadAccounts(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final accountState = ref.watch(accountControllerProvider);
    final user = authState.user;

    final s = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myAccounts),
        actions: [
          const LangToggleButton(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: s.logout,
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: accountState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : accountState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${accountState.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (user != null) {
                            ref
                                .read(accountControllerProvider.notifier)
                                .loadAccounts(user.id);
                          }
                        },
                        child: Text(s.retry),
                      ),
                    ],
                  ),
                )
              : accountState.accounts.isEmpty
                  ? Center(child: Text(s.noAccountsFound))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: accountState.accounts.length,
                      itemBuilder: (context, index) {
                        final account = accountState.accounts[index];
                        return _AccountCard(
                          account: account,
                          onTap: () {
                            context.push('/dashboard', extra: account.accNumber);
                          },
                        );
                      },
                    ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  final Account account;
  final VoidCallback onTap;

  const _AccountCard({
    required this.account,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(languageProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'lo_LA',
      symbol: '₭',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.displayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Acc: ${account.accNumber}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: account.status == '1'
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      account.status == '1'
                          ? (s.langCode == 'lo' ? 'ເປີດໃຊ້' : 'Active')
                          : (s.langCode == 'lo' ? 'ປິດໃຊ້' : 'Inactive'),
                      style: TextStyle(
                        color: account.status == '1'
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.currentBalance,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(account.currentBalance),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: account.currentBalance >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              if (account.accountType != null) ...[
                const SizedBox(height: 8),
                Text(
                  account.accountType!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
