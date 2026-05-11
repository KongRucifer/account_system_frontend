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
  final String? accountType;

  const DashboardPage({
    super.key,
    required this.accNumber,
    this.accountType,
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

                          // Financial Summary
                          // _SummaryCard(
                          //   summary: state.data!.financialSummary,
                          //   currencyFormat: currencyFormat,
                          // ),
                          // const SizedBox(height: 16),

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
                                context.push('/transactions', extra: {
                                  'accNumber': widget.accNumber,
                                  'accountType': widget.accountType ?? '',
                                });
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
