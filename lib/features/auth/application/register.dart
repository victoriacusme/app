import '../../../core/result/result.dart';
import '../domain/auth_repository.dart';
import '../domain/registration.dart';
import '../domain/session.dart';

class Register {
  const Register(this._repository);

  final AuthRepository _repository;

  Future<Result<Session>> call(Registration data) => _repository.register(data);
}
