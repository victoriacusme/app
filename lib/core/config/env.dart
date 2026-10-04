/// Configuración inyectada en compilación con `--dart-define`.
///
/// Ejemplo: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080`.
/// `10.0.2.2` es el host de la máquina visto desde el emulador de Android.
abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const connectTimeout = Duration(seconds: 5);
  static const receiveTimeout = Duration(seconds: 10);
}
