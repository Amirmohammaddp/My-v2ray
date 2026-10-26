import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/proxy_config.dart';

class ConfigParseException implements Exception {
  final String message;
  ConfigParseException(this.message);
  @override
  String toString() => 'ConfigParseException: $message';
}

/// Converts share links into [ProxyConfig] and builds Xray JSON configs.
class ConfigParser {
  static const _uuid = Uuid();

  /// Parses many links separated by newlines; invalid lines are skipped and reported.
  static ({List<ProxyConfig> configs, List<String> errors}) parseMany(String text,
      {String? subscriptionId}) {
    final configs = <ProxyConfig>[];
    final errors = <String>[];
    for (final line in const LineSplitter().convert(text)) {
      final l = line.trim();
      if (l.isEmpty) continue;
      try {
        configs.add(parse(l, subscriptionId: subscriptionId));
      } on ConfigParseException catch (e) {
        errors.add(e.message);
      }
    }
    return (configs: configs, errors: errors);
  }

  static ProxyConfig parse(String link, {String? subscriptionId}) {
    final l = link.trim();
    final scheme = l.split('://').first.toLowerCase();
    try {
      return switch (scheme) {
        'vmess' => _vmess(l, subscriptionId),
        'vless' => _uriBased(l, ProxyProtocol.vless, subscriptionId),
        'trojan' => _uriBased(l, ProxyProtocol.trojan, subscriptionId),
        'hy2' || 'hysteria2' => _uriBased(l, ProxyProtocol.hysteria2, subscriptionId),
        'ss' => _shadowsocks(l, subscriptionId),
        _ => throw ConfigParseException('پروتکل پشتیبانی نمی‌شود: $scheme'),
      };
    } on ConfigParseException {
      rethrow;
    } catch (e) {
      throw ConfigParseException('لینک نامعتبر ($scheme): $e');
    }
  }

  // ---------- helpers ----------
  static String decodeBase64Loose(String input) {
    var s = input.trim().replaceAll('-', '+').replaceAll('_', '/').replaceAll(RegExp(r'\s'), '');
    while (s.length % 4 != 0) {
      s += '=';
    }
    return utf8.decode(base64.decode(s));
  }

  static bool looksLikeBase64(String s) =>
      RegExp(r'^[A-Za-z0-9+/=_\-\s]+$').hasMatch(s.trim()) && !s.contains('://');

  static void _validate(String host, int port, String cred) {
    if (host.isEmpty) throw ConfigParseException('آدرس سرور خالی است');
    if (port <= 0 || port > 65535) throw ConfigParseException('پورت نامعتبر: $port');
    if (cred.isEmpty) throw ConfigParseException('UUID / رمز عبور خالی است');
  }

  static ProxyConfig _uriBased(String link, ProxyProtocol p, String? subId) {
    final uri = Uri.parse(link);
    final cred = Uri.decodeComponent(uri.userInfo);
    final port = uri.hasPort ? uri.port : 443;
    _validate(uri.host, port, cred);
    final name = uri.fragment.isEmpty ? '${p.label} ${uri.host}' : Uri.decodeComponent(uri.fragment);
    return ProxyConfig(
      id: _uuid.v4(),
      name: name,
      protocol: p,
      address: uri.host,
      port: port,
      credential: cred,
      params: Map.of(uri.queryParameters),
      rawLink: link,
      subscriptionId: subId,
    );
  }

  static ProxyConfig _vmess(String link, String? subId) {
    final body = link.substring('vmess://'.length);
    final Map<String, dynamic> j;
    try {
      j = jsonDecode(decodeBase64Loose(body)) as Map<String, dynamic>;
    } catch (_) {
      throw ConfigParseException('محتوای VMess قابل دیکد نیست');
    }
    final host = '${j['add'] ?? ''}';
    final port = int.tryParse('${j['port']}') ?? 0;
    final id = '${j['id'] ?? ''}';
    _validate(host, port, id);
    String s(String k) => '${j[k] ?? ''}';
    return ProxyConfig(
      id: _uuid.v4(),
      name: s('ps').isEmpty ? 'VMess $host' : s('ps'),
      protocol: ProxyProtocol.vmess,
      address: host,
      port: port,
      credential: id,
      params: {
        'aid': s('aid').isEmpty ? '0' : s('aid'),
        'scy': s('scy').isEmpty ? 'auto' : s('scy'),
        'type': s('net').isEmpty ? 'tcp' : s('net'),
        'headerType': s('type'),
        'host': s('host'),
        'path': s('path'),
        'security': s('tls'),
        'sni': s('sni'),
        'fp': s('fp'),
        'alpn': s('alpn'),
      }..removeWhere((_, v) => v.isEmpty),
      rawLink: link,
      subscriptionId: subId,
    );
  }

