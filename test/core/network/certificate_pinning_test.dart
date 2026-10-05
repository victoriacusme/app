import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/core/network/certificate_pinning.dart';

void main() {
  // Certificado real de open.er-api.com (test/fixtures). Hash de referencia:
  //   openssl x509 -inform DER -in er_api_leaf.der -pubkey -noout |
  //     openssl pkey -pubin -outform DER | openssl dgst -sha256 -binary | base64
  const expectedPin = 't7bF3dihOhrNsLCk4tTi8EOx31lFhYg6HlajLU4U9pg=';

  test('calcula el hash SPKI igual que openssl', () {
    final der = File('test/fixtures/er_api_leaf.der').readAsBytesSync();

    expect(CertificatePinning.spkiSha256(der), expectedPin);
  });

  test('sin pines configurados el pinning queda desactivado', () {
    expect(CertificatePinning.fromEnvironment(), isNull);
  });

  group('conexión TLS real', () {
    final skip = Platform.environment['CONTRACT_BASE_URL'] == null
        ? 'Define CONTRACT_BASE_URL (usa internet)'
        : false;

    Dio pinned(List<String> pins) {
      final dio = Dio(BaseOptions(baseUrl: 'https://open.er-api.com'));
      CertificatePinning(pins).applyTo(dio);
      return dio;
    }

    test('con el pin correcto (y uno de respaldo) conecta', () async {
      final response = await pinned([
        'respaldoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        CertificatePinning.spkiSha256(
          File('test/fixtures/er_api_leaf.der').readAsBytesSync(),
        ),
      ]).get<dynamic>('/v6/latest/USD');

      expect(response.statusCode, 200);
    }, skip: skip);

    test('con un pin distinto rechaza la conexión', () async {
      await expectLater(
        pinned(['otroAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='])
            .get<dynamic>('/v6/latest/USD'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.badCertificate,
          ),
        ),
      );
    }, skip: skip);
  });
}
