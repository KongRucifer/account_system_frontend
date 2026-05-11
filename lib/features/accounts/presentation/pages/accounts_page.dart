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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).user;
      if (user != null) {
        ref.read(accountControllerProvider.notifier).loadAccounts(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState  = ref.watch(authControllerProvider);
    final accountState = ref.watch(accountControllerProvider);
    final user = authState.user;
    final s    = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        centerTitle: false,
        title: Image.asset(
          'assets/images/logo.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        actions: [
          const LangToggleButton(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: s.logout,
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (mounted) context.go('/login');
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
              : CustomScrollView(
                  slivers: [
                    // ── Owner profile card (always first) ──────────────
                    if (accountState.accountOwner != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: _OwnerProfileCard(
                              owner: accountState.accountOwner!),
                        ),
                      ),

                    // ── Section header ──────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          s.myAccounts,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                      ),
                    ),

                    // ── Account list ────────────────────────────────────
                    accountState.accounts.isEmpty
                        ? SliverFillRemaining(
                            child: Center(child: Text(s.noAccountsFound)),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final account =
                                      accountState.accounts[index];
                                  return _AccountCard(
                                    account: account,
                                    onTap: () => context.push(
                                        '/dashboard',
                                        extra: {
                                          'accNumber': account.accNumber,
                                          'accountType': account.accountType ?? '',
                                        }),
                                  );
                                },
                                childCount: accountState.accounts.length,
                              ),
                            ),
                          ),
                  ],
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
                      color: account.status == '2'
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      account.status == '2'
                          ? (s.langCode == 'lo' ? 'ເປີດໃຊ້' : 'Active')
                          : (s.langCode == 'lo' ? 'ປິດໃຊ້' : 'Inactive'),
                      style: TextStyle(
                        color: account.status == '2'
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

class _OwnerProfileCard extends ConsumerWidget {
  final AccountOwnerInfo owner;
  const _OwnerProfileCard({required this.owner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(languageProvider);
    final initial = owner.clientName.isNotEmpty
        ? owner.clientName[0].toUpperCase()
        : '?';

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    owner.clientName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  _InfoChip(
                    icon: Icons.book_outlined,
                    label: s.langCode == 'lo'
                        ? 'ເລກສະໝຸດ: ${owner.bankbookNumber}'
                        : 'Bankbook: ${owner.bankbookNumber}',
                  ),
                  if (owner.phoneNumber != null &&
                      owner.phoneNumber!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _InfoChip(
                      icon: Icons.phone_outlined,
                      label: owner.phoneNumber!,
                    ),
                  ],
                  if (owner.gender != null &&
                      owner.gender!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _InfoChip(
                      icon: Icons.person_outline,
                      label: owner.gender!,
                    ),
                  ],
                  if (owner.birthDate != null) ...[
                    const SizedBox(height: 4),
                    _InfoChip(
                      icon: Icons.cake_outlined,
                      label:
                          '${owner.birthDate!.day.toString().padLeft(2, '0')}/'
                          '${owner.birthDate!.month.toString().padLeft(2, '0')}/'
                          '${owner.birthDate!.year}',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
