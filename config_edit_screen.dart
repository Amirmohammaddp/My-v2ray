import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app.dart';
import '../../models/proxy_config.dart';
import '../../providers/providers.dart';

/// Manual entry / edit form.
class ConfigEditScreen extends ConsumerStatefulWidget {
  final ProxyConfig? initial;
  const ConfigEditScreen({super.key, this.initial});
  @override
  ConsumerState<ConfigEditScreen> createState() => _ConfigEditScreenState();
}

class _ConfigEditScreenState extends ConsumerState<ConfigEditScreen> {
  final _form = GlobalKey<FormState>();
  late ProxyProtocol _protocol = widget.initial?.protocol ?? ProxyProtocol.vless;
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _addr = TextEditingController(text: widget.initial?.address);
  late final _port = TextEditingController(text: '${widget.initial?.port ?? 443}');
  late final _cred = TextEditingController(text: widget.initial?.credential);
  late final _params = TextEditingController(
      text: (widget.initial?.params ?? {'type': 'tcp', 'security': 'tls'})
          .entries
          .map((e) => '${e.key}=${e.value}')
          .join('&'));

  void _save() {
    if (!_form.currentState!.validate()) return;
    final params = Uri.splitQueryString(_params.text.trim());
    final base = widget.initial;
    final cfg = ProxyConfig(
      id: base?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      protocol: base?.protocol ?? _protocol,
      address: _addr.text.trim(),
      port: int.parse(_port.text),
      credential: _cred.text.trim(),
      params: params,
      rawLink: base?.rawLink ?? '',
      subscriptionId: base?.subscriptionId,
    );
    ref.read(configsProvider.notifier).upsert(cfg);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    String? required(String? v) => (v == null || v.trim().isEmpty) ? '—' : null;
    return Scaffold(
      appBar: AppBar(title: Text(widget.initial == null ? s.manual : s.edit)),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (widget.initial == null)
            SegmentedButton<ProxyProtocol>(
              segments: [
                for (final p in ProxyProtocol.values) ButtonSegment(value: p, label: Text(p.label, style: const TextStyle(fontSize: 10))),
              ],
              selected: {_protocol},
              onSelectionChanged: (v) => setState(() => _protocol = v.first),
            ),
          const SizedBox(height: 12),
          TextFormField(controller: _name, decoration: InputDecoration(labelText: s.name), validator: required),
          const SizedBox(height: 12),
          TextFormField(
              controller: _addr,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: s.address),
              validator: required),
          const SizedBox(height: 12),
          TextFormField(
            controller: _port,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(labelText: s.port),
            validator: (v) {
              final p = int.tryParse(v ?? '');
              return (p == null || p < 1 || p > 65535) ? '1–65535' : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
              controller: _cred,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: s.credential),
              validator: required),
          const SizedBox(height: 12),
          TextFormField(
            controller: _params,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(labelText: 'params (type=ws&security=tls&sni=…)'),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: Text(s.save)),
        ]),
      ),
    );
  }
}
