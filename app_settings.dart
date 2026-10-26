enum ConnectionMode { vpn, proxy }

enum RoutingMode { global, ruleBased, direct }

enum AppLanguage {
  fa('fa'),
  en('en');

  final String code;
  const AppLanguage(this.code);
}

class AppSettings {
  final ConnectionMode mode;
  final RoutingMode routing;
  final String dns;
  final bool useDoh;
  final String dohUrl;
  final bool killSwitch;
  final bool autoConnect;
  final List<String> excludedApps; // split tunneling (package names)
  final AppLanguage language;
  final int socksPort;
  final int httpPort;

  const AppSettings({
    this.mode = ConnectionMode.vpn,
    this.routing = RoutingMode.ruleBased,
    this.dns = '1.1.1.1',
    this.useDoh = false,
    this.dohUrl = 'https://cloudflare-dns.com/dns-query',
    this.killSwitch = false,
    this.autoConnect = false,
    this.excludedApps = const [],
    this.language = AppLanguage.fa,
    this.socksPort = 10808,
    this.httpPort = 10809,
  });

  AppSettings copyWith({
    ConnectionMode? mode,
    RoutingMode? routing,
    String? dns,
    bool? useDoh,
    String? dohUrl,
    bool? killSwitch,
    bool? autoConnect,
    List<String>? excludedApps,
    AppLanguage? language,
  }) =>
      AppSettings(
        mode: mode ?? this.mode,
        routing: routing ?? this.routing,
        dns: dns ?? this.dns,
        useDoh: useDoh ?? this.useDoh,
        dohUrl: dohUrl ?? this.dohUrl,
        killSwitch: killSwitch ?? this.killSwitch,
        autoConnect: autoConnect ?? this.autoConnect,
        excludedApps: excludedApps ?? this.excludedApps,
        language: language ?? this.language,
        socksPort: socksPort,
        httpPort: httpPort,
      );

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'routing': routing.name,
        'dns': dns,
        'useDoh': useDoh,
        'dohUrl': dohUrl,
        'killSwitch': killSwitch,
        'autoConnect': autoConnect,
        'excludedApps': excludedApps,
        'language': language.name,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    const d = AppSettings();
    T pick<T extends Enum>(List<T> values, Object? v, T fallback) =>
        values.firstWhere((e) => e.name == v, orElse: () => fallback);
    return AppSettings(
      mode: pick(ConnectionMode.values, j['mode'], d.mode),
      routing: pick(RoutingMode.values, j['routing'], d.routing),
      dns: j['dns'] as String? ?? d.dns,
      useDoh: j['useDoh'] as bool? ?? d.useDoh,
      dohUrl: j['dohUrl'] as String? ?? d.dohUrl,
      killSwitch: j['killSwitch'] as bool? ?? d.killSwitch,
      autoConnect: j['autoConnect'] as bool? ?? d.autoConnect,
      excludedApps: (j['excludedApps'] as List?)?.cast<String>() ?? d.excludedApps,
      language: pick(AppLanguage.values, j['language'], d.language),
    );
  }
}
