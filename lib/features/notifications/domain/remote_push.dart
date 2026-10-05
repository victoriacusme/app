/// Notificación enviada por el backend (ms-customer → FCM), sin depender del
/// SDK de Firebase.
class RemotePush {
  const RemotePush({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;

  /// Datos del backend: `type`, `transferId` y `deeplink` (`app://...`).
  final Map<String, String> data;

  String? get deepLink => data['deeplink'];

  /// Clave que identifica el aviso: una transferencia avisada en local y
  /// por push comparte la misma, así el segundo reemplaza al primero.
  String? get key => data['transferId'];
}

/// Id de notificación estable para una clave (p. ej. el id de transferencia).
int notificationIdFor(String key) => key.hashCode & 0x7fffffff;
