import 'package:dio/dio.dart';

import '../../../core/network/request_options_x.dart';
import '../../../core/security/jwe_encryptor.dart';

/// Obtiene del JWKS de ms-auth la clave pública para cifrar el login
/// (`use: enc`, `alg: RSA-OAEP-256`) y la guarda en memoria.
class JwksClient {
  JwksClient(this._dio);

  final Dio _dio;
  RsaPublicJwk? _cached;

  Future<RsaPublicJwk> encryptionKey({bool refresh = false}) async {
    if (!refresh && _cached != null) return _cached!;
    final response = await _dio.get<Map<String, dynamic>>(
      '/.well-known/jwks.json',
      options: RequestFlags.public(),
    );
    final keys = (response.data!['keys'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final json = keys.firstWhere(
      (k) =>
          k['kty'] == 'RSA' &&
          k['use'] == 'enc' &&
          (k['alg'] == null || k['alg'] == JweEncryptor.algorithm),
      orElse: () => throw StateError('El JWKS no publica una clave de cifrado'),
    );
    return _cached = RsaPublicJwk.fromJson(json);
  }
}
