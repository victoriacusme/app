import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/core/network/dio_client.dart';
import 'package:nexo_bank/core/network/request_options_x.dart';

import '../../helpers/fakes.dart';

void main() {
  late InMemoryTokenStore store;
  late FakeHttpAdapter adapter;
  late Dio dio;
  late int refreshCalls;
  late int expiredCalls;
  late Future<void> Function() refreshBehavior;

  setUp(() {
    store = InMemoryTokenStore(tokens('old'));
    refreshCalls = 0;
    expiredCalls = 0;
    refreshBehavior = () async {};
    dio = createDioClient(
      baseUrl: 'http://test',
      tokenStore: store,
      refresh: (refreshToken) async {
        refreshCalls++;
        expect(refreshToken, 'refresh-old');
        await refreshBehavior();
        return tokens('new');
      },
      onSessionExpired: () => expiredCalls++,
    );
    // El backend acepta solo el access token nuevo.
    adapter = FakeHttpAdapter((options) async {
      return options.headers['Authorization'] == 'Bearer access-new'
          ? const FakeResponse(200, {'ok': true})
          : const FakeResponse(401, {'code': 'unauthorized'});
    });
    dio.httpClientAdapter = adapter;
  });

  test('ante un 401 refresca y reintenta con el token nuevo', () async {
    final response = await dio.get<dynamic>('/accounts');

    expect(response.statusCode, 200);
    expect(refreshCalls, 1);
    expect(store.tokens, tokens('new'));
    expect(adapter.requests.map((r) => r.headers['Authorization']), [
      'Bearer access-old',
      'Bearer access-new',
    ]);
  });

  test('agrega X-Correlation-Id a cada petición', () async {
    await dio.get<dynamic>('/accounts');

    expect(adapter.requests.first.headers['X-Correlation-Id'], isNotEmpty);
  });

  test('varios 401 simultáneos comparten un único refresh', () async {
    refreshBehavior = () =>
        Future<void>.delayed(const Duration(milliseconds: 20));

    final responses = await Future.wait([
      dio.get<dynamic>('/a'),
      dio.get<dynamic>('/b'),
      dio.get<dynamic>('/c'),
    ]);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(refreshCalls, 1);
  });

  test('si el backend rechaza el refresh, cierra la sesión', () async {
    refreshBehavior = () async => throw DioException.badResponse(
      statusCode: 401,
      requestOptions: RequestOptions(path: '/auth/refresh'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        statusCode: 401,
      ),
    );

    await expectLater(
      dio.get<dynamic>('/accounts'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(store.tokens, isNull);
    expect(expiredCalls, 1);
  });

  test('si el refresh falla por red, conserva la sesión', () async {
    refreshBehavior = () async => throw DioException.connectionError(
      requestOptions: RequestOptions(path: '/auth/refresh'),
      reason: 'sin red',
    );

    await expectLater(
      dio.get<dynamic>('/accounts'),
      throwsA(isA<DioException>()),
    );
    expect(store.tokens, tokens('old'));
    expect(expiredCalls, 0);
  });

  test('no reintenta peticiones públicas (login)', () async {
    await expectLater(
      dio.post<dynamic>('/auth/login', options: RequestFlags.public()),
      throwsA(isA<DioException>()),
    );
    expect(refreshCalls, 0);
    expect(adapter.requests.single.headers['Authorization'], isNull);
  });

  test('si el reintento vuelve a dar 401 no entra en bucle', () async {
    adapter.handler = (_) async => const FakeResponse(401);

    await expectLater(
      dio.get<dynamic>('/accounts'),
      throwsA(isA<DioException>()),
    );
    expect(refreshCalls, 1);
    expect(adapter.requests, hasLength(2));
  });
}
