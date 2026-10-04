import 'package:nexo_bank/core/money/money.dart';
import 'package:nexo_bank/features/accounts/domain/account.dart';
import 'package:nexo_bank/features/accounts/domain/movement.dart';

Map<String, dynamic> accountJson(
  String id, {
  String balance = '100.00',
  String status = 'ACTIVE',
  bool isDefault = false,
  String? alias,
}) => {
  'id': id,
  'number': '****${id.padLeft(4, '0')}',
  'type': 'SAVINGS',
  'currency': 'USD',
  'balance': balance,
  'status': status,
  'alias': alias,
  'isDefault': isDefault,
};

Map<String, dynamic> accountsJson(List<Map<String, dynamic>> items) => {
  'items': items,
};

Map<String, dynamic> movementJson(
  String id, {
  String type = 'DEBIT',
  String amount = '10.00',
  String bookedAt = '2026-10-04T15:00:00Z',
}) => {
  'id': id,
  'type': type,
  'amount': amount,
  'balanceAfter': '90.00',
  'description': 'Mov $id',
  'bookedAt': bookedAt,
};

Account account(
  String id, {
  int cents = 10000,
  AccountStatus status = AccountStatus.active,
  bool isDefault = false,
  String? alias,
}) => Account(
  id: id,
  maskedNumber: '****${id.padLeft(4, '0')}',
  type: AccountType.savings,
  balance: Money(cents, 'USD'),
  status: status,
  isDefault: isDefault,
  alias: alias,
);

Movement movement(String id, {DateTime? bookedAt, bool credit = false}) =>
    Movement(
      id: id,
      type: credit ? MovementType.credit : MovementType.debit,
      amount: const Money(1000, 'USD'),
      balanceAfter: const Money(9000, 'USD'),
      description: 'Mov $id',
      bookedAt: bookedAt ?? DateTime.utc(2026, 10, 4, 15),
    );
