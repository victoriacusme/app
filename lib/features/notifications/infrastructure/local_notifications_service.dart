import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notificaciones locales del dispositivo. El `payload` de cada aviso es un
/// deep link (`app://...`) que se abre al tocarlo.
class LocalNotificationsService {
  LocalNotificationsService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();

  /// Deep link de la notificación que abrió la app en frío, si la hubo.
  String? launchDeepLink;

  /// Deep links de las notificaciones que el usuario toca.
  Stream<String> get taps => _taps.stream;

  Future<void> init() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // El permiso se pide en contexto, al primer aviso (no al abrir).
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final link = response.payload;
        if (link != null) _taps.add(link);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      launchDeepLink = launch!.notificationResponse?.payload;
    }
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
    String? deepLink,
  }) => _plugin.show(
    id: id,
    title: title,
    body: body,
    payload: deepLink,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'transfers',
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        // En la pantalla de bloqueo no se muestra el contenido.
        visibility: NotificationVisibility.private,
      ),
      iOS: const DarwinNotificationDetails(),
    ),
  );
}
