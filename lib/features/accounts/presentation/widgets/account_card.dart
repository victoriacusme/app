import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/account.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({required this.account, this.onTap, super.key});

  final Account account;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: onTap != null,
      label:
          '${account.displayName}, ${account.typeLabel} '
          'terminada en ${account.maskedNumber.replaceAll('*', '')}. '
          'Saldo disponible ${account.balance.toSpeech()}'
          '${account.isActive ? '' : '. Cuenta no activa'}',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        account.displayName,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (account.isDefault)
                      _Chip(label: 'Principal', color: scheme.primary),
                    if (!account.isActive)
                      _Chip(label: 'No activa', color: scheme.error),
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  '${account.typeLabel} · ${account.maskedNumber}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  'Saldo disponible',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  account.balance.format(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: Spacing.sm),
    padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: color),
      borderRadius: const BorderRadius.all(Radii.sm),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
    ),
  );
}

class AccountCardSkeleton extends StatelessWidget {
  const AccountCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 140, height: 18),
          SizedBox(height: Spacing.sm),
          Skeleton(width: 190, height: 14),
          SizedBox(height: Spacing.lg),
          Skeleton(width: 110, height: 12),
          SizedBox(height: Spacing.xs),
          Skeleton(width: 160, height: 28),
        ],
      ),
    ),
  );
}
