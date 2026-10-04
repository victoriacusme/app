import 'package:dio/dio.dart';

import '../../../core/network/request_options_x.dart';
import 'token_response_dto.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<TokenResponseDto> login({
    required String username,
    required String password,
    required String deviceId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'username': username, 'password': password, 'deviceId': deviceId},
      options: RequestFlags.public(),
    );
    return TokenResponseDto.fromJson(response.data!);
  }

  Future<TokenResponseDto> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: RequestFlags.public(),
    );
    return TokenResponseDto.fromJson(response.data!);
  }

  Future<void> logout(String refreshToken) => _dio.post<void>(
    '/auth/logout',
    data: {'refreshToken': refreshToken},
    options: RequestFlags.public(),
  );
}
