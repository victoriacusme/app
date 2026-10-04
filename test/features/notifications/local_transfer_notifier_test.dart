import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/money/money.dart';
import 'package:nexo_bank/features/notifications/application/local_transfer_notifier.dart';
import 'package:nexo_bank/features/notifications/infrastructure/local_notifications_service.dart';
import 'package:nexo_bank/features/transfers/domain/transfer.dart';

import '../../helpers/accounts_fixtures.dart';

class _MockService extends Mock implements LocalNotificationsService {}

void main() {
  late _MockService service;
  final draft = TransferDraft(
    source: account('4521', alias: 'Ahorros'),
    target: account('7834', alias: 'Viaje'),
    amount: const Money(2550, 'USD'),
  );
  final transfer = Transfer(
    id: 't-1',
    status: TransferStatus.completed,
    sourceAccountId: '4521',
    targetAccountId: '7834',
    amount: const Money(2550, 'USD'),
    createdAt: DateTime.utc(2026),
  );

  setUp(() {
    service = _MockService();
    when(service.requestPermission).thenAnswer((_) async => true);
    when(
      () => service.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        deepLink: any(named: 'deepLink'),
      ),
    ).thenAnswer((_) async {});
  });

  test(
    'avisa con montos y cuentas enmascaradas y enlaza a la cuenta',
    () async {
      await LocalTransferNotifier(
        service: service,
        isEnabled: () => true,
      ).transferCompleted(draft, transfer);

      final captured = verify(
        () => service.show(
          id: any(named: 'id'),
          title: 'Transferencia realizada',
          body: captureAny(named: 'body'),
          deepLink: captureAny(named: 'deepLink'),
        ),
      ).captured;
      expect(captured[0], contains(r'$25,50'));
      expect(captured[0], contains('****4521'));
      expect(captured[1], 'app://accounts/4521');
    },
  );

  test(
    'si el cliente desactivó los avisos no notifica ni pide permiso',
    () async {
      await LocalTransferNotifier(
        service: service,
        isEnabled: () => false,
      ).transferCompleted(draft, transfer);

      verifyNever(service.requestPermission);
    },
  );

  test('sin permiso del sistema no notifica', () async {
    when(service.requestPermission).thenAnswer((_) async => false);

    await LocalTransferNotifier(
      service: service,
      isEnabled: () => true,
    ).transferCompleted(draft, transfer);

    verifyNever(
      () => service.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        deepLink: any(named: 'deepLink'),
      ),
    );
  });
}
