import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/money/money.dart';
import 'package:nexo_bank/core/network/error_mapper.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/core/result/result.dart';
import 'package:nexo_bank/features/accounts/domain/account.dart';
import 'package:nexo_bank/features/transfers/application/get_own_accounts.dart';
import 'package:nexo_bank/features/transfers/application/transfer_between_own_accounts.dart';
import 'package:nexo_bank/features/transfers/domain/transfer.dart';
import 'package:nexo_bank/features/transfers/presentation/bloc/own_transfer_bloc.dart';

import '../../../helpers/accounts_fixtures.dart';

class _MockGetOwnAccounts extends Mock implements GetOwnAccounts {}

class _MockTransfer extends Mock implements TransferBetweenOwnAccounts {}

void main() {
  late _MockGetOwnAccounts getAccounts;
  late _MockTransfer transfer;
  late int keyCounter;

  final source = account('1', cents: 10000, isDefault: true, alias: 'Ahorros');
  final target = account('2', cents: 500);
  final blocked = account('3', status: AccountStatus.blocked);
  final done = Transfer(
    id: 't-1',
    status: TransferStatus.completed,
    sourceAccountId: '1',
    targetAccountId: '2',
    amount: const Money(2550, 'USD'),
    createdAt: DateTime.utc(2026, 10, 4),
  );

  setUpAll(() {
    registerFallbackValue(
      TransferDraft(
        source: source,
        target: target,
        amount: const Money(1, 'USD'),
      ),
    );
  });

  setUp(() {
    getAccounts = _MockGetOwnAccounts();
    transfer = _MockTransfer();
    keyCounter = 0;
    when(() => getAccounts())
        .thenAnswer((_) async => Ok([source, target, blocked]));
  });

  OwnTransferBloc build() => OwnTransferBloc(
    getOwnAccounts: getAccounts,
    transfer: transfer,
    newIdempotencyKey: () => 'key-${++keyCounter}',
  );

  OwnTransferState editing({String amount = '25.50'}) => OwnTransferState(
    step: TransferStep.editing,
    accounts: [source, target, blocked],
    sourceId: '1',
    targetId: '2',
    amountText: amount,
  );

  void transferReturns(Result<Transfer> result) =>
      when(() => transfer(any(), idempotencyKey: any(named: 'idempotencyKey')))
          .thenAnswer((_) async => result);

  group('inicio', () {
    blocTest<OwnTransferBloc, OwnTransferState>(
      'preselecciona la cuenta principal y, si solo hay un destino, ese',
      build: build,
      act: (b) => b.add(const TransferStarted()),
      skip: 1,
      expect: () => [
        isA<OwnTransferState>()
            .having((s) => s.step, 'step', TransferStep.editing)
            .having((s) => s.sourceId, 'source', '1')
            .having((s) => s.targetId, 'target', '2')
            .having((s) => s.targets.map((a) => a.id), 'targets', ['2']),
      ],
    );

    blocTest<OwnTransferBloc, OwnTransferState>(
      'el destino nunca incluye el origen ni cuentas bloqueadas',
      build: build,
      seed: editing,
      act: (b) => b.add(const TransferSourceChanged('2')),
      verify: (b) {
        expect(b.state.targets.map((a) => a.id), ['1']);
        expect(b.state.targetId, '1');
      },
    );
  });

  group('validación', () {
    blocTest<OwnTransferBloc, OwnTransferState>(
      'monto mayor al saldo: muestra error y no avanza',
      build: build,
      seed: () => editing(amount: '100.01'),
      act: (b) => b.add(const TransferReviewRequested()),
      expect: () => [
        isA<OwnTransferState>()
            .having((s) => s.step, 'step', TransferStep.editing)
            .having((s) => s.showErrors, 'showErrors', true)
            .having(
              (s) => s.amountError,
              'error',
              contains('Saldo insuficiente'),
            ),
      ],
    );

    blocTest<OwnTransferBloc, OwnTransferState>(
      'monto cero o inválido no avanza',
      build: build,
      seed: () => editing(amount: '0'),
      act: (b) => b.add(const TransferReviewRequested()),
      verify: (b) {
        expect(b.state.step, TransferStep.editing);
        expect(b.state.amountError, contains('mayor a cero'));
      },
    );
  });

  group('envío', () {
    blocTest<OwnTransferBloc, OwnTransferState>(
      'éxito: editing → confirming → submitting → success con una sola clave',
      setUp: () => transferReturns(Ok(done)),
      build: build,
      seed: editing,
      act: (b) => b
        ..add(const TransferReviewRequested())
        ..add(const TransferConfirmed()),
      expect: () => [
        isA<OwnTransferState>()
            .having((s) => s.step, 'step', TransferStep.confirming)
            .having((s) => s.idempotencyKey, 'key', 'key-1'),
        isA<OwnTransferState>().having(
          (s) => s.step,
          'step',
          TransferStep.submitting,
        ),
        isA<OwnTransferState>()
            .having((s) => s.step, 'step', TransferStep.success)
            .having((s) => s.transfer, 'transfer', done),
      ],
      verify: (_) {
        final draft =
            verify(() => transfer(captureAny(), idempotencyKey: 'key-1'))
                    .captured
                    .single
                as TransferDraft;
        expect(draft.amount, const Money(2550, 'USD'));
      },
    );

    blocTest<OwnTransferBloc, OwnTransferState>(
      'saldo insuficiente (422): rejected con mensaje claro',
      setUp: () => transferReturns(
        const Err(
          ValidationFailure(
            message: 'x',
            code: 'insufficient-funds',
            statusCode: 422,
          ),
        ),
      ),
      build: build,
      seed: () => editing().copyWith(
        step: TransferStep.confirming,
        idempotencyKey: () => 'key-1',
      ),
      act: (b) => b.add(const TransferConfirmed()),
      skip: 1,
      expect: () => [
        isA<OwnTransferState>()
            .having((s) => s.step, 'step', TransferStep.rejected)
            .having(
              (s) => s.failureMessage,
              'msg',
              contains('Saldo insuficiente'),
            ),
      ],
    );

    blocTest<OwnTransferBloc, OwnTransferState>(
      'timeout → unknown; "verificar estado" reenvía la MISMA clave',
      setUp: () {
        var calls = 0;
        when(
          () => transfer(any(), idempotencyKey: any(named: 'idempotencyKey')),
        ).thenAnswer(
          (_) async => ++calls == 1 ? const Err(TimeoutFailure()) : Ok(done),
        );
      },
      build: build,
      seed: () => editing().copyWith(
        step: TransferStep.confirming,
        idempotencyKey: () => 'key-1',
      ),
      act: (b) async {
        b.add(const TransferConfirmed());
        await Future<void>.delayed(Duration.zero);
        b.add(const TransferConfirmed());
      },
      expect: () => [
        isA<OwnTransferState>().having(
          (s) => s.step,
          's',
          TransferStep.submitting,
        ),
        isA<OwnTransferState>().having(
          (s) => s.step,
          's',
          TransferStep.unknown,
        ),
        isA<OwnTransferState>().having(
          (s) => s.step,
          's',
          TransferStep.submitting,
        ),
        isA<OwnTransferState>().having(
          (s) => s.step,
          's',
          TransferStep.success,
        ),
      ],
      verify: (_) =>
          verify(() => transfer(any(), idempotencyKey: 'key-1')).called(2),
    );

    blocTest<OwnTransferBloc, OwnTransferState>(
      'un 5xx también es resultado desconocido',
      setUp: () => transferReturns(const Err(ServerFailure(statusCode: 504))),
      build: build,
      seed: () => editing().copyWith(
        step: TransferStep.confirming,
        idempotencyKey: () => 'key-1',
      ),
      act: (b) => b.add(const TransferConfirmed()),
      verify: (b) => expect(b.state.step, TransferStep.unknown),
    );

    blocTest<OwnTransferBloc, OwnTransferState>(
      'circuito abierto: la petición no salió, es un rechazo',
      setUp: () => transferReturns(
        const Err(
          ServerFailure(code: ErrorMapper.circuitOpenCode, statusCode: 503),
        ),
      ),
      build: build,
      seed: () => editing().copyWith(
        step: TransferStep.confirming,
        idempotencyKey: () => 'key-1',
      ),
      act: (b) => b.add(const TransferConfirmed()),
      verify: (b) => expect(b.state.step, TransferStep.rejected),
    );

    blocTest<OwnTransferBloc, OwnTransferState>(
      'doble toque en "Confirmar" envía una sola vez',
      setUp: () =>
          when(
            () => transfer(any(), idempotencyKey: any(named: 'idempotencyKey')),
          ).thenAnswer((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return Ok(done);
          }),
      build: build,
      seed: () => editing().copyWith(
        step: TransferStep.confirming,
        idempotencyKey: () => 'key-1',
      ),
      act: (b) => b
        ..add(const TransferConfirmed())
        ..add(const TransferConfirmed()),
      wait: const Duration(milliseconds: 30),
      verify: (_) => verify(
        () => transfer(any(), idempotencyKey: any(named: 'idempotencyKey')),
      ).called(1),
    );

    blocTest<OwnTransferBloc, OwnTransferState>(
      'editar descarta la clave: el siguiente intento usa una nueva',
      build: build,
      seed: editing,
      act: (b) => b
        ..add(const TransferReviewRequested())
        ..add(const TransferEditRequested())
        ..add(const TransferReviewRequested()),
      verify: (b) => expect(b.state.idempotencyKey, 'key-2'),
    );
  });
}
