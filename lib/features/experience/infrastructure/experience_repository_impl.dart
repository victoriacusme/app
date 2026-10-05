import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/storage/encrypted_cache.dart';
import '../domain/experience_layout.dart';
import '../domain/experience_repository.dart';

class ExperienceRepositoryImpl implements ExperienceRepository {
  ExperienceRepositoryImpl({
    required this._dio,
    required this._cache,
    required this._loadFallback,
  });

  static const _cacheKey = 'experience:home';

  final Dio _dio;
  final KeyValueCache _cache;

  /// Lee el JSON de respaldo incluido en la app (assets).
  final Future<String> Function() _loadFallback;

  @override
  Stream<ExperienceLayout> watchHome() async* {
    final cached = await _readCache();
    if (cached != null) yield fromJson(cached.json);

    try {
      // Revalida con ETag: si no cambió, el backend responde 304 sin cuerpo.
      final response = await _dio.get<Map<String, dynamic>>(
        '/experience/home',
        options: Options(
          headers: {'If-None-Match': ?cached?.etag},
          validateStatus: (s) => s == 200 || s == 304,
        ),
      );
      if (response.statusCode == 304 && cached != null) return;
      final json = response.data!;
      final layout = fromJson(json);
      await _cache.write(_cacheKey, {
        'etag': response.headers.value('etag'),
        'json': json,
      });
      yield layout;
    } catch (_) {
      if (cached == null) {
        yield fromJson(
          jsonDecode(await _loadFallback()) as Map<String, dynamic>,
          isFallback: true,
        );
      }
    }
  }

  Future<({String? etag, Map<String, dynamic> json})?> _readCache() async {
    try {
      final entry = await _cache.read(_cacheKey);
      if (entry?.data case {'json': final Map<String, dynamic> json}) {
        final etag = (entry!.data! as Map)['etag'] as String?;
        fromJson(json); // valida que el formato guardado siga siendo legible
        return (etag: etag, json: json);
      }
    } catch (_) {
      await _cache.delete(_cacheKey);
    }
    return null;
  }

  static ExperienceLayout fromJson(
    Map<String, dynamic> json, {
    bool isFallback = false,
  }) => ExperienceLayout(
    screen: json['screen'] as String? ?? 'home',
    segment: json['segment'] as String? ?? 'STANDARD',
    isFallback: isFallback,
    components: [
      for (final c in (json['components'] as List<dynamic>? ?? const []))
        if (c case {'type': final String type})
          ComponentSpec(
            id: c['id']?.toString() ?? type,
            type: type,
            properties: (c['props'] as Map<String, dynamic>?) ?? const {},
          ),
    ],
  );
}
