import 'package:dio/dio.dart';

import '../config/env.dart';
import '../security/token_store.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/correlation_id_interceptor.dart';
import 'interceptors/refresh_token_interceptor.dart';

/// Cliente HTTP único de la app. El orden de los interceptores importa:
/// correlation-id → auth → (respuesta) refresh ante 401.
Dio createDioClient({
  required TokenStore tokenStore,
  required TokenRefresher refresh,
  required void Function() onSessionExpired,
  String baseUrl = Env.apiBaseUrl,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Env.connectTimeout,
      receiveTimeout: Env.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors.addAll([
    CorrelationIdInterceptor(),
    AuthInterceptor(tokenStore),
    RefreshTokenInterceptor(
      dio: dio,
      tokenStore: tokenStore,
      refresh: refresh,
      onSessionExpired: onSessionExpired,
    ),
  ]);
  return dio;
}
