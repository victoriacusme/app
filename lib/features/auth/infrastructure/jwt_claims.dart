import 'dart:convert';

/// Lee los claims de un JWT **sin validar la firma**. Solo para mostrar
/// datos en la app: la validación la hace cada microservicio.
abstract final class JwtClaims {
  static Map<String, dynamic> decode(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) throw const FormatException('JWT inválido');
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    return jsonDecode(payload) as Map<String, dynamic>;
  }

  static String subject(String jwt) => decode(jwt)['sub'] as String;
}
