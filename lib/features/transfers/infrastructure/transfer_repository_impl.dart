import '../../../core/network/error_mapper.dart';
import '../../../core/result/result.dart';
import '../domain/transfer.dart';
import '../domain/transfer_repository.dart';
import 'transfer_remote_data_source.dart';

class TransferRepositoryImpl implements TransferRepository {
  TransferRepositoryImpl(this._remote);

  final TransferRemoteDataSource _remote;

  @override
  Future<Result<Transfer>> transferBetweenOwnAccounts(
    TransferDraft draft, {
    required String idempotencyKey,
  }) async {
    try {
      return Ok(
        await _remote.transferOwn(draft, idempotencyKey: idempotencyKey),
      );
    } catch (e) {
      return Err(ErrorMapper.from(e));
    }
  }
}
