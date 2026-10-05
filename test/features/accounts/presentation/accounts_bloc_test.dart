import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/data/snapshot.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/core/result/result.dart';
import 'package:nexo_bank/features/accounts/application/watch_accounts.dart';
import 'package:nexo_bank/features/accounts/domain/account.dart';
import 'package:nexo_bank/features/accounts/presentation/bloc/accounts_bloc.dart';

import '../../../helpers/accounts_fixtures.dart';

class _MockWatchAccounts extends Mock implements WatchAccounts {}

void main() {
  late _MockWatchAccounts watch;
  late StreamController<void> changes;
  final t0 = DateTime.utc(2026, 10, 4, 11);
  final t1 = DateTime.utc(2026, 10, 4, 12);
  final cached = [account('1', cents: 1000)];
  final fresh = [account('1', cents: 2000)];

  setUp(() {
    watch = _MockWatchAccounts();
    changes = StreamController<void>.broadcast();
    when(() => watch.changes).thenAnswer((_) => changes.stream);
  });

  void emits(List<Result<Snapshot<List<Account>>>> results) =>
      when(() => watch()).thenAnswer((_) => Stream.fromIterable(results));

  blocTest<AccountsBloc, AccountsState>(
    'caché y luego remoto: loaded(stale) → loaded(fresco)',
    setUp: () => emits([
      Ok(Snapshot(data: cached, updatedAt: t0, fromCache: true)),
      Ok(Snapshot(data: fresh, updatedAt: t1)),
    ]),
    build: () => AccountsBloc(watch),
    act: (bloc) => bloc.add(const AccountsRequested()),
    expect: () => [
      AccountsState(
        status: AccountsStatus.loaded,
        accounts: cached,
        updatedAt: t0,
        fromCache: true,
      ),
      AccountsState(
        status: AccountsStatus.loaded,
        accounts: fresh,
        updatedAt: t1,
      ),
    ],
  );

  blocTest<AccountsBloc, AccountsState>(
    'sin datos y con error: failure',
    setUp: () => emits([const Err(NetworkFailure())]),
    build: () => AccountsBloc(watch),
    act: (bloc) => bloc.add(const AccountsRequested()),
    expect: () => [
      const AccountsState(
        status: AccountsStatus.failure,
        failure: NetworkFailure(),
      ),
    ],
  );

  blocTest<AccountsBloc, AccountsState>(
    'si un refresco falla conserva las cuentas que ya se veían',
    setUp: () => emits([const Err(TimeoutFailure())]),
    build: () => AccountsBloc(watch),
    seed: () => AccountsState(
      status: AccountsStatus.loaded,
      accounts: fresh,
      updatedAt: t1,
    ),
    act: (bloc) => bloc.add(const AccountsRequested()),
    expect: () => [
      AccountsState(
        status: AccountsStatus.loaded,
        accounts: fresh,
        updatedAt: t1,
        fromCache: true,
        refreshFailure: const TimeoutFailure(),
      ),
    ],
  );

  blocTest<AccountsBloc, AccountsState>(
    'cuando el repositorio avisa un cambio (transferencia), recarga',
    setUp: () => emits([Ok(Snapshot(data: fresh, updatedAt: t1))]),
    build: () => AccountsBloc(watch),
    act: (_) => changes.add(null),
    expect: () => [
      AccountsState(
        status: AccountsStatus.loaded,
        accounts: fresh,
        updatedAt: t1,
      ),
    ],
  );
}
