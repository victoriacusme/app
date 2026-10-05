import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/connectivity/connectivity_cubit.dart';
import 'package:nexo_bank/core/money/money.dart';
import 'package:nexo_bank/features/transfers/domain/transfer.dart';
import 'package:nexo_bank/features/transfers/presentation/bloc/own_transfer_bloc.dart';
import 'package:nexo_bank/features/transfers/presentation/pages/transfer_page.dart';

import '../../../helpers/accounts_fixtures.dart';
import '../../../helpers/pump_app.dart';

class _MockTransferBloc extends MockBloc<OwnTransferEvent, OwnTransferState>
    implements OwnTransferBloc {}

void main() {
  late _MockTransferBloc bloc;
  final accounts = [
    account('1', cents: 10000, alias: 'Ahorros'),
    account('2', cents: 500, alias: 'Viaje'),
    account('3', cents: 0, alias: 'Gastos'),
  ];
  final editing = OwnTransferState(
    step: TransferStep.editing,
    accounts: accounts,
    sourceId: '1',
    targetId: '2',
    amountText: '25.50',
  );

  setUpAll(() => registerFallbackValue(const TransferConfirmed()));
  setUp(() => bloc = _MockTransferBloc());

  Future<void> pump(
    WidgetTester tester,
    OwnTransferState state, {
    bool offline = false,
  }) async {
    when(() => bloc.state).thenReturn(state);
    final connectivity = MockConnectivityCubit();
    when(() => connectivity.state).thenReturn(
      offline ? ConnectivityStatus.offline : ConnectivityStatus.online,
    );
    await pumpPage(
      tester,
      const TransferPage(),
      connectivity: connectivity,
      providers: [BlocProvider<OwnTransferBloc>.value(value: bloc)],
    );
  }

  testWidgets('el destino no ofrece la cuenta de origen', (tester) async {
    await pump(tester, editing);

    await tester.tap(find.byKey(const Key('transfer_target')));
    await tester.pumpAndSettle();

    final options = find.descendant(
      of: find.byType(Scrollable).last,
      matching: find.textContaining('Ahorros'),
    );
    expect(options, findsNothing);
    expect(find.textContaining('Viaje'), findsWidgets);
    expect(find.textContaining('Gastos'), findsWidgets);
  });

  testWidgets('muestra el saldo disponible y el error de saldo insuficiente', (
    tester,
  ) async {
    await pump(
      tester,
      OwnTransferState(
        step: TransferStep.editing,
        accounts: accounts,
        sourceId: '1',
        targetId: '2',
        amountText: '200',
        showErrors: true,
      ),
    );

    expect(find.textContaining(r'Disponible: $100,00'), findsWidgets);
    expect(find.textContaining('Saldo insuficiente'), findsOneWidget);
  });

  testWidgets('escribir el monto y continuar envía los eventos', (
    tester,
  ) async {
    await pump(tester, editing.copyWith(amountText: ''));

    await tester.enterText(find.byKey(const Key('transfer_amount')), '12,5');
    await tester.tap(find.byKey(const Key('transfer_continue')));

    verify(
      () => bloc.add(
        any(
          that: isA<TransferAmountChanged>().having(
            (e) => e.text,
            'text',
            '12,5',
          ),
        ),
      ),
    ).called(1);
    verify(() => bloc.add(any(that: isA<TransferReviewRequested>()))).called(1);
  });

  testWidgets('en la confirmación, sin conexión, el botón está deshabilitado', (
    tester,
  ) async {
    await pump(
      tester,
      editing.copyWith(
        step: TransferStep.confirming,
        idempotencyKey: () => 'k',
      ),
      offline: true,
    );

    expect(find.byKey(const Key('transfer_offline')), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('transfer_confirm')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('confirmar envía TransferConfirmed', (tester) async {
    await pump(
      tester,
      editing.copyWith(
        step: TransferStep.confirming,
        idempotencyKey: () => 'k',
      ),
    );

    expect(find.text(r'$25,50'), findsOneWidget);
    await tester.tap(find.byKey(const Key('transfer_confirm')));

    verify(() => bloc.add(any(that: isA<TransferConfirmed>()))).called(1);
  });

  testWidgets('resultado desconocido ofrece verificar el estado', (
    tester,
  ) async {
    await pump(
      tester,
      editing.copyWith(step: TransferStep.unknown, idempotencyKey: () => 'k'),
    );

    expect(find.text('No pudimos confirmar el resultado'), findsOneWidget);
    await tester.tap(find.byKey(const Key('transfer_check_status')));

    verify(() => bloc.add(any(that: isA<TransferConfirmed>()))).called(1);
  });

  testWidgets('el comprobante muestra monto e identificador', (tester) async {
    await pump(
      tester,
      editing.copyWith(
        step: TransferStep.success,
        transfer: () => Transfer(
          id: 'abcd1234-0000',
          status: TransferStatus.completed,
          sourceAccountId: '1',
          targetAccountId: '2',
          amount: const Money(2550, 'USD'),
          createdAt: DateTime.utc(2026, 10, 4, 15),
        ),
      ),
    );

    expect(find.byKey(const Key('transfer_success')), findsOneWidget);
    expect(find.text(r'$25,50'), findsOneWidget);
    expect(find.text('ABCD1234'), findsOneWidget);
  });
}
