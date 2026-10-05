import '../domain/push_token_source.dart';
import '../infrastructure/device_remote_data_source.dart';

/// Asocia el token de push de este dispositivo al cliente en ms-customer,
/// para que el backend pueda avisar (p. ej. tras una transferencia).
///
/// Es best effort: sin token o sin red no se bloquea el login ni el logout.
/// Si la sesión expira sin desregistrar, el backend reasigna el token al
/// siguiente cliente que inicie sesión en el dispositivo.
class PushRegistration {
  PushRegistration(this._tokens, this._remote);

  final PushTokenSource _tokens;
  final DeviceRemoteDataSource _remote;

  Future<void> register() async {
    try {
      final token = await _tokens.currentToken();
      if (token != null) await _remote.register(token, _tokens.platform);
    } catch (_) {}
  }

  Future<void> unregister() async {
    try {
      final token = await _tokens.currentToken();
      if (token != null) await _remote.unregister(token);
    } catch (_) {}
  }
}
