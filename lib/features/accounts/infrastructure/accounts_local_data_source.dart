import '../../../core/storage/encrypted_cache.dart';

/// Caché de cuentas y de la primera página de movimientos.
class AccountsLocalDataSource {
  AccountsLocalDataSource(this._cache);

  static const _accountsKey = 'accounts:list';
  static const _movementsPrefix = 'accounts:movements:';

  final KeyValueCache _cache;

  Future<CacheEntry?> readAccounts() => _cache.read(_accountsKey);

  Future<void> saveAccounts(Map<String, dynamic> json) =>
      _cache.write(_accountsKey, json);

  Future<CacheEntry?> readMovements(String accountId) =>
      _cache.read('$_movementsPrefix$accountId');

  Future<void> saveMovements(String accountId, Map<String, dynamic> json) =>
      _cache.write('$_movementsPrefix$accountId', json);

  Future<void> deleteMovements(Iterable<String> accountIds) =>
      _cache.deleteWhere(
        (key) => accountIds.any((id) => key == '$_movementsPrefix$id'),
      );
}
