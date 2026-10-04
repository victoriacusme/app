import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/experience_layout.dart';

class GreetingComponent extends StatelessWidget {
  const GreetingComponent({required this.title, this.subtitle, super.key});

  factory GreetingComponent.fromSpec(ComponentSpec spec) => GreetingComponent(
    title: spec.properties['title'] as String,
    subtitle: spec.properties['subtitle'] as String?,
  );

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.headlineSmall),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
