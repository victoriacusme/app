// E2E de registro (onboarding en 4 pasos) contra el backend real.
// Crea un usuario nuevo `e2e.<número>` en cada corrida.
//   flutter test integration_test/register_test.dart -d <dispositivo> \
//     --dart-define=API_BASE_URL=http://<ip-de-la-pc>:8080
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nexo_bank/features/accounts/presentation/widgets/account_card.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('un cliente nuevo crea su cuenta y entra al home', (
    tester,
  ) async {
    final username = 'e2e.${DateTime.now().millisecondsSinceEpoch % 100000000}';
    Finder field(String name) => find.byKey(Key('onboarding_$name'));

    Future<void> next() async {
      const button = Key('onboarding_next');
      // Deja que el teclado termine de cerrarse antes de buscar el botón.
      await tester.pump(const Duration(milliseconds: 600));
      // En pantallas chicas el botón queda debajo del formulario.
      await tester.dragUntilVisible(
        find.byKey(button),
        find.byType(ListView).last,
        const Offset(0, -200),
      );
      await tapVisible(tester, find.byKey(button));
      await tester.pump(const Duration(milliseconds: 500));
    }

    /// Si la app muestra un error, el test falla con ese mensaje.
    void failIfError() {
      final error = find.byKey(const Key('onboarding_error'));
      if (error.evaluate().isNotEmpty) {
        final texts = find
            .descendant(of: error, matching: find.byType(Text))
            .evaluate()
            .map((e) => (e.widget as Text).data)
            .join(' ');
        fail('La app mostró un error: $texts');
      }
    }

    await startApp(tester);
    await tester.tap(find.byKey(const Key('login_create_account')));
    await pumpUntil(tester, field('fullName'));

    // Paso 1: datos personales.
    await tester.enterText(field('fullName'), 'Prueba Registro');
    await tester.enterText(field('idNumber'), '0102030405');
    await tapVisible(tester, find.byKey(const Key('onboarding_birthDate')));
    await pumpUntil(tester, find.byType(DatePickerDialog));
    final ok = MaterialLocalizations.of(
      tester.element(find.byType(DatePickerDialog)),
    ).okButtonLabel;
    await tester.tap(find.text(ok));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(field('email'), 'e2e@nexo.ec');
    await tester.enterText(field('phone'), '0991234567');
    FocusManager.instance.primaryFocus?.unfocus();
    await next();

    // Paso 2: credenciales.
    await pumpUntil(tester, field('username'));
    await tester.enterText(field('username'), username);
    await tester.enterText(field('password'), 'Clave2026x');
    await tester.enterText(field('confirmation'), 'Clave2026x');
    FocusManager.instance.primaryFocus?.unfocus();
    await next();

    // Paso 3: términos y envío.
    await pumpUntil(tester, find.byKey(const Key('onboarding_terms')));
    await tapVisible(tester, find.byKey(const Key('onboarding_terms')));
    await next();

    // Paso 4: bienvenida (o error del backend).
    final welcome = find.byKey(const Key('onboarding_welcome'));
    final end = DateTime.now().add(const Duration(seconds: 30));
    while (welcome.evaluate().isEmpty && DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 300));
      failIfError();
    }
    expect(welcome, findsOneWidget, reason: 'no llegó a la bienvenida');

    await tapVisible(tester, find.byKey(const Key('onboarding_start')));
    await pumpUntil(tester, find.byType(AccountCard));
  });
}
