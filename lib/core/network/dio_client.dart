import 'package:dio/dio.dart';

import '../config/env.dart';
import '../security/token_store.dart';
import 'certificate_pinning.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/circuit_breaker_interceptor.dart';
import 'interceptors/correlation_id_interceptor.dart';
import 'interceptors/language_interceptor.dart';
import 'interceptors/refresh_token_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

/// Cliente HTTP único de la app. El orden de los interceptores importa:
///
/// 1. correlation-id: cada intento lleva el mismo id.
/// 2. circuit breaker: corta antes de tocar la red si el servicio cayó, y
///    cuenta cada intento (también los reintentos).
/// 3. auth: agrega el Bearer vigente.
/// 4. retry: reintenta GET ante fallos transitorios.
/// 5. refresh: ante un 401 renueva el token y repite la petición.
Dio createDioClient({
  required TokenStore tokenStore,
  required TokenRefresher refresh,
  required void Function() onSessionExpired,
  String baseUrl = Env.apiBaseUrl,
  CircuitBreakerInterceptor? circuitBreaker,
  Delay? retryDelay,
  CertificatePinning? pinning,
  String Function()? language,
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
  // En producción (con PIN_SHA256) solo se aceptan los certificados pineados.
  (pinning ?? CertificatePinning.fromEnvironment())?.applyTo(dio);
  dio.interceptors.addAll([
    CorrelationIdInterceptor(),
    if (language != null) LanguageInterceptor(language),
    circuitBreaker ?? CircuitBreakerInterceptor(),
    AuthInterceptor(tokenStore),
    RetryInterceptor(dio: dio, delay: retryDelay),
    RefreshTokenInterceptor(
      dio: dio,
      tokenStore: tokenStore,
      refresh: refresh,
      onSessionExpired: onSessionExpired,
    ),
  ]);
  return dio;
}
