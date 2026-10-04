import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Clave pública RSA publicada en el JWKS (`kty: RSA`).
class RsaPublicJwk {
  const RsaPublicJwk({
    required this.kid,
    required this.modulus,
    required this.exponent,
  });

  factory RsaPublicJwk.fromJson(Map<String, dynamic> json) => RsaPublicJwk(
    kid: json['kid'] as String?,
    modulus: _bigInt(json['n'] as String),
    exponent: _bigInt(json['e'] as String),
  );

  final String? kid;
  final BigInt modulus;
  final BigInt exponent;

  RSAPublicKey toKey() => RSAPublicKey(modulus, exponent);

  static BigInt _bigInt(String base64Url) {
    final bytes = base64Url.isEmpty
        ? Uint8List(0)
        : base64.decode(
            base64.normalize(
              base64Url.replaceAll('-', '+').replaceAll('_', '/'),
            ),
          );
    return bytes.fold(BigInt.zero, (n, b) => (n << 8) | BigInt.from(b));
  }
}

/// Cifra un payload como JWE compacto con `alg: RSA-OAEP-256` y
/// `enc: A256GCM`, el único formato que acepta ms-auth en el login.
///
/// 1. Genera una clave de contenido (CEK) AES-256 y un IV aleatorios.
/// 2. Cifra el payload con AES-GCM; el encabezado protegido va como AAD.
/// 3. Cifra la CEK con la clave pública RSA (OAEP con SHA-256 y MGF1-SHA-256).
///
/// Así las credenciales viajan cifradas de extremo a extremo hasta ms-auth,
/// aunque el TLS termine antes (gateway, proxy corporativo, inspección TLS).
class JweEncryptor {
  JweEncryptor({Random? random}) : _random = random ?? Random.secure();

  static const algorithm = 'RSA-OAEP-256';
  static const encryption = 'A256GCM';

  final Random _random;

  String encrypt(String payload, RsaPublicJwk key) {
    final header = _b64(
      utf8.encode(
        jsonEncode({
          'alg': algorithm,
          'enc': encryption,
          'kid': ?key.kid,
          'cty': 'JSON',
        }),
      ),
    );
    final cek = _bytes(32);
    final iv = _bytes(12);

    final gcm = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(KeyParameter(cek), 128, iv, ascii.encode(header)),
      );
    final sealed = gcm.process(Uint8List.fromList(utf8.encode(payload)));
    final cipherText = sealed.sublist(0, sealed.length - 16);
    final tag = sealed.sublist(sealed.length - 16);

    final oaep = OAEPEncoding.withSHA256(RSAEngine())
      ..init(
        true,
        ParametersWithRandom(
          PublicKeyParameter<RSAPublicKey>(key.toKey()),
          _secureRandom(),
        ),
      );
    final encryptedKey = oaep.process(cek);

    return [
      header,
      _b64(encryptedKey),
      _b64(iv),
      _b64(cipherText),
      _b64(tag),
    ].join('.');
  }

  Uint8List _bytes(int length) =>
      Uint8List.fromList(List.generate(length, (_) => _random.nextInt(256)));

  SecureRandom _secureRandom() =>
      FortunaRandom()..seed(KeyParameter(_bytes(32)));

  static String _b64(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}
