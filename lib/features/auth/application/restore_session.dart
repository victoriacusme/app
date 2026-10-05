import '../domain/auth_repository.dart';
import '../domain/session.dart';

/// Recupera la sesión al abrir la app. Si el access token ya venció,
/// el `RefreshTokenInterceptor` lo renovará en la primera petición.
class RestoreSession {
  const RestoreSession(this._repository);

  final AuthRepository _repository;

  Future<Session?> call() => _repository.currentSession();
}
