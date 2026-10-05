import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/features/notifications/application/push_registration.dart';
import 'package:nexo_bank/features/notifications/domain/push_token_source.dart';
import 'package:nexo_bank/features/notifications/infrastructure/device_remote_data_source.dart';

import '../../helpers/fakes.dart';

class _FixedToken implements PushTokenSource {
  _FixedToken(this.token);

  final String? token;

  @override
  Future<String?> currentToken() async => token;

  @override
  DevicePlatform get platform => DevicePlatform.android;
}

void main() {
  late FakeHttpAdapter adapter;
  late DeviceRemoteDataSource remote;

  setUp(() {
    adapter = FakeHttpAdapter((_) async => const FakeResponse(204));
    remote = DeviceRemoteDataSource(
      Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = adapter,
    );
  });

  test('registra el token con el formato de ms-customer', () async {
    await PushRegistration(_FixedToken('fcm:abc/1'), remote).register();

    final request = adapter.requests.single;
    expect(request.method, 'PUT');
    expect(request.path, '/customers/me/devices');
    expect(request.data, {'token': 'fcm:abc/1', 'platform': 'ANDROID'});
  });

  test('desregistra codificando el token en la URL', () async {
    await PushRegistration(_FixedToken('fcm:abc/1'), remote).unregister();

    final request = adapter.requests.single;
    expect(request.method, 'DELETE');
    expect(request.uri.path, '/customers/me/devices/fcm%3Aabc%2F1');
  });

  test('sin token (sin Firebase) no llama al backend', () async {
    await PushRegistration(_FixedToken(null), remote).register();

    expect(adapter.requests, isEmpty);
  });

  test(
    'un token rotado por FCM se vuelve a registrar hasta cerrar sesión',
    () async {
      final refreshes = StreamController<String>.broadcast();
      final registration = PushRegistration(
        _FixedToken('t1'),
        remote,
        tokenRefreshes: refreshes.stream,
      );

      await registration.register();
      refreshes.add('t2');
      await pumpEventQueue();
      await registration.unregister();
      refreshes.add('t3');
      await pumpEventQueue();

      final registered = adapter.requests
          .where((r) => r.method == 'PUT')
          .map((r) => (r.data as Map<String, dynamic>)['token'])
          .toList();
      expect(registered, ['t1', 't2']);
      await refreshes.close();
    },
  );

  test('un error del backend no interrumpe el login', () async {
    adapter.handler = (_) async => const FakeResponse(503);

    await expectLater(
      PushRegistration(_FixedToken('t'), remote).register(),
      completes,
    );
  });
}
