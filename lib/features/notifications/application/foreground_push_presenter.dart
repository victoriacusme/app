import 'dart:async';

import '../../../l10n/l10n.dart';
import '../domain/remote_push.dart';
import '../infrastructure/local_notifications_service.dart';

/// Muestra las push que llegan con la app abierta (Android no las muestra
/// solo). Respeta la preferencia de notificaciones del cliente.
class ForegroundPushPresenter {
  ForegroundPushPresenter({
    required this._service,
    required this._isEnabled,
    required this._l10n,
  });

  final LocalNotificationsService _service;
  final bool Function() _isEnabled;
  final AppLocalizations Function() _l10n;

  StreamSubscription<RemotePush> listen(Stream<RemotePush> messages) =>
      messages.listen(show);

  Future<void> show(RemotePush push) async {
    final title = push.title;
    if (title == null || !_isEnabled()) return;
    final l10n = _l10n();
    await _service.show(
      // Mismo id que el aviso local de la transferencia: lo reemplaza en vez
      // de duplicarlo.
      id: notificationIdFor(push.key ?? '$title${push.body}'),
      title: title,
      body: push.body ?? '',
      channelName: l10n.notificationChannelName,
      channelDescription: l10n.notificationChannelDescription,
      deepLink: push.deepLink,
    );
  }
}
