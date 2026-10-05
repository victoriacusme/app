import '../../../core/navigation/deep_links.dart';
import '../../../l10n/domain_l10n.dart';
import '../../../l10n/l10n.dart';
import '../../transfers/domain/transfer.dart';
import '../../transfers/domain/transfer_notifier.dart';
import '../domain/remote_push.dart';
import '../infrastructure/local_notifications_service.dart';

/// Aviso local tras una transferencia exitosa. Respeta la preferencia de
/// notificaciones del cliente y no incluye datos completos de las cuentas.
/// El texto se arma en el idioma activo de la app.
class LocalTransferNotifier implements TransferNotifier {
  LocalTransferNotifier({
    required this._service,
    required this._isEnabled,
    required this._l10n,
  });

  final LocalNotificationsService _service;
  final bool Function() _isEnabled;
  final AppLocalizations Function() _l10n;

  @override
  Future<void> transferCompleted(TransferDraft draft, Transfer transfer) async {
    if (!_isEnabled() || !await _service.requestPermission()) return;
    final l10n = _l10n();
    await _service.show(
      // La push del backend para esta transferencia usa el mismo id.
      id: notificationIdFor(transfer.id),
      title: l10n.notificationTransferTitle,
      body: l10n.notificationTransferBody(
        transfer.amount.formatL(l10n),
        draft.source.label(l10n),
        draft.target.label(l10n),
      ),
      channelName: l10n.notificationChannelName,
      channelDescription: l10n.notificationChannelDescription,
      deepLink: DeepLinks.accountLink(draft.source.id),
    );
  }
}
