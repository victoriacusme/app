import '../../../core/result/result.dart';
import 'session.dart';

/// Puerto de autenticación.
abstract interface class AuthRepository {
  Future<Result<Session>> login({
    required String username,
    required String password,
  });

  /// Cierra la sesión en el backend (best effort) y borra los tokens locales.
  Future<void> logout();

  /// Devuelve la sesión guardada, o `null` si no hay.
  Future<Session?> currentSession();
}
