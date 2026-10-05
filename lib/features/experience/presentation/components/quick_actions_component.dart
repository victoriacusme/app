import 'package:flutter/material.dart';

import '../../../../core/navigation/deep_links.dart';
import '../../../../design_system/design_system.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/experience_layout.dart';
import '../localized_text.dart';

class QuickAction {
  const QuickAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.deeplink,
  });

  final String? id;
  final LocalizedText label;
  final String icon;
  final String deeplink;

  /// Las acciones conocidas por `id` usan el texto traducido de la app; las
  /// nuevas usan el texto del backend.
  String text(AppLocalizations l10n) {
    if (label.isLocalized) return label.resolve(l10n.localeName);
    return switch (id) {
      'transfer' => l10n.quickActionTransfer,
      'topup' => l10n.quickActionTopup,
      'goals' => l10n.quickActionGoals,
      'invest' => l10n.quickActionInvest,
      'advisor' => l10n.quickActionAdvisor,
      'collect' => l10n.quickActionCollect,
      'suppliers' => l10n.quickActionSuppliers,
      'profile' => l10n.quickActionProfile,
      _ => label.resolve(l10n.localeName),
    };
  }
}

class QuickActionsComponent extends StatelessWidget {
  const QuickActionsComponent({required this.actions, super.key});

  factory QuickActionsComponent.fromSpec(ComponentSpec spec) =>
      QuickActionsComponent(
        actions: [
          for (final a in spec.properties['actions'] as List<dynamic>)
            QuickAction(
              id: (a as Map)['id'] as String?,
              label: LocalizedText.parse(a['label']),
              icon: a['icon'] as String? ?? '',
              deeplink: a['deeplink'] as String,
            ),
        ],
      );

  final List<QuickAction> actions;

  static IconData iconFor(String name) => switch (name) {
    'swap' => Icons.swap_horiz,
    'phone' => Icons.smartphone,
    'target' => Icons.flag_outlined,
    'chart' => Icons.show_chart,
    'person' => Icons.support_agent,
    'qr' => Icons.qr_code_2,
    'store' => Icons.storefront_outlined,
    _ => Icons.apps,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final action in actions)
            Expanded(
              child: Semantics(
                button: true,
                label: action.text(l10n),
                excludeSemantics: true,
                child: InkWell(
                  key: Key('quick_action_${action.deeplink}'),
                  borderRadius: const BorderRadius.all(Radii.md),
                  onTap: () => DeepLinks.open(context, action.deeplink),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(
                            iconFor(action.icon),
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          action.text(l10n),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
