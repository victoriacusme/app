import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/core/money/money.dart';
import 'package:nexo_bank/features/accounts/domain/account.dart';
import 'package:nexo_bank/features/experience/presentation/components/greeting_component.dart';
import 'package:nexo_bank/features/experience/presentation/components/promo_banner_component.dart';
import 'package:nexo_bank/features/experience/presentation/components/savings_goal_component.dart';
import 'package:nexo_bank/features/experience/presentation/localized_text.dart';
import 'package:nexo_bank/l10n/domain_l10n.dart';

import '../helpers/l10n.dart';

Account _account(AccountType type, String? alias) => Account(
  id: '1',
  maskedNumber: '****4521',
  type: type,
  balance: const Money(100, 'USD'),
  status: AccountStatus.active,
  isDefault: false,
  alias: alias,
);

void main() {
  group('nombre de la cuenta', () {
    test('sin alias muestra el tipo traducido', () {
      final a = _account(AccountType.savings, null);
      expect(a.displayName(es), 'Cuenta de ahorros');
      expect(a.displayName(en), 'Savings account');
    });

    test('alias genérico del banco se traduce si coincide con el tipo', () {
      expect(
        _account(AccountType.savings, 'Ahorros').displayName(en),
        'Savings',
      );
      expect(
        _account(AccountType.savings, 'Ahorros').displayName(es),
        'Ahorros',
      );
      expect(
        _account(AccountType.checking, 'Corriente').displayName(en),
        'Checking',
      );
      expect(
        _account(AccountType.savings, 'Cuenta de ahorros').displayName(en),
        'Savings account',
      );
      expect(
        _account(AccountType.savings, 'Inversiones').displayName(en),
        'Investments',
      );
      expect(
        _account(AccountType.checking, 'Negocio').displayName(en),
        'Business',
      );
    });

    test('"Ahorros" en una cuenta que no es de ahorros no se traduce', () {
      expect(
        _account(AccountType.checking, 'Ahorros').displayName(en),
        'Ahorros',
      );
    });

    test('un alias propio del cliente es un nombre: no se traduce', () {
      expect(
        _account(AccountType.savings, 'Meta: viaje').displayName(en),
        'Meta: viaje',
      );
      expect(
        _account(AccountType.savings, 'Fondo de Lucas').displayName(en),
        'Fondo de Lucas',
      );
    });
  });

  test('saludo por franja horaria en ambos idiomas', () {
    DateTime at(int h) => DateTime(2026, 10, 4, h);
    expect(GreetingComponent.greeting(es, at(8)), 'Buenos días');
    expect(GreetingComponent.greeting(es, at(15)), 'Buenas tardes');
    expect(GreetingComponent.greeting(es, at(22)), 'Buenas noches');
    expect(GreetingComponent.greeting(es, at(3)), 'Buenas noches');
    expect(GreetingComponent.greeting(en, at(8)), 'Good morning');
    expect(GreetingComponent.greeting(en, at(12)), 'Good afternoon');
    expect(GreetingComponent.greeting(en, at(19)), 'Good evening');
  });

  test('de la meta solo se conserva el nombre que puso el cliente', () {
    expect(
      SavingsGoalComponent.goalName('Meta: viaje a Galápagos'),
      'Viaje a Galápagos',
    );
    expect(SavingsGoalComponent.goalName('Goal: new car'), 'New car');
    expect(SavingsGoalComponent.goalName('Casa propia'), 'Casa propia');
    expect(SavingsGoalComponent.goalName('Meta:'), '');
  });

  group('promociones', () {
    PromoBannerComponent promo(String deeplink) => PromoBannerComponent(
      title: LocalizedText.parse('Texto del backend'),
      subtitle: LocalizedText.parse('Subtítulo del backend'),
      deeplink: deeplink,
    );

    test('las conocidas usan el texto de la app en el idioma activo', () {
      expect(promo('app://savings').texts(en), (
        'Earn 5% extra on your first goal',
        'This month only',
      ));
      expect(promo('app://credit').texts(es), (
        'Crédito para tu negocio',
        r'Pre-aprobado hasta $5.000',
      ));
      expect(promo('app://credit').texts(en).$2, r'Pre-approved up to $5,000');
      expect(promo('app://transfers').texts(en).$1, 'Nexo Black Friday');
    });

    test(
      'una campaña nueva que la app no conoce muestra el texto del backend',
      () {
        expect(promo('app://nueva-campana').texts(en), (
          'Texto del backend',
          'Subtítulo del backend',
        ));
      },
    );
  });
}
