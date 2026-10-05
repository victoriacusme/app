import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/data/snapshot.dart';
import 'package:nexo_bank/core/money/money.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/core/result/result.dart';
import 'package:nexo_bank/features/accounts/domain/account_repository.dart';
import 'package:nexo_bank/features/transfers/application/get_transfer_detail.dart';
import 'package:nexo_bank/features/transfers/domain/transfer.dart';
import 'package:nexo_bank/features/transfers/domain/transfer_repository.dart';

import '../../../helpers/accounts_fixtures.dart';

class _MockTransfers extends Mock implements TransferRepository {}

class _MockAccounts extends Mock implements AccountRepository {}

void main() {
  late _MockTransfers transfers;
  late _MockAccounts accounts;
  final transfer = Transfer(
    id: 't-1',
    status: TransferStatus.completed,
    sourceAccountId: '1',
    targetAccountId: '2',
    amount: const Money(500, 'USD'),
    createdAt: DateTime.utc(2026),
  );

  setUp(() {
    transfers = _MockTransfers();
    accounts = _MockAccounts();
  });

  test(
    'devuelve la transferencia con las cuentas para mostrar nombres',
    () async {
      when(() => transfers.getTransfer('t-1'))
          .thenAnswer((_) async => Ok(transfer));
      when(accounts.watchAccounts).thenAnswer(
        (_) => Stream.value(
          Ok(
            Snapshot(
              data: [account('1'), account('2')],
              updatedAt: DateTime.utc(2026),
            ),
          ),
        ),
      );

      final result = await GetTransferDetail(transfers, accounts)('t-1');

      final detail = (result as Ok<TransferDetail>).value;
      expect(detail.transfer, transfer);
      expect(detail.accounts, hasLength(2));
    },
  );

  test('si las cuentas fallan, igual muestra la transferencia', () async {
    when(() => transfers.getTransfer('t-1'))
        .thenAnswer((_) async => Ok(transfer));
    when(accounts.watchAccounts)
        .thenAnswer((_) => Stream.value(const Err(NetworkFailure())));

    final result = await GetTransferDetail(transfers, accounts)('t-1');

    expect((result as Ok<TransferDetail>).value.accounts, isEmpty);
  });

  test('transferencia de otro cliente o inexistente: error', () async {
    when(() => transfers.getTransfer('x')).thenAnswer(
      (_) async => const Err(
        ServerFailure(
          message: 'x',
          code: 'transfer-not-found',
          statusCode: 404,
        ),
      ),
    );

    final result = await GetTransferDetail(transfers, accounts)('x');

    expect((result as Err).failure.code, 'transfer-not-found');
    verifyNever(accounts.watchAccounts);
  });
}
