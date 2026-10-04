import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/core/network/error_mapper.dart';
import 'package:nexo_bank/core/network/interceptors/circuit_breaker_interceptor.dart';

import '../../helpers/fakes.dart';

void main() {
  late DateTime now;
  late CircuitBreakerInterceptor breaker;
  late FakeHttpAdapter adapter;
  late Dio dio;

  setUp(() {
    now = DateTime(2026);
    breaker = CircuitBreakerInterceptor(now: () => now);
    adapter = FakeHttpAdapter((_) async => const FakeResponse(503));
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(breaker)
      ..httpClientAdapter = adapter;
  });

  Future<void> failTimes(int n, [String path = '/accounts']) async {
    for (var i = 0; i < n; i++) {
      await expectLater(dio.get<dynamic>(path), throwsA(isA<DioException>()));
    }
  }

  test('tras 5 fallos se abre y responde sin llamar a la red', () async {
    await failTimes(5);
    expect(breaker.stateOf('accounts'), CircuitState.open);

    final error = await dio
        .get<dynamic>('/accounts')
        .then<DioException?>(
          (_) => null,
          onError: (Object e) => e as DioException,
        );

    expect(error!.error, isA<CircuitOpenException>());
    expect(adapter.requests, hasLength(5));
    expect(ErrorMapper.fromDio(error).code, ErrorMapper.circuitOpenCode);
  });

  test('a los 30 s deja pasar una prueba y, si funciona, se cierra', () async {
    await failTimes(5);
    now = now.add(const Duration(seconds: 30));
    adapter.handler = (_) async => const FakeResponse(200, {});

    await dio.get<dynamic>('/accounts');

    expect(breaker.stateOf('accounts'), CircuitState.closed);
    expect(adapter.requests, hasLength(6));
  });

  test('si la prueba falla, vuelve a abrirse otros 30 s', () async {
    await failTimes(5);
    now = now.add(const Duration(seconds: 31));

    await failTimes(1); // la prueba falla
    await failTimes(1); // esta ya no sale a la red

    expect(adapter.requests, hasLength(6));
    expect(breaker.stateOf('accounts'), CircuitState.open);
  });

  test('cada servicio tiene su propio circuito', () async {
    await failTimes(5, '/accounts');
    adapter.handler = (_) async => const FakeResponse(200, {});

    await dio.get<dynamic>('/customers/me');

    expect(breaker.stateOf('customers'), CircuitState.closed);
  });

  test('los 4xx no cuentan como fallo del servicio', () async {
    adapter.handler = (_) async => const FakeResponse(422);
    await failTimes(10);

    expect(breaker.stateOf('accounts'), CircuitState.closed);
  });
}
