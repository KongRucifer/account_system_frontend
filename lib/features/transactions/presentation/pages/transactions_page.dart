import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/l10n/app_strings.dart';
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
  Set<int> get _availableYears {
    final currentYear = DateTime.now().year;
    return Set<int>.from(
      List.generate(currentYear - 2021 + 1, (i) => currentYear - i),
    );
  }

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

  bool get _isLoan {
    final t = accountType?.toLowerCase() ?? '';
    return t.contains('loan') || t.contains('ກູ');
  }

  Map<String, String> get _txOptions {
    if (_isLoan) {
      return {
        '1010': 'ຊຳລະຕົ້ນທຶນ',
        '1001': 'ຊຳລະດອກເບ້ຍ',
        '1201': 'ປ່ອຍກູ້',
      };
    }
    return {
      '1006': 'ເງິນຝາກ',
      '3101': 'ເງິນຖອນ',
      '6410': 'ເງິນປັບຜົນ',
    };
  }

  Future<void> _openYearPicker(BuildContext context, AppStrings s, List<int> sortedYears) async {
    final result = await showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _YearPickerSheet(
        sortedYears: sortedYears,
        selectedYear: selectedYear,
        allYearsLabel: s.allYears,
      ),
    );
    if (result != null && result == -1) {
      onYearSelected(null);
    } else if (result != null) {
      onYearSelected(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(languageProvider);
    final sortedYears = availableYears.toList()..sort((a, b) => b.compareTo(a));
    final options = _txOptions;
    final effectiveTxCode =
        (selectedTxCode != null && options.containsKey(selectedTxCode))
            ? selectedTxCode
            : null;

    final yearLabel = selectedYear != null
        ? selectedYear.toString()
        : s.allYears;

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
          // ── Year filter (custom picker) ──
          Icon(Icons.calendar_today_outlined,
              size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _openYearPicker(context, s, sortedYears),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        yearLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: selectedYear != null
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).hintColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),
          Container(width: 1, height: 28, color: Theme.of(context).dividerColor),
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
                hint: const Text('ທັງໝົດ', style: TextStyle(fontSize: 13)),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('ທັງໝົດ', style: TextStyle(fontSize: 13)),
                  ),
                  ...options.entries.map(
                    (e) => DropdownMenuItem<String?>(
                      value: e.key,
                      child: Text(e.value, style: const TextStyle(fontSize: 13)),
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

class _YearPickerSheet extends StatefulWidget {
  final List<int> sortedYears;
  final int? selectedYear;
  final String allYearsLabel;

  const _YearPickerSheet({
    required this.sortedYears,
    required this.selectedYear,
    required this.allYearsLabel,
  });

  @override
  State<_YearPickerSheet> createState() => _YearPickerSheetState();
}

class _YearPickerSheetState extends State<_YearPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<int> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.sortedYears;
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.sortedYears;
      } else {
        _filtered = widget.sortedYears
            .where((y) => y.toString().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final manualYear = int.tryParse(query);
    final canApplyManual = manualYear != null &&
        manualYear >= 2000 &&
        manualYear <= DateTime.now().year + 1 &&
        !widget.sortedYears.contains(manualYear);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'ຄົ້ນຫາ / ພິມປີ (e.g. 2024)',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // ── Reset button ──
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: query.isNotEmpty
                        ? () => _searchController.clear()
                        : null,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('ລີເຊັດ', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // ── Search/Apply button ──
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: (manualYear != null &&
                            manualYear >= 2000 &&
                            manualYear <= DateTime.now().year + 1)
                        ? () => Navigator.pop(context, manualYear)
                        : null,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('ກົດເພື່ອຄົ້ນຫາ',
                        style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                // ── All years option ──
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.calendar_view_month_outlined,
                    size: 20,
                    color: widget.selectedYear == null
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(
                    widget.allYearsLabel,
                    style: TextStyle(
                      fontWeight: widget.selectedYear == null
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: widget.selectedYear == null
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, -1),
                ),
                const Divider(height: 1),
                // ── Manual year apply (if typed a year not in list) ──
                if (canApplyManual)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.add_circle_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text(
                      'ໃຊ້ປີ $manualYear',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, manualYear),
                  ),
                // ── Filtered year list ──
                ..._filtered.map(
                  (year) => ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: widget.selectedYear == year
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(
                      year.toString(),
                      style: TextStyle(
                        fontWeight: widget.selectedYear == year
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: widget.selectedYear == year
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    trailing: widget.selectedYear == year
                        ? Icon(Icons.check,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () => Navigator.pop(context, year),
                  ),
                ),
                if (_filtered.isEmpty && !canApplyManual)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'ບໍ່ພົບປີ',
                      style: TextStyle(color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
              ],
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
      case '1006':
        badgeBg     = Colors.green.shade100;
        badgeFg     = Colors.green.shade800;
        amountColor = Colors.green.shade700;
        badgeLabel  = 'ເງິນຝາກ';
        break;
      case '3101':
        badgeBg     = Colors.red.shade100;
        badgeFg     = Colors.red.shade800;
        amountColor = Colors.red.shade700;
        badgeLabel  = 'ເງິນຖອນ';
        break;
      case '6410':
        badgeBg     = Colors.blue.shade100;
        badgeFg     = Colors.blue.shade800;
        amountColor = Colors.blue.shade700;
        badgeLabel  = 'ເງິນປັບຜົນ';
        break;
      case '1010':
        badgeBg     = Colors.green.shade100;
        badgeFg     = Colors.green.shade800;
        amountColor = Colors.green.shade700;
        badgeLabel  = 'ຊຳລະຕົ້ນທຶນ';
        break;
      case '1001':
       badgeBg     = Colors.blue.shade100;
        badgeFg     = Colors.blue.shade800;
        amountColor = Colors.blue.shade700;
        badgeLabel  = 'ຊຳລະດອກເບ້ຍ';
        break;
      case '1201':
        badgeBg     = Colors.orange.shade100;
        badgeFg     = Colors.orange.shade800;
        amountColor = Colors.orange.shade700;
        badgeLabel  = 'ປ່ອຍກູ້';
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

