import '../../../core/result/result.dart';
import '../domain/customer_profile.dart';
import '../domain/customer_repository.dart';

class UpdatePreferences {
  const UpdatePreferences(this._repository);

  final CustomerRepository _repository;

  Future<Result<Preferences>> call(Preferences current, Preferences next) =>
      _repository.updatePreferences(current, next);
}
