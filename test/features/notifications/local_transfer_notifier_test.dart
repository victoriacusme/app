import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/money/money.dart';
import 'package:nexo_bank/features/notifications/application/local_transfer_notifier.dart';
import 'package:nexo_bank/features/notifications/infrastructure/local_notifications_service.dart';
import 'package:nexo_bank/features/transfers/domain/transfer.dart';

import '../../helpers/accounts_fixtures.dart';
import '../../helpers/l10n.dart';

class _MockService extends Mock implements LocalNotificationsService {}

void main() {
  late _MockService service;
  final draft = TransferDraft(
    source: account('4521', alias: 'Ahorros'),
    target: account('7834', alias: 'Viaje'),
    amount: const Money(125050, 'USD'),
  );
  final transfer = Transfer(
    id: 't-1',
    status: TransferStatus.completed,
    sourceAccountId: '4521',
    targetAccountId: '7834',
    amount: const Money(125050, 'USD'),
    createdAt: DateTime.utc(2026),
  );

  void stubShow() => when(
    () => service.show(
      id: any(named: 'id'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      channelName: any(named: 'channelName'),
      channelDescription: any(named: 'channelDescription'),
      deepLink: any(named: 'deepLink'),
    ),
  ).thenAnswer((_) async {});

  List<dynamic> captured() => verify(
    () => service.show(
      id: any(named: 'id'),
      title: captureAny(named: 'title'),
      body: captureAny(named: 'body'),
      channelName: captureAny(named: 'channelName'),
      channelDescription: any(named: 'channelDescription'),
      deepLink: captureAny(named: 'deepLink'),
    ),
  ).captured;

  setUp(() {
    service = _MockService();
    when(service.requestPermission).thenAnswer((_) async => true);
    stubShow();
  });

  test(
    'avisa en español con cuentas enmascaradas y enlaza a la cuenta',
    () async {
      await LocalTransferNotifier(
        service: service,
        isEnabled: () => true,
        l10n: () => es,
      ).transferCompleted(draft, transfer);

      final c = captured();
      expect(c[0], 'Transferencia realizada');
      expect(c[1], r'Enviaste $1.250,50 de Ahorros ****4521 a Viaje ****7834.');
      expect(c[2], 'Transferencias');
      expect(c[3], 'app://accounts/4521');
    },
  );

  test('con la app en inglés el aviso sale en inglés', () async {
    await LocalTransferNotifier(
      service: service,
      isEnabled: () => true,
      l10n: () => en,
    ).transferCompleted(draft, transfer);

    final c = captured();
    expect(c[0], 'Transfer completed');
    expect(
      c[1],
      r'You sent $1,250.50 from Savings ****4521 to Viaje ****7834.',
    );
    expect(c[2], 'Transfers');
  });

  test(
    'si el cliente desactivó los avisos no notifica ni pide permiso',
    () async {
      await LocalTransferNotifier(
        service: service,
        isEnabled: () => false,
        l10n: () => es,
      ).transferCompleted(draft, transfer);

      verifyNever(service.requestPermission);
    },
  );

  test('sin permiso del sistema no notifica', () async {
    when(service.requestPermission).thenAnswer((_) async => false);

    await LocalTransferNotifier(
      service: service,
      isEnabled: () => true,
      l10n: () => es,
    ).transferCompleted(draft, transfer);

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
}
