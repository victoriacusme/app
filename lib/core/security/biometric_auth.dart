import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Autenticación con huella o rostro del sistema.
abstract interface class BiometricAuth {
  Future<bool> isAvailable();
  Future<bool> authenticate(String reason);
}

class LocalBiometricAuth implements BiometricAuth {
  LocalBiometricAuth([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported() &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      // Cancelado, bloqueado por intentos o sin biometría enrolada.
      return false;
    }
  }
}

/// Preferencia del dispositivo (no del cliente): si esta instalación pide
/// biometría para volver a entrar.
class BiometricSettings {
  BiometricSettings(this._storage);

  static const _key = 'security.biometric_lock';

  final FlutterSecureStorage _storage;

  Future<bool> isEnabled() async => await _storage.read(key: _key) == 'true';

  Future<void> setEnabled({required bool enabled}) =>
      _storage.write(key: _key, value: '$enabled');
}
