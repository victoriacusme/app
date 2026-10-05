import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/money/money.dart';
import '../../../../core/navigation/deep_links.dart';
import '../../../../design_system/design_system.dart';
import '../../../../l10n/l10n.dart';
import '../../../accounts/presentation/bloc/accounts_bloc.dart';
import '../../domain/experience_layout.dart';
import '../localized_text.dart';

/// Meta de ahorro: el progreso es el saldo de la cuenta asociada frente al
/// objetivo. Usa los datos de `AccountsBloc`; si la cuenta no está, se oculta.
class SavingsGoalComponent extends StatelessWidget {
  const SavingsGoalComponent({
    required this.title,
    required this.targetText,
    required this.accountId,
    this.deeplink,
    super.key,
  });

  factory SavingsGoalComponent.fromSpec(ComponentSpec spec) {
    final target = spec.properties['target'] as String;
    if (Money.tryParseCents(target) == null) {
      throw FormatException('target inválido: $target');
    }
    return SavingsGoalComponent(
      title: LocalizedText.parse(spec.properties['title']),
      targetText: target,
      accountId: spec.properties['accountId'] as String,
      deeplink: spec.properties['deeplink'] as String?,
    );
  }

  final LocalizedText title;

  static final _prefix = RegExp(
    r'^\s*(meta|goal)\s*:?\s*',
    caseSensitive: false,
  );

  /// Nombre de la meta sin el prefijo genérico ("Meta:", "Goal:").
  static String goalName(String title) {
    final name = title.replaceFirst(_prefix, '').trim();
    return name.isEmpty ? '' : '${name[0].toUpperCase()}${name.substring(1)}';
  }

  final String targetText;
  final String accountId;
  final String? deeplink;

  @override
  Widget build(BuildContext context) {
    final account = context.select(
      (AccountsBloc b) =>
          b.state.accounts.where((a) => a.id == accountId).firstOrNull,
    );
    if (account == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    // El encabezado lo pone la app; del backend solo se usa el nombre que el
    // cliente le dio a su meta ("Meta: viaje a Galápagos" → "viaje a
    // Galápagos").
    final name = goalName(title.resolve(l10n.localeName));
    final target = Money.parse(targetText, account.currency);
    final progress = target.cents <= 0
        ? 1.0
        : (account.balance.cents / target.cents).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Semantics(
        label: l10n.savingsSemantics(
          name.isEmpty ? l10n.savingsGoal : '${l10n.savingsGoal}: $name',
          account.balance.speech(l10n),
          target.speech(l10n),
          percent,
        ),
        button: deeplink != null,
        excludeSemantics: true,
        child: Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: const BorderRadius.all(Radii.lg),
            onTap: deeplink == null
                ? null
                : () => DeepLinks.open(context, deeplink!),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          l10n.savingsGoal,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Text('$percent %', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  if (name.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.xs),
                      child: Text(
                        name,
                        key: const Key('savings_goal_name'),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  const SizedBox(height: Spacing.sm),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: const BorderRadius.all(Radii.sm),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    l10n.savingsProgress(
                      account.balance.formatL(l10n),
                      target.formatL(l10n),
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
