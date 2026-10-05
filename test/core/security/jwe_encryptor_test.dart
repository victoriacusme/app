import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/core/security/jwe_encryptor.dart';
import 'package:pointycastle/export.dart';

/// Descifra como lo haría el backend, para verificar el formato.
String decrypt(String compact, RSAPrivateKey key) {
  final parts = compact.split('.');
  Uint8List b64(String s) => base64Url.decode(base64Url.normalize(s));
  final cek =
      (OAEPEncoding.withSHA256(RSAEngine())
            ..init(false, PrivateKeyParameter<RSAPrivateKey>(key)))
          .process(b64(parts[1]));
  final gcm = GCMBlockCipher(AESEngine())
    ..init(
      false,
      AEADParameters(
        KeyParameter(cek),
        128,
        b64(parts[2]),
        ascii.encode(parts[0]),
      ),
    );
  return utf8.decode(
    gcm.process(Uint8List.fromList([...b64(parts[3]), ...b64(parts[4])])),
  );
}

void main() {
  late AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> pair;

  setUpAll(() {
    final generator = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
          FortunaRandom()..seed(KeyParameter(Uint8List(32))),
        ),
      );
    final generated = generator.generateKeyPair();
    pair = AsymmetricKeyPair(generated.publicKey, generated.privateKey);
  });

  String b64Int(BigInt n) {
    final hex = n.toRadixString(16);
    final bytes = <int>[
      for (var i = hex.length.isOdd ? -1 : 0; i < hex.length; i += 2)
        int.parse(hex.substring(i < 0 ? 0 : i, i + 2), radix: 16),
    ];
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  RsaPublicJwk jwk() => RsaPublicJwk.fromJson({
    'kty': 'RSA',
    'kid': 'enc-1',
    'n': b64Int(pair.publicKey.modulus!),
    'e': b64Int(pair.publicKey.exponent!),
  });

  test('JWE compacto RSA-OAEP-256 + A256GCM que se puede descifrar', () {
    const payload = '{"username":"ana","password":"Nexo2026*"}';

    final compact = JweEncryptor().encrypt(payload, jwk());

    final parts = compact.split('.');
    expect(parts, hasLength(5));
    final header = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
    );
    expect(header, containsPair('alg', 'RSA-OAEP-256'));
    expect(header, containsPair('enc', 'A256GCM'));
    expect(header, containsPair('kid', 'enc-1'));
    expect(compact, isNot(contains('Nexo2026')));
    expect(decrypt(compact, pair.privateKey), payload);
  });

  test('cada cifrado usa una clave e IV nuevos', () {
    final encryptor = JweEncryptor();

    final a = encryptor.encrypt('x', jwk());
    final b = encryptor.encrypt('x', jwk());

    expect(a, isNot(b));
  });

  test('si se altera el texto cifrado, falla la autenticación GCM', () {
    final parts = JweEncryptor().encrypt('secreto', jwk()).split('.');
    final tampered = [...parts]
      ..[3] = parts[3].replaceRange(0, 1, parts[3].startsWith('A') ? 'B' : 'A');

    expect(
      () => decrypt(tampered.join('.'), pair.privateKey),
      throwsA(isA<InvalidCipherTextException>()),
    );
  });
}
