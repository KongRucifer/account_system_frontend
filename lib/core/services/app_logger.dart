import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLogger {
  static const _key = 'app_logs';
  static const _maxLogs = 200;
  static final List<String> _buffer = [];

  static void log(String message) {
    final now = DateTime.now();
    final entry =
        '[${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}] $message';
    _buffer.add(entry);
    debugPrint(entry);
    _flush();
  }

  static Future<void> _flush() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_key) ?? [];
      final updated = [...existing, ..._buffer];
      final trimmed =
          updated.length > _maxLogs ? updated.sublist(updated.length - _maxLogs) : updated;
      await prefs.setStringList(_key, trimmed);
      _buffer.clear();
    } catch (_) {}
  }

  static Future<List<String>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _buffer.clear();
  }
}
