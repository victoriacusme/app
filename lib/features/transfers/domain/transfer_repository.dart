import '../../../core/result/result.dart';
import 'transfer.dart';

abstract interface class TransferRepository {
  /// Envía la transferencia. Con la misma [idempotencyKey] el backend
  /// nunca la ejecuta dos veces: devuelve el resultado original.
  Future<Result<Transfer>> transferBetweenOwnAccounts(
    TransferDraft draft, {
    required String idempotencyKey,
  });

  /// Detalle de una transferencia propia (p. ej. al abrir un push).
  Future<Result<Transfer>> getTransfer(String id);
}
