import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/lang_toggle_button.dart';
import '../../data/models/dashboard_model.dart';
import '../controllers/dashboard_controller.dart';

class DashboardPage extends ConsumerStatefulWidget {
  final String accNumber;

  const DashboardPage({
    super.key,
    required this.accNumber,
  });

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardControllerProvider.notifier).loadDashboard(widget.accNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'lo_LA',
      symbol: '₭',
      decimalDigits: 0,
    );

    final s = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.dashboard),
        actions: const [LangToggleButton(), SizedBox(width: 8)],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${state.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(dashboardControllerProvider.notifier)
                              .loadDashboard(widget.accNumber);
                        },
                        child: Text(s.retry),
                      ),
                    ],
                  ),
                )
              : state.data == null
                  ? Center(child: Text(s.noData))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Account Info Card
                          _AccountCard(
                            account: state.data!.account,
                            currencyFormat: currencyFormat,
                          ),
                          const SizedBox(height: 16),

                          // Account Owners Card
                          _OwnersCard(
                            owners: state.data!.account.owners,
                          ),
                          const SizedBox(height: 16),

                          // Financial Summary
                          _SummaryCard(
                            summary: state.data!.financialSummary,
                            currencyFormat: currencyFormat,
                          ),
                          const SizedBox(height: 16),

                          // Loan Section (if exists)
                          if (state.data!.loan != null) ...[
                            _LoanCard(
                              loan: state.data!.loan!,
                              currencyFormat: currencyFormat,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Savings Section (if exists)
                          if (state.data!.savings != null) ...[
                            _SavingsCard(
                              savings: state.data!.savings!,
                              currencyFormat: currencyFormat,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // View Transactions Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.push('/transactions', extra: widget.accNumber);
                              },
                              icon: const Icon(Icons.list),
                              label: Text(s.viewTransactions),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  final AccountInfo account;
  final NumberFormat currencyFormat;

  const _AccountCard({
    required this.account,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(languageProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.accountInfo,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _InfoRow(s.accountNumber, account.accNumber),
            _InfoRow(s.langCode == 'lo' ? 'ຊື່:' : 'Name:', account.displayName),
            _InfoRow(s.accountType, account.accountType ?? 'N/A'),
            _InfoRow(s.branch, account.vbName ?? account.vbCode),
            _InfoRow(
              s.currentBalance,
              currencyFormat.format(account.currentBalance),
              isHighlight: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  final FinancialSummary summary;
  final NumberFormat currencyFormat;

  const _SummaryCard({
    required this.summary,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(languageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.financialSummary,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _InfoRow(
              s.currentBalance,
              currencyFormat.format(summary.currentBalance),
            ),
            _InfoRow(
              s.totalLoan,
              currencyFormat.format(summary.totalLoanAmount),
              valueColor: Colors.orange,
            ),
            _InfoRow(
              s.loanOutstanding,
              currencyFormat.format(summary.loanOutstanding),
              valueColor: Colors.red,
            ),
            _InfoRow(
              s.savingsBalance,
              currencyFormat.format(summary.savingsBalance),
              valueColor: Colors.green,
            ),
            const Divider(),
            _InfoRow(
              s.netPosition,
              currencyFormat.format(summary.netPosition),
              isHighlight: true,
              valueColor: summary.netPosition >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanCard extends ConsumerWidget {
  final LoanInfo loan;
  final NumberFormat currencyFormat;

  const _LoanCard({
    required this.loan,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(languageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark
          ? Colors.orange.shade900.withOpacity(0.25)
          : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance,
                    color: isDark ? Colors.orange.shade300 : Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  s.loanInfo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _InfoRow(s.totalLoan, currencyFormat.format(loan.totalLoanAmount)),
            _InfoRow(
              s.loanOutstanding,
              currencyFormat.format(loan.loanOutstanding),
              isHighlight: true,
              valueColor: Colors.red,
            ),
            _InfoRow(s.interestDue, currencyFormat.format(loan.interestDue)),
            _InfoRow(s.interestPaid, currencyFormat.format(loan.interestPaid)),
            _InfoRow(s.interestRate, '${loan.interestRate}%'),
            _InfoRow(s.loanPeriod, '${loan.loanPeriodMonths} ${s.months}'),
            if (loan.repaymentType != null)
              _InfoRow(s.repaymentType, loan.repaymentType!),
            _InfoRow(s.status, loan.status),
          ],
        ),
      ),
    );
  }
}

class _SavingsCard extends ConsumerWidget {
  final SavingsInfo savings;
  final NumberFormat currencyFormat;

  const _SavingsCard({
    required this.savings,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(languageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark
          ? Colors.green.shade900.withOpacity(0.25)
          : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.savings,
                    color: isDark ? Colors.green.shade300 : Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  s.savingsInfo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _InfoRow(
              s.currentBalance,
              currencyFormat.format(savings.currentBalance),
              isHighlight: true,
              valueColor: Colors.green,
            ),
            if (savings.savingAmount != null)
              _InfoRow(
                s.langCode == 'lo' ? 'ຝາກຄັ້ງຫຼ້າສຸດ:' : 'Last Deposit:',
                currencyFormat.format(savings.savingAmount!),
              ),
            if (savings.withdrawalAmount != null)
              _InfoRow(
                s.langCode == 'lo' ? 'ຖອນຄັ້ງຫຼ້າສຸດ:' : 'Last Withdrawal:',
                currencyFormat.format(savings.withdrawalAmount!),
              ),
            _InfoRow(
              s.langCode == 'lo' ? 'ດອກເບ້ຍສະສົມ:' : 'Interest Numerator:',
              currencyFormat.format(savings.interestNumerator),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnersCard extends ConsumerWidget {
  final List<OwnerInfo> owners;

  const _OwnersCard({required this.owners});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(languageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_outline,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  s.accountOwners,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${owners.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            if (owners.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(s.noOwners,
                      style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600)),
                ),
              )
            else
              ...owners.asMap().entries.map((entry) {
                final i = entry.key;
                final owner = entry.value;
                return Column(
                  children: [
                    if (i > 0) const Divider(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4)
                            : Theme.of(context).colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  owner.clientName.isNotEmpty
                                      ? owner.clientName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      owner.clientName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    if (owner.gender != null)
                                      Text(
                                        owner.gender!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: isDark
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade600),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(s.bankbookNo, owner.bankbookNumber),
                          if (owner.phoneNumber != null && owner.phoneNumber!.isNotEmpty)
                            _InfoRow(s.phone, owner.phoneNumber!),
                          if (owner.birthDate != null)
                            _InfoRow(
                              s.birthDate,
                              '${owner.birthDate!.day.toString().padLeft(2, '0')}/${owner.birthDate!.month.toString().padLeft(2, '0')}/${owner.birthDate!.year}',
                            ),
                          if (owner.clientType.isNotEmpty)
                            _InfoRow(s.clientType, owner.clientType),
                        ],
                      ),
                    ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final Color? valueColor;

  const _InfoRow(
    this.label,
    this.value, {
    this.isHighlight = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
              fontSize: isHighlight ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
