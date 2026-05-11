import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/lang_toggle_button.dart';
import '../../data/models/transaction_model.dart';
import '../controllers/transaction_controller.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  final String accNumber;

  const TransactionsPage({
    super.key,
    required this.accNumber,
  });

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final Set<int> _availableYears = {2025, 2024, 2023, 2022, 2021};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionControllerProvider.notifier).loadTransactions(
        widget.accNumber,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionControllerProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'lo_LA',
      symbol: '₭',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final s = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.transactionHistory),
        actions: const [LangToggleButton(), SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          // Year Filter
          _YearFilter(
            selectedYear: state.selectedYear,
            availableYears: _availableYears,
            onYearSelected: (year) {
              ref.read(transactionControllerProvider.notifier).setYear(year);
              ref.read(transactionControllerProvider.notifier).loadTransactions(
                widget.accNumber,
                year: year,
              );
            },
          ),

          // Transaction List
          Expanded(
            child: state.isLoading && state.data == null
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
                                    .read(transactionControllerProvider.notifier)
                                    .loadTransactions(
                                      widget.accNumber,
                                      year: state.selectedYear,
                                    );
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : state.data?.results.isEmpty ?? true
                        ? Center(child: Text(s.noTransactions))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.data!.results.length + 1,
                            itemBuilder: (context, index) {
                              if (index == state.data!.results.length) {
                                // Pagination
                                if (state.data!.pagination.hasNextPage) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: ElevatedButton(
                                      onPressed: state.isLoading
                                          ? null
                                          : () {
                                              ref
                                                  .read(transactionControllerProvider.notifier)
                                                  .loadNextPage(widget.accNumber);
                                            },
                                      child: state.isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : Text(s.loadMore),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }

                              final transaction = state.data!.results[index];
                              return _TransactionCard(
                                transaction: transaction,
                                currencyFormat: currencyFormat,
                                dateFormat: dateFormat,
                              );
                            },
                          ),
          ),

          // Pagination Info
          if (state.data != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${s.page} ${state.data!.pagination.page} ${s.of} ${state.data!.pagination.totalPages}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${s.total}: ${state.data!.pagination.total} ${s.transactions}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _YearFilter extends ConsumerWidget {
  final int? selectedYear;
  final Set<int> availableYears;
  final Function(int?) onYearSelected;

  const _YearFilter({
    required this.selectedYear,
    required this.availableYears,
    required this.onYearSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(languageProvider);
    final sortedYears = availableYears.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            s.filterByYear,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: selectedYear,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(s.allYears),
                  ),
                  ...sortedYears.map((year) => DropdownMenuItem<int?>(
                        value: year,
                        child: Text(year.toString()),
                      )),
                ],
                onChanged: (value) => onYearSelected(value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends ConsumerWidget {
  final Transaction transaction;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;

  const _TransactionCard({
    required this.transaction,
    required this.currencyFormat,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(languageProvider);
    final isPositive = transaction.amount >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    transaction.transactionCode?.displayName ?? 'Transaction',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPositive ? s.transactionIn : s.transactionOut,
                    style: TextStyle(
                      color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(transaction.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  currencyFormat.format(transaction.amount.abs()),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            if (transaction.description != null) ...[
              const SizedBox(height: 4),
              Text(
                transaction.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
