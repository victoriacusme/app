// Test de contrato contra ms-auth real. Se omite si no se define la URL:
//   CONTRACT_BASE_URL=http://localhost:8081 flutter test test/contract
@Tags(['contract'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/core/network/dio_client.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/core/result/result.dart';
import 'package:nexo_bank/core/security/device_id_provider.dart';
import 'package:nexo_bank/features/auth/domain/session.dart';
import 'package:nexo_bank/features/auth/infrastructure/auth_remote_data_source.dart';
import 'package:nexo_bank/features/auth/infrastructure/auth_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';

class _FixedDeviceId extends Mock implements DeviceIdProvider {
  @override
  Future<String> get() async => 'contract-test';
}

void main() {
  final baseUrl = Platform.environment['CONTRACT_BASE_URL'];
  final skip = baseUrl == null ? 'Define CONTRACT_BASE_URL' : false;

  late InMemoryTokenStore store;
  late AuthRemoteDataSource remote;
  late AuthRepositoryImpl repository;

  setUp(() {
    store = InMemoryTokenStore();
    remote = AuthRemoteDataSource(
      createDioClient(
        baseUrl: baseUrl ?? '',
        tokenStore: store,
        refresh: (rt) async => (await remote.refresh(rt)).toTokens(),
        onSessionExpired: () {},
      ),
    );
    repository = AuthRepositoryImpl(
      remote: remote,
      tokenStore: store,
      deviceId: _FixedDeviceId(),
    );
  });

  test(
    'contraseña incorrecta → UnauthorizedFailure invalid-credentials',
    () async {
      final result = await repository.login(
        username: 'carlos',
        password: 'mala',
      );

      final failure = (result as Err<Session>).failure;
      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.code, 'invalid-credentials');
    },
    skip: skip,
  );

  test('login → refresh rota el token → logout invalida el refresh', () async {
    final result = await repository.login(
      username: 'carlos',
      password: 'Nexo2026*',
    );

    expect(
      (result as Ok<Session>).value.customerId,
      '22222222-2222-2222-2222-222222222222',
    );
    final first = store.tokens!;

    final rotated = (await remote.refresh(first.refreshToken)).toTokens();
    expect(rotated.refreshToken, isNot(first.refreshToken));
    store.tokens = rotated;

    await repository.logout();
    expect(store.tokens, isNull);
    await expectLater(remote.refresh(rotated.refreshToken), throwsA(anything));
  }, skip: skip);
}
