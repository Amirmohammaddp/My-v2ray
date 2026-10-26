import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/connection_state.dart';
import '../theme.dart';

class ConnectButton extends StatefulWidget {
  final VpnStatus status;
  final VoidCallback onTap;
  const ConnectButton({super.key, required this.status, required this.onTap});

  @override
  State<ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.status == VpnStatus.connected;
    final busy = widget.status == VpnStatus.connecting || widget.status == VpnStatus.disconnecting;
    const size = 180.0;
    return GestureDetector(
      onTap: busy ? null : widget.onTap,
      child: SizedBox(
        width: size * 1.7,
        height: size * 1.7,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) => Stack(
            alignment: Alignment.center,
            children: [
              if (on || busy)
                for (final offset in [0.0, 0.5])
                  _Pulse(
                    t: (_c.value + offset) % 1,
                    size: size,
                    color: on ? AppTheme.connected : AppTheme.purple,
                  ),
              child!,
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: on
                  ? const LinearGradient(colors: [AppTheme.connected, AppTheme.blue])
                  : AppTheme.gradient,
              boxShadow: [
                BoxShadow(
                  color: (on ? AppTheme.connected : AppTheme.purple).withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(64),
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                  )
                : const Icon(Symbols.power_settings_new, size: 72, color: Colors.white, weight: 600),
          ),
        ),
      ),
    );
  }
}

class _Pulse extends StatelessWidget {
  final double t, size;
  final Color color;
  const _Pulse({required this.t, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    final s = size * (1 + 0.7 * t);
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.35 * (1 - t))),
    );
  }
}