  static ProxyConfig _shadowsocks(String link, String? subId) {
    var body = link.substring('ss://'.length);
    var name = '';
    final hash = body.indexOf('#');
    if (hash >= 0) {
      name = Uri.decodeComponent(body.substring(hash + 1));
      body = body.substring(0, hash);
    }
    body = body.split('?').first.split('/').first;
    String userInfo, hostPort;
    if (body.contains('@')) {
      final at = body.lastIndexOf('@');
      userInfo = body.substring(0, at);
      hostPort = body.substring(at + 1);
      if (!userInfo.contains(':')) userInfo = decodeBase64Loose(userInfo);
    } else {
      final dec = decodeBase64Loose(body);
      final at = dec.lastIndexOf('@');
      if (at < 0) throw ConfigParseException('فرمت Shadowsocks نامعتبر است');
      userInfo = dec.substring(0, at);
      hostPort = dec.substring(at + 1);
    }
    final colon = userInfo.indexOf(':');
    if (colon < 0) throw ConfigParseException('method:password در SS یافت نشد');
    final method = userInfo.substring(0, colon);
    final pass = Uri.decodeComponent(userInfo.substring(colon + 1));
    final pc = hostPort.lastIndexOf(':');
    final host = hostPort.substring(0, pc).replaceAll(RegExp(r'[\[\]]'), '');
    final port = int.tryParse(hostPort.substring(pc + 1)) ?? 0;
    _validate(host, port, pass);
    return ProxyConfig(
      id: _uuid.v4(),
      name: name.isEmpty ? 'SS $host' : name,
      protocol: ProxyProtocol.shadowsocks,
      address: host,
      port: port,
      credential: pass,
      params: {'method': method},
      rawLink: link,
      subscriptionId: subId,
    );
  }

  // ---------- Xray JSON ----------
  static Map<String, dynamic> toXrayJson(ProxyConfig c, AppSettings s) {
    return {
      'log': {'loglevel': 'warning'},
      'dns': {
        'servers': [s.useDoh ? s.dohUrl : s.dns, 'localhost'],
      },
      'inbounds': [
        {
          'tag': 'socks',
          'port': s.socksPort,
          'listen': '127.0.0.1',
          'protocol': 'socks',
          'settings': {'udp': true},
          'sniffing': {'enabled': true, 'destOverride': ['http', 'tls', 'quic']},
        },
        {'tag': 'http', 'port': s.httpPort, 'listen': '127.0.0.1', 'protocol': 'http'},
      ],
      'outbounds': [
        _outbound(c),
        {'tag': 'direct', 'protocol': 'freedom'},
        {'tag': 'block', 'protocol': 'blackhole'},
      ],
      'routing': routingFor(s.routing),
    };
  }

  /// Default rules: geosite:ir → direct, ads → block, rest → proxy.
  static Map<String, dynamic> routingFor(RoutingMode mode) {
    switch (mode) {
      case RoutingMode.global:
        return {'domainStrategy': 'AsIs', 'rules': []};
      case RoutingMode.direct:
        return {
          'rules': [
            {'type': 'field', 'network': 'tcp,udp', 'outboundTag': 'direct'}
          ]
        };
      case RoutingMode.ruleBased:
        return {
          'domainStrategy': 'IPIfNonMatch',
          'rules': [
            {'type': 'field', 'domain': ['geosite:category-ads-all'], 'outboundTag': 'block'},
            {'type': 'field', 'domain': ['geosite:ir', 'domain:ir'], 'outboundTag': 'direct'},
            {'type': 'field', 'ip': ['geoip:ir', 'geoip:private'], 'outboundTag': 'direct'},
          ],
        };
    }
  }

