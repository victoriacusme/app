import 'package:dio/dio.dart';

/// Error que se lanza sin llamar a la red mientras el circuito está abierto.
class CircuitOpenException implements Exception {
  const CircuitOpenException(this.service);

  final String service;

  @override
  String toString() => 'CircuitOpenException($service)';
}

enum CircuitState { closed, open, halfOpen }

/// Circuit breaker por servicio (primer segmento de la ruta: `accounts`,
/// `transfers`, `auth`...). Tras [failureThreshold] fallos seguidos (sin
/// red, timeout o 5xx) corta las peticiones durante [openDuration] y luego
/// deja pasar una de prueba (medio abierto). Si funciona, se cierra.
///
/// Así, si ms-accounts está caído, la app responde al instante con la
/// caché en lugar de esperar timeouts, y no satura al servicio.
class CircuitBreakerInterceptor extends Interceptor {
  CircuitBreakerInterceptor({
    this.failureThreshold = 5,
    this.openDuration = const Duration(seconds: 30),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final int failureThreshold;
  final Duration openDuration;
  final DateTime Function() _now;
  final _circuits = <String, _Circuit>{};

  CircuitState stateOf(String service) =>
      _circuits[service]?.state(_now()) ?? CircuitState.closed;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final service = _serviceOf(options);
    final circuit = _circuits.putIfAbsent(service, _Circuit.new);
    if (!circuit.allowRequest(_now(), openDuration)) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: CircuitOpenException(service),
          message: 'Circuit open for $service',
        ),
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _circuits[_serviceOf(response.requestOptions)]?.recordSuccess();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final circuit = _circuits[_serviceOf(err.requestOptions)];
    if (circuit != null) {
      if (_isServiceFailure(err)) {
        circuit.recordFailure(_now(), failureThreshold);
      } else {
        // Un 4xx significa que el servicio respondió: está vivo.
        circuit.recordSuccess();
      }
    }
    handler.next(err);
  }

  static bool _isServiceFailure(DioException err) => switch (err.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => true,
    DioExceptionType.badResponse => (err.response?.statusCode ?? 0) >= 500,
    _ => false,
  };

  static String _serviceOf(RequestOptions options) {
    final segments = options.uri.pathSegments.where((s) => s.isNotEmpty);
    return segments.isEmpty ? '' : segments.first;
  }
}

class _Circuit {
  int _failures = 0;
  DateTime? _openedAt;
  bool _trialInFlight = false;

  CircuitState state(DateTime now) => _openedAt == null
      ? CircuitState.closed
      : _trialInFlight
      ? CircuitState.halfOpen
      : CircuitState.open;

  bool allowRequest(DateTime now, Duration openDuration) {
    final openedAt = _openedAt;
    if (openedAt == null) return true;
    if (now.difference(openedAt) < openDuration || _trialInFlight) return false;
    _trialInFlight = true; // medio abierto: una sola petición de prueba
    return true;
  }

  void recordSuccess() {
    _failures = 0;
    _openedAt = null;
    _trialInFlight = false;
  }

  void recordFailure(DateTime now, int threshold) {
    _failures++;
    if (_trialInFlight || _failures >= threshold) {
      _openedAt = now;
      _trialInFlight = false;
    }
  }
}
