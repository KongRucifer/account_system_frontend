import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/lang_toggle_button.dart';
import '../../../notifications/notification_badge.dart';
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
        ref.read(accountControllerProvider.notifier).loadAccounts(
          user.bankbookNumber,
          user.vbCode ?? '',
        );
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
          const NotificationBadge(),
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
                                .loadAccounts(
                                  user.bankbookNumber,
                                  user.vbCode ?? '',
                                );
                          }
                        },
                        child: Text(s.retry),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // ── Bankbook info card ──────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: _BankbookCard(
                          bankbookNumber: accountState.bankbookNumber,
                          vbCode: accountState.vbCode ?? '',
                          username: accountState.username,
                        ),
                      ),
                    ),

                    // ── Client cards ────────────────────────────────────
                    if (accountState.accountOwners.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ClientCard(
                                  owner: accountState.accountOwners[index]),
                            ),
                            childCount: accountState.accountOwners.length,
                          ),
                        ),
                      ),

                    // ── ບັນຊິເງີນຝາກ (Savings) section ─────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Row(
                          children: [
                            Icon(Icons.savings_outlined,
                                size: 18, color: Colors.green.shade700),
                            const SizedBox(width: 6),
                            Text(
                              s.langCode == 'lo'
                                  ? 'ບັນຊິເງີນຝາກ'
                                  : 'Savings Accounts',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    accountState.savingsAccounts.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Text(
                                s.noAccountsFound,
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final account =
                                      accountState.savingsAccounts[index];
                                  return _AccountCard(
                                    account: account,
                                    accentColor: Colors.green.shade700,
                                    onTap: () => context.push(
                                      '/dashboard',
                                      extra: {
                                        'accNumber': account.accNumber,
                                        'accountType': account.accountType ?? '',
                                      },
                                    ),
                                  );
                                },
                                childCount: accountState.savingsAccounts.length,
                              ),
                            ),
                          ),

                    // ── ບັນຊີເງີນກູ້ (Loans) section ───────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_outlined,
                                size: 18, color: Colors.orange.shade700),
                            const SizedBox(width: 6),
                            Text(
                              s.langCode == 'lo'
                                  ? 'ບັນຊີເງີນກູ້'
                                  : 'Loan Accounts',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    accountState.loanAccounts.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(
                                s.noAccountsFound,
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final account =
                                      accountState.loanAccounts[index];
                                  return _AccountCard(
                                    account: account,
                                    accentColor: Colors.orange.shade700,
                                    onTap: () => context.push(
                                      '/dashboard',
                                      extra: {
                                        'accNumber': account.accNumber,
                                        'accountType': account.accountType ?? '',
                                      },
                                    ),
                                  );
                                },
                                childCount: accountState.loanAccounts.length,
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
  final Color? accentColor;

  const _AccountCard({
    required this.account,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(languageProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'lo_LA',
      symbol: '₭',
      decimalDigits: 0,
    );

    final accent = accentColor ?? Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accent, width: 4),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
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
                          s.langCode == 'lo'
                              ? (account.accNameLao ?? account.accNameEng ?? '')
                              : (account.accNameEng ?? account.accNameLao ?? ''),
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
              // if (account.accountType != null) ...[
              //   const SizedBox(height: 8),
              //   Text(
              //     account.accountType!,
              //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
              //       color: Colors.grey,
              //     ),
              //   ),
              // ],
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _BankbookCard extends ConsumerWidget {
  final String bankbookNumber;
  final String vbCode;
  final String? username;

  const _BankbookCard({
    required this.bankbookNumber,
    required this.vbCode,
    this.username,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(languageProvider);
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.book_outlined,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoChip(
                    icon: Icons.book_outlined,
                    label: s.langCode == 'lo'
                        ? 'ເລກບັນຊີ: $bankbookNumber'
                        : 'Bankbook: $bankbookNumber',
                  ),
                  const SizedBox(height: 4),
                  _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: s.langCode == 'lo'
                        ? 'ລະຫັດບ້ານ: $vbCode'
                        : 'Village Code: $vbCode',
                  ),
                  if (username != null && username!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _InfoChip(
                      icon: Icons.person_outline,
                      label: s.langCode == 'lo'
                          ? 'ຊື່ຜູ້ໃຊ້: $username'
                          : 'Username: $username',
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

class _ClientCard extends ConsumerWidget {
  final AccountOwnerInfo owner;
  const _ClientCard({required this.owner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(languageProvider);
    final fullName = owner.fullName;
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  Theme.of(context).colorScheme.secondaryContainer,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName.isNotEmpty ? fullName : (owner.nickName ?? '-'),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (owner.nickName != null &&
                      owner.nickName!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    _InfoChip(
                      icon: Icons.badge_outlined,
                      label: s.langCode == 'lo'
                          ? 'ຊື່ຫຼິ້ນ: ${owner.nickName}'
                          : 'Nickname: ${owner.nickName}',
                    ),
                  ],
                  if (owner.phoneNumber != null &&
                      owner.phoneNumber!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    _InfoChip(
                        icon: Icons.phone_outlined,
                        label: owner.phoneNumber!),
                  ],
                  if (owner.gender != null && owner.gender!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    _InfoChip(
                        icon: Icons.wc_outlined, label: owner.gender!),
                  ],
                  if (owner.birthDate != null) ...[
                    const SizedBox(height: 2),
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
