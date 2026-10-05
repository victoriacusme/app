import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/features/notifications/application/foreground_push_presenter.dart';
import 'package:nexo_bank/features/notifications/domain/remote_push.dart';
import 'package:nexo_bank/features/notifications/infrastructure/local_notifications_service.dart';

import '../../helpers/l10n.dart';

class _MockService extends Mock implements LocalNotificationsService {}

void main() {
  late _MockService service;
  var enabled = true;

  const push = RemotePush(
    title: 'Transferencia exitosa',
    body: r'Transferiste $10.00 a tu cuenta ****7834',
    data: {
      'type': 'TRANSFER_COMPLETED',
      'transferId': 't-1',
      'deeplink': 'app://transfers/t-1',
    },
  );

  ForegroundPushPresenter presenter() => ForegroundPushPresenter(
    service: service,
    isEnabled: () => enabled,
    l10n: () => es,
  );

  setUp(() {
    enabled = true;
    service = _MockService();
    when(
      () => service.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        channelName: any(named: 'channelName'),
        channelDescription: any(named: 'channelDescription'),
        deepLink: any(named: 'deepLink'),
      ),
    ).thenAnswer((_) async {});
  });

  test(
    'muestra la push con el id de la transferencia y su deep link',
    () async {
      await presenter().show(push);

      verify(
        () => service.show(
          // Mismo id que el aviso local: lo reemplaza, no lo duplica.
          id: notificationIdFor('t-1'),
          title: 'Transferencia exitosa',
          body: r'Transferiste $10.00 a tu cuenta ****7834',
          channelName: 'Transferencias',
          channelDescription: any(named: 'channelDescription'),
          deepLink: 'app://transfers/t-1',
        ),
      ).called(1);
    },
  );

  test('con las notificaciones desactivadas no muestra nada', () async {
    enabled = false;

    await presenter().show(push);

    verifyNever(
      () => service.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        channelName: any(named: 'channelName'),
        channelDescription: any(named: 'channelDescription'),
        deepLink: any(named: 'deepLink'),
      ),
    );
  });

  test('una push solo de datos (sin título) no se muestra', () async {
    await presenter().show(const RemotePush(data: {'type': 'SYNC'}));

    verifyNever(
      () => service.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        channelName: any(named: 'channelName'),
        channelDescription: any(named: 'channelDescription'),
        deepLink: any(named: 'deepLink'),
      ),
    );
  });

  test('escucha el flujo de mensajes en primer plano', () async {
    final messages = StreamController<RemotePush>();
    final subscription = presenter().listen(messages.stream);

    messages.add(push);
    await pumpEventQueue();

    verify(
      () => service.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        channelName: any(named: 'channelName'),
        channelDescription: any(named: 'channelDescription'),
        deepLink: any(named: 'deepLink'),
      ),
    ).called(1);
    await subscription.cancel();
    await messages.close();
  });
}
