import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';

class LangToggleButton extends ConsumerWidget {
  const LangToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final themeMode = ref.watch(themeProvider);
    final s = lang;

    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 48),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            lang.langCode == 'lo' ? '🇱🇦' : '🇬🇧',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 2),
          Icon(Icons.arrow_drop_down,
              color: Theme.of(context).appBarTheme.foregroundColor ??
                  Theme.of(context).colorScheme.onSurface),
        ],
      ),
      itemBuilder: (context) => [
        // ─── Language section ───────────────────────
        PopupMenuItem<String>(
          enabled: false,
          height: 32,
          child: Text(
            s.language,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'lang_en',
          child: Row(
            children: [
              const Text('🇬🇧', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              const Text('English'),
              const Spacer(),
              if (lang.langCode == 'en')
                Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'lang_lo',
          child: Row(
            children: [
              const Text('🇱🇦', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              const Text('ລາວ'),
              const Spacer(),
              if (lang.langCode == 'lo')
                Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // ─── Theme section ───────────────────────────
        PopupMenuItem<String>(
          enabled: false,
          height: 32,
          child: Text(
            lang.langCode == 'lo' ? 'ຮູບແບບ' : 'Theme',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'theme_light',
          child: Row(
            children: [
              const Icon(Icons.light_mode_outlined, size: 20),
              const SizedBox(width: 10),
              Text(lang.langCode == 'lo' ? 'ສ່ວາງ' : 'Light'),
              const Spacer(),
              if (themeMode == ThemeMode.light)
                Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'theme_dark',
          child: Row(
            children: [
              const Icon(Icons.dark_mode_outlined, size: 20),
              const SizedBox(width: 10),
              Text(lang.langCode == 'lo' ? 'ມືດ' : 'Dark'),
              const Spacer(),
              if (themeMode == ThemeMode.dark)
                Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'theme_system',
          child: Row(
            children: [
              const Icon(Icons.brightness_auto_outlined, size: 20),
              const SizedBox(width: 10),
              Text(lang.langCode == 'lo' ? 'ລະບົບ' : 'System'),
              const Spacer(),
              if (themeMode == ThemeMode.system)
                Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'lang_en':
            ref.read(languageProvider.notifier).setLanguage('en');
            break;
          case 'lang_lo':
            ref.read(languageProvider.notifier).setLanguage('lo');
            break;
          case 'theme_light':
            ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
            break;
          case 'theme_dark':
            ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
            break;
          case 'theme_system':
            ref.read(themeProvider.notifier).setTheme(ThemeMode.system);
            break;
        }
      },
    );
  }
}
