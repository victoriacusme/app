import 'package:flutter/widgets.dart';

import '../domain/experience_layout.dart';
import 'components/accounts_summary_component.dart';
import 'components/fx_rates_component.dart';
import 'components/greeting_component.dart';
import 'components/promo_banner_component.dart';
import 'components/quick_actions_component.dart';
import 'components/savings_goal_component.dart';

/// Crea el widget a partir de las props. Puede lanzar si las props no son
/// válidas: el registry lo atrapa y omite el componente.
typedef ComponentFactory = Widget Function(ComponentSpec spec);

/// Traduce cada `type` del SDUI a un widget.
///
/// - Un `type` desconocido se **ignora** (así el backend puede publicar
///   componentes nuevos sin romper versiones viejas de la app).
/// - Un componente con props inválidas también se omite.
class ComponentRegistry {
  const ComponentRegistry(this._factories);

  factory ComponentRegistry.defaults() => const ComponentRegistry({
    'greeting': GreetingComponent.fromSpec,
    'accounts_summary': AccountsSummaryComponent.fromSpec,
    'quick_actions': QuickActionsComponent.fromSpec,
    'promo_banner': PromoBannerComponent.fromSpec,
    'savings_goal': SavingsGoalComponent.fromSpec,
    'fx_rates': FxRatesComponent.fromSpec,
  });

  final Map<String, ComponentFactory> _factories;

  bool supports(String type) => _factories.containsKey(type);

  Widget? build(ComponentSpec spec) {
    final factory = _factories[spec.type];
    if (factory == null) {
      debugPrint('SDUI: tipo "${spec.type}" no soportado, se ignora');
      return null;
    }
    try {
      return KeyedSubtree(key: ValueKey(spec.id), child: factory(spec));
    } catch (e) {
      debugPrint('SDUI: props inválidas en "${spec.type}" (${spec.id}): $e');
      return null;
    }
  }
}
