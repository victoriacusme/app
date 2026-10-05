part of 'own_transfer_bloc.dart';

sealed class OwnTransferEvent {
  const OwnTransferEvent();
}

final class TransferStarted extends OwnTransferEvent {
  const TransferStarted({this.sourceAccountId});

  final String? sourceAccountId;
}

final class TransferSourceChanged extends OwnTransferEvent {
  const TransferSourceChanged(this.accountId);

  final String accountId;
}

final class TransferTargetChanged extends OwnTransferEvent {
  const TransferTargetChanged(this.accountId);

  final String accountId;
}

final class TransferAmountChanged extends OwnTransferEvent {
  const TransferAmountChanged(this.text);

  final String text;
}

final class TransferDescriptionChanged extends OwnTransferEvent {
  const TransferDescriptionChanged(this.text);

  final String text;
}

/// "Continuar": valida y pasa a la pantalla de confirmación.
final class TransferReviewRequested extends OwnTransferEvent {
  const TransferReviewRequested();
}

/// Volver a editar desde la confirmación o tras un rechazo.
final class TransferEditRequested extends OwnTransferEvent {
  const TransferEditRequested();
}

/// "Confirmar" o, en estado desconocido, "Verificar estado". Ambos envían
/// la misma Idempotency-Key, así que nunca se duplica la transferencia.
final class TransferConfirmed extends OwnTransferEvent {
  const TransferConfirmed();
}

/// Empezar una transferencia nueva desde el comprobante.
final class TransferRestarted extends OwnTransferEvent {
  const TransferRestarted();
}
