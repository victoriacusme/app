import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/core/result/result.dart';
import 'package:nexo_bank/features/auth/application/login.dart';
import 'package:nexo_bank/features/auth/domain/session.dart';
import 'package:nexo_bank/features/auth/presentation/bloc/login_bloc.dart';

class _MockLogin extends Mock implements Login {}

void main() {
  late _MockLogin login;
  const session = Session(customerId: 'customer-1');
  const submitted = LoginSubmitted(username: 'ana', password: 'Nexo2026*');

  void loginReturns(Result<Session> result) => when(
    () => login(
      username: any(named: 'username'),
      password: any(named: 'password'),
    ),
  ).thenAnswer((_) async => result);

  setUp(() => login = _MockLogin());

  blocTest<LoginBloc, LoginState>(
    'credenciales válidas: submitting → success con la sesión',
    setUp: () => loginReturns(const Ok(session)),
    build: () => LoginBloc(login),
    act: (bloc) => bloc.add(submitted),
    expect: () => const [
      LoginState(status: LoginStatus.submitting),
      LoginState(status: LoginStatus.success, session: session),
    ],
    verify: (_) =>
        verify(() => login(username: 'ana', password: 'Nexo2026*')).called(1),
  );

  blocTest<LoginBloc, LoginState>(
    'credenciales inválidas → error invalidCredentials',
    setUp: () => loginReturns(
      const Err(UnauthorizedFailure(message: 'x', code: 'invalid-credentials')),
    ),
    build: () => LoginBloc(login),
    act: (bloc) => bloc.add(submitted),
    skip: 1,
    expect: () => [
      isA<LoginState>()
          .having((s) => s.status, 'status', LoginStatus.failure)
          .having((s) => s.error, 'error', LoginError.invalidCredentials),
    ],
  );

  blocTest<LoginBloc, LoginState>(
    'usuario bloqueado (423 user-locked) → error locked',
    setUp: () => loginReturns(
      const Err(
        ServerFailure(message: 'x', code: 'user-locked', statusCode: 423),
      ),
    ),
    build: () => LoginBloc(login),
    act: (bloc) => bloc.add(submitted),
    skip: 1,
    expect: () => [
      isA<LoginState>()
          .having((s) => s.error, 'error', LoginError.locked)
          .having((s) => s.message, 'message', contains('bloqueado')),
    ],
  );

  blocTest<LoginBloc, LoginState>(
    'sin conexión → error network',
    setUp: () => loginReturns(const Err(NetworkFailure())),
    build: () => LoginBloc(login),
    act: (bloc) => bloc.add(submitted),
    skip: 1,
    expect: () => [
      isA<LoginState>().having((s) => s.error, 'error', LoginError.network),
    ],
  );

  blocTest<LoginBloc, LoginState>(
    'ignora un segundo envío mientras el primero está en curso',
    setUp: () =>
        when(
          () => login(
            username: any(named: 'username'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return const Ok(session);
        }),
    build: () => LoginBloc(login),
    act: (bloc) => bloc
      ..add(submitted)
      ..add(submitted),
    wait: const Duration(milliseconds: 30),
    verify: (_) => verify(
      () => login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).called(1),
  );
}
