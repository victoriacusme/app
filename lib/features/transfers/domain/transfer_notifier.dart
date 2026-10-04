import 'transfer.dart';

/// Puerto para avisar al cliente que una transferencia terminó (push o
/// notificación local). Es best effort: nunca afecta el resultado.
abstract interface class TransferNotifier {
  Future<void> transferCompleted(TransferDraft draft, Transfer transfer);
}
