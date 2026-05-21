import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/app_logger.dart';

class LogViewerPage extends StatefulWidget {
  const LogViewerPage({super.key});

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> {
  List<String> _logs = [];
  List<String> _filteredLogs = [];
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await AppLogger.getLogs();
    setState(() {
      _logs = logs.reversed.toList();
      _applyFilter();
    });
  }

  void _applyFilter() {
    setState(() {
      _filteredLogs = _logs.where((log) {
        bool matchesSearch = _searchController.text.isEmpty || 
                           log.toLowerCase().contains(_searchController.text.toLowerCase());
        
        if (!matchesSearch) return false;
        
        switch (_selectedFilter) {
          case 'Notifications':
            return log.contains('🔔') || log.contains('FCM') || log.contains('BACKGROUND') || log.contains('FOREGROUND');
          case 'WebSocket':
            return log.contains('WebSocket') || log.contains('connect') || log.contains('disconnect');
          case 'Errors':
            return log.contains('❌') || log.contains('ERROR') || log.contains('Failed');
          case 'Success':
            return log.contains('✅');
          case 'Sound':
            return log.contains('🔇') || log.contains('🔊') || log.contains('sound') || log.contains('cancel');
          default:
            return true;
        }
      }).toList();
    });
  }

  Future<void> _clear() async {
    await AppLogger.clear();
    setState(() {
      _logs = [];
      _filteredLogs = [];
    });
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _filteredLogs.reversed.join('\n')));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied filtered logs to clipboard')));
  }

  Color _getLogColor(String log) {
    if (log.contains('❌') || log.contains('ERROR')) return Colors.red.shade50;
    if (log.contains('✅')) return Colors.green.shade50;
    if (log.contains('🔔') || log.contains('FCM')) return Colors.blue.shade50;
    if (log.contains('📩') || log.contains('BACKGROUND') || log.contains('FOREGROUND')) return Colors.purple.shade50;
    if (log.contains('WebSocket') || log.contains('connect')) return Colors.orange.shade50;
    if (log.contains('🔇') || log.contains('🔊')) return Colors.amber.shade50;
    if (log.contains('🔄') || log.contains('APP LIFECYCLE')) return Colors.cyan.shade50;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        actions: [
          IconButton(icon: const Icon(Icons.copy), onPressed: _copy, tooltip: 'Copy filtered'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Refresh'),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clear, tooltip: 'Clear'),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                // Search Box
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search logs...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilter();
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) => _applyFilter(),
                ),
                const SizedBox(height: 8),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      _buildFilterChip('Notifications'),
                      _buildFilterChip('WebSocket'),
                      _buildFilterChip('Sound'),
                      _buildFilterChip('Errors'),
                      _buildFilterChip('Success'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text('${_filteredLogs.length} / ${_logs.length} logs', 
                     style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          // Logs List
          Expanded(
            child: _filteredLogs.isEmpty
                ? Center(
                    child: Text(
                      _logs.isEmpty ? 'No logs yet' : 'No logs match filter',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = _filteredLogs[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getLogColor(log),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          log,
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
            _applyFilter();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.blue.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.blue.shade800 : Colors.black87,
          fontSize: 12,
        ),
      ),
    );
  }
}
