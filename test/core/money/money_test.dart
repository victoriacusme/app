import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/core/money/money.dart';

void main() {
  group('Money.parse', () {
    test('lee montos de la API sin pasar por double', () {
      expect(Money.parse('1250.50', 'USD').cents, 125050);
      expect(Money.parse('0.10', 'USD').cents, 10);
      expect(Money.parse('3', 'USD').cents, 300);
      expect(Money.parse('3.5', 'USD').cents, 350);
      expect(Money.parse('-10.00', 'USD').cents, -1000);
      // 0.1 + 0.2 en double daría 0.30000000000000004
      expect(
        Money.parse('0.10', 'USD') + Money.parse('0.20', 'USD'),
        Money.parse('0.30', 'USD'),
      );
    });

    test('acepta coma decimal escrita por el usuario', () {
      expect(Money.tryParseCents('25,50'), 2550);
    });

    test('rechaza formatos inválidos', () {
      for (final v in ['', 'abc', '1.234', '1.2.3', '12,345.00', '.5']) {
        expect(Money.tryParseCents(v), isNull, reason: v);
      }
    });
  });

  test('toApiString usa punto y dos decimales', () {
    expect(const Money(125050, 'USD').toApiString(), '1250.50');
    expect(const Money(5, 'USD').toApiString(), '0.05');
    expect(const Money(-1000, 'USD').toApiString(), '-10.00');
  });

  test('format muestra símbolo, separadores y signo', () {
    expect(const Money(125050, 'USD').format(), r'$1.250,50');
    expect(const Money(100000000, 'USD').format(), r'$1.000.000,00');
    expect(const Money(1000, 'USD').format(signed: true), r'+$10,00');
    expect(const Money(-1000, 'USD').format(), r'-$10,00');
    expect(const Money(0, 'USD').format(signed: true), r'$0,00');
  });

  test('no permite operar monedas distintas', () {
    expect(
      () => const Money(1, 'USD') + const Money(1, 'EUR'),
      throwsArgumentError,
    );
  });
}
