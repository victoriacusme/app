import '../../../core/data/snapshot.dart';
import '../../../core/result/result.dart';
import '../domain/account.dart';
import '../domain/account_repository.dart';

class WatchAccounts {
  const WatchAccounts(this._repository);

  final AccountRepository _repository;

  Stream<Result<Snapshot<List<Account>>>> call() => _repository.watchAccounts();

  Stream<void> get changes => _repository.changes;
}
