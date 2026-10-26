import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/proxy_config.dart';
import '../theme.dart';

class ConfigCard extends StatelessWidget {
  final ProxyConfig config;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String timeoutLabel;

  const ConfigCard({
    super.key,
    required this.config,
    this.selected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.timeoutLabel = 'timeout',
  });

  Color _pingColor(int ms) =>
      ms < 0 ? AppTheme.danger : (ms < 200 ? AppTheme.connected : (ms < 500 ? Colors.amber : AppTheme.danger));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: selected ? AppTheme.gradient : null,
        color: selected ? null : cs.surfaceContainerHigh,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(selected ? 0.25 : 1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(config.flag, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(config.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 4),
                      Row(children: [
                        _Chip(config.protocol.label),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text('${config.address}:${config.port}',
                              textDirection: TextDirection.ltr,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                        ),
                      ]),
                    ],
                  ),
                ),
                if (config.pingMs != null)
                  Text(
                    config.pingMs! < 0 ? timeoutLabel : '${config.pingMs} ms',
                    style: TextStyle(color: _pingColor(config.pingMs!), fontWeight: FontWeight.w600),
                  ),
                PopupMenuButton<int>(
                  icon: const Icon(Symbols.more_vert),
                  onSelected: (v) => v == 0 ? onEdit?.call() : onDelete?.call(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 0, child: Icon(Symbols.edit)),
                    PopupMenuItem(value: 1, child: Icon(Symbols.delete)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      );
}
