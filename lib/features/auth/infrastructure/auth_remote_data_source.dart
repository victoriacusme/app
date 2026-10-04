import 'package:dio/dio.dart';

import '../../../core/network/request_options_x.dart';
import '../domain/registration.dart';
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

  Future<TokenResponseDto> register(
    Registration data, {
    required String deviceId,
  }) async {
    final birth = data.birthDate;
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'username': data.username.trim(),
        'password': data.password,
        'fullName': data.fullName.trim(),
        'idNumber': data.idNumber.trim(),
        'email': data.email.trim(),
        'phone': data.phone.replaceAll(' ', ''),
        'birthDate':
            '${birth.year.toString().padLeft(4, '0')}-'
            '${birth.month.toString().padLeft(2, '0')}-'
            '${birth.day.toString().padLeft(2, '0')}',
        'deviceId': deviceId,
      },
      // El registro hace tres llamadas síncronas en el backend.
      options: RequestFlags.public().copyWith(
        receiveTimeout: const Duration(seconds: 20),
      ),
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
