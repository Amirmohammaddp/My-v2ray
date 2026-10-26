import 'package:dio/dio.dart';

import '../models/proxy_config.dart';
import 'config_parser.dart';

class SubscriptionException implements Exception {
  final String message;
  SubscriptionException(this.message);
  @override
  String toString() => message;
}

class SubscriptionResult {
  final List<ProxyConfig> configs;
  final List<String> errors;
  final String? title;
  const SubscriptionResult(this.configs, this.errors, this.title);
}

class SubscriptionManager {
  final Dio _dio;

  SubscriptionManager([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              responseType: ResponseType.plain,
              headers: {'User-Agent': 'Happ/1.0 v2rayNG/1.8.19 Xray-core'},
            ));

  Future<SubscriptionResult> fetch(String url, {required String subscriptionId}) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      throw SubscriptionException('آدرس سابسکریپشن نامعتبر است');
    }
    final Response<String> res;
    try {
      res = await _dio.getUri<String>(uri);
    } on DioException catch (e) {
      throw SubscriptionException(switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout =>
          'زمان اتصال به سرور سابسکریپشن تمام شد',
        DioExceptionType.badResponse => 'خطای سرور: ${e.response?.statusCode}',
        DioExceptionType.connectionError => 'اتصال به اینترنت برقرار نیست',
        _ => 'خطای شبکه: ${e.message}',
      });
    }
    var body = (res.data ?? '').trim();
    if (body.isEmpty) throw SubscriptionException('پاسخ سابسکریپشن خالی است');
    if (ConfigParser.looksLikeBase64(body)) {
      try {
        body = ConfigParser.decodeBase64Loose(body);
      } catch (_) {
        throw SubscriptionException('دیکد base64 سابسکریپشن ناموفق بود');
      }
    }
    final parsed = ConfigParser.parseMany(body, subscriptionId: subscriptionId);
    if (parsed.configs.isEmpty) {
      throw SubscriptionException('هیچ کانفیگ معتبری در سابسکریپشن یافت نشد');
    }
    final title = res.headers.value('profile-title');
    return SubscriptionResult(parsed.configs, parsed.errors, title);
  }
}
