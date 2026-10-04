import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/money/money.dart';
import '../../../../core/navigation/deep_links.dart';
import '../../../../design_system/design_system.dart';
import '../../../accounts/presentation/bloc/accounts_bloc.dart';
import '../../domain/experience_layout.dart';

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
      title: spec.properties['title'] as String,
      targetText: target,
      accountId: spec.properties['accountId'] as String,
      deeplink: spec.properties['deeplink'] as String?,
    );
  }

  final String title;
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

    final target = Money.parse(targetText, account.currency);
    final progress = target.cents <= 0
        ? 1.0
        : (account.balance.cents / target.cents).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Semantics(
        label:
            '$title. Llevas ${account.balance.toSpeech()} de '
            '${target.toSpeech()}, $percent por ciento',
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
                        child: Text(title, style: theme.textTheme.titleMedium),
                      ),
                      Text('$percent %', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: const BorderRadius.all(Radii.sm),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    '${account.balance.format()} de ${target.format()}',
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
