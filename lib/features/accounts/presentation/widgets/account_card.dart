import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/domain_l10n.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/account.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({required this.account, this.onTap, super.key});

  final Account account;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final name = account.displayName(l10n);
    final type = account.typeLabel(l10n);
    return Semantics(
      button: onTap != null,
      label:
          l10n.accountSemantics(
            name,
            type,
            account.maskedNumber.replaceAll('*', ''),
            account.balance.speech(l10n),
          ) +
          (account.isActive ? '' : l10n.accountInactiveSuffix),
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
                        name,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (account.isDefault)
                      _Chip(label: l10n.accountMain, color: scheme.primary),
                    if (!account.isActive)
                      _Chip(label: l10n.accountInactive, color: scheme.error),
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  '$type · ${account.maskedNumber}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  l10n.availableBalance,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  account.balance.formatL(l10n),
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
