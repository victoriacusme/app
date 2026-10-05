import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/data/snapshot.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/core/result/result.dart';
import 'package:nexo_bank/features/accounts/application/get_movements.dart';
import 'package:nexo_bank/features/accounts/domain/movement.dart';
import 'package:nexo_bank/features/accounts/presentation/bloc/movements_bloc.dart';

import '../../../helpers/accounts_fixtures.dart';

class _MockGetMovements extends Mock implements GetMovements {}

void main() {
  late _MockGetMovements getMovements;
  final t = DateTime.utc(2026, 10, 4);
  final loaded = MovementsState(
    status: MovementsStatus.loaded,
    items: [movement('m1')],
    nextCursor: 'c1',
    updatedAt: t,
  );

  setUp(() => getMovements = _MockGetMovements());

  blocTest<MovementsBloc, MovementsState>(
    'carga la primera página',
    setUp: () => when(() => getMovements.firstPage('a')).thenAnswer(
      (_) => Stream.value(
        Ok(
          Snapshot(
            data: MovementPage(items: [movement('m1')], nextCursor: 'c1'),
            updatedAt: t,
          ),
        ),
      ),
    ),
    build: () => MovementsBloc(getMovements, accountId: 'a'),
    act: (bloc) => bloc.add(const MovementsRequested()),
    expect: () => [loaded],
  );

  blocTest<MovementsBloc, MovementsState>(
    'la página siguiente se agrega al final',
    setUp: () =>
        when(() => getMovements.nextPage('a', cursor: 'c1'))
            .thenAnswer((_) async => Ok(MovementPage(items: [movement('m2')]))),
    build: () => MovementsBloc(getMovements, accountId: 'a'),
    seed: () => loaded,
    act: (bloc) => bloc.add(const MovementsNextPageRequested()),
    expect: () => [
      loaded.copyWith(loadingMore: true),
      loaded.copyWith(
        items: [movement('m1'), movement('m2')],
        nextCursor: () => null,
        loadingMore: false,
      ),
    ],
  );

  blocTest<MovementsBloc, MovementsState>(
    'si falla la página siguiente conserva lo cargado y permite reintentar',
    setUp: () =>
        when(() => getMovements.nextPage('a', cursor: 'c1'))
            .thenAnswer((_) async => const Err(NetworkFailure())),
    build: () => MovementsBloc(getMovements, accountId: 'a'),
    seed: () => loaded,
    act: (bloc) => bloc.add(const MovementsNextPageRequested()),
    expect: () => [
      loaded.copyWith(loadingMore: true),
      loaded.copyWith(
        loadingMore: false,
        loadMoreFailure: () => const NetworkFailure(),
      ),
    ],
  );

  blocTest<MovementsBloc, MovementsState>(
    'en la última página no pide más',
    build: () => MovementsBloc(getMovements, accountId: 'a'),
    seed: () => loaded.copyWith(nextCursor: () => null),
    act: (bloc) => bloc.add(const MovementsNextPageRequested()),
    expect: () => <MovementsState>[],
  );
}
