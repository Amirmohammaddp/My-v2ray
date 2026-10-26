import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:happ_clone/models/app_settings.dart';
import 'package:happ_clone/models/proxy_config.dart';
import 'package:happ_clone/services/config_parser.dart';

void main() {
  test('vless link', () {
    final c = ConfigParser.parse('vless://uuid-1@a.com:8443?type=ws&security=tls#🇩🇪 DE');
    expect(c.protocol, ProxyProtocol.vless);
    expect(c.port, 8443);
    expect(c.countryCode, 'DE');
  });

  test('vmess link', () {
    final b = base64.encode(utf8.encode(jsonEncode({'add': 'v.com', 'port': '443', 'id': 'x', 'ps': 'VM', 'net': 'ws'})));
    final c = ConfigParser.parse('vmess://$b');
    expect(c.address, 'v.com');
    expect(c.params['type'], 'ws');
  });

  test('ss SIP002', () {
    final c = ConfigParser.parse('ss://YWVzLTI1Ni1nY206cGFzcw@s.com:8388#S');
    expect(c.params['method'], 'aes-256-gcm');
    expect(c.credential, 'pass');
  });

  test('invalid link throws', () {
    expect(() => ConfigParser.parse('foo://bar'), throwsA(isA<ConfigParseException>()));
    expect(() => ConfigParser.parse('vless://@:0'), throwsA(isA<ConfigParseException>()));
  });

  test('rule-based routing: ir direct, ads block', () {
    final r = ConfigParser.routingFor(RoutingMode.ruleBased);
    final rules = (r['rules'] as List).cast<Map>();
    expect(rules.any((x) => (x['domain'] as List?)?.contains('geosite:ir') == true && x['outboundTag'] == 'direct'), isTrue);
    expect(rules.any((x) => x['outboundTag'] == 'block'), isTrue);
  });
}
