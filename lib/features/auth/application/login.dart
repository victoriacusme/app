import '../../../core/result/result.dart';
import '../domain/auth_repository.dart';
import '../domain/session.dart';

class Login {
  const Login(this._repository);

  final AuthRepository _repository;

  Future<Result<Session>> call({
    required String username,
    required String password,
  }) => _repository.login(username: username.trim(), password: password);
}
