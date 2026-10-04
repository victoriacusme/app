import '../../../core/money/money.dart';
import '../domain/account.dart';
import '../domain/movement.dart';

/// Mapeo manual del JSON de ms-accounts. Los valores desconocidos de los
/// enums no rompen la app: se mapean a `unknown`.
abstract final class AccountDtos {
  static List<Account> accountList(Map<String, dynamic> json) =>
      (json['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(account)
          .toList();

  static Account account(Map<String, dynamic> json) {
    final currency = json['currency'] as String;
    return Account(
      id: json['id'] as String,
      maskedNumber: json['number'] as String,
      type: switch (json['type']) {
        'SAVINGS' => AccountType.savings,
        'CHECKING' => AccountType.checking,
        _ => AccountType.unknown,
      },
      balance: Money.parse(json['balance'] as String, currency),
      status: switch (json['status']) {
        'ACTIVE' => AccountStatus.active,
        'BLOCKED' => AccountStatus.blocked,
        'CLOSED' => AccountStatus.closed,
        _ => AccountStatus.unknown,
      },
      alias: json['alias'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// La API de movimientos no repite la moneda: se toma de la cuenta.
  static MovementPage movementPage(
    Map<String, dynamic> json, {
    required String currency,
  }) => MovementPage(
    items: (json['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((m) => movement(m, currency: currency))
        .toList(),
    nextCursor: json['nextCursor'] as String?,
  );

  static Movement movement(
    Map<String, dynamic> json, {
    required String currency,
  }) => Movement(
    id: json['id'] as String,
    type: json['type'] == 'CREDIT' ? MovementType.credit : MovementType.debit,
    amount: Money.parse(json['amount'] as String, currency),
    balanceAfter: Money.parse(json['balanceAfter'] as String, currency),
    description: json['description'] as String?,
    bookedAt: DateTime.parse(json['bookedAt'] as String),
  );
}