  static Map<String, dynamic> _outbound(ProxyConfig c) {
    final p = c.params;
    final net = p['type'] ?? 'tcp';
    final security = p['security'] ?? (c.protocol == ProxyProtocol.trojan ? 'tls' : 'none');

    Map<String, dynamic> stream() {
      final m = <String, dynamic>{'network': net, 'security': security};
      final sni = p['sni'] ?? p['host'] ?? c.address;
      if (security == 'tls') {
        m['tlsSettings'] = {
          'serverName': sni,
          if (p['fp'] != null) 'fingerprint': p['fp'],
          if (p['alpn'] != null) 'alpn': p['alpn']!.split(','),
          'allowInsecure': p['allowInsecure'] == '1',
        };
      } else if (security == 'reality') {
        m['realitySettings'] = {
          'serverName': sni,
          'fingerprint': p['fp'] ?? 'chrome',
          'publicKey': p['pbk'] ?? '',
          'shortId': p['sid'] ?? '',
          'spiderX': p['spx'] ?? '',
        };
      }
      switch (net) {
        case 'ws':
          m['wsSettings'] = {'path': p['path'] ?? '/', 'headers': {'Host': p['host'] ?? ''}};
        case 'grpc':
          m['grpcSettings'] = {'serviceName': p['serviceName'] ?? p['path'] ?? ''};
        case 'httpupgrade':
          m['httpupgradeSettings'] = {'path': p['path'] ?? '/', 'host': p['host'] ?? ''};
        case 'xhttp' || 'splithttp':
          m['xhttpSettings'] = {'path': p['path'] ?? '/', 'host': p['host'] ?? ''};
        case 'tcp' when p['headerType'] == 'http':
          m['tcpSettings'] = {
            'header': {
              'type': 'http',
              'request': {'path': [p['path'] ?? '/'], 'headers': {'Host': [p['host'] ?? '']}}
            }
          };
      }
      return m;
    }

    return switch (c.protocol) {
      ProxyProtocol.vless => {
          'tag': 'proxy',
          'protocol': 'vless',
          'settings': {
            'vnext': [
              {
                'address': c.address,
                'port': c.port,
                'users': [
                  {'id': c.credential, 'encryption': p['encryption'] ?? 'none', if (p['flow'] != null) 'flow': p['flow']}
                ]
              }
            ]
          },
          'streamSettings': stream(),
        },
      ProxyProtocol.vmess => {
          'tag': 'proxy',
          'protocol': 'vmess',
          'settings': {
            'vnext': [
              {
                'address': c.address,
                'port': c.port,
                'users': [
                  {'id': c.credential, 'alterId': int.tryParse(p['aid'] ?? '0') ?? 0, 'security': p['scy'] ?? 'auto'}
                ]
              }
            ]
          },
          'streamSettings': stream(),
        },
      ProxyProtocol.trojan => {
          'tag': 'proxy',
          'protocol': 'trojan',
          'settings': {
            'servers': [
              {'address': c.address, 'port': c.port, 'password': c.credential}
            ]
          },
          'streamSettings': stream(),
        },
      ProxyProtocol.shadowsocks => {
          'tag': 'proxy',
          'protocol': 'shadowsocks',
          'settings': {
            'servers': [
              {'address': c.address, 'port': c.port, 'method': p['method'] ?? 'aes-256-gcm', 'password': c.credential}
            ]
          },
        },
      ProxyProtocol.hysteria2 => {
          'tag': 'proxy',
          'protocol': 'hysteria2',
          'settings': {
            'servers': [
              {'address': c.address, 'port': c.port, 'password': c.credential}
            ]
          },
          'streamSettings': {
            'network': 'hysteria2',
            'security': 'tls',
            'tlsSettings': {
              'serverName': p['sni'] ?? c.address,
              'allowInsecure': p['insecure'] == '1',
              'alpn': ['h3'],
            },
            if (p['obfs'] != null)
              'hysteriaSettings': {'obfs': p['obfs'], 'obfsPassword': p['obfs-password'] ?? ''},
          },
        },
    };
  }
}
