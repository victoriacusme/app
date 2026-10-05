import '../../../core/result/result.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_repository.dart';
import '../domain/transfer.dart';
import '../domain/transfer_repository.dart';

typedef TransferDetail = ({Transfer transfer, List<Account> accounts});

/// Transferencia y cuentas propias (para mostrar nombres en lugar de ids).
/// Si las cuentas no cargan, el detalle igual se muestra.
class GetTransferDetail {
  const GetTransferDetail(this._transfers, this._accounts);

  final TransferRepository _transfers;
  final AccountRepository _accounts;

  Future<Result<TransferDetail>> call(String id) async {
    final transfer = await _transfers.getTransfer(id);
    if (transfer case Err(:final failure)) return Err(failure);
    var accounts = const <Account>[];
    final last = await _accounts.watchAccounts().last;
    if (last case Ok(value: final snapshot)) accounts = snapshot.data;
    return Ok((transfer: (transfer as Ok<Transfer>).value, accounts: accounts));
  }
}
