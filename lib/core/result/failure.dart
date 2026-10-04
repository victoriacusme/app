import 'package:equatable/equatable.dart';

/// Error tipado que la UI sabe mostrar.
///
/// [code] es el `code` estable del `ProblemDetail` del backend
/// (por ejemplo `invalid-credentials` o `user-locked`).
sealed class Failure extends Equatable {
  const Failure({
    required this.message,
    this.code,
    this.statusCode,
    this.correlationId,
  });

  final String message;
  final String? code;
  final int? statusCode;

  /// Para soporte: permite rastrear la petición en los logs del backend.
  final String? correlationId;

  @override
  List<Object?> get props => [runtimeType, message, code, statusCode];
}

/// No hubo respuesta del servidor (sin red, DNS, conexión rechazada).
final class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No pudimos conectarnos. Revisa tu conexión.',
    super.correlationId,
  });
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'El servidor tardó demasiado en responder.',
    super.correlationId,
  });
}

/// 401: credenciales inválidas o sesión expirada.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    required super.message,
    super.code,
    super.statusCode = 401,
    super.correlationId,
  });
}

/// 400/422: los datos enviados no son válidos.
final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.statusCode,
    super.correlationId,
    this.fieldErrors = const {},
  });

  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

/// Cualquier otra respuesta de error del servidor (403, 404, 409, 423, 5xx).
final class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Ocurrió un error inesperado. Intenta nuevamente.',
    super.code,
    super.statusCode,
    super.correlationId,
  });
}
