import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:nexo_bank/core/security/auth_tokens.dart';
import 'package:nexo_bank/core/security/token_store.dart';

class InMemoryTokenStore implements TokenStore {
  InMemoryTokenStore([this.tokens]);

  AuthTokens? tokens;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> save(AuthTokens tokens) async => this.tokens = tokens;

  @override
  Future<void> clear() async => tokens = null;
}

AuthTokens tokens(String suffix) => AuthTokens(
  accessToken: 'access-$suffix',
  refreshToken: 'refresh-$suffix',
  accessTokenExpiresAt: DateTime.utc(2030),
);

extension AuthTokensX on AuthTokens {
  AuthTokens copyWithAccess(String accessToken) => AuthTokens(
    accessToken: accessToken,
    refreshToken: refreshToken,
    accessTokenExpiresAt: accessTokenExpiresAt,
  );
}

typedef FakeHandler = Future<FakeResponse> Function(RequestOptions options);

class FakeResponse {
  const FakeResponse(this.status, [this.body]);

  final int status;
  final Object? body;
}

/// Adaptador HTTP en memoria: responde según [handler] y registra
/// cada petición recibida.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.handler);

  FakeHandler handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = await handler(options);
    return ResponseBody.fromString(
      response.body == null ? '' : jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// JWT sin firma válida, solo para leer el `sub` en la app.
String fakeJwt(String sub) {
  String part(Map<String, Object> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'RS256'})}.${part({'sub': sub})}.firma';
}
