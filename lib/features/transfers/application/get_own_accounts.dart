import '../../../core/result/result.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_repository.dart';

/// Cuentas propias para el formulario: la versión más reciente que se
/// pueda obtener (remota o, si falla, la guardada).
class GetOwnAccounts {
  const GetOwnAccounts(this._accounts);

  final AccountRepository _accounts;

  Future<Result<List<Account>>> call() async {
    Result<List<Account>>? last;
    await for (final result in _accounts.watchAccounts()) {
      last = switch (result) {
        Ok(value: final snapshot) => Ok(snapshot.data),
        Err(:final failure) => Err(failure),
      };
    }
    return last!;
  }
}
