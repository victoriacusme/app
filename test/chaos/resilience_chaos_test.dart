// Demo de resiliencia automatizada con Toxiproxy (Fase 3). Necesita el
// backend completo levantado y se omite si no se define CHAOS_BASE_URL:
//
//   CHAOS_BASE_URL=http://localhost:8080 flutter test test/chaos
//
// Recorre el guion de la demo sobre ms-accounts: latencia → caída →
// circuito abierto → recuperación. Al terminar restaura Toxiproxy.
@Tags(['chaos'])
@Timeout(Duration(minutes: 2))
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/data/snapshot.dart';
import 'package:nexo_bank/core/network/dio_client.dart';
import 'package:nexo_bank/core/network/error_mapper.dart';
import 'package:nexo_bank/core/network/interceptors/circuit_breaker_interceptor.dart';
import 'package:nexo_bank/core/result/result.dart';
import 'package:nexo_bank/core/security/device_id_provider.dart';
import 'package:nexo_bank/features/accounts/domain/account.dart';
import 'package:nexo_bank/features/accounts/infrastructure/account_repository_impl.dart';
import 'package:nexo_bank/features/accounts/infrastructure/accounts_local_data_source.dart';
import 'package:nexo_bank/features/accounts/infrastructure/accounts_remote_data_source.dart';
import 'package:nexo_bank/features/auth/infrastructure/auth_remote_data_source.dart';
import 'package:nexo_bank/features/auth/infrastructure/auth_repository_impl.dart';

import '../helpers/fakes.dart';

class _FixedDeviceId extends Mock implements DeviceIdProvider {
  @override
  Future<String> get() async => 'chaos-test';
}

void main() {
  final baseUrl = Platform.environment['CHAOS_BASE_URL'];
  final toxiproxyUrl =
      Platform.environment['TOXIPROXY_URL'] ?? 'http://localhost:8474';
  final skip = baseUrl == null ? 'Define CHAOS_BASE_URL' : false;

  final toxiproxy = Dio(BaseOptions(baseUrl: toxiproxyUrl));
  Future<void> reset() => toxiproxy.post<void>('/reset');
  Future<void> latency(int ms) => toxiproxy.post<void>(
    '/proxies/ms-accounts/toxics',
    data: {
      'name': 'latency',
      'type': 'latency',
      'stream': 'downstream',
      'attributes': {'latency': ms},
    },
  );
  Future<void> down() =>
      toxiproxy.post<void>('/proxies/ms-accounts', data: {'enabled': false});

  late AccountRepositoryImpl repository;
  late CircuitBreakerInterceptor breaker;
  var clock = DateTime.now();

  setUpAll(() async {
    if (baseUrl == null) return;
    await reset();
    final store = InMemoryTokenStore();
    breaker = CircuitBreakerInterceptor(now: () => clock);
    late AuthRemoteDataSource auth;
    final dio = createDioClient(
      baseUrl: baseUrl,
      tokenStore: store,
      refresh: (rt) async => (await auth.refresh(rt)).toTokens(),
      onSessionExpired: () {},
      circuitBreaker: breaker,
      retryDelay: (_) async {},
    );
    auth = AuthRemoteDataSource(dio);
    final login = await AuthRepositoryImpl(
      remote: auth,
      tokenStore: store,
      deviceId: _FixedDeviceId(),
    ).login(username: 'carlos', password: 'Nexo2026*');
    expect(login.isOk, isTrue);
    repository = AccountRepositoryImpl(
      remote: AccountsRemoteDataSource(dio),
      local: AccountsLocalDataSource(InMemoryCache()),
    );
  });

  tearDownAll(() async {
    if (baseUrl != null) await reset();
  });

  Future<List<(Duration, Snapshot<List<Account>>?)>> load() async {
    final watch = Stopwatch()..start();
    return [
      await for (final r in repository.watchAccounts())
        (watch.elapsed, r is Ok<Snapshot<List<Account>>> ? r.value : null),
    ];
  }

  test('1. normal: datos del backend y caché guardada', () async {
    final results = await load();

    expect(results.single.$2!.fromCache, isFalse);
  }, skip: skip);

  test(
    '2. latencia de 3 s: la caché se ve al instante y luego llega el dato',
    () async {
      await latency(3000);

      final results = await load();

      expect(results, hasLength(2));
      expect(results.first.$2!.fromCache, isTrue);
      expect(results.first.$1, lessThan(const Duration(milliseconds: 500)));
      expect(results.last.$2!.fromCache, isFalse);
      expect(results.last.$1, greaterThan(const Duration(seconds: 3)));
      await reset();
    },
    skip: skip,
  );

  test('3. ms-accounts caído: se conservan los datos con el aviso', () async {
    await down();

    final results = await load();
    final last = results.last.$2!;

    expect(last.data, isNotEmpty);
    expect(last.refreshFailure?.code, 'service-unavailable');
  }, skip: skip);

  test('4. tras 5 fallos el circuito se abre y responde sin esperar', () async {
    // El paso 3 ya hizo 3 intentos (retry); este suma los demás.
    await load();
    expect(breaker.stateOf('accounts'), CircuitState.open);

    final results = await load();

    expect(results.last.$2!.refreshFailure?.code, ErrorMapper.circuitOpenCode);
    expect(results.last.$1, lessThan(const Duration(milliseconds: 200)));
  }, skip: skip);

  test(
    '5. recuperación: al volver el servicio y pasar 30 s, se actualiza',
    () async {
      await reset();
      clock = clock.add(const Duration(seconds: 31));

      final results = await load();

      expect(results.last.$2!.fromCache, isFalse);
      expect(results.last.$2!.refreshFailure, isNull);
      expect(breaker.stateOf('accounts'), CircuitState.closed);
    },
    skip: skip,
  );
}
