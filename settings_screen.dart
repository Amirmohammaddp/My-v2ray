import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app.dart';
import '../../models/app_settings.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final st = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    Widget section(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(t, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(children: [
        section(s.mode),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<ConnectionMode>(
            segments: const [
              ButtonSegment(value: ConnectionMode.vpn, label: Text('VPN (TUN)'), icon: Icon(Symbols.vpn_lock)),
              ButtonSegment(value: ConnectionMode.proxy, label: Text('Proxy'), icon: Icon(Symbols.lan)),
            ],
            selected: {st.mode},
            onSelectionChanged: (v) => n.update((x) => x.copyWith(mode: v.first)),
          ),
        ),
        section(s.routing),
        for (final r in RoutingMode.values)
          RadioListTile<RoutingMode>(
            value: r,
            groupValue: st.routing,
            onChanged: (v) => n.update((x) => x.copyWith(routing: v)),
            title: Text(switch (r) {
              RoutingMode.global => s.global,
              RoutingMode.ruleBased => s.ruleBased,
              RoutingMode.direct => s.direct,
            }),
          ),
        section(s.dns),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextFormField(
            initialValue: st.useDoh ? st.dohUrl : st.dns,
            key: ValueKey(st.useDoh),
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(prefixIcon: const Icon(Symbols.dns), labelText: st.useDoh ? 'DoH URL' : 'DNS'),
            onChanged: (v) => n.update((x) => st.useDoh ? x.copyWith(dohUrl: v) : x.copyWith(dns: v)),
          ),
        ),
        SwitchListTile(
          title: Text(s.useDoh),
          value: st.useDoh,
          onChanged: (v) => n.update((x) => x.copyWith(useDoh: v)),
        ),
        const Divider(),
        SwitchListTile(
          secondary: const Icon(Symbols.shield_lock),
          title: Text(s.killSwitch),
          subtitle: Text(s.killSwitchDesc),
          value: st.killSwitch,
          onChanged: (v) => n.update((x) => x.copyWith(killSwitch: v)),
        ),
        SwitchListTile(
          secondary: const Icon(Symbols.bolt),
          title: Text(s.autoConnect),
          value: st.autoConnect,
          onChanged: (v) => n.update((x) => x.copyWith(autoConnect: v)),
        ),
        section(s.splitTunnel),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextFormField(
            initialValue: st.excludedApps.join(', '),
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(hintText: s.splitHint, prefixIcon: const Icon(Symbols.call_split)),
            onChanged: (v) => n.update((x) => x.copyWith(
                excludedApps: v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList())),
          ),
        ),
        section(s.language),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: SegmentedButton<AppLanguage>(
            segments: const [
              ButtonSegment(value: AppLanguage.fa, label: Text('فارسی')),
              ButtonSegment(value: AppLanguage.en, label: Text('English')),
            ],
            selected: {st.language},
            onSelectionChanged: (v) => n.update((x) => x.copyWith(language: v.first)),
          ),
        ),
      ]),
    );
  }
}
