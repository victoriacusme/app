// E2E de idioma: el cliente cambia el idioma desde su perfil y TODA la app
// (home SDUI, cuentas, perfil) pasa a ese idioma. Al final se restaura el
// idioma que tenía el cliente.
//   flutter test integration_test/language_test.dart -d emulator-5554
// Con capturas en docs/screenshots:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/language_test.dart -d emulator-5554
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nexo_bank/app/di.dart';
import 'package:nexo_bank/features/accounts/presentation/widgets/account_card.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ana cambia a inglés desde el perfil y toda la app cambia', (
    tester,
  ) async {
    Future<void> shot(String name) async {
      await tester.pump(const Duration(seconds: 1));
      try {
        await binding.takeScreenshot(name);
      } catch (_) {
        // Sin `flutter drive` no hay dónde guardar la captura.
      }
    }

    Future<void> chooseLanguage(String label) async {
      await tapVisible(tester, find.byKey(const Key('profile_language')));
      await pumpUntil(tester, find.text(label).last);
      await tester.tap(find.text(label).last);
    }

    await startApp(tester);
    try {
      await binding.convertFlutterSurfaceToImage();
    } catch (_) {}
    await login(tester, 'ana');
    await pumpUntil(tester, find.byType(AccountCard));

    // Se guarda el idioma que tenga ana y se restaura al final, pase lo que
    // pase, para no alterar los datos de prueba.
    final dio = getIt<Dio>();
    final original =
        ((await dio.get<Map<String, dynamic>>('/customers/me'))
                    .data!['preferences']
                as Map)['language']
            as String;
    addTearDown(
      () => dio.patch<void>(
        '/customers/me/preferences',
        data: {'language': original},
      ),
    );

    // Punto de partida conocido: español.
    await tester.tap(find.byKey(const Key('home_profile')));
    await pumpUntil(tester, find.byKey(const Key('profile_language')));
    await chooseLanguage('Español');
    await pumpUntil(tester, find.text('Mi perfil'));
    await tester.binding.handlePopRoute();
    await pumpUntil(tester, find.text('Tus cuentas'));
    expect(find.text('Saldo disponible'), findsWidgets);

    // Perfil → Idioma → English.
    await tester.tap(find.byKey(const Key('home_profile')));
    await pumpUntil(tester, find.byKey(const Key('profile_language')));
    await chooseLanguage('English');
    await pumpUntil(tester, find.text('My profile'));
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    await shot('12_perfil_en');

    // De vuelta al home: el layout se recarga en inglés.
    await tester.binding.handlePopRoute();
    await pumpUntil(tester, find.text('Your accounts'));
    await pumpUntil(tester, find.textContaining(RegExp('^Good ')));
    expect(find.text('Available balance'), findsWidgets);
    // Alias genérico "Ahorros" de una cuenta de ahorros → traducido.
    expect(find.text('Savings'), findsOneWidget);
    // "Meta: viaje" es el nombre que puso la clienta → se respeta.
    expect(find.text('Meta: viaje'), findsOneWidget);
    expect(find.textContaining('Total balance'), findsOneWidget);
    for (final spanish in [
      'Tus cuentas',
      'Saldo disponible',
      'Saldo total',
      'Buenas',
      'Buenos',
      'Ahorros',
    ]) {
      expect(find.textContaining(spanish), findsNothing, reason: spanish);
    }
    await shot('11_home_en');
  });
}
