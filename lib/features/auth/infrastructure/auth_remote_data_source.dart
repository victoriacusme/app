import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/request_options_x.dart';
import '../../../core/security/jwe_encryptor.dart';
import '../domain/registration.dart';
import 'jwks_client.dart';
import 'token_response_dto.dart';

class AuthRemoteDataSource {
  /// Sin [jwks] ni [encryptor] el login viaja como JSON plano (solo tests).
  AuthRemoteDataSource(this._dio, {this._jwks, this._encryptor});

  static const _joseContentType = 'application/jose';

  final Dio _dio;
  final JwksClient? _jwks;
  final JweEncryptor? _encryptor;

  /// Con JWE configurado, las credenciales viajan cifradas con la clave
  /// `enc` del JWKS (`Content-Type: application/jose`). Si el backend rotó
  /// la clave, se vuelve a leer el JWKS y se reintenta una sola vez.
  Future<TokenResponseDto> login({
    required String username,
    required String password,
    required String deviceId,
  }) async {
    final body = {
      'username': username,
      'password': password,
      'deviceId': deviceId,
    };
    final jwks = _jwks;
    final encryptor = _encryptor;
    if (jwks == null || encryptor == null) {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: body,
        options: RequestFlags.public(),
      );
      return TokenResponseDto.fromJson(response.data!);
    }

    Future<TokenResponseDto> send({required bool refreshKey}) async {
      final key = await jwks.encryptionKey(refresh: refreshKey);
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: encryptor.encrypt(jsonEncode(body), key),
        options: RequestFlags.public().copyWith(contentType: _joseContentType),
      );
      return TokenResponseDto.fromJson(response.data!);
    }

    try {
      return await send(refreshKey: false);
    } on DioException catch (e) {
      final code = (e.response?.data as Map?)?['code'];
      if (code != 'invalid-encrypted-payload') rethrow;
      return send(refreshKey: true);
    }
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
