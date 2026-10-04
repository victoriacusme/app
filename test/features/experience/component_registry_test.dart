import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/features/experience/domain/experience_layout.dart';
import 'package:nexo_bank/features/experience/presentation/component_registry.dart';
import 'package:nexo_bank/features/experience/presentation/components/greeting_component.dart';

void main() {
  final registry = ComponentRegistry.defaults();

  test('un tipo desconocido se ignora', () {
    expect(
      registry.build(const ComponentSpec(id: '1', type: 'cash_flow_chart')),
      isNull,
    );
  });

  test('props inválidas: el componente se omite sin romper el home', () {
    expect(
      registry.build(
        const ComponentSpec(
          id: '1',
          type: 'greeting',
          properties: {'title': 3},
        ),
      ),
      isNull,
    );
    expect(
      registry.build(
        const ComponentSpec(
          id: '2',
          type: 'savings_goal',
          properties: {'title': 'Meta', 'target': 'mil', 'accountId': 'a'},
        ),
      ),
      isNull,
    );
  });

  test('un tipo conocido crea su widget', () {
    final widget = registry.build(
      const ComponentSpec(
        id: '1',
        type: 'greeting',
        properties: {'title': 'Hola'},
      ),
    );

    expect((widget! as KeyedSubtree).child, isA<GreetingComponent>());
  });

  test('soporta los componentes del contrato', () {
    for (final type in [
      'greeting',
      'accounts_summary',
      'quick_actions',
      'promo_banner',
      'savings_goal',
      'fx_rates',
    ]) {
      expect(registry.supports(type), isTrue, reason: type);
    }
  });
}
