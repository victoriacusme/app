import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';

enum MovementType { debit, credit }

class Movement extends Equatable {
  const Movement({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.bookedAt,
    this.description,
  });

  final String id;
  final MovementType type;

  /// Siempre positivo; el signo lo da [type].
  final Money amount;
  final Money balanceAfter;
  final DateTime bookedAt;
  final String? description;

  Money get signedAmount => type == MovementType.debit ? -amount : amount;

  @override
  List<Object?> get props => [
    id,
    type,
    amount,
    balanceAfter,
    bookedAt,
    description,
  ];
}

/// Página de movimientos. [nextCursor] es `null` en la última página.
class MovementPage extends Equatable {
  const MovementPage({required this.items, this.nextCursor});

  final List<Movement> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  @override
  List<Object?> get props => [items, nextCursor];
}
