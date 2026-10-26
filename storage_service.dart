import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../models/proxy_config.dart';
import '../models/subscription.dart';

/// Hive persistence. Objects are stored as JSON strings → no codegen needed.
class StorageService {
  final Box<String> _configs;
  final Box<String> _subs;
  final Box<String> _meta;

  StorageService._(this._configs, this._subs, this._meta);

  static Future<StorageService> init() async {
    await Hive.initFlutter();
    return StorageService._(
      await Hive.openBox<String>('configs'),
      await Hive.openBox<String>('subscriptions'),
      await Hive.openBox<String>('meta'),
    );
  }

  List<ProxyConfig> loadConfigs() => _decodeAll(_configs, ProxyConfig.fromJson);
  Future<void> saveConfig(ProxyConfig c) => _configs.put(c.id, jsonEncode(c.toJson()));
  Future<void> saveConfigs(Iterable<ProxyConfig> cs) =>
      _configs.putAll({for (final c in cs) c.id: jsonEncode(c.toJson())});
  Future<void> deleteConfig(String id) => _configs.delete(id);
  Future<void> deleteConfigs(Iterable<String> ids) => _configs.deleteAll(ids);

  List<Subscription> loadSubscriptions() => _decodeAll(_subs, Subscription.fromJson);
  Future<void> saveSubscription(Subscription s) => _subs.put(s.id, jsonEncode(s.toJson()));
  Future<void> deleteSubscription(String id) => _subs.delete(id);

  AppSettings loadSettings() {
    final raw = _meta.get('settings');
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings s) => _meta.put('settings', jsonEncode(s.toJson()));

  String? get activeConfigId => _meta.get('activeConfigId');
  Future<void> setActiveConfigId(String? id) =>
      id == null ? _meta.delete('activeConfigId') : _meta.put('activeConfigId', id);

  static List<T> _decodeAll<T>(Box<String> box, T Function(Map<String, dynamic>) f) {
    final out = <T>[];
    for (final v in box.values) {
      try {
        out.add(f(jsonDecode(v) as Map<String, dynamic>));
      } catch (_) {/* skip corrupted entry */}
    }
    return out;
  }
}

final storageServiceProvider =
    Provider<StorageService>((_) => throw UnimplementedError('Override in main()'));
