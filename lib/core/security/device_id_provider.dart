import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Identificador aleatorio y estable de esta instalación. El backend lo
/// asocia al refresh token; no identifica al hardware.
class DeviceIdProvider {
  DeviceIdProvider(this._storage, {this._uuid = const Uuid()});

  static const _key = 'device.id';

  final FlutterSecureStorage _storage;
  final Uuid _uuid;
  String? _cache;

  Future<String> get() async {
    if (_cache != null) return _cache!;
    var id = await _storage.read(key: _key);
    if (id == null) {
      id = _uuid.v4();
      await _storage.write(key: _key, value: id);
    }
    return _cache = id;
  }
}
