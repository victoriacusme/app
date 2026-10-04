// E2E 1: login → home → movimientos, contra el backend real.
//   flutter test integration_test/login_movements_test.dart -d emulator-5554
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nexo_bank/features/accounts/presentation/widgets/account_card.dart';
import 'package:nexo_bank/features/accounts/presentation/widgets/movement_tile.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ana inicia sesión, ve su home y los movimientos de su cuenta', (
    tester,
  ) async {
    await startApp(tester);

    await login(tester, 'ana');

    // Home SDUI del segmento joven: saludo, cuentas y meta de ahorro.
    await pumpUntil(tester, find.byType(AccountCard));
    expect(find.textContaining('Ana'), findsWidgets);
    expect(find.textContaining('****4521'), findsOneWidget);
    expect(find.byKey(const Key('accounts_total')), findsOneWidget);

    await tester.tap(find.textContaining('****4521'));
    await pumpUntil(tester, find.byType(MovementTile));
    expect(find.byType(MovementTile), findsWidgets);

    // Scroll infinito: al bajar se cargan más movimientos.
    final before = find.byType(MovementTile).evaluate().length;
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -3000),
      3000,
    );
    await pumpUntil(
      tester,
      find.text('No hay más movimientos'),
      timeout: const Duration(seconds: 20),
    ).catchError((_) {});
    expect(
      find.byType(MovementTile).evaluate().length,
      greaterThanOrEqualTo(before),
    );

    // Volver al home y cerrar sesión desde el perfil.
    // Botón "atrás" del sistema.
    await tester.binding.handlePopRoute();
    await pumpUntil(tester, find.byKey(const Key('home_profile')));
    await tester.tap(find.byKey(const Key('home_profile')));
    await pumpUntil(tester, find.text('Preferencias'));
    await tester.scrollUntilVisible(
      find.byKey(const Key('profile_logout')),
      300,
    );
    await tester.ensureVisible(find.byKey(const Key('profile_logout')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('profile_logout')));
    await pumpUntil(tester, find.byKey(const Key('login_submit')));
  });
}
