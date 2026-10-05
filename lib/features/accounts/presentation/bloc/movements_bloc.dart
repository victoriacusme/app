import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/snapshot.dart';
import '../../../../core/result/failure.dart';
import '../../../../core/result/result.dart';
import '../../application/get_movements.dart';
import '../../domain/movement.dart';

sealed class MovementsEvent {
  const MovementsEvent();
}

final class MovementsRequested extends MovementsEvent {
  const MovementsRequested();
}

final class MovementsNextPageRequested extends MovementsEvent {
  const MovementsNextPageRequested();
}

enum MovementsStatus { loading, loaded, failure }

final class MovementsState extends Equatable {
  const MovementsState({
    this.status = MovementsStatus.loading,
    this.items = const [],
    this.nextCursor,
    this.updatedAt,
    this.fromCache = false,
    this.refreshFailure,
    this.failure,
    this.loadingMore = false,
    this.loadMoreFailure,
  });

  final MovementsStatus status;
  final List<Movement> items;
  final String? nextCursor;
  final DateTime? updatedAt;
  final bool fromCache;
  final Failure? refreshFailure;
  final Failure? failure;
  final bool loadingMore;
  final Failure? loadMoreFailure;

  bool get hasMore => nextCursor != null;
  bool get isStale => fromCache || refreshFailure != null;

  MovementsState copyWith({
    List<Movement>? items,
    String? Function()? nextCursor,
    bool? loadingMore,
    Failure? Function()? loadMoreFailure,
  }) => MovementsState(
    status: status,
    items: items ?? this.items,
    nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
    updatedAt: updatedAt,
    fromCache: fromCache,
    refreshFailure: refreshFailure,
    failure: failure,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreFailure: loadMoreFailure != null
        ? loadMoreFailure()
        : this.loadMoreFailure,
  );

  @override
  List<Object?> get props => [
    status,
    items,
    nextCursor,
    updatedAt,
    fromCache,
    refreshFailure,
    failure,
    loadingMore,
    loadMoreFailure,
  ];
}

class MovementsBloc extends Bloc<MovementsEvent, MovementsState> {
  MovementsBloc(this._getMovements, {required this.accountId})
    : super(const MovementsState()) {
    on<MovementsRequested>(_onRequested, transformer: restartable());
    // droppable: mientras se carga una página se ignoran nuevos pedidos.
    on<MovementsNextPageRequested>(_onNextPage, transformer: droppable());
  }

  final GetMovements _getMovements;
  final String accountId;

  Future<void> _onRequested(
    MovementsRequested event,
    Emitter<MovementsState> emit,
  ) => emit.forEach<Result<Snapshot<MovementPage>>>(
    _getMovements.firstPage(accountId),
    onData: (result) => switch (result) {
      Ok(value: final snapshot) => MovementsState(
        status: MovementsStatus.loaded,
        items: snapshot.data.items,
        nextCursor: snapshot.data.nextCursor,
        updatedAt: snapshot.updatedAt,
        fromCache: snapshot.fromCache,
        refreshFailure: snapshot.refreshFailure,
      ),
      Err(:final failure) when state.items.isNotEmpty => MovementsState(
        status: MovementsStatus.loaded,
        items: state.items,
        nextCursor: state.nextCursor,
        updatedAt: state.updatedAt,
        fromCache: true,
        refreshFailure: failure,
      ),
      Err(:final failure) => MovementsState(
        status: MovementsStatus.failure,
        failure: failure,
      ),
    },
  );

  Future<void> _onNextPage(
    MovementsNextPageRequested event,
    Emitter<MovementsState> emit,
  ) async {
    final cursor = state.nextCursor;
    if (cursor == null || state.status != MovementsStatus.loaded) return;
    emit(state.copyWith(loadingMore: true, loadMoreFailure: () => null));

    final result = await _getMovements.nextPage(accountId, cursor: cursor);
    emit(switch (result) {
      Ok(value: final page) => state.copyWith(
        items: [...state.items, ...page.items],
        nextCursor: () => page.nextCursor,
        loadingMore: false,
      ),
      Err(:final failure) => state.copyWith(
        loadingMore: false,
        loadMoreFailure: () => failure,
      ),
    });
  }
}
