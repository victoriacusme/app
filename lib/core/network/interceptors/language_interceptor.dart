import 'package:dio/dio.dart';

/// Envía el idioma activo de la app (`Accept-Language`) para que el backend
/// pueda responder en ese idioma.
class LanguageInterceptor extends Interceptor {
  LanguageInterceptor(this._language);

  final String Function() _language;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent('Accept-Language', _language);
    handler.next(options);
  }
}
