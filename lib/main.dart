import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'app/session_cubit.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'core/storage/encrypted_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  await Hive.initFlutter();
  final cache = await HiveEncryptedCache.open(storage);

  configureDependencies(
    storage: storage,
    cache: cache,
    connectivity: ConnectivityPlusSource(),
  );

  final session = getIt<SessionCubit>();
  final connectivity = getIt<ConnectivityCubit>();
  unawaited(session.restore());
  unawaited(connectivity.start());

  runApp(NexoApp(sessionCubit: session, connectivityCubit: connectivity));
}
