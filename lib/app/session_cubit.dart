import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/application/logout.dart';
import '../features/auth/application/restore_session.dart';
import '../features/auth/domain/session.dart';

sealed class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

/// Todavía no se sabe si hay sesión (se muestra el splash).
final class SessionUnknown extends SessionState {
  const SessionUnknown();
}

final class SessionAuthenticated extends SessionState {
  const SessionAuthenticated(this.session, {this.restored = false});

  final Session session;

  /// La sesión se recuperó al abrir la app (no hubo login con contraseña).
  final bool restored;

  @override
  List<Object?> get props => [session, restored];
}

final class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated({this.expired = false});

  /// La sesión terminó porque el backend rechazó el refresh token.
  final bool expired;

  @override
  List<Object?> get props => [expired];
}

/// Estado global de la sesión. El router redirige según este estado.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({
    required this._restoreSession,
    required this._logout,
    required this._clearUserData,
    this._onSignedIn,
    this._onSigningOut,
  }) : super(const SessionUnknown());

  final RestoreSession _restoreSession;
  final Logout _logout;
  final Future<void> Function() _clearUserData;

  /// Al iniciar o restaurar la sesión (p. ej. registrar el token de push).
  final Future<void> Function()? _onSignedIn;

  /// Antes de cerrar la sesión, mientras los tokens siguen vigentes.
  final Future<void> Function()? _onSigningOut;

  Future<void> restore() async {
    final session = await _restoreSession();
    emit(
      session == null
          ? const SessionUnauthenticated()
          : SessionAuthenticated(session, restored: true),
    );
    if (session != null) unawaited(_onSignedIn?.call());
  }

  void authenticated(Session session) {
    emit(SessionAuthenticated(session));
    unawaited(_onSignedIn?.call());
  }

  Future<void> logout() async {
    await _onSigningOut?.call();
    await _logout();
    await _clearUserData();
    emit(const SessionUnauthenticated());
  }

  /// Lo invoca el `RefreshTokenInterceptor` cuando el refresh falla.
  Future<void> sessionExpired() async {
    if (state is! SessionAuthenticated) return;
    emit(const SessionUnauthenticated(expired: true));
    await _clearUserData();
  }
}
