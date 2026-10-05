import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Entorno de la app y URL del backend.
///
/// **Sin configurar nada** (el Run por defecto del IDE) la app elige sola
/// según dónde corre:
///
/// | Dispositivo            | Backend                                        |
/// |------------------------|------------------------------------------------|
/// | Teléfono físico        | Túnel HTTPS fijo ([stagingUrl]), cualquier red |
/// | Emulador de Android    | `http://10.0.2.2:8080` (la PC, directo)        |
/// | Simulador de iOS       | `http://localhost:8080` (la PC, directo)       |
///
/// Una URL explícita siempre manda (p. ej. producción):
///
/// ```bash
/// flutter run --dart-define-from-file=config/prod.json
/// ```
abstract final class Env {
  /// URL pública fija del túnel hacia el gateway local (perfil `tunnel` del
  /// docker compose de `app-backend`). Igual a `config/staging.json`.
  static const stagingUrl = 'https://ragweed-onshore-correct.ngrok-free.dev';

  static const _definedUrl = String.fromEnvironment('API_BASE_URL');
  static const _definedName = String.fromEnvironment('ENV');

  static const connectTimeout = Duration(seconds: 5);
  static const receiveTimeout = Duration(seconds: 10);

  static String _apiBaseUrl = _definedUrl.isNotEmpty
      ? _definedUrl
      : 'http://10.0.2.2:8080';
  static String _name = _definedName.isNotEmpty ? _definedName : 'dev';

  /// URL del backend. Se resuelve en [init] al arrancar la app.
  static String get apiBaseUrl => _apiBaseUrl;

  /// `dev`, `staging` o `prod`.
  static String get name => _name;

  static bool get isProduction => _name == 'prod';

  /// Resuelve la URL según el dispositivo, salvo que venga explícita.
  static Future<void> init({DeviceInfoPlugin? deviceInfo}) async {
    if (_definedUrl.isNotEmpty) return;
    final (url, name) = await _detect(deviceInfo ?? DeviceInfoPlugin());
    _apiBaseUrl = url;
    _name = _definedName.isNotEmpty ? _definedName : name;
    debugPrint('Backend ($_name): $_apiBaseUrl');
  }

  static Future<(String, String)> _detect(DeviceInfoPlugin info) async {
    try {
      if (Platform.isAndroid) {
        return (await info.androidInfo).isPhysicalDevice
            ? (stagingUrl, 'staging')
            : ('http://10.0.2.2:8080', 'dev');
      }
      if (Platform.isIOS) {
        return (await info.iosInfo).isPhysicalDevice
            ? (stagingUrl, 'staging')
            : ('http://localhost:8080', 'dev');
      }
    } catch (_) {
      // Sin información del dispositivo: se usa el túnel, que funciona en
      // cualquier dispositivo con internet.
    }
    return (stagingUrl, 'staging');
  }
}
