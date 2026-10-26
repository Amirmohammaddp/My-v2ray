enum ProxyProtocol { vless, vmess, trojan, shadowsocks, hysteria2 }

extension ProxyProtocolX on ProxyProtocol {
  String get label => switch (this) {
        ProxyProtocol.vless => 'VLESS',
        ProxyProtocol.vmess => 'VMess',
        ProxyProtocol.trojan => 'Trojan',
        ProxyProtocol.shadowsocks => 'Shadowsocks',
        ProxyProtocol.hysteria2 => 'Hysteria2',
      };
}

/// Immutable, protocol-agnostic proxy configuration.
class ProxyConfig {
  final String id;
  final String name;
  final ProxyProtocol protocol;
  final String address;
  final int port;

  /// UUID (vless/vmess) or password (trojan/ss/hy2).
  final String credential;

  /// Extra parameters: type, security, sni, path, host, flow, pbk, sid, fp, method, aid...
  final Map<String, String> params;
  final String rawLink;
  final String? subscriptionId;
  final int? pingMs; // null = untested, -1 = timeout

  const ProxyConfig({
    required this.id,
    required this.name,
    required this.protocol,
    required this.address,
    required this.port,
    required this.credential,
    required this.params,
    required this.rawLink,
    this.subscriptionId,
    this.pingMs,
  });

  /// ISO country code guessed from name (flag emoji or 2-letter tag).
  String? get countryCode {
    final runes = name.runes.toList();
    for (var i = 0; i + 1 < runes.length; i++) {
      final a = runes[i], b = runes[i + 1];
      if (a >= 0x1F1E6 && a <= 0x1F1FF && b >= 0x1F1E6 && b <= 0x1F1FF) {
        return String.fromCharCodes([a - 0x1F1E6 + 65, b - 0x1F1E6 + 65]);
      }
    }
    final m = RegExp(r'\b([A-Z]{2})\b').firstMatch(name);
    return m?.group(1);
  }

  String get flag {
    final cc = countryCode;
    if (cc == null || cc.length != 2) return '🌐';
    return String.fromCharCodes(cc.codeUnits.map((c) => c - 65 + 0x1F1E6));
  }

  ProxyConfig copyWith({
    String? name,
    String? address,
    int? port,
    String? credential,
    Map<String, String>? params,
    String? rawLink,
    int? pingMs,
    bool clearPing = false,
  }) =>
      ProxyConfig(
        id: id,
        name: name ?? this.name,
        protocol: protocol,
        address: address ?? this.address,
        port: port ?? this.port,
        credential: credential ?? this.credential,
        params: params ?? this.params,
        rawLink: rawLink ?? this.rawLink,
        subscriptionId: subscriptionId,
        pingMs: clearPing ? null : (pingMs ?? this.pingMs),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'protocol': protocol.name,
        'address': address,
        'port': port,
        'credential': credential,
        'params': params,
        'rawLink': rawLink,
        'subscriptionId': subscriptionId,
        'pingMs': pingMs,
      };

  factory ProxyConfig.fromJson(Map<String, dynamic> j) => ProxyConfig(
        id: j['id'] as String,
        name: j['name'] as String,
        protocol: ProxyProtocol.values.byName(j['protocol'] as String),
        address: j['address'] as String,
        port: j['port'] as int,
        credential: j['credential'] as String,
        params: Map<String, String>.from(j['params'] as Map),
        rawLink: j['rawLink'] as String,
        subscriptionId: j['subscriptionId'] as String?,
        pingMs: j['pingMs'] as int?,
      );
}
