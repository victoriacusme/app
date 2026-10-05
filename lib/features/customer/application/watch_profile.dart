import '../../../core/data/snapshot.dart';
import '../../../core/result/result.dart';
import '../domain/customer_profile.dart';
import '../domain/customer_repository.dart';

class WatchProfile {
  const WatchProfile(this._repository);

  final CustomerRepository _repository;

  Stream<Result<Snapshot<CustomerProfile>>> call() =>
      _repository.watchProfile();
}
