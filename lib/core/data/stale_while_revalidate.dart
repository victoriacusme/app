import '../network/error_mapper.dart';
import '../result/result.dart';
import '../storage/encrypted_cache.dart';
import 'snapshot.dart';

/// Implementa stale-while-revalidate sobre una caché de JSON:
///
/// 1. Si hay caché, la emite (`fromCache: true`).
/// 2. Pide el dato remoto: si llega, lo guarda y lo emite.
/// 3. Si falla: con caché, re-emite la caché con `refreshFailure`;
///    sin caché, emite el error.
Stream<Result<Snapshot<T>>> staleWhileRevalidate<T>({
  required Future<CacheEntry?> Function() readCache,
  required Future<Map<String, dynamic>> Function() fetch,
  required Future<void> Function(Map<String, dynamic> json) save,
  required T Function(Map<String, dynamic> json) map,
  DateTime Function() now = DateTime.now,
}) async* {
  Snapshot<T>? cached;
  try {
    final entry = await readCache();
    if (entry?.data case final Map<String, dynamic> json) {
      cached = Snapshot(
        data: map(json),
        updatedAt: entry!.savedAt,
        fromCache: true,
      );
    }
  } catch (_) {
    cached = null; // caché corrupta o de un formato anterior: se ignora
  }
  if (cached != null) yield Ok(cached);

  try {
    final json = await fetch();
    final fresh = Snapshot(data: map(json), updatedAt: now());
    await save(json);
    yield Ok(fresh);
  } catch (e) {
    final failure = ErrorMapper.from(e);
    yield cached == null
        ? Err(failure)
        : Ok(cached.withRefreshFailure(failure));
  }
}
