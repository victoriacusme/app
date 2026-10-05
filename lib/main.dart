import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/app_lock_cubit.dart';
import 'app/app_settings_cubit.dart';
import 'app/di.dart';
import 'app/session_cubit.dart';
import 'core/config/env.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'core/storage/encrypted_cache.dart';
import 'features/notifications/application/foreground_push_presenter.dart';
import 'features/notifications/infrastructure/firebase_push_service.dart';
import 'features/notifications/infrastructure/local_notifications_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Backend según el dispositivo (teléfono → túnel HTTPS, emulador → PC).
  await Env.init();
  // Nombres de meses y días para las fechas en español e inglés.
  await initializeDateFormatting();

  const storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  await Hive.initFlutter();
  final cache = await HiveEncryptedCache.open(storage);
  final notifications = LocalNotificationsService();
  await notifications.init();
  // Push remota si hay google-services.json; si no, solo avisos locales.
  final push = await FirebasePushService.tryInit(currentDevicePlatform());

  configureDependencies(
    storage: storage,
    cache: cache,
    connectivity: ConnectivityPlusSource(),
    notifications: notifications,
    push: push,
  );
  if (push != null) {
    getIt<ForegroundPushPresenter>().listen(push.foregroundMessages);
  }

  final session = getIt<SessionCubit>();
  final connectivity = getIt<ConnectivityCubit>();
  final settings = getIt<AppSettingsCubit>();
  final lock = getIt<AppLockCubit>();
  // El bloqueo debe saber si hay biometría antes de restaurar la sesión.
  await lock.init();
  unawaited(session.restore());
  unawaited(connectivity.start());

  runApp(
    NexoApp(
      sessionCubit: session,
      connectivityCubit: connectivity,
      settingsCubit: settings,
      lockCubit: lock,
      deepLinks: push == null
          ? notifications.taps
          : _merge(notifications.taps, push.taps),
      initialDeepLink:
          notifications.launchDeepLink ?? await push?.launchDeepLink(),
    ),
  );
}

Stream<T> _merge<T>(Stream<T> a, Stream<T> b) {
  final merged = StreamController<T>.broadcast();
  a.listen(merged.add);
  b.listen(merged.add);
  return merged.stream;
}
