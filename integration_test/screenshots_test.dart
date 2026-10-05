// Capturas de la demo para el README (no es un test de comportamiento):
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshots_test.dart -d emulator-5554
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nexo_bank/features/accounts/presentation/widgets/account_card.dart';
import 'package:nexo_bank/features/accounts/presentation/widgets/movement_tile.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capturas de la demo', (tester) async {
    Future<void> shot(String name) async {
      await tester.pump(const Duration(seconds: 1));
      await binding.takeScreenshot(name);
    }

    Future<void> logout() async {
      await tester.tap(find.byKey(const Key('home_profile')));
      await pumpUntil(tester, find.byKey(const Key('profile_language')));
      await tester.scrollUntilVisible(
        find.byKey(const Key('profile_logout')),
        300,
      );
      await tapVisible(tester, find.byKey(const Key('profile_logout')));
      await pumpUntil(tester, find.byKey(const Key('login_submit')));
    }

    await startApp(tester);
    await binding.convertFlutterSurfaceToImage();
    await shot('01_login');

    // Ana (joven): home con meta de ahorro.
    await login(tester, 'ana');
    await pumpUntil(tester, find.byType(AccountCard));
    await tester.pump(const Duration(seconds: 2));
    await shot('02_home_joven_ana');

    await tester.tap(find.textContaining('****4521'));
    await pumpUntil(tester, find.byType(MovementTile));
    await shot('03_movimientos');
    await tester.binding.handlePopRoute();
    await pumpUntil(tester, find.byKey(const Key('home_profile')));

    const transferAction = Key('quick_action_app://transfers');
    await tester.scrollUntilVisible(find.byKey(transferAction), 300);
    await tapVisible(tester, find.byKey(transferAction));
    await pumpUntil(tester, find.byKey(const Key('transfer_amount')));
    await tester.enterText(find.byKey(const Key('transfer_amount')), '25.50');
    await tester.enterText(
      find.byKey(const Key('transfer_description')),
      'Ahorro viaje',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await shot('04_transferencia_formulario');
    await tapVisible(tester, find.byKey(const Key('transfer_continue')));
    await pumpUntil(tester, find.byKey(const Key('transfer_confirm')));
    await shot('05_transferencia_confirmar');
    await tester.binding.handlePopRoute(); // vuelve a editar
    await tester.pump(const Duration(milliseconds: 500));
    await tester.binding.handlePopRoute(); // sale del flujo
    await pumpUntil(tester, find.byKey(const Key('home_profile')));

    await tester.tap(find.byKey(const Key('home_profile')));
    await pumpUntil(tester, find.byKey(const Key('profile_language')));
    await shot('06_perfil');
    await tester.binding.handlePopRoute();
    await pumpUntil(tester, find.byKey(const Key('home_profile')));
    await logout();

    // Carlos (premium): otro home, con tipo de cambio.
    await login(tester, 'carlos');
    await pumpUntil(tester, find.byType(AccountCard));
    await tester.pump(const Duration(seconds: 2));
    await shot('07_home_premium_carlos');
    await tester.scrollUntilVisible(find.byKey(const Key('fx_rates')), 300);
    await shot('08_home_premium_tipo_de_cambio');
    await logout();

    // Lucía (emprendedora).
    await login(tester, 'lucia');
    await pumpUntil(tester, find.byType(AccountCard));
    await tester.pump(const Duration(seconds: 2));
    await shot('09_home_emprendedor_lucia');
    await logout();

    // Onboarding.
    await tester.tap(find.byKey(const Key('login_create_account')));
    await pumpUntil(tester, find.byKey(const Key('onboarding_next')));
    await tester.tap(find.byKey(const Key('onboarding_next')));
    await shot('10_onboarding_validacion');
  });
}
