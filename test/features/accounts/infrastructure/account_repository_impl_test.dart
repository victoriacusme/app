import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/data/snapshot.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/core/result/result.dart';
import 'package:nexo_bank/features/accounts/domain/account.dart';
import 'package:nexo_bank/features/accounts/infrastructure/account_repository_impl.dart';
import 'package:nexo_bank/features/accounts/infrastructure/accounts_local_data_source.dart';
import 'package:nexo_bank/features/accounts/infrastructure/accounts_remote_data_source.dart';

import '../../../helpers/accounts_fixtures.dart';
import '../../../helpers/fakes.dart';

class _MockRemote extends Mock implements AccountsRemoteDataSource {}

DioException _offline() => DioException.connectionError(
  requestOptions: RequestOptions(path: '/accounts'),
  reason: 'sin red',
);

void main() {
  late _MockRemote remote;
  late InMemoryCache cache;
  late AccountRepositoryImpl repository;
  final now = DateTime.utc(2026, 10, 4, 12);
  final savedAt = DateTime.utc(2026, 10, 4, 11, 30);

  setUp(() {
    remote = _MockRemote();
    cache = InMemoryCache();
    repository = AccountRepositoryImpl(
      remote: remote,
      local: AccountsLocalDataSource(cache),
      now: () => now,
    );
  });

  Future<void> seedCache(String balance) => cache.write(
    'accounts:list',
    accountsJson([accountJson('1', balance: balance)]),
    savedAt: savedAt,
  );

  group('watchAccounts (stale-while-revalidate)', () {
    test('sin caché: emite solo el dato remoto y lo guarda', () async {
      when(remote.getAccounts).thenAnswer(
        (_) async => accountsJson([accountJson('1', balance: '50.25')]),
      );

      final results = await repository.watchAccounts().toList();

      expect(results, hasLength(1));
      final snapshot = (results.single as Ok<Snapshot<List<Account>>>).value;
      expect(snapshot.fromCache, isFalse);
      expect(snapshot.data.single.balance.cents, 5025);
      expect(cache.entries['accounts:list'], isNotNull);
    });

    test('con caché: emite primero la caché y luego el remoto', () async {
      await seedCache('10.00');
      when(remote.getAccounts).thenAnswer(
        (_) async => accountsJson([accountJson('1', balance: '20.00')]),
      );

      final results = await repository.watchAccounts().toList();
      final snapshots = results
          .map((r) => (r as Ok<Snapshot<List<Account>>>).value)
          .toList();

      expect(snapshots.map((s) => s.fromCache), [true, false]);
      expect(snapshots.map((s) => s.data.single.balance.cents), [1000, 2000]);
      expect(snapshots.first.updatedAt, savedAt);
      expect(snapshots.last.updatedAt, now);
    });

    test(
      'si falla la red y hay caché: conserva los datos y marca el error',
      () async {
        await seedCache('10.00');
        when(remote.getAccounts).thenThrow(_offline());

        final results = await repository.watchAccounts().toList();
        final last = (results.last as Ok<Snapshot<List<Account>>>).value;

        expect(results, hasLength(2));
        expect(last.data.single.balance.cents, 1000);
        expect(last.refreshFailure, isA<NetworkFailure>());
        expect(last.isStale, isTrue);
      },
    );

    test('si falla la red y no hay caché: error', () async {
      when(remote.getAccounts).thenThrow(_offline());

      final results = await repository.watchAccounts().toList();

      expect((results.single as Err).failure, isA<NetworkFailure>());
    });

    test('una caché corrupta se ignora', () async {
      await cache.write('accounts:list', {'formato': 'viejo'});
      when(remote.getAccounts)
          .thenAnswer((_) async => accountsJson([accountJson('1')]));

      final results = await repository.watchAccounts().toList();

      expect(results, hasLength(1));
      expect(results.single.isOk, isTrue);
    });
  });

  group('movimientos', () {
    test('usa la moneda de la cuenta guardada y pagina sin caché', () async {
      await seedCache('10.00');
      when(() => remote.getMovements('1')).thenAnswer(
        (_) async => {
          'items': [movementJson('m1')],
          'nextCursor': 'c1',
        },
      );
      when(() => remote.getMovements('1', cursor: 'c1')).thenAnswer(
        (_) async => {
          'items': [movementJson('m2')],
          'nextCursor': null,
        },
      );

      final first = await repository.watchMovements('1').last;
      final next = await repository.getMovementsPage('1', cursor: 'c1');

      final page = (first as Ok<Snapshot<dynamic>>).value.data;
      expect(page.nextCursor, 'c1');
      expect(page.items.single.amount.currency, 'USD');
      expect((next as Ok).value.hasMore, isFalse);
      verifyNever(() => remote.getAccount(any()));
    });

    test(
      'invalidate borra la caché de movimientos y avisa del cambio',
      () async {
        await cache.write('accounts:movements:1', {'items': []});
        await cache.write('accounts:movements:2', {'items': []});
        final changes = repository.changes.first;

        await repository.invalidate(accountIds: ['1']);

        await expectLater(changes, completes);
        expect(cache.entries.keys, ['accounts:movements:2']);
      },
    );
  });
}
