import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

typedef Delay = Future<void> Function(Duration duration);

/// Reintenta **solo peticiones GET** ante fallos transitorios (sin red,
/// timeout, 502/503/504), con backoff exponencial y jitter completo.
///
/// Los POST nunca se reintentan aquí: una operación de dinero podría
/// ejecutarse dos veces. Eso se resuelve con `Idempotency-Key`.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this._dio,
    this._maxAttempts = 3,
    this._baseDelay = const Duration(milliseconds: 400),
    Delay? delay,
    Random? random,
  }) : _delay = delay ?? Future<void>.delayed,
       _random = random ?? Random();

  static const _attemptKey = 'nexo.retryAttempt';
  static const _retriableStatus = {502, 503, 504};

  final Dio _dio;
  final int _maxAttempts;
  final Duration _baseDelay;
  final Delay _delay;
  final Random _random;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final attempt = (request.extra[_attemptKey] as int?) ?? 1;
    if (!_isRetriable(err) || attempt >= _maxAttempts) {
      return handler.next(err);
    }

    await _delay(_backoff(attempt));
    try {
      final response = await _dio.fetch<dynamic>(
        request.copyWith(extra: {...request.extra, _attemptKey: attempt + 1}),
      );
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _isRetriable(DioException err) {
    if (err.requestOptions.method.toUpperCase() != 'GET') return false;
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      DioExceptionType.badResponse => _retriableStatus.contains(
        err.response?.statusCode,
      ),
      _ => false,
    };
  }

  /// Jitter completo: un valor aleatorio entre 0 y base·2^(intento-1).
  Duration _backoff(int attempt) {
    final cap = _baseDelay.inMilliseconds * pow(2, attempt - 1);
    return Duration(milliseconds: (_random.nextDouble() * cap).round());
  }
}
