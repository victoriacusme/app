import '../../../core/data/snapshot.dart';
import '../../../core/result/result.dart';
import 'account.dart';
import 'movement.dart';

/// Puerto de cuentas. Las lecturas siguen stale-while-revalidate: primero
/// emiten lo guardado y luego lo que llega del backend.
abstract interface class AccountRepository {
  /// Emite la caché (si existe) y luego el dato remoto. Si el remoto falla:
  /// con caché emite `Ok` con `refreshFailure`; sin caché emite `Err`.
  Stream<Result<Snapshot<List<Account>>>> watchAccounts();

  /// Igual que [watchAccounts], para la primera página de movimientos.
  Stream<Result<Snapshot<MovementPage>>> watchMovements(String accountId);

  /// Páginas siguientes (no se guardan en caché).
  Future<Result<MovementPage>> getMovementsPage(
    String accountId, {
    required String cursor,
  });

  /// Avisa que los saldos cambiaron (por ejemplo, tras una transferencia).
  Stream<void> get changes;

  /// Descarta la caché de movimientos de esas cuentas y emite en [changes].
  Future<void> invalidate({Iterable<String> accountIds = const []});
}
