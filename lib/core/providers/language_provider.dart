import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

const _langKey = 'app_language';

class LanguageNotifier extends StateNotifier<AppStrings> {
  LanguageNotifier() : super(AppStrings.en) {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_langKey) ?? 'en';
    state = code == 'lo' ? AppStrings.lo : AppStrings.en;
  }

  Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, code);
    state = code == 'lo' ? AppStrings.lo : AppStrings.en;
  }

  void toggleLanguage() {
    if (state.langCode == 'en') {
      setLanguage('lo');
    } else {
      setLanguage('en');
    }
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppStrings>(
  (ref) => LanguageNotifier(),
);

// Convenience extension on WidgetRef
extension LanguageRef on Object {
  static AppStrings of(Object ref) => AppStrings.en;
}
