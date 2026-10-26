# Happ Clone – Flutter VPN/Proxy Client

A minimal client similar to Happ for VLESS / VMess / Trojan / Shadowsocks / Hysteria2.
Right now it runs on a **mock Xray engine**. The UI, parsing, subscriptions and storage all work for real.

## Running it

```bash
# 1) Generate the missing platform files (gradle wrapper, res, ...) without overwriting the existing ones
flutter create . --platforms android --project-name happ_clone --org com.example
# If flutter create overwrote any of the files in android/, put back the versions from the archive.

# 2) Get the dependencies
flutter pub get

# 3) Run and test
flutter run
flutter test
```

Requirements: Flutter 3.22 or newer, JDK 17, Android SDK 34, minSdk 23.

Optional Persian font: add Vazirmatn to `assets/fonts` and register it in `pubspec.yaml` (the theme already uses `fontFamily: 'Vazirmatn'`).

## Structure

```
lib/
  main.dart, app.dart         # bootstrap, RTL, theme, navigation
  models/                     # ProxyConfig, Subscription, AppSettings, connection state
  services/
    config_parser.dart        # link → ProxyConfig → Xray JSON + routing rules
    subscription_manager.dart # Dio + User-Agent + base64 + error handling
    xray_service.dart         # XrayService interface + MockXrayService + VpnPermission
    storage_service.dart      # Hive (JSON, no codegen)
  providers/providers.dart    # Riverpod
  l10n/strings.dart           # Persian / English
  ui/                         # theme, widgets, screens (Home, Configs, Logs, Settings, Edit, QR)
android/                      # Manifest, gradle, MainActivity (VpnService.prepare)
test/config_parser_test.dart
```

## Default routing rules

| Rule | Destination |
|---|---|
| `geosite:category-ads-all` | block |
| `geosite:ir`, `domain:ir`, `geoip:ir`, `geoip:private` | direct |
| everything else | proxy |

## Adding the real Xray core

1. Uncomment `flutter_vless` in `pubspec.yaml` and enable the VPN `<service>` in the Manifest.
2. Write a `FlutterVlessXrayService implements XrayService` class:
   - `start`: `ConfigParser.toXrayJson(config, settings)` → `jsonEncode` → `flutterVless.startVless(config: json, proxyOnly: settings.mode == ConnectionMode.proxy, blockedApps: settings.excludedApps)`
   - Map the plugin's status callback to `statusStream` and `trafficStream`.
   - `ping` → `getServerDelay(config: json)`.
3. In `providers.dart`, swap `MockXrayService()` for the new class.

Kill Switch on Android: the system "Always-on VPN + Block connections without VPN" setting is the most reliable option. The in-app setting only takes effect once the real core is in place.
