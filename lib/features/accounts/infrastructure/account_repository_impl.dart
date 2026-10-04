import 'dart:async';

import '../../../core/data/snapshot.dart';
import '../../../core/data/stale_while_revalidate.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/result/result.dart';
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
      staleWhileRevalidate(
        readCache: _local.readAccounts,
        fetch: _remote.getAccounts,
        save: _local.saveAccounts,
        map: AccountDtos.accountList,
        now: _now,
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
    yield* staleWhileRevalidate(
      readCache: () => _local.readMovements(accountId),
      fetch: () => _remote.getMovements(accountId),
      save: (json) => _local.saveMovements(accountId, json),
      map: (json) => AccountDtos.movementPage(json, currency: code),
      now: _now,
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

  Future<void> dispose() => _changes.close();
}
