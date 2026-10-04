import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/core/result/result.dart';
import 'package:nexo_bank/core/security/device_id_provider.dart';
import 'package:nexo_bank/features/auth/domain/session.dart';
import 'package:nexo_bank/features/auth/infrastructure/auth_remote_data_source.dart';
import 'package:nexo_bank/features/auth/infrastructure/auth_repository_impl.dart';
import 'package:nexo_bank/features/auth/infrastructure/token_response_dto.dart';

import '../../../helpers/fakes.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockDeviceId extends Mock implements DeviceIdProvider {}

void main() {
  late _MockRemote remote;
  late InMemoryTokenStore store;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    store = InMemoryTokenStore();
    final deviceId = _MockDeviceId();
    when(deviceId.get).thenAnswer((_) async => 'device-1');
    repository = AuthRepositoryImpl(
      remote: remote,
      tokenStore: store,
      deviceId: deviceId,
    );
  });

  group('login', () {
    test('guarda los tokens y devuelve la sesión con el sub del JWT', () async {
      when(
        () => remote.login(
          username: 'ana',
          password: 'secreta',
          deviceId: 'device-1',
        ),
      ).thenAnswer(
        (_) async => TokenResponseDto(
          accessToken: fakeJwt('customer-1'),
          refreshToken: 'refresh-1',
          expiresIn: 900,
        ),
      );

      final result = await repository.login(
        username: 'ana',
        password: 'secreta',
      );

      expect(
        (result as Ok<Session>).value,
        const Session(customerId: 'customer-1'),
      );
      expect(store.tokens?.refreshToken, 'refresh-1');
    });

    test(
      'un 401 se convierte en UnauthorizedFailure y no guarda tokens',
      () async {
        final options = RequestOptions(path: '/auth/login');
        when(
          () => remote.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
            deviceId: any(named: 'deviceId'),
          ),
        ).thenThrow(
          DioException.badResponse(
            statusCode: 401,
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 401,
              data: {'code': 'invalid-credentials', 'detail': 'Incorrectos'},
            ),
          ),
        );

        final result = await repository.login(username: 'ana', password: 'x');

        expect((result as Err<Session>).failure, isA<UnauthorizedFailure>());
        expect(store.tokens, isNull);
      },
    );
  });

  group('logout', () {
    test('borra los tokens aunque el backend falle', () async {
      store.tokens = tokens('1');
      when(() => remote.logout(any())).thenThrow(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/auth/logout'),
          reason: 'sin red',
        ),
      );

      await repository.logout();

      expect(store.tokens, isNull);
      verify(() => remote.logout('refresh-1')).called(1);
    });
  });

  group('currentSession', () {
    test('sin tokens devuelve null', () async {
      expect(await repository.currentSession(), isNull);
    });

    test('con tokens devuelve la sesión', () async {
      store.tokens = tokens('1').copyWithAccess(fakeJwt('customer-9'));

      expect(
        await repository.currentSession(),
        const Session(customerId: 'customer-9'),
      );
    });

    test('con un token corrupto limpia y devuelve null', () async {
      store.tokens = tokens('1');

      expect(await repository.currentSession(), isNull);
      expect(store.tokens, isNull);
    });
  });
}
