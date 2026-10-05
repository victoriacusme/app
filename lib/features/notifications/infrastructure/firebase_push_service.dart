import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../domain/push_token_source.dart';
import '../domain/remote_push.dart';

/// Push remota con Firebase Cloud Messaging.
///
/// Con la app cerrada o en segundo plano, el sistema muestra la notificación
/// que envía el backend. Con la app abierta, Android no la muestra: llega por
/// [foregroundMessages] y la app la presenta como notificación local.
class FirebasePushService implements PushTokenSource {
  FirebasePushService(this._messaging, this.platform);

  final FirebaseMessaging _messaging;
  bool _permissionAsked = false;

  @override
  final DevicePlatform platform;

  /// `null` si el proyecto no tiene Firebase configurado
  /// (`google-services.json` / `GoogleService-Info.plist`).
  static Future<FirebasePushService?> tryInit(DevicePlatform platform) async {
    try {
      await Firebase.initializeApp();
      return FirebasePushService(FirebaseMessaging.instance, platform);
    } catch (e) {
      debugPrint('Firebase no configurado, push desactivado: $e');
      return null;
    }
  }

  /// Pide el permiso de notificaciones una vez (Android 13+ e iOS) y devuelve
  /// el token FCM de este dispositivo.
  @override
  Future<String?> currentToken() async {
    if (!_permissionAsked) {
      _permissionAsked = true;
      await _messaging.requestPermission();
    }
    return _messaging.getToken();
  }

  /// FCM puede rotar el token; hay que volver a registrarlo en el backend.
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  Stream<RemotePush> get foregroundMessages =>
      FirebaseMessaging.onMessage.map(_toPush);

  /// Deep links de las push que el usuario toca con la app en segundo plano.
  Stream<String> get taps => FirebaseMessaging.onMessageOpenedApp
      .map((m) => _toPush(m).deepLink)
      .where((link) => link != null)
      .cast<String>();

  /// Deep link de la push que abrió la app en frío, si la hubo.
  Future<String?> launchDeepLink() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _toPush(message).deepLink;
  }

  static RemotePush _toPush(RemoteMessage message) => RemotePush(
    title: message.notification?.title,
    body: message.notification?.body,
    data: message.data.map((key, value) => MapEntry(key, '$value')),
  );
}
