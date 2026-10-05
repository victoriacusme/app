import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/core/network/error_mapper.dart';
import 'package:nexo_bank/core/result/failure.dart';

DioException _response(int status, Object? data) {
  final options = RequestOptions(
    path: '/x',
    headers: {'X-Correlation-Id': 'cid-1'},
  );
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  test('401 con ProblemDetail → UnauthorizedFailure con code y detail', () {
    final failure = ErrorMapper.fromDio(
      _response(401, {
        'status': 401,
        'detail': 'Usuario o contraseña incorrectos',
        'code': 'invalid-credentials',
      }),
    );

    expect(failure, isA<UnauthorizedFailure>());
    expect(failure.code, 'invalid-credentials');
    expect(failure.message, 'Usuario o contraseña incorrectos');
    expect(failure.correlationId, 'cid-1');
  });

  test('400 de validación → ValidationFailure con errores por campo', () {
    final failure = ErrorMapper.fromDio(
      _response(400, {
        'detail': 'La solicitud tiene datos inválidos',
        'code': 'validation-error',
        'errors': {'username': 'no debe estar vacío'},
      }),
    );

    expect(failure, isA<ValidationFailure>());
    expect((failure as ValidationFailure).fieldErrors, {
      'username': 'no debe estar vacío',
    });
  });

  test('423 bloqueado → ServerFailure que conserva el code', () {
    final failure = ErrorMapper.fromDio(
      _response(423, {'detail': 'Bloqueado', 'code': 'user-locked'}),
    );

    expect(failure, isA<ServerFailure>());
    expect(failure.code, 'user-locked');
    expect(failure.statusCode, 423);
  });

  test('5xx no muestra el detalle interno del servidor', () {
    final failure = ErrorMapper.fromDio(
      _response(500, {'detail': 'NullPointerException en X'}),
    );

    expect(failure, isA<ServerFailure>());
    expect(failure.message, isNot(contains('NullPointer')));
  });

  test('timeouts → TimeoutFailure; sin conexión → NetworkFailure', () {
    final options = RequestOptions(path: '/x');

    expect(
      ErrorMapper.fromDio(
        DioException.receiveTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: options,
        ),
      ),
      isA<TimeoutFailure>(),
    );
    expect(
      ErrorMapper.fromDio(
        DioException.connectionError(requestOptions: options, reason: 'x'),
      ),
      isA<NetworkFailure>(),
    );
  });

  test('si no se pudo conectar es un error de red, no de lentitud', () {
    final options = RequestOptions(path: '/auth/register');

    expect(
      ErrorMapper.fromDio(
        DioException.connectionTimeout(
          timeout: const Duration(seconds: 5),
          requestOptions: options,
        ),
      ),
      isA<NetworkFailure>(),
    );
  });
}
