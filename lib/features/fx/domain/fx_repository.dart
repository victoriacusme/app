import '../../../core/data/snapshot.dart';
import '../../../core/result/result.dart';
import 'fx_rates.dart';

abstract interface class FxRepository {
  Stream<Result<Snapshot<FxRates>>> watchLatest(String base);
}
