import 'package:dio/dio.dart';

import '../domain/push_token_source.dart';

/// `PUT/DELETE /customers/me/devices` de ms-customer (idempotentes).
class DeviceRemoteDataSource {
  DeviceRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> register(String token, DevicePlatform platform) =>
      _dio.put<void>(
        '/customers/me/devices',
        data: {'token': token, 'platform': platform.name.toUpperCase()},
      );

  Future<void> unregister(String token) =>
      _dio.delete<void>('/customers/me/devices/${Uri.encodeComponent(token)}');
}
