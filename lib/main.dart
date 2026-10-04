import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app/app.dart';
import 'app/app_lock_cubit.dart';
import 'app/app_settings_cubit.dart';
import 'app/di.dart';
import 'app/session_cubit.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'core/storage/encrypted_cache.dart';
import 'features/notifications/infrastructure/local_notifications_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  await Hive.initFlutter();
  final cache = await HiveEncryptedCache.open(storage);
  final notifications = LocalNotificationsService();
  await notifications.init();

  configureDependencies(
    storage: storage,
    cache: cache,
    connectivity: ConnectivityPlusSource(),
    notifications: notifications,
  );

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
      deepLinks: notifications.taps,
      initialDeepLink: notifications.launchDeepLink,
    ),
  );
}
