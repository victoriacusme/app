import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/movement.dart';

class MovementTile extends StatelessWidget {
  const MovementTile({required this.movement, super.key});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = movement.type == MovementType.credit;
    final color = isCredit ? NexoColors.success : theme.colorScheme.onSurface;
    final description = movement.description?.isNotEmpty ?? false
        ? movement.description!
        : (isCredit ? 'Crédito' : 'Débito');
    return Semantics(
      label:
          '$description, ${isCredit ? 'ingreso' : 'egreso'} de '
          '${movement.amount.toSpeech()}, ${DateTexts.time(movement.bookedAt)}',
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
          '${DateTexts.time(movement.bookedAt)} · '
          'Saldo ${movement.balanceAfter.format()}',
        ),
        trailing: Text(
          movement.signedAmount.format(signed: true),
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
