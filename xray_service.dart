import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../models/connection_state.dart';
import '../models/proxy_config.dart';
import 'config_parser.dart';

class XrayException implements Exception {
  final String message;
  XrayException(this.message);
  @override
  String toString() => message;
}

/// Contract for the VPN engine. Replace [MockXrayService] with a
/// flutter_vless-backed implementation later.
abstract class XrayService {
  Stream<VpnStatus> get statusStream;
  Stream<TrafficStats> get trafficStream;
  Stream<String> get logStream;
  VpnStatus get status;

  Future<void> start(ProxyConfig config, AppSettings settings);
  Future<void> stop();
  Future<int> ping(ProxyConfig config);
  void dispose();
}

/// Android VpnService permission bridge (see MainActivity.kt).
class VpnPermission {
  static const _ch = MethodChannel('happ/vpn');
  static Future<bool> request() async {
    try {
      return await _ch.invokeMethod<bool>('prepare') ?? false;
    } on MissingPluginException {
      return true; // non-Android / tests
    } on PlatformException catch (e) {
      throw XrayException('دسترسی VPN رد شد: ${e.message}');
    }
  }
}

class MockXrayService implements XrayService {
  final _status = StreamController<VpnStatus>.broadcast();
  final _traffic = StreamController<TrafficStats>.broadcast();
  final _logs = StreamController<String>.broadcast();
  final _rnd = Random();
  Timer? _timer;
  VpnStatus _current = VpnStatus.disconnected;
  TrafficStats _stats = TrafficStats.zero;

  @override
  Stream<VpnStatus> get statusStream => _status.stream;
  @override
  Stream<TrafficStats> get trafficStream => _traffic.stream;
  @override
  Stream<String> get logStream => _logs.stream;
  @override
  VpnStatus get status => _current;

  void _set(VpnStatus s) {
    _current = s;
    _status.add(s);
  }

  void _log(String level, String msg) {
    final t = DateTime.now().toIso8601String().substring(11, 23);
    _logs.add('$t [$level] $msg');
  }

  @override
  Future<void> start(ProxyConfig config, AppSettings settings) async {
    if (_current == VpnStatus.connected || _current == VpnStatus.connecting) return;
    _set(VpnStatus.connecting);
    try {
      if (settings.mode == ConnectionMode.vpn && !await VpnPermission.request()) {
        throw XrayException('کاربر دسترسی VPN را نداد');
      }
      final json = ConfigParser.toXrayJson(config, settings);
      _log('Info', 'Xray 1.8.x (mock) started');
      _log('Debug', 'config: ${jsonEncode(json).length} bytes, outbound=${config.protocol.name}');
      _log('Info', 'routing mode: ${settings.routing.name}');
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      _set(VpnStatus.connected);
      _log('Info', 'connected to ${config.address}:${config.port}');
      _stats = TrafficStats.zero;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick(config));
    } catch (e) {
      _log('Error', '$e');
      _set(VpnStatus.error);
      _set(VpnStatus.disconnected);
      rethrow;
    }
  }

  void _tick(ProxyConfig c) {
    final down = 20000 + _rnd.nextInt(900000);
    final up = 5000 + _rnd.nextInt(120000);
    _stats = TrafficStats(
      downBps: down,
      upBps: up,
      totalDown: _stats.totalDown + down,
      totalUp: _stats.totalUp + up,
    );
    _traffic.add(_stats);
    if (_rnd.nextInt(4) == 0) {
      const hosts = ['www.google.com', 'api.telegram.org', 'digikala.com', 'youtube.com'];
      final h = hosts[_rnd.nextInt(hosts.length)];
      final route = h.endsWith('.com') && h.startsWith('digi') ? 'direct' : 'proxy';
      _log('Info', 'tcp:$h:443 accepted [socks -> $route]');
    }
  }

  @override
  Future<void> stop() async {
    if (_current == VpnStatus.disconnected) return;
    _set(VpnStatus.disconnecting);
    _timer?.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _traffic.add(TrafficStats.zero);
    _log('Info', 'Xray stopped');
    _set(VpnStatus.disconnected);
  }

  @override
  Future<int> ping(ProxyConfig config) async {
    await Future<void>.delayed(Duration(milliseconds: 200 + _rnd.nextInt(800)));
    return _rnd.nextInt(10) == 0 ? -1 : 60 + _rnd.nextInt(400);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _status.close();
    _traffic.close();
    _logs.close();
  }
}
