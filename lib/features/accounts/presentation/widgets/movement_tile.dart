import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/movement.dart';

class MovementTile extends StatelessWidget {
  const MovementTile({required this.movement, super.key});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isCredit = movement.type == MovementType.credit;
    final color = isCredit ? NexoColors.success : theme.colorScheme.onSurface;
    final time = l10n.time(movement.bookedAt);
    final description = movement.description?.isNotEmpty ?? false
        ? movement.description!
        : (isCredit ? l10n.movementCredit : l10n.movementDebit);
    return Semantics(
      label: l10n.movementSemantics(
        description,
        isCredit ? l10n.movementIncoming : l10n.movementOutgoing,
        movement.amount.speech(l10n),
        time,
      ),
      excludeSemantics: true,
      child: ListTile(
        minVerticalPadding: Spacing.sm,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            isCredit ? Icons.south_west : Icons.north_east,
            color: color,
            size: 20,
          ),
        ),
        title: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          l10n.movementSubtitle(time, movement.balanceAfter.formatL(l10n)),
        ),
        trailing: Text(
          movement.signedAmount.formatL(l10n, signed: true),
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
