enum DevicePlatform { android, ios }

/// Origen del token de push del dispositivo (FCM en Android e iOS).
abstract interface class PushTokenSource {
  /// `null` si push no está disponible en esta instalación.
  Future<String?> currentToken();

  DevicePlatform get platform;
}

/// Mientras no haya proyecto de Firebase (`google-services.json` /
/// `GoogleService-Info.plist`) no hay token: el registro no envía nada.
/// Con Firebase, se reemplaza por una implementación con
/// `FirebaseMessaging.instance.getToken()` y el resto del flujo no cambia.
class NoPushTokenSource implements PushTokenSource {
  const NoPushTokenSource(this.platform);

  @override
  final DevicePlatform platform;

  @override
  Future<String?> currentToken() async => null;
}
