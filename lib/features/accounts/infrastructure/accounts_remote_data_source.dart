import 'package:dio/dio.dart';

/// Devuelve el JSON crudo: así se guarda tal cual en la caché.
class AccountsRemoteDataSource {
  AccountsRemoteDataSource(this._dio);

  static const pageSize = 20;

  final Dio _dio;

  Future<Map<String, dynamic>> getAccounts() async =>
      (await _dio.get<Map<String, dynamic>>('/accounts')).data!;

  Future<Map<String, dynamic>> getAccount(String id) async =>
      (await _dio.get<Map<String, dynamic>>('/accounts/$id')).data!;

  Future<Map<String, dynamic>> getMovements(
    String accountId, {
    String? cursor,
  }) async => (await _dio.get<Map<String, dynamic>>(
    '/accounts/$accountId/movements',
    queryParameters: {'size': pageSize, 'cursor': ?cursor},
  )).data!;
}
