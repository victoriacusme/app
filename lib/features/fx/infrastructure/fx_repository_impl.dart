import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../core/data/snapshot.dart';
import '../../../core/data/stale_while_revalidate.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/encrypted_cache.dart';
import '../domain/fx_rates.dart';
import '../domain/fx_repository.dart';

/// Consulta `/external/fx/latest/{base}` (el gateway lo redirige a
/// open.er-api.com) y guarda la última respuesta en caché.
class FxRepositoryImpl implements FxRepository {
  FxRepositoryImpl({required this._dio, required this._cache});

  final Dio _dio;
  final KeyValueCache _cache;

  @override
  Stream<Result<Snapshot<FxRates>>> watchLatest(String base) =>
      staleWhileRevalidate(
        readCache: () => _cache.read('fx:$base'),
        fetch: () async {
          final json = (await _dio.get<Map<String, dynamic>>(
            '/external/fx/latest/$base',
          )).data!;
          if (json['result'] != 'success') {
            throw StateError('Respuesta de tipo de cambio inválida');
          }
          return json;
        },
        save: (json) => _cache.write('fx:$base', json),
        map: fromJson,
      );

  static final _rfc1123 = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US');

  static FxRates fromJson(Map<String, dynamic> json) {
    final published = json['time_last_update_utc'] as String?;
    return FxRates(
      base: json['base_code'] as String,
      rates: {
        for (final e in (json['rates'] as Map<String, dynamic>).entries)
          e.key: (e.value as num).toDouble(),
      },
      publishedAt: published == null
          ? DateTime.now().toUtc()
          : _rfc1123.parseUtc(published.replaceAll(' +0000', '')),
    );
  }
}
