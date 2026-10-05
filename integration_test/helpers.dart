import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/core/security/token_store.dart';
import 'package:nexo_bank/main.dart' as app;

/// Arranca la app real (DI, Hive, backend vía gateway) sin sesión previa.
Future<void> startApp(WidgetTester tester) async {
  await SecureTokenStore(const FlutterSecureStorage()).clear();
  await app.main();
  await pumpUntil(tester, find.byKey(const Key('login_submit')));
}

/// Bombea frames hasta que [finder] encuentre algo. No se usa
/// `pumpAndSettle` porque los skeletons animan sin fin.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('No apareció a tiempo: $finder');
}

Future<void> login(WidgetTester tester, String username) async {
  await tester.enterText(find.byKey(const Key('login_username')), username);
  await tester.enterText(find.byKey(const Key('login_password')), 'Nexo2026*');
  await tester.tap(find.byKey(const Key('login_submit')));
}

/// Toca un widget asegurando antes que esté entero en pantalla (los botones
/// al final de una lista pueden quedar a medias bajo el borde).
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
}
