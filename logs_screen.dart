import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app.dart';
import '../../providers/providers.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  Color _color(String l, ColorScheme cs) {
    if (l.contains('[Error]')) return cs.error;
    if (l.contains('[Warning]')) return Colors.amber;
    if (l.contains('[Debug]')) return cs.onSurfaceVariant;
    return cs.onSurface;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final logs = ref.watch(logsProvider);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(s.logs), actions: [
        IconButton(
          tooltip: s.copyAll,
          icon: const Icon(Symbols.content_copy),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: logs.join('\n')));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.copied)));
            }
          },
        ),
        IconButton(
          tooltip: s.clear,
          icon: const Icon(Symbols.delete_sweep),
          onPressed: ref.read(logsProvider.notifier).clear,
        ),
      ]),
      body: logs.isEmpty
          ? Center(child: Text(s.emptyLogs))
          : Directionality(
              textDirection: TextDirection.ltr,
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: logs.length,
                itemBuilder: (_, i) {
                  final l = logs[logs.length - 1 - i];
                  return SelectableText(l,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: _color(l, cs)));
                },
              ),
            ),
    );
  }
}
