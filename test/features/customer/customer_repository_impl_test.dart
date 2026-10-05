import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/result/result.dart';
import 'package:nexo_bank/features/customer/domain/customer_profile.dart';
import 'package:nexo_bank/features/customer/infrastructure/customer_remote_data_source.dart';
import 'package:nexo_bank/features/customer/infrastructure/customer_repository_impl.dart';

import '../../helpers/customer_fixtures.dart';
import '../../helpers/fakes.dart';

class _MockRemote extends Mock implements CustomerRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late InMemoryCache cache;
  late CustomerRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    cache = InMemoryCache();
    repository = CustomerRepositoryImpl(remote: remote, cache: cache);
  });

  test(
    'mapea el perfil con datos enmascarados y avisa las preferencias',
    () async {
      when(remote.getProfile).thenAnswer((_) async => profileJson());
      final prefs = repository.preferences.first;

      final last = await repository.watchProfile().last;
      final profile = (last as Ok).value.data as CustomerProfile;

      expect(profile.segment, Segment.entrepreneur);
      expect(profile.maskedIdNumber, '******6789');
      expect((await prefs).theme, ThemePreference.light);
    },
  );

  test('PATCH envía solo lo que cambió y actualiza la caché', () async {
    when(remote.getProfile).thenAnswer((_) async => profileJson());
    await repository.watchProfile().drain<void>();
    when(() => remote.patchPreferences(any())).thenAnswer(
      (_) async => {
        'language': 'es',
        'theme': 'DARK',
        'notificationsEnabled': true,
        'showPromotions': true,
      },
    );
    const before = Preferences(theme: ThemePreference.light);

    final result = await repository.updatePreferences(
      before,
      before.copyWith(theme: ThemePreference.dark),
    );

    expect((result as Ok<Preferences>).value.theme, ThemePreference.dark);
    verify(() => remote.patchPreferences({'theme': 'DARK'})).called(1);
    final cached = cache.entries['customer:profile']!.data! as Map;
    expect((cached['preferences'] as Map)['theme'], 'DARK');
  });

  test('sin cambios no llama al backend', () async {
    const prefs = Preferences();

    final result = await repository.updatePreferences(prefs, prefs);

    expect(result.isOk, isTrue);
    verifyNever(() => remote.patchPreferences(any()));
  });

  test('si el PATCH falla devuelve el error', () async {
    when(() => remote.patchPreferences(any())).thenThrow(
      DioException.connectionError(
        requestOptions: RequestOptions(path: '/customers/me/preferences'),
        reason: 'sin red',
      ),
    );

    final result = await repository.updatePreferences(
      const Preferences(),
      const Preferences(showPromotions: false),
    );

    expect(result.isOk, isFalse);
  });
}
