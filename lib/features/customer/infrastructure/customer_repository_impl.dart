import 'dart:async';

import '../../../core/data/snapshot.dart';
import '../../../core/data/stale_while_revalidate.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/encrypted_cache.dart';
import '../domain/customer_profile.dart';
import '../domain/customer_repository.dart';
import 'customer_dtos.dart';
import 'customer_remote_data_source.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl({required this._remote, required this._cache});

  static const _profileKey = 'customer:profile';

  final CustomerRemoteDataSource _remote;
  final KeyValueCache _cache;
  final _preferences = StreamController<Preferences>.broadcast();

  @override
  Stream<Preferences> get preferences => _preferences.stream;

  @override
  Stream<Result<Snapshot<CustomerProfile>>> watchProfile() =>
      staleWhileRevalidate(
        readCache: () => _cache.read(_profileKey),
        fetch: _remote.getProfile,
        save: (json) => _cache.write(_profileKey, json),
        map: CustomerDtos.profile,
      ).map((result) {
        if (result case Ok(value: final snapshot)) {
          _preferences.add(snapshot.data.preferences);
        }
        return result;
      });

  @override
  Future<String?> cachedFirstName() async {
    try {
      final entry = await _cache.read(_profileKey);
      if (entry?.data case {'firstName': final String name}) return name;
    } catch (_) {}
    return null;
  }

  @override
  Future<Result<Preferences>> updatePreferences(
    Preferences current,
    Preferences next,
  ) async {
    final patch = CustomerDtos.preferencesPatch(current, next);
    if (patch.isEmpty) return Ok(current);
    try {
      final saved = CustomerDtos.preferences(
        await _remote.patchPreferences(patch),
      );
      await _updateCachedPreferences(saved);
      _preferences.add(saved);
      return Ok(saved);
    } catch (e) {
      return Err(ErrorMapper.from(e));
    }
  }

  Future<void> _updateCachedPreferences(Preferences saved) async {
    final entry = await _cache.read(_profileKey);
    if (entry?.data case final Map<String, dynamic> json) {
      await _cache.write(_profileKey, {
        ...json,
        'preferences': CustomerDtos.preferencesToJson(saved),
      }, savedAt: entry!.savedAt);
    }
  }
}
