import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../accounts/domain/account.dart';

enum TransferStatus { completed, unknown }

class Transfer extends Equatable {
  const Transfer({
    required this.id,
    required this.status,
    required this.sourceAccountId,
    required this.targetAccountId,
    required this.amount,
    required this.createdAt,
    this.description,
  });

  final String id;
  final TransferStatus status;
  final String sourceAccountId;
  final String targetAccountId;
  final Money amount;
  final DateTime createdAt;
  final String? description;

  @override
  List<Object?> get props => [
    id,
    status,
    sourceAccountId,
    targetAccountId,
    amount,
    createdAt,
    description,
  ];
}

/// Lo que el cliente quiere transferir, ya validado.
class TransferDraft extends Equatable {
  const TransferDraft({
    required this.source,
    required this.target,
    required this.amount,
    this.description,
  });

  final Account source;
  final Account target;
  final Money amount;
  final String? description;

  @override
  List<Object?> get props => [source.id, target.id, amount, description];
}
