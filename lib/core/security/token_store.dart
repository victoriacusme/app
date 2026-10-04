import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_tokens.dart';

/// Guarda los tokens de la sesión. Nunca se persisten fuera del
/// almacenamiento seguro del sistema (Keychain / Keystore).
abstract interface class TokenStore {
  Future<AuthTokens?> read();
  Future<void> save(AuthTokens tokens);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore(this._storage);

  static const _accessKey = 'auth.access_token';
  static const _refreshKey = 'auth.refresh_token';
  static const _expiresAtKey = 'auth.access_expires_at';

  final FlutterSecureStorage _storage;

  // Evita leer del Keychain/Keystore en cada petición.
  AuthTokens? _cache;
  bool _loaded = false;

  @override
  Future<AuthTokens?> read() async {
    if (_loaded) return _cache;
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    final expiresAt = DateTime.tryParse(
      await _storage.read(key: _expiresAtKey) ?? '',
    );
    _cache = access != null && refresh != null && expiresAt != null
        ? AuthTokens(
            accessToken: access,
            refreshToken: refresh,
            accessTokenExpiresAt: expiresAt,
          )
        : null;
    _loaded = true;
    return _cache;
  }

  @override
  Future<void> save(AuthTokens tokens) async {
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
    await _storage.write(
      key: _expiresAtKey,
      value: tokens.accessTokenExpiresAt.toUtc().toIso8601String(),
    );
    _cache = tokens;
    _loaded = true;
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _expiresAtKey);
    _cache = null;
    _loaded = true;
  }
}
