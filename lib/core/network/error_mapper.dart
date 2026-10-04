import 'package:dio/dio.dart';

import '../result/failure.dart';
import 'interceptors/circuit_breaker_interceptor.dart';
import 'interceptors/correlation_id_interceptor.dart';

/// Traduce errores de red y `ProblemDetail` (RFC 7807) a [Failure].
abstract final class ErrorMapper {
  static const circuitOpenCode = 'circuit-open';

  static Failure from(Object error) => switch (error) {
    DioException() => fromDio(error),
    _ => const ServerFailure(),
  };

  static Failure fromDio(DioException e) {
    final correlationId =
        e.requestOptions.headers[CorrelationIdInterceptor.header] as String?;
    if (e.error is CircuitOpenException) {
      return ServerFailure(
        code: circuitOpenCode,
        statusCode: 503,
        message:
            'El servicio no está disponible en este momento. '
            'Lo intentaremos de nuevo en unos segundos.',
        correlationId: correlationId,
      );
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => TimeoutFailure(
        correlationId: correlationId,
      ),
      DioExceptionType.badResponse => _fromResponse(e.response, correlationId),
      DioExceptionType.connectionError ||
      DioExceptionType.cancel ||
      DioExceptionType.badCertificate => NetworkFailure(
        correlationId: correlationId,
      ),
      DioExceptionType.unknown =>
        e.response != null
            ? _fromResponse(e.response, correlationId)
            : NetworkFailure(correlationId: correlationId),
    };
  }

  static Failure _fromResponse(Response<dynamic>? response, String? cid) {
    final status = response?.statusCode;
    final data = response?.data;
    final problem = data is Map ? data : const <dynamic, dynamic>{};
    final code = problem['code'] as String?;
    final detail = problem['detail'] as String?;
    final correlationId =
        response?.headers.value(CorrelationIdInterceptor.header) ?? cid;

    // Los 5xx pueden traer detalles internos: no se muestran al usuario.
    if (status == null || status >= 500) {
      return ServerFailure(
        code: code,
        statusCode: status,
        correlationId: correlationId,
      );
    }
    final message = detail ?? 'No pudimos completar la operación.';
    return switch (status) {
      401 => UnauthorizedFailure(
        message: message,
        code: code,
        correlationId: correlationId,
      ),
      400 || 422 => ValidationFailure(
        message: message,
        code: code,
        statusCode: status,
        correlationId: correlationId,
        fieldErrors: _fieldErrors(problem['errors']),
      ),
      _ => ServerFailure(
        message: message,
        code: code,
        statusCode: status,
        correlationId: correlationId,
      ),
    };
  }

  static Map<String, String> _fieldErrors(Object? errors) => errors is Map
      ? {for (final e in errors.entries) '${e.key}': '${e.value}'}
      : const {};
}
