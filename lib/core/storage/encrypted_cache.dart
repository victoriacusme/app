import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';

/// Entrada guardada en la caché, con la fecha en que se obtuvo.
class CacheEntry {
  const CacheEntry(this.data, this.savedAt);

  final Object? data;
  final DateTime savedAt;
}

/// Caché local de respuestas JSON.
abstract interface class KeyValueCache {
  Future<CacheEntry?> read(String key);
  Future<void> write(String key, Object? data, {DateTime? savedAt});
  Future<void> delete(String key);
  Future<void> deleteWhere(bool Function(String key) test);

  /// Se llama al cerrar sesión: no deben quedar datos del cliente.
  Future<void> clear();
}

/// Caché en Hive CE cifrada con AES-256. La clave se genera una vez y se
/// guarda en el almacenamiento seguro del sistema (Keychain / Keystore).
class HiveEncryptedCache implements KeyValueCache {
  HiveEncryptedCache._(this._box);

  static const _boxName = 'nexo_cache';
  static const _keyName = 'cache.aes_key';

  final Box<String> _box;

  static Future<HiveEncryptedCache> open(FlutterSecureStorage storage) async {
    var encoded = await storage.read(key: _keyName);
    if (encoded == null) {
      encoded = base64Url.encode(Hive.generateSecureKey());
      await storage.write(key: _keyName, value: encoded);
    }
    final box = await Hive.openBox<String>(
      _boxName,
      encryptionCipher: HiveAesCipher(base64Url.decode(encoded)),
    );
    return HiveEncryptedCache._(box);
  }

  /// Para tests: abre la caja con una clave conocida.
  static Future<HiveEncryptedCache> openWithKey(
    List<int> key, {
    String boxName = _boxName,
  }) async => HiveEncryptedCache._(
    await Hive.openBox<String>(boxName, encryptionCipher: HiveAesCipher(key)),
  );

  @override
  Future<CacheEntry?> read(String key) async {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CacheEntry(
        json['data'],
        DateTime.parse(json['savedAt'] as String),
      );
    } on FormatException {
      await _box.delete(key);
      return null;
    }
  }

  @override
  Future<void> write(String key, Object? data, {DateTime? savedAt}) => _box.put(
    key,
    jsonEncode({
      'savedAt': (savedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'data': data,
    }),
  );

  @override
  Future<void> delete(String key) => _box.delete(key);

  @override
  Future<void> deleteWhere(bool Function(String key) test) =>
      _box.deleteAll(_box.keys.cast<String>().where(test).toList());

  @override
  Future<void> clear() => _box.clear();
}
