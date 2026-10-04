import 'dart:async';

import '../../../core/result/result.dart';
import '../../accounts/domain/account_repository.dart';
import '../domain/transfer.dart';
import '../domain/transfer_notifier.dart';
import '../domain/transfer_repository.dart';

class TransferBetweenOwnAccounts {
  const TransferBetweenOwnAccounts(
    this._transfers,
    this._accounts, [
    this._notifier,
  ]);

  final TransferRepository _transfers;
  final AccountRepository _accounts;
  final TransferNotifier? _notifier;

  Future<Result<Transfer>> call(
    TransferDraft draft, {
    required String idempotencyKey,
  }) async {
    final result = await _transfers.transferBetweenOwnAccounts(
      draft,
      idempotencyKey: idempotencyKey,
    );
    if (result case Ok(value: final transfer)) {
      // Los saldos y movimientos guardados ya no son válidos.
      await _accounts.invalidate(
        accountIds: [draft.source.id, draft.target.id],
      );
      // No se espera: pedir el permiso de notificaciones puede mostrar un
      // diálogo, y el comprobante no debe quedar bloqueado por eso. Un fallo
      // al notificar tampoco cambia el resultado de la transferencia.
      if (_notifier case final notifier?) {
        unawaited(
          Future.sync(() => notifier.transferCompleted(draft, transfer))
              .catchError((Object _) {}),
        );
      }
    }
    return result;
  }
}
