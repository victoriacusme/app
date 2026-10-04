import 'dart:async';

import '../../../core/data/snapshot.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/encrypted_cache.dart';
import '../domain/account.dart';
import '../domain/account_repository.dart';
import '../domain/movement.dart';
import 'account_dtos.dart';
import 'accounts_local_data_source.dart';
import 'accounts_remote_data_source.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({
    required this._remote,
    required this._local,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AccountsRemoteDataSource _remote;
  final AccountsLocalDataSource _local;
  final DateTime Function() _now;
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Stream<Result<Snapshot<List<Account>>>> watchAccounts() =>
      _staleWhileRevalidate(
        readCache: _local.readAccounts,
        fetch: _remote.getAccounts,
        save: _local.saveAccounts,
        map: AccountDtos.accountList,
      );

  @override
  Stream<Result<Snapshot<MovementPage>>> watchMovements(
    String accountId,
  ) async* {
    // Los movimientos no traen la moneda: se toma de la cuenta en caché o
    // del backend.
    final currency = await _currencyOf(accountId);
    if (currency case Err(:final failure)) {
      yield Err(failure);
      return;
    }
    final code = (currency as Ok<String>).value;
    yield* _staleWhileRevalidate(
      readCache: () => _local.readMovements(accountId),
      fetch: () => _remote.getMovements(accountId),
      save: (json) => _local.saveMovements(accountId, json),
      map: (json) => AccountDtos.movementPage(json, currency: code),
    );
  }

  @override
  Future<Result<MovementPage>> getMovementsPage(
    String accountId, {
    required String cursor,
  }) async {
    try {
      final currency = await _currencyOf(accountId);
      if (currency case Err(:final failure)) return Err(failure);
      final json = await _remote.getMovements(accountId, cursor: cursor);
      return Ok(
        AccountDtos.movementPage(
          json,
          currency: (currency as Ok<String>).value,
        ),
      );
    } catch (e) {
      return Err(ErrorMapper.from(e));
    }
  }

  @override
  Future<void> invalidate({Iterable<String> accountIds = const []}) async {
    await _local.deleteMovements(accountIds);
    _changes.add(null);
  }

  Future<Result<String>> _currencyOf(String accountId) async {
    final cached = await _local.readAccounts();
    if (cached?.data case final Map<String, dynamic> json) {
      for (final account in AccountDtos.accountList(json)) {
        if (account.id == accountId) return Ok(account.currency);
      }
    }
    try {
      final json = await _remote.getAccount(accountId);
      return Ok(json['currency'] as String);
    } catch (e) {
      return Err(ErrorMapper.from(e));
    }
  }

  /// 1. Si hay caché, la emite (`fromCache: true`).
  /// 2. Pide el dato remoto: si llega, lo guarda y lo emite.
  /// 3. Si falla: con caché, re-emite la caché con `refreshFailure`;
  ///    sin caché, emite el error.
  Stream<Result<Snapshot<T>>> _staleWhileRevalidate<T>({
    required Future<CacheEntry?> Function() readCache,
    required Future<Map<String, dynamic>> Function() fetch,
    required Future<void> Function(Map<String, dynamic>) save,
    required T Function(Map<String, dynamic>) map,
  }) async* {
    Snapshot<T>? cached;
    try {
      final entry = await readCache();
      if (entry?.data case final Map<String, dynamic> json) {
        cached = Snapshot(
          data: map(json),
          updatedAt: entry!.savedAt,
          fromCache: true,
        );
      }
    } catch (_) {
      cached = null; // caché corrupta o de un formato anterior: se ignora
    }
    if (cached != null) yield Ok(cached);

    try {
      final json = await fetch();
      final fresh = Snapshot(data: map(json), updatedAt: _now());
      await save(json);
      yield Ok(fresh);
    } catch (e) {
      final failure = ErrorMapper.from(e);
      yield cached == null
          ? Err(failure)
          : Ok(cached.withRefreshFailure(failure));
    }
  }

  Future<void> dispose() => _changes.close();
}
