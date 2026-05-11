import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/lang_toggle_button.dart';
import '../../data/models/transaction_model.dart';
import '../controllers/transaction_controller.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  final String accNumber;
  final String? accountType;

  const TransactionsPage({
    super.key,
    required this.accNumber,
    this.accountType,
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
          // Combined filters row
          _FilterBar(
            selectedYear: state.selectedYear,
            availableYears: _availableYears,
            selectedTxCode: state.selectedTxCode,
            accountType: widget.accountType,
            onYearSelected: (year) {
              final notifier = ref.read(transactionControllerProvider.notifier);
              notifier.setYear(year);
              notifier.loadTransactions(
                widget.accNumber,
                year: year,
                txCode: state.selectedTxCode,
              );
            },
            onTxCodeSelected: (code) {
              final notifier = ref.read(transactionControllerProvider.notifier);
              notifier.setTxCode(code);
              notifier.loadTransactions(
                widget.accNumber,
                year: state.selectedYear,
                txCode: code,
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
                                      txCode: state.selectedTxCode,
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
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            itemCount: state.data!.results.length,
                            itemBuilder: (context, index) {
                              final transaction = state.data!.results[index];
                              return _TransactionCard(
                                transaction: transaction,
                                currencyFormat: currencyFormat,
                                dateFormat: dateFormat,
                              );
                            },
                          ),
          ),

          // Pagination bar
          if (state.data != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ◀ Previous
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: state.isLoading ||
                            !state.data!.pagination.hasPreviousPage
                        ? null
                        : () => ref
                            .read(transactionControllerProvider.notifier)
                            .loadPreviousPage(widget.accNumber),
                    tooltip: s.langCode == 'lo' ? 'ໜ້າກ່ອນ' : 'Previous',
                  ),

                  // Page info
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${s.page} ${state.data!.pagination.page} ${s.of} ${state.data!.pagination.totalPages}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${s.total}: ${state.data!.pagination.total} ${s.transactions}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),

                  // ▶ Next
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: state.isLoading ||
                            !state.data!.pagination.hasNextPage
                        ? null
                        : () => ref
                            .read(transactionControllerProvider.notifier)
                            .loadNextPage(widget.accNumber),
                    tooltip: s.langCode == 'lo' ? 'ໜ້າຕໍ່ໄປ' : 'Next',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  final int? selectedYear;
  final Set<int> availableYears;
  final String? selectedTxCode;
  final String? accountType;
  final Function(int?) onYearSelected;
  final Function(String?) onTxCodeSelected;

  const _FilterBar({
    required this.selectedYear,
    required this.availableYears,
    required this.selectedTxCode,
    required this.accountType,
    required this.onYearSelected,
    required this.onTxCodeSelected,
  });

  // ກວດວ່າ account ເປັນ ເງິນກູ້ ຫຼື ເງິນຝາກ
  bool get _isLoan {
    final t = accountType?.toLowerCase() ?? '';
    return t.contains('loan') || t.contains('ກູ');
  }

  Map<String, String> get _txOptions {
    if (_isLoan) {
      return {
        '1011': 'ຊຳລະຕົ້ນທຶນ',
        '1012': 'ຊຳລະດອກເບ້ຍ',
        // '1201': 'ປ່ອຍກູ້',
        // '1010': 'ຊຳລະໜີ້',
      };
    }
    return {
      '2201': 'ເງິນຝາກ',
      '2202': 'ເງິນຖອນ',
      '2203': 'ເງິນປັບຜົນ',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(languageProvider);
    final sortedYears = availableYears.toList()..sort((a, b) => b.compareTo(a));
    final options = _txOptions;
    // Reset txCode if it doesn't belong to current account type options
    final effectiveTxCode =
        (selectedTxCode != null && options.containsKey(selectedTxCode))
            ? selectedTxCode
            : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // ── Year filter ──
          Icon(Icons.calendar_today_outlined,
              size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: selectedYear,
                isExpanded: true,
                isDense: true,
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                hint: Text(s.filterByYear,
                    style: const TextStyle(fontSize: 13)),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(s.allYears,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  ...sortedYears.map((year) => DropdownMenuItem<int?>(
                        value: year,
                        child: Text(year.toString(),
                            style: const TextStyle(fontSize: 13)),
                      )),
                ],
                onChanged: onYearSelected,
              ),
            ),
          ),

          const SizedBox(width: 8),
          Container(width: 1, height: 28,
              color: Theme.of(context).dividerColor),
          const SizedBox(width: 8),

          // ── Type filter ──
          Icon(Icons.filter_list_outlined,
              size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: effectiveTxCode,
                isExpanded: true,
                isDense: true,
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                hint: const Text('ທັງໝົດ',
                    style: TextStyle(fontSize: 13)),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('ທັງໝົດ',
                        style: TextStyle(fontSize: 13)),
                  ),
                  ...options.entries.map(
                    (e) => DropdownMenuItem<String?>(
                      value: e.key,
                      child: Text(e.value,
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
                onChanged: onTxCodeSelected,
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
    final code = transaction.transactionCode?.transactionCode;

    final Color badgeBg;
    final Color badgeFg;
    final Color amountColor;
    final String badgeLabel;

    switch (code) {
      case '2201':
        badgeBg     = Colors.green.shade100;
        badgeFg     = Colors.green.shade800;
        amountColor = Colors.green.shade700;
        badgeLabel  = 'ເງິນຝາກ';
        break;
      case '2202':
        badgeBg     = Colors.red.shade100;
        badgeFg     = Colors.red.shade800;
        amountColor = Colors.red.shade700;
        badgeLabel  = 'ເງິນຖອນ';
        break;
      case '2203':
        badgeBg     = Colors.blue.shade100;
        badgeFg     = Colors.blue.shade800;
        amountColor = Colors.blue.shade700;
        badgeLabel  = 'ເງິນປັບຜົນ';
        break;
      case '1011':
        badgeBg     = Colors.green.shade100;
        badgeFg     = Colors.green.shade800;
        amountColor = Colors.green.shade700;
        badgeLabel  = 'ຊຳລະຕົ້ນທຶນ';
        break;
      case '1012':
        badgeBg     = Colors.orange.shade100;
        badgeFg     = Colors.orange.shade800;
        amountColor = Colors.orange.shade700;
        badgeLabel  = 'ຊຳລະດອກເບ້ຍ';
        break;
      case '1201':
        badgeBg     = Colors.green.shade100;
        badgeFg     = Colors.green.shade800;
        amountColor = Colors.green.shade700;
        badgeLabel  = 'ປ່ອຍກູ້';
        break;
      case '1010':
        badgeBg     = Colors.orange.shade100;
        badgeFg     = Colors.orange.shade800;
        amountColor = Colors.orange.shade700;
        badgeLabel  = 'ຊຳລະໜີ້';
        break;
      default:
        badgeBg     = Colors.grey.shade200;
        badgeFg     = Colors.grey.shade700;
        amountColor = Colors.grey.shade700;
        badgeLabel  = code ?? '-';
        break;
    }

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
                  child: Tooltip(
                    message: transaction.transactionCode?.displayName ?? 'Transaction',
                    child: Text(
                      transaction.transactionCode?.displayName ?? 'Transaction',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      color: badgeFg,
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
                    color: amountColor,
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

