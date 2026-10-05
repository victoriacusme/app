import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';

enum AccountType { savings, checking, unknown }

enum AccountStatus { active, blocked, closed, unknown }

class Account extends Equatable {
  const Account({
    required this.id,
    required this.maskedNumber,
    required this.type,
    required this.balance,
    required this.status,
    required this.isDefault,
    this.alias,
  });

  final String id;

  /// Siempre enmascarado desde el backend (`****4521`).
  final String maskedNumber;
  final AccountType type;
  final Money balance;
  final AccountStatus status;
  final bool isDefault;
  final String? alias;

  String get currency => balance.currency;
  bool get isActive => status == AccountStatus.active;

  @override
  List<Object?> get props => [
    id,
    maskedNumber,
    type,
    balance,
    status,
    isDefault,
    alias,
  ];
}
