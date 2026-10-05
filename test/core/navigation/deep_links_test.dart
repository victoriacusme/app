import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/core/navigation/deep_links.dart';

void main() {
  test('traduce los enlaces conocidos a rutas', () {
    expect(DeepLinks.routeFor('app://transfers'), '/transfer');
    expect(DeepLinks.routeFor('app://accounts/abc-1'), '/accounts/abc-1');
    expect(DeepLinks.routeFor('app://profile'), '/profile');
    expect(DeepLinks.routeFor(DeepLinks.accountLink('x')), '/accounts/x');
    // Push del backend tras una transferencia.
    expect(DeepLinks.routeFor('app://transfers/t-1'), '/transfers/t-1');
  });

  test('lo desconocido o de otro esquema devuelve null', () {
    expect(DeepLinks.routeFor('app://investments'), isNull);
    expect(DeepLinks.routeFor('https://evil.example/accounts/1'), isNull);
    expect(DeepLinks.routeFor('no es un link'), isNull);
  });
}
