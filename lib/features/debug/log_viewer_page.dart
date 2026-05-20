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
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await AppLogger.getLogs();
    setState(() => _logs = logs.reversed.toList());
  }

  Future<void> _clear() async {
    await AppLogger.clear();
    setState(() => _logs = []);
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _logs.reversed.join('\n')));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Logs'),
        actions: [
          IconButton(icon: const Icon(Icons.copy), onPressed: _copy, tooltip: 'Copy all'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Refresh'),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clear, tooltip: 'Clear'),
        ],
      ),
      body: _logs.isEmpty
          ? const Center(child: Text('No logs yet'))
          : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(8),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                Color color = Colors.white;
                if (log.contains('❌') || log.contains('ERROR')) color = Colors.red.shade100;
                if (log.contains('✅')) color = Colors.green.shade50;
                if (log.contains('🔔') || log.contains('FCM')) color = Colors.blue.shade50;
                if (log.contains('WebSocket') || log.contains('connect')) {
                  color = Colors.orange.shade50;
                }
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(log, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                );
              },
            ),
    );
  }
}
