import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/money/money.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/core/result/result.dart';
import 'package:nexo_bank/features/accounts/domain/account_repository.dart';
import 'package:nexo_bank/features/transfers/application/transfer_between_own_accounts.dart';
import 'package:nexo_bank/features/transfers/domain/transfer.dart';
import 'package:nexo_bank/features/transfers/domain/transfer_repository.dart';

import '../../../helpers/accounts_fixtures.dart';

class _MockTransfers extends Mock implements TransferRepository {}

class _MockAccounts extends Mock implements AccountRepository {}

void main() {
  late _MockTransfers transfers;
  late _MockAccounts accounts;
  late TransferBetweenOwnAccounts useCase;
  final draft = TransferDraft(
    source: account('1'),
    target: account('2'),
    amount: const Money(100, 'USD'),
  );

  setUp(() {
    transfers = _MockTransfers();
    accounts = _MockAccounts();
    useCase = TransferBetweenOwnAccounts(transfers, accounts);
    when(() => accounts.invalidate(accountIds: any(named: 'accountIds')))
        .thenAnswer((_) async {});
  });

  test('al tener éxito invalida la caché de ambas cuentas', () async {
    when(() => transfers.transferBetweenOwnAccounts(draft, idempotencyKey: 'k'))
        .thenAnswer(
          (_) async => Ok(
            Transfer(
              id: 't',
              status: TransferStatus.completed,
              sourceAccountId: '1',
              targetAccountId: '2',
              amount: const Money(100, 'USD'),
              createdAt: DateTime.utc(2026),
            ),
          ),
        );

    await useCase(draft, idempotencyKey: 'k');

    verify(() => accounts.invalidate(accountIds: ['1', '2'])).called(1);
  });

  test('si falla no toca la caché', () async {
    when(() => transfers.transferBetweenOwnAccounts(draft, idempotencyKey: 'k'))
        .thenAnswer((_) async => const Err(TimeoutFailure()));

    await useCase(draft, idempotencyKey: 'k');

    verifyNever(
      () => accounts.invalidate(accountIds: any(named: 'accountIds')),
    );
  });
}
