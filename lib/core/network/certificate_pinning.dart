import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/digests/sha256.dart';

/// Certificate pinning por clave pública (SPKI), como `sha256/<base64>` en
/// OkHttp o TrustKit. Se compara el hash SHA-256 del `SubjectPublicKeyInfo`
/// del certificado del servidor con los pines configurados.
///
/// Pinear la clave y no el certificado permite renovar el certificado sin
/// publicar una versión nueva de la app, siempre que se conserve la clave.
/// Se debe configurar al menos un pin de respaldo (otra clave ya generada).
class CertificatePinning {
  CertificatePinning(Iterable<String> pins) : _pins = pins.toSet();

  /// Lee `PIN_SHA256` (pines separados por coma) de `--dart-define`.
  /// Vacío = pinning desactivado (desarrollo con HTTP local).
  static CertificatePinning? fromEnvironment() {
    const raw = String.fromEnvironment('PIN_SHA256');
    final pins = raw.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty);
    return pins.isEmpty ? null : CertificatePinning(pins);
  }

  final Set<String> _pins;

  /// Hash SPKI en base64 de un certificado DER.
  static String spkiSha256(Uint8List certificateDer) {
    final certificate = ASN1Parser(certificateDer).nextObject() as ASN1Sequence;
    final tbs = certificate.elements!.first as ASN1Sequence;
    // tbsCertificate: [0] version (opcional), serialNumber, signature,
    // issuer, validity, subject, subjectPublicKeyInfo...
    final fields = tbs.elements!;
    final hasVersion = fields.first.tag == 0xa0;
    final spki = fields[hasVersion ? 6 : 5];
    final digest = SHA256Digest().process(spki.encodedBytes!);
    return base64.encode(digest);
  }

  bool isTrusted(X509Certificate? certificate) {
    if (certificate == null) return false;
    try {
      return _pins.contains(spkiSha256(certificate.der));
    } catch (_) {
      return false;
    }
  }

  /// Aplica el pinning al cliente: una conexión cuyo certificado no
  /// coincida falla con `DioExceptionType.badCertificate`.
  void applyTo(Dio dio) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      validateCertificate: (certificate, host, port) => isTrusted(certificate),
    );
  }
}
