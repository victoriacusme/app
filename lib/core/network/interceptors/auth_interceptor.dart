import 'package:dio/dio.dart';

import '../../security/token_store.dart';
import '../request_options_x.dart';

/// Agrega `Authorization: Bearer <access token>` a las peticiones privadas.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStore);

  final TokenStore _tokenStore;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.skipAuth) {
      final tokens = await _tokenStore.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }
}
