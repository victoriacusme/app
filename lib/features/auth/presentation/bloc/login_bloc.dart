import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/failure.dart';
import '../../../../core/result/result.dart';
import '../../application/login.dart';
import '../../domain/auth_error_codes.dart';
import '../../domain/session.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(this._login) : super(const LoginState()) {
    on<LoginSubmitted>(_onSubmitted);
  }

  final Login _login;

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    // Ignora toques repetidos mientras hay un login en curso.
    if (state.isSubmitting) return;
    emit(const LoginState(status: LoginStatus.submitting));

    final result = await _login(
      username: event.username,
      password: event.password,
    );
    switch (result) {
      case Ok(:final value):
        emit(LoginState(status: LoginStatus.success, session: value));
      case Err(:final failure):
        emit(_failureState(failure));
    }
  }

  static LoginState _failureState(Failure failure) {
    final (error, message) = switch (failure) {
      Failure(code: AuthErrorCodes.userLocked) => (
        LoginError.locked,
        'Tu usuario está bloqueado por varios intentos fallidos. '
            'Comunícate con soporte para desbloquearlo.',
      ),
      UnauthorizedFailure() => (
        LoginError.invalidCredentials,
        'Usuario o contraseña incorrectos.',
      ),
      NetworkFailure() ||
      TimeoutFailure() => (LoginError.network, failure.message),
      _ => (LoginError.unknown, failure.message),
    };
    return LoginState(
      status: LoginStatus.failure,
      error: error,
      message: message,
    );
  }
}
