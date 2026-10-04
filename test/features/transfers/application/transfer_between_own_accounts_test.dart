import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/money/money.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/core/result/result.dart';
import 'package:nexo_bank/features/accounts/domain/account_repository.dart';
import 'package:nexo_bank/features/transfers/application/transfer_between_own_accounts.dart';
import 'package:nexo_bank/features/transfers/domain/transfer.dart';
import 'package:nexo_bank/features/transfers/domain/transfer_notifier.dart';
import 'package:nexo_bank/features/transfers/domain/transfer_repository.dart';

import '../../../helpers/accounts_fixtures.dart';

class _MockTransfers extends Mock implements TransferRepository {}

class _MockAccounts extends Mock implements AccountRepository {}

class _MockNotifier extends Mock implements TransferNotifier {}

final _transfer = Transfer(
  id: 't',
  status: TransferStatus.completed,
  sourceAccountId: '1',
  targetAccountId: '2',
  amount: const Money(100, 'USD'),
  createdAt: DateTime.utc(2026),
);

void main() {
  late _MockTransfers transfers;
  late _MockAccounts accounts;
  late _MockNotifier notifier;
  late TransferBetweenOwnAccounts useCase;
  final draft = TransferDraft(
    source: account('1'),
    target: account('2'),
    amount: const Money(100, 'USD'),
  );

  setUpAll(() {
    registerFallbackValue(draft);
    registerFallbackValue(_transfer);
  });

  setUp(() {
    transfers = _MockTransfers();
    accounts = _MockAccounts();
    notifier = _MockNotifier();
    useCase = TransferBetweenOwnAccounts(transfers, accounts, notifier);
    when(() => notifier.transferCompleted(any(), any()))
        .thenAnswer((_) async {});
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
    verify(() => notifier.transferCompleted(draft, any())).called(1);
  });

  test('si la notificación falla, la transferencia igual es exitosa', () async {
    when(() => transfers.transferBetweenOwnAccounts(draft, idempotencyKey: 'k'))
        .thenAnswer((_) async => Ok(_transfer));
    when(() => notifier.transferCompleted(any(), any()))
        .thenThrow(Exception('sin permiso'));

    final result = await useCase(draft, idempotencyKey: 'k');

    expect(result.isOk, isTrue);
  });

  test('si falla no toca la caché', () async {
    when(() => transfers.transferBetweenOwnAccounts(draft, idempotencyKey: 'k'))
        .thenAnswer((_) async => const Err(TimeoutFailure()));

    await useCase(draft, idempotencyKey: 'k');

    verifyNever(
      () => accounts.invalidate(accountIds: any(named: 'accountIds')),
    );
    verifyNever(() => notifier.transferCompleted(any(), any()));
  });
}
