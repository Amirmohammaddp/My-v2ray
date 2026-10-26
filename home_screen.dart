import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app.dart';
import '../../models/connection_state.dart';
import '../../providers/providers.dart';
import '../theme.dart';
import '../widgets/config_card.dart';
import '../widgets/connect_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final status = ref.watch(vpnStatusProvider).valueOrNull ?? VpnStatus.disconnected;
    final traffic = ref.watch(trafficProvider).valueOrNull ?? TrafficStats.zero;
    final active = ref.watch(activeConfigProvider);

    final label = switch (status) {
      VpnStatus.connected => s.connected,
      VpnStatus.connecting => s.connecting,
      VpnStatus.disconnecting => s.disconnecting,
      _ => s.tapToConnect,
    };

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 1.1,
            colors: [AppTheme.purple.withOpacity(0.25), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text('Happ', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              ConnectButton(
                status: status,
                onTap: () async {
                  try {
                    await ref.read(connectionControllerProvider).toggle();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
              ),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              if (status == VpnStatus.connected) const _Timer(),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(child: _Stat(Symbols.arrow_downward, s.download, formatBytes(traffic.downBps, perSecond: true))),
                  const SizedBox(width: 12),
                  Expanded(child: _Stat(Symbols.arrow_upward, s.upload, formatBytes(traffic.upBps, perSecond: true))),
                ]),
              ),
              const SizedBox(height: 8),
              if (active != null)
                ConfigCard(config: active, selected: true, timeoutLabel: s.timeout)
              else
                Padding(padding: const EdgeInsets.all(16), child: Text(s.noConfig)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Timer extends ConsumerStatefulWidget {
  const _Timer();
  @override
  ConsumerState<_Timer> createState() => _TimerState();
}

class _TimerState extends ConsumerState<_Timer> {
  late final Timer _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final since = ref.watch(connectedSinceProvider);
    final d = since == null ? Duration.zero : DateTime.now().difference(since);
    String two(int n) => n.toString().padLeft(2, '0');
    return Text('${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}',
        textDirection: TextDirection.ltr,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300, fontFeatures: [FontFeature.tabularFigures()]));
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Stat(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Icon(icon, color: cs.primary),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          Text(value, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}
