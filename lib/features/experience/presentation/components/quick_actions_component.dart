import 'package:flutter/material.dart';

import '../../../../core/navigation/deep_links.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/experience_layout.dart';

class QuickAction {
  const QuickAction({
    required this.label,
    required this.icon,
    required this.deeplink,
  });

  final String label;
  final String icon;
  final String deeplink;
}

class QuickActionsComponent extends StatelessWidget {
  const QuickActionsComponent({required this.actions, super.key});

  factory QuickActionsComponent.fromSpec(ComponentSpec spec) =>
      QuickActionsComponent(
        actions: [
          for (final a in spec.properties['actions'] as List<dynamic>)
            QuickAction(
              label: (a as Map)['label'] as String,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final action in actions)
            Expanded(
              child: Semantics(
                button: true,
                label: action.label,
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
                          action.label,
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
