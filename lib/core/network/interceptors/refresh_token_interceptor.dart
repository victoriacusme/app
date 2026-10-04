import 'package:dio/dio.dart';

import '../../security/auth_tokens.dart';
import '../../security/token_store.dart';
import '../request_options_x.dart';

/// Pide un par de tokens nuevo al backend a partir del refresh token.
typedef TokenRefresher = Future<AuthTokens> Function(String refreshToken);

/// Ante un 401 en una petición privada refresca el token **una sola vez**
/// y reintenta la petición original.
///
/// - Si varias peticiones reciben 401 a la vez, todas esperan el mismo
///   refresh en curso (no se lanzan refresh en paralelo, que el backend
///   detectaría como reutilización del refresh token).
/// - Si el backend rechaza el refresh, se borran los tokens y se avisa
///   con [onSessionExpired] para volver al login.
class RefreshTokenInterceptor extends Interceptor {
  RefreshTokenInterceptor({
    required this._dio,
    required this._tokenStore,
    required this._refresh,
    required this._onSessionExpired,
  });

  final Dio _dio;
  final TokenStore _tokenStore;
  final TokenRefresher _refresh;
  final void Function() _onSessionExpired;

  Future<AuthTokens?>? _inFlight;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        request.skipAuth ||
        request.retriedAfterRefresh) {
      return handler.next(err);
    }

    final current = await _tokenStore.read();
    if (current == null) return handler.next(err);

    final AuthTokens? fresh;
    if (request.headers['Authorization'] != 'Bearer ${current.accessToken}') {
      // Otra petición ya refrescó mientras esta estaba en vuelo.
      fresh = current;
    } else {
      fresh = await (_inFlight ??= _refreshOnce(current.refreshToken)
          .whenComplete(() => _inFlight = null));
    }
    if (fresh == null) return handler.next(err);

    try {
      final response = await _dio.fetch<dynamic>(
        request.copyWith(
          headers: {
            ...request.headers,
            'Authorization': 'Bearer ${fresh.accessToken}',
          },
          extra: {...request.extra, RequestFlags.retriedAfterRefresh: true},
        ),
      );
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<AuthTokens?> _refreshOnce(String refreshToken) async {
    try {
      final tokens = await _refresh(refreshToken);
      await _tokenStore.save(tokens);
      return tokens;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401) {
        // Refresh inválido, expirado o reutilizado: la sesión terminó.
        await _tokenStore.clear();
        _onSessionExpired();
      }
      // Sin red o 5xx: se conserva la sesión y falla solo esta petición.
      return null;
    } catch (_) {
      return null;
    }
  }
}
