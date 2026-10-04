import '../../../core/navigation/deep_links.dart';
import '../../transfers/domain/transfer.dart';
import '../../transfers/domain/transfer_notifier.dart';
import '../infrastructure/local_notifications_service.dart';

/// Aviso local tras una transferencia exitosa. Respeta la preferencia de
/// notificaciones del cliente y no incluye datos completos de las cuentas.
class LocalTransferNotifier implements TransferNotifier {
  LocalTransferNotifier({required this._service, required this._isEnabled});

  final LocalNotificationsService _service;
  final bool Function() _isEnabled;

  @override
  Future<void> transferCompleted(TransferDraft draft, Transfer transfer) async {
    if (!_isEnabled() || !await _service.requestPermission()) return;
    await _service.show(
      id: transfer.id.hashCode & 0x7fffffff,
      title: 'Transferencia realizada',
      body:
          'Enviaste ${transfer.amount.format()} de '
          '${draft.source.displayName} ${draft.source.maskedNumber} a '
          '${draft.target.displayName} ${draft.target.maskedNumber}.',
      deepLink: DeepLinks.accountLink(draft.source.id),
    );
  }
}
