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
  const SessionAuthenticated(this.session);

  final Session session;

  @override
  List<Object?> get props => [session];
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
  SessionCubit({required this._restoreSession, required this._logout})
    : super(const SessionUnknown());

  final RestoreSession _restoreSession;
  final Logout _logout;

  Future<void> restore() async {
    final session = await _restoreSession();
    emit(
      session == null
          ? const SessionUnauthenticated()
          : SessionAuthenticated(session),
    );
  }

  void authenticated(Session session) => emit(SessionAuthenticated(session));

  Future<void> logout() async {
    await _logout();
    emit(const SessionUnauthenticated());
  }

  /// Lo invoca el `RefreshTokenInterceptor` cuando el refresh falla.
  void sessionExpired() {
    if (state is SessionAuthenticated) {
      emit(const SessionUnauthenticated(expired: true));
    }
  }
}
