part of 'login_bloc.dart';

enum LoginStatus { initial, submitting, success, failure }

/// Tipo de error, para que la UI elija el mensaje y el estilo.
enum LoginError { invalidCredentials, locked, network, unknown }

final class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.error,
    this.failure,
    this.session,
  });

  final LoginStatus status;
  final LoginError? error;

  /// Detalle del error (para el mensaje y el código de soporte).
  final Failure? failure;
  final Session? session;

  bool get isSubmitting => status == LoginStatus.submitting;

  @override
  List<Object?> get props => [status, error, failure, session];
}
