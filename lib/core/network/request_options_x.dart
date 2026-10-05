import 'package:dio/dio.dart';

/// Banderas por petición que leen los interceptores.
abstract final class RequestFlags {
  /// La petición no lleva `Authorization` (login, refresh, registro).
  static const skipAuth = 'nexo.skipAuth';

  /// La petición ya se reintentó tras refrescar el token.
  static const retriedAfterRefresh = 'nexo.retriedAfterRefresh';

  static Options public() => Options(extra: {skipAuth: true});
}

extension RequestOptionsX on RequestOptions {
  bool get skipAuth => extra[RequestFlags.skipAuth] == true;
  bool get retriedAfterRefresh =>
      extra[RequestFlags.retriedAfterRefresh] == true;
}
