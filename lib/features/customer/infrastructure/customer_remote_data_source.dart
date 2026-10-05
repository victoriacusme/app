import 'package:dio/dio.dart';

class CustomerRemoteDataSource {
  CustomerRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getProfile() async =>
      (await _dio.get<Map<String, dynamic>>('/customers/me')).data!;

  Future<Map<String, dynamic>> patchPreferences(
    Map<String, dynamic> patch,
  ) async => (await _dio.patch<Map<String, dynamic>>(
    '/customers/me/preferences',
    data: patch,
  )).data!;
}
