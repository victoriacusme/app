// E2E: al desactivar "Promociones" en el perfil y volver al inicio, la
// promoción ya no se muestra (sin recargar a mano). Al final se reactivan.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nexo_bank/app/di.dart';
import 'package:nexo_bank/features/accounts/presentation/widgets/account_card.dart';
import 'package:nexo_bank/features/experience/presentation/components/promo_banner_component.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desactivar promociones las quita del inicio al volver', (
    tester,
  ) async {
    final promo = find.byType(PromoBannerComponent);
    const toggle = Key('profile_promotions');

    Future<void> setPromotions(bool on) async {
      await tester.tap(find.byKey(const Key('home_profile')));
      await pumpUntil(tester, find.byKey(const Key('profile_theme')));
      await tester.scrollUntilVisible(find.byKey(toggle), 200);
      final current = tester.widget<SwitchListTile>(find.byKey(toggle)).value;
      if (current != on) await tapVisible(tester, find.byKey(toggle));
      await tester.pump(const Duration(seconds: 1));
      await tester.binding.handlePopRoute();
      await pumpUntil(tester, find.byType(AccountCard));
    }

    await startApp(tester);
    await login(tester, 'lucia');
    await pumpUntil(tester, find.byType(AccountCard));
    addTearDown(
      () => getIt<Dio>().patch<void>(
        '/customers/me/preferences',
        data: {'showPromotions': true},
      ),
    );

    // Con promociones activas, la promoción se ve en el inicio.
    await setPromotions(true);
    await tester.scrollUntilVisible(promo, 300);
    expect(promo, findsOneWidget);

    // Se desactivan y al volver ya no está, sin recargar a mano.
    await setPromotions(false);
    await tester.pump(const Duration(seconds: 2));
    expect(promo, findsNothing);

    // Se reactivan y vuelve a aparecer.
    await setPromotions(true);
    await pumpUntil(tester, promo, timeout: const Duration(seconds: 15));
  });
}
