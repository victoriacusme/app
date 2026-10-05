import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/snapshot.dart';
import '../../../../core/result/failure.dart';
import '../../../../core/result/result.dart';
import '../../application/watch_accounts.dart';
import '../../domain/account.dart';

sealed class AccountsEvent {
  const AccountsEvent();
}

/// Carga inicial y cada refresco (pull-to-refresh, reconexión, cambios).
final class AccountsRequested extends AccountsEvent {
  const AccountsRequested();
}

enum AccountsStatus { loading, loaded, failure }

final class AccountsState extends Equatable {
  const AccountsState({
    this.status = AccountsStatus.loading,
    this.accounts = const [],
    this.updatedAt,
    this.fromCache = false,
    this.refreshFailure,
    this.failure,
  });

  final AccountsStatus status;
  final List<Account> accounts;
  final DateTime? updatedAt;

  /// Se muestran datos guardados mientras llega la respuesta.
  final bool fromCache;

  /// Hay datos, pero el último refresco falló.
  final Failure? refreshFailure;

  /// No hay datos que mostrar.
  final Failure? failure;

  bool get isStale => fromCache || refreshFailure != null;

  @override
  List<Object?> get props => [
    status,
    accounts,
    updatedAt,
    fromCache,
    refreshFailure,
    failure,
  ];
}

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  AccountsBloc(this._watchAccounts) : super(const AccountsState()) {
    // restartable: un refresco nuevo cancela el que estaba en curso.
    on<AccountsRequested>(_onRequested, transformer: restartable());
    _changes = _watchAccounts.changes.listen(
      (_) => add(const AccountsRequested()),
    );
  }

  final WatchAccounts _watchAccounts;
  late final StreamSubscription<void> _changes;

  Future<void> _onRequested(
    AccountsRequested event,
    Emitter<AccountsState> emit,
  ) => emit.forEach<Result<Snapshot<List<Account>>>>(
    _watchAccounts(),
    onData: (result) => switch (result) {
      Ok(value: final snapshot) => AccountsState(
        status: AccountsStatus.loaded,
        accounts: snapshot.data,
        updatedAt: snapshot.updatedAt,
        fromCache: snapshot.fromCache,
        refreshFailure: snapshot.refreshFailure,
      ),
      // Si ya había cuentas en pantalla, se conservan.
      Err(:final failure) when state.accounts.isNotEmpty => AccountsState(
        status: AccountsStatus.loaded,
        accounts: state.accounts,
        updatedAt: state.updatedAt,
        fromCache: true,
        refreshFailure: failure,
      ),
      Err(:final failure) => AccountsState(
        status: AccountsStatus.failure,
        failure: failure,
      ),
    },
  );

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
