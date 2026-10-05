import '../../../core/data/snapshot.dart';
import '../../../core/result/result.dart';
import '../domain/account_repository.dart';
import '../domain/movement.dart';

class GetMovements {
  const GetMovements(this._repository);

  final AccountRepository _repository;

  Stream<Result<Snapshot<MovementPage>>> firstPage(String accountId) =>
      _repository.watchMovements(accountId);

  Future<Result<MovementPage>> nextPage(
    String accountId, {
    required String cursor,
  }) => _repository.getMovementsPage(accountId, cursor: cursor);
}
