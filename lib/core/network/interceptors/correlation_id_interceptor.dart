import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Agrega `X-Correlation-Id` a cada petición para rastrearla en el backend.
class CorrelationIdInterceptor extends Interceptor {
  CorrelationIdInterceptor({this._uuid = const Uuid()});

  static const header = 'X-Correlation-Id';

  final Uuid _uuid;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent(header, _uuid.v4);
    handler.next(options);
  }
}
