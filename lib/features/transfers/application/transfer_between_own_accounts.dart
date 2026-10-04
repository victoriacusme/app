import '../../../core/result/result.dart';
import '../../accounts/domain/account_repository.dart';
import '../domain/transfer.dart';
import '../domain/transfer_repository.dart';

class TransferBetweenOwnAccounts {
  const TransferBetweenOwnAccounts(this._transfers, this._accounts);

  final TransferRepository _transfers;
  final AccountRepository _accounts;

  Future<Result<Transfer>> call(
    TransferDraft draft, {
    required String idempotencyKey,
  }) async {
    final result = await _transfers.transferBetweenOwnAccounts(
      draft,
      idempotencyKey: idempotencyKey,
    );
    if (result.isOk) {
      // Los saldos y movimientos guardados ya no son válidos.
      await _accounts.invalidate(
        accountIds: [draft.source.id, draft.target.id],
      );
    }
    return result;
  }
}
