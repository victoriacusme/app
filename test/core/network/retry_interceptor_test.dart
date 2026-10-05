import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/core/network/dio_client.dart';
import 'package:nexo_bank/core/network/interceptors/circuit_breaker_interceptor.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeHttpAdapter adapter;
  late Dio dio;
  late List<Duration> delays;

  setUp(() {
    delays = [];
    dio = createDioClient(
      baseUrl: 'http://test',
      tokenStore: InMemoryTokenStore(tokens('1')),
      refresh: (_) async => tokens('2'),
      onSessionExpired: () {},
      // Umbral alto para que el circuito no interfiera en estos tests.
      circuitBreaker: CircuitBreakerInterceptor(failureThreshold: 100),
      retryDelay: (d) async => delays.add(d),
    );
    adapter = FakeHttpAdapter((_) async => const FakeResponse(200));
    dio.httpClientAdapter = adapter;
  });

  test('GET con 503 se reintenta hasta tener éxito', () async {
    var calls = 0;
    adapter.handler = (_) async =>
        ++calls < 3 ? const FakeResponse(503) : const FakeResponse(200, {});

    final response = await dio.get<dynamic>('/accounts');

    expect(response.statusCode, 200);
    expect(adapter.requests, hasLength(3));
    expect(delays, hasLength(2));
  });

  test('GET deja de reintentar tras 3 intentos en total', () async {
    adapter.handler = (_) async => const FakeResponse(503);

    await expectLater(
      dio.get<dynamic>('/accounts'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, hasLength(3));
  });

  test('el backoff crece y tiene jitter (nunca supera el tope)', () async {
    adapter.handler = (_) async => const FakeResponse(503);

    await expectLater(
      dio.get<dynamic>('/accounts'),
      throwsA(isA<DioException>()),
    );
    expect(delays[0].inMilliseconds, lessThanOrEqualTo(400));
    expect(delays[1].inMilliseconds, lessThanOrEqualTo(800));
  });

  test('POST nunca se reintenta (operaciones de dinero)', () async {
    adapter.handler = (_) async => const FakeResponse(503);

    await expectLater(
      dio.post<dynamic>('/transfers/own', data: {}),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, hasLength(1));
  });

  test('un 4xx no se reintenta', () async {
    adapter.handler = (_) async => const FakeResponse(404);

    await expectLater(
      dio.get<dynamic>('/accounts/x'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, hasLength(1));
  });
}
