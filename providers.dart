import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/connection_state.dart';
import '../models/proxy_config.dart';
import '../models/subscription.dart';
import '../services/config_parser.dart';
import '../services/storage_service.dart';
import '../services/subscription_manager.dart';
import '../services/xray_service.dart';

final xrayServiceProvider = Provider<XrayService>((ref) {
  final s = MockXrayService();
  ref.onDispose(s.dispose);
  return s;
});

final subscriptionManagerProvider = Provider((_) => SubscriptionManager());

// ---------------- Settings ----------------
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(storageServiceProvider).loadSettings();

  void update(AppSettings Function(AppSettings) f) {
    state = f(state);
    ref.read(storageServiceProvider).saveSettings(state);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// ---------------- Configs ----------------
class ConfigsNotifier extends Notifier<List<ProxyConfig>> {
  StorageService get _store => ref.read(storageServiceProvider);

  @override
  List<ProxyConfig> build() {
    final list = _store.loadConfigs();
    if (list.isNotEmpty) return list;
    // Mock seed data
    final seed = ConfigParser.parseMany(_mockLinks).configs;
    _store.saveConfigs(seed);
    return seed;
  }

  /// Returns number added; throws [ConfigParseException] if nothing valid.
  int addFromText(String text) {
    final r = ConfigParser.parseMany(text);
    if (r.configs.isEmpty) {
      throw ConfigParseException(r.errors.isEmpty ? 'لینک معتبری یافت نشد' : r.errors.first);
    }
    state = [...state, ...r.configs];
    _store.saveConfigs(r.configs);
    return r.configs.length;
  }

  void upsert(ProxyConfig c) {
    final i = state.indexWhere((e) => e.id == c.id);
    state = i < 0 ? [...state, c] : ([...state]..[i] = c);
    _store.saveConfig(c);
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    _store.deleteConfig(id);
    if (ref.read(activeConfigIdProvider) == id) {
      ref.read(activeConfigIdProvider.notifier).set(null);
    }
  }

  void replaceSubscription(String subId, List<ProxyConfig> fresh) {
    final old = state.where((c) => c.subscriptionId == subId).map((c) => c.id).toList();
    state = [...state.where((c) => c.subscriptionId != subId), ...fresh];
    _store.deleteConfigs(old);
    _store.saveConfigs(fresh);
  }

  Future<void> pingAll() async {
    final xray = ref.read(xrayServiceProvider);
    state = [for (final c in state) c.copyWith(clearPing: true)];
    await Future.wait(state.map((c) async {
      final ms = await xray.ping(c);
      final cur = state.where((e) => e.id == c.id).firstOrNull;
      if (cur != null) upsert(cur.copyWith(pingMs: ms));
    }));
  }
}

final configsProvider = NotifierProvider<ConfigsNotifier, List<ProxyConfig>>(ConfigsNotifier.new);

class ActiveConfigNotifier extends Notifier<String?> {
  @override
  String? build() => ref.read(storageServiceProvider).activeConfigId;
  void set(String? id) {
    state = id;
    ref.read(storageServiceProvider).setActiveConfigId(id);
  }
}

final activeConfigIdProvider = NotifierProvider<ActiveConfigNotifier, String?>(ActiveConfigNotifier.new);

final activeConfigProvider = Provider<ProxyConfig?>((ref) {
  final id = ref.watch(activeConfigIdProvider);
  final list = ref.watch(configsProvider);
  return list.where((c) => c.id == id).firstOrNull ?? list.firstOrNull;
});

// ---------------- Subscriptions ----------------
class SubscriptionsNotifier extends Notifier<List<Subscription>> {
  @override
  List<Subscription> build() => ref.read(storageServiceProvider).loadSubscriptions();

  Future<int> add(String url, {String? name}) async {
    final sub = Subscription(id: const Uuid().v4(), name: name ?? Uri.parse(url).host, url: url);
    final n = await _refresh(sub);
    state = [...state, state.isEmpty ? sub : sub];
    return n;
  }

  Future<int> _refresh(Subscription sub) async {
    final r = await ref.read(subscriptionManagerProvider).fetch(sub.url, subscriptionId: sub.id);
    ref.read(configsProvider.notifier).replaceSubscription(sub.id, r.configs);
    final updated = sub.copyWith(name: r.title, lastUpdated: DateTime.now());
    await ref.read(storageServiceProvider).saveSubscription(updated);
    state = [for (final s in state) s.id == sub.id ? updated : s];
    return r.configs.length;
  }

  /// Updates all; returns list of error messages (empty = success).
  Future<List<String>> refreshAll() async {
    final errors = <String>[];
    for (final s in state) {
      try {
        await _refresh(s);
      } catch (e) {
        errors.add('${s.name}: $e');
      }
    }
    return errors;
  }
}

final subscriptionsProvider =
    NotifierProvider<SubscriptionsNotifier, List<Subscription>>(SubscriptionsNotifier.new);

// ---------------- Connection ----------------
final vpnStatusProvider = StreamProvider<VpnStatus>((ref) async* {
  final x = ref.watch(xrayServiceProvider);
  yield x.status;
  yield* x.statusStream;
});

final trafficProvider = StreamProvider<TrafficStats>((ref) async* {
  yield TrafficStats.zero;
  yield* ref.watch(xrayServiceProvider).trafficStream;
});

final connectedSinceProvider = StateProvider<DateTime?>((_) => null);

class LogsNotifier extends Notifier<List<String>> {
  static const _max = 1000;
  @override
  List<String> build() {
    final sub = ref.watch(xrayServiceProvider).logStream.listen((l) {
      final next = [...state, l];
      state = next.length > _max ? next.sublist(next.length - _max) : next;
    });
    ref.onDispose(sub.cancel);
    return const [];
  }

  void clear() => state = const [];
}

final logsProvider = NotifierProvider<LogsNotifier, List<String>>(LogsNotifier.new);

class ConnectionController {
  final Ref ref;
  ConnectionController(this.ref);

  Future<void> toggle() async {
    final xray = ref.read(xrayServiceProvider);
    if (xray.status == VpnStatus.connected) {
      await xray.stop();
      ref.read(connectedSinceProvider.notifier).state = null;
      return;
    }
    final cfg = ref.read(activeConfigProvider);
    if (cfg == null) throw XrayException('ابتدا یک کانفیگ انتخاب کنید');
    await xray.start(cfg, ref.read(settingsProvider));
    ref.read(connectedSinceProvider.notifier).state = DateTime.now();
  }
}

final connectionControllerProvider = Provider(ConnectionController.new);

const _mockLinks = '''
vless://0b5e4a7c-1f2d-4c3b-9a8e-7d6c5b4a3f21@de1.example.com:443?type=ws&security=tls&sni=de1.example.com&path=%2Fws#🇩🇪 Germany VLESS
trojan://s3cretPass@nl.example.net:443?sni=nl.example.net&type=grpc&serviceName=tg#🇳🇱 Netherlands Trojan
ss://YWVzLTI1Ni1nY206bW9ja3Bhc3M@fi.example.org:8388#🇫🇮 Finland SS
hy2://hyPass@tr.example.io:8443?sni=tr.example.io&insecure=1#🇹🇷 Turkey Hy2
vless://9f8e7d6c-5b4a-3f21-0b5e-4a7c1f2d4c3b@us.example.com:443?type=tcp&security=reality&pbk=abc123&sid=6ba8&fp=chrome&sni=www.microsoft.com&flow=xtls-rprx-vision#🇺🇸 USA Reality
''';
