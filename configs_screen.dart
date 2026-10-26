import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app.dart';
import '../../providers/providers.dart';
import '../widgets/config_card.dart';
import 'config_edit_screen.dart';
import 'qr_scan_screen.dart';

class ConfigsScreen extends ConsumerStatefulWidget {
  const ConfigsScreen({super.key});
  @override
  ConsumerState<ConfigsScreen> createState() => _ConfigsScreenState();
}

class _ConfigsScreenState extends ConsumerState<ConfigsScreen> {
  String _query = '';
  bool _busy = false;

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _addText(String text) {
    try {
      final n = ref.read(configsProvider.notifier).addFromText(text);
      _toast(ref.read(stringsProvider).added(n));
    } catch (e) {
      _toast('$e');
    }
  }

  Future<String?> _prompt(String title, {String hint = ''}) {
    final c = TextEditingController();
    final s = ref.read(stringsProvider);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          maxLines: 4,
          minLines: 1,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(s.add)),
        ],
      ),
    );
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showAddSheet() {
    final s = ref.read(stringsProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Symbols.content_paste),
            title: Text(s.fromClipboard),
            onTap: () async {
              Navigator.pop(ctx);
              final d = await Clipboard.getData(Clipboard.kTextPlain);
              _addText(d?.text ?? '');
            },
          ),
          ListTile(
            leading: const Icon(Symbols.link),
            title: Text(s.pasteLink),
            onTap: () async {
              Navigator.pop(ctx);
              final t = await _prompt(s.pasteLink, hint: 'vless:// vmess:// trojan:// ss:// hy2://');
              if (t != null) _addText(t);
            },
          ),
          ListTile(
            leading: const Icon(Symbols.qr_code_scanner),
            title: Text(s.scanQr),
            onTap: () async {
              Navigator.pop(ctx);
              final t = await Navigator.push<String>(
                  context, MaterialPageRoute(builder: (_) => const QrScanScreen()));
              if (t != null) _addText(t);
            },
          ),
          ListTile(
            leading: const Icon(Symbols.edit_note),
            title: Text(s.manual),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfigEditScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Symbols.rss_feed),
            title: Text(s.subscription),
            onTap: () async {
              Navigator.pop(ctx);
              final url = await _prompt(s.subscription, hint: 'https://…');
              if (url == null || url.trim().isEmpty) return;
              await _run(() async {
                final n = await ref.read(subscriptionsProvider.notifier).add(url.trim());
                _toast(s.added(n));
              });
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final all = ref.watch(configsProvider);
    final activeId = ref.watch(activeConfigProvider)?.id;
    final q = _query.toLowerCase();
    final list = q.isEmpty
        ? all
        : all.where((c) => c.name.toLowerCase().contains(q) || c.address.contains(q)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.configs),
        actions: [
          IconButton(
            tooltip: s.pingAll,
            icon: const Icon(Symbols.speed),
            onPressed: _busy ? null : () => _run(ref.read(configsProvider.notifier).pingAll),
          ),
          IconButton(
            tooltip: s.updateSubs,
            icon: const Icon(Symbols.sync),
            onPressed: _busy
                ? null
                : () => _run(() async {
                      final errs = await ref.read(subscriptionsProvider.notifier).refreshAll();
                      if (errs.isNotEmpty) _toast(errs.join('\n'));
                    }),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(prefixIcon: const Icon(Symbols.search), hintText: s.search),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Symbols.add),
        label: Text(s.addConfig),
      ),
      body: Column(children: [
        if (_busy) const LinearProgressIndicator(),
        Expanded(
          child: list.isEmpty
              ? Center(child: Text(s.emptyConfigs))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final c = list[i];
                    return ConfigCard(
                      config: c,
                      selected: c.id == activeId,
                      timeoutLabel: s.timeout,
                      onTap: () => ref.read(activeConfigIdProvider.notifier).set(c.id),
                      onEdit: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => ConfigEditScreen(initial: c))),
                      onDelete: () => ref.read(configsProvider.notifier).remove(c.id),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
