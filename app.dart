import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'l10n/strings.dart';
import 'providers/providers.dart';
import 'ui/screens/configs_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/logs_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/theme.dart';

class HappApp extends ConsumerWidget {
  const HappApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider.select((s) => s.language));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Happ Clone',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      locale: Locale(lang.code),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RootShell(),
    );
  }
}

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});
  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _index = 0;
  static const _pages = [HomeScreen(), ConfigsScreen(), LogsScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Symbols.power_settings_new), label: s.home),
          NavigationDestination(icon: const Icon(Symbols.dns), label: s.configs),
          NavigationDestination(icon: const Icon(Symbols.terminal), label: s.logs),
          NavigationDestination(icon: const Icon(Symbols.settings), label: s.settings),
        ],
      ),
    );
  }
}

final stringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(settingsProvider.select((s) => s.language));
  return AppStrings.of(lang);
});
