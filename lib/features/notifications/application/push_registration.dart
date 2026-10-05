import 'dart:async';

import '../domain/push_token_source.dart';
import '../infrastructure/device_remote_data_source.dart';

/// Asocia el token de push de este dispositivo al cliente en ms-customer,
/// para que el backend pueda avisar (p. ej. tras una transferencia).
///
/// Es best effort: sin token o sin red no se bloquea el login ni el logout.
/// Si la sesión expira sin desregistrar, el backend reasigna el token al
/// siguiente cliente que inicie sesión en el dispositivo.
class PushRegistration {
  PushRegistration(this._tokens, this._remote, {this._tokenRefreshes});

  final PushTokenSource _tokens;
  final DeviceRemoteDataSource _remote;
  final Stream<String>? _tokenRefreshes;
  StreamSubscription<String>? _refreshes;

  Future<void> register() async {
    try {
      final token = await _tokens.currentToken();
      if (token != null) await _remote.register(token, _tokens.platform);
    } catch (_) {}
    // Mientras haya sesión, un token rotado por FCM se vuelve a registrar.
    _refreshes ??= _tokenRefreshes?.listen((token) async {
      try {
        await _remote.register(token, _tokens.platform);
      } catch (_) {}
    });
  }

  Future<void> unregister() async {
    await _refreshes?.cancel();
    _refreshes = null;
    try {
      final token = await _tokens.currentToken();
      if (token != null) await _remote.unregister(token);
    } catch (_) {}
  }
}
