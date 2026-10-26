import '../models/app_settings.dart';

/// Lightweight bilingual strings (fa default, RTL handled by Locale).
class AppStrings {
  final bool fa;
  const AppStrings._(this.fa);
  factory AppStrings.of(AppLanguage l) => AppStrings._(l == AppLanguage.fa);

  String _t(String f, String e) => fa ? f : e;

  String get home => _t('خانه', 'Home');
  String get configs => _t('کانفیگ‌ها', 'Configs');
  String get logs => _t('لاگ‌ها', 'Logs');
  String get settings => _t('تنظیمات', 'Settings');
  String get connected => _t('متصل', 'Connected');
  String get disconnected => _t('قطع', 'Disconnected');
  String get connecting => _t('در حال اتصال…', 'Connecting…');
  String get disconnecting => _t('در حال قطع…', 'Disconnecting…');
  String get tapToConnect => _t('برای اتصال لمس کنید', 'Tap to connect');
  String get download => _t('دانلود', 'Download');
  String get upload => _t('آپلود', 'Upload');
  String get noConfig => _t('کانفیگی انتخاب نشده', 'No config selected');
  String get addConfig => _t('افزودن کانفیگ', 'Add config');
  String get fromClipboard => _t('از کلیپ‌بورد', 'From clipboard');
  String get pasteLink => _t('وارد کردن لینک', 'Paste link');
  String get scanQr => _t('اسکن QR', 'Scan QR');
  String get manual => _t('ورود دستی', 'Manual');
  String get subscription => _t('لینک سابسکریپشن', 'Subscription URL');
  String get search => _t('جستجو…', 'Search…');
  String get pingAll => _t('تست پینگ همه', 'Ping all');
  String get updateSubs => _t('آپدیت سابسکریپشن‌ها', 'Update subscriptions');
  String get edit => _t('ویرایش', 'Edit');
  String get delete => _t('حذف', 'Delete');
  String get save => _t('ذخیره', 'Save');
  String get cancel => _t('انصراف', 'Cancel');
  String get add => _t('افزودن', 'Add');
  String get copied => _t('کپی شد', 'Copied');
  String get copyAll => _t('کپی همه', 'Copy all');
  String get clear => _t('پاک کردن', 'Clear');
  String get mode => _t('حالت اتصال', 'Connection mode');
  String get routing => _t('مسیریابی', 'Routing');
  String get global => _t('سراسری', 'Global');
  String get ruleBased => _t('هوشمند (ایران مستقیم)', 'Rule-based (IR direct)');
  String get direct => _t('مستقیم', 'Direct');
  String get dns => _t('DNS', 'DNS');
  String get useDoh => _t('استفاده از DoH', 'Use DNS over HTTPS');
  String get killSwitch => _t('Kill Switch', 'Kill Switch');
  String get killSwitchDesc => _t('قطع اینترنت هنگام قطع VPN', 'Block traffic when VPN drops');
  String get splitTunnel => _t('تونل جداگانه (اپ‌های مستثنی)', 'Split tunneling (excluded apps)');
  String get splitHint => _t('نام پکیج‌ها، با کاما', 'Package names, comma-separated');
  String get autoConnect => _t('اتصال خودکار', 'Auto connect');
  String get language => _t('زبان', 'Language');
  String get emptyConfigs => _t('هنوز کانفیگی اضافه نشده', 'No configs yet');
  String get emptyLogs => _t('لاگی وجود ندارد', 'No logs yet');
  String get name => _t('نام', 'Name');
  String get address => _t('آدرس', 'Address');
  String get port => _t('پورت', 'Port');
  String get credential => _t('UUID / رمز', 'UUID / Password');
  String get link => _t('لینک', 'Link');
  String get timeout => _t('ناموفق', 'timeout');
  String added(int n) => _t('$n کانفیگ اضافه شد', '$n config(s) added');
}
