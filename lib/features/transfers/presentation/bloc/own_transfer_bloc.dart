import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/money/money.dart';
import '../../../../core/network/error_mapper.dart';
import '../../../../core/result/failure.dart';
import '../../../../core/result/result.dart';
import '../../../accounts/domain/account.dart';
import '../../application/get_own_accounts.dart';
import '../../application/transfer_between_own_accounts.dart';
import '../../domain/transfer.dart';
import '../../domain/transfer_rules.dart';

part 'own_transfer_event.dart';
part 'own_transfer_state.dart';

/// Flujo: editing → confirming → submitting → success | rejected | unknown.
///
/// La Idempotency-Key se crea al confirmar el formulario y se conserva
/// mientras no se edite: "Verificar estado" en `unknown` reenvía la misma
/// solicitud y el backend devuelve el resultado original sin duplicarla.
class OwnTransferBloc extends Bloc<OwnTransferEvent, OwnTransferState> {
  OwnTransferBloc({
    required this._getOwnAccounts,
    required this._transfer,
    required this._newIdempotencyKey,
  }) : super(const OwnTransferState()) {
    on<TransferStarted>(_onStarted);
    on<TransferSourceChanged>(_onSourceChanged);
    on<TransferTargetChanged>(
      (e, emit) => _edit(emit, state.copyWith(targetId: () => e.accountId)),
    );
    on<TransferAmountChanged>(
      (e, emit) => _edit(emit, state.copyWith(amountText: e.text)),
    );
    on<TransferDescriptionChanged>(
      (e, emit) => _edit(emit, state.copyWith(description: e.text)),
    );
    on<TransferReviewRequested>(_onReview);
    on<TransferEditRequested>(_onEdit);
    // droppable: un doble toque en "Confirmar" no envía dos veces.
    on<TransferConfirmed>(_onConfirmed, transformer: droppable());
    on<TransferRestarted>(_onRestarted);
  }

  final GetOwnAccounts _getOwnAccounts;
  final TransferBetweenOwnAccounts _transfer;
  final String Function() _newIdempotencyKey;

  Future<void> _onStarted(
    TransferStarted event,
    Emitter<OwnTransferState> emit,
  ) async {
    emit(state.copyWith(step: TransferStep.loadingAccounts));
    final result = await _getOwnAccounts();
    switch (result) {
      case Ok(value: final accounts):
        final next = OwnTransferState(
          step: TransferStep.editing,
          accounts: accounts,
        );
        final preferred =
            event.sourceAccountId ??
            next.sources.where((a) => a.isDefault).firstOrNull?.id ??
            next.sources.firstOrNull?.id;
        final withSource = next.copyWith(
          sourceId: () =>
              next.sources.any((a) => a.id == preferred) ? preferred : null,
        );
        // Con solo dos cuentas, el destino es obvio.
        emit(
          withSource.targets.length == 1
              ? withSource.copyWith(
                  targetId: () => withSource.targets.single.id,
                )
              : withSource,
        );
      case Err(:final failure):
        emit(
          state.copyWith(
            step: TransferStep.accountsFailure,
            failure: () => failure,
          ),
        );
    }
  }

  void _onSourceChanged(
    TransferSourceChanged event,
    Emitter<OwnTransferState> emit,
  ) {
    var next = state.copyWith(sourceId: () => event.accountId);
    if (next.targetId == event.accountId) {
      next = next.copyWith(targetId: () => null);
    }
    if (next.targetId == null && next.targets.length == 1) {
      next = next.copyWith(targetId: () => next.targets.single.id);
    }
    _edit(emit, next);
  }

  void _edit(Emitter<OwnTransferState> emit, OwnTransferState next) {
    if (state.step == TransferStep.editing) emit(next);
  }

  void _onReview(
    TransferReviewRequested event,
    Emitter<OwnTransferState> emit,
  ) {
    if (state.step != TransferStep.editing) return;
    if (!state.isValid) {
      emit(state.copyWith(showErrors: true));
      return;
    }
    emit(
      state.copyWith(
        step: TransferStep.confirming,
        idempotencyKey: () => _newIdempotencyKey(),
      ),
    );
  }

  void _onEdit(TransferEditRequested event, Emitter<OwnTransferState> emit) {
    if (state.step != TransferStep.confirming &&
        state.step != TransferStep.rejected) {
      return;
    }
    // Al editar, la operación cambia: se descartará la clave anterior.
    emit(
      state.copyWith(
        step: TransferStep.editing,
        idempotencyKey: () => null,
        failure: () => null,
      ),
    );
  }

  Future<void> _onConfirmed(
    TransferConfirmed event,
    Emitter<OwnTransferState> emit,
  ) async {
    final draft = state.draft;
    final key = state.idempotencyKey;
    if (draft == null ||
        key == null ||
        (state.step != TransferStep.confirming &&
            state.step != TransferStep.unknown)) {
      return;
    }
    emit(state.copyWith(step: TransferStep.submitting));

    final result = await _transfer(draft, idempotencyKey: key);
    switch (result) {
      case Ok(value: final transfer):
        emit(
          state.copyWith(
            step: TransferStep.success,
            transfer: () => transfer,
            failure: () => null,
          ),
        );
      case Err(:final failure) when _outcomeUnknown(failure):
        emit(
          state.copyWith(step: TransferStep.unknown, failure: () => failure),
        );
      case Err(:final failure):
        emit(
          state.copyWith(step: TransferStep.rejected, failure: () => failure),
        );
    }
  }

  void _onRestarted(TransferRestarted event, Emitter<OwnTransferState> emit) {
    if (state.step != TransferStep.success) return;
    add(TransferStarted(sourceAccountId: state.sourceId));
  }

  /// Sin respuesta definitiva del backend: pudo haberse ejecutado.
  /// El circuito abierto es la excepción: la petición nunca salió.
  static bool _outcomeUnknown(Failure failure) => switch (failure) {
    TimeoutFailure() || NetworkFailure() => true,
    ServerFailure(code: ErrorMapper.circuitOpenCode) => false,
    ServerFailure(:final statusCode) => statusCode == null || statusCode >= 500,
    _ => false,
  };
}
