import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/core/result/result.dart';
import 'package:nexo_bank/features/customer/application/update_preferences.dart';
import 'package:nexo_bank/features/customer/application/watch_profile.dart';
import 'package:nexo_bank/features/customer/domain/customer_profile.dart';
import 'package:nexo_bank/features/customer/infrastructure/customer_dtos.dart';
import 'package:nexo_bank/features/customer/presentation/profile_bloc.dart';

import '../../helpers/customer_fixtures.dart';

class _MockWatch extends Mock implements WatchProfile {}

class _MockUpdate extends Mock implements UpdatePreferences {}

void main() {
  late _MockWatch watch;
  late _MockUpdate update;
  final profile = CustomerDtos.profile(profileJson());
  final dark = profile.preferences.copyWith(theme: ThemePreference.dark);

  setUpAll(() => registerFallbackValue(const Preferences()));
  setUp(() {
    watch = _MockWatch();
    update = _MockUpdate();
  });

  ProfileState loaded(Preferences p, {bool saving = false, Failure? error}) =>
      ProfileState(
        status: ProfileStatus.loaded,
        profile: profile.withPreferences(p),
        saving: saving,
        saveFailure: error,
      );

  blocTest<ProfileBloc, ProfileState>(
    'edición optimista: el cambio se ve antes de que responda el backend',
    setUp: () =>
        when(() => update(any(), any())).thenAnswer((_) async => Ok(dark)),
    build: () => ProfileBloc(watch, update),
    seed: () => loaded(profile.preferences),
    act: (b) => b.add(PreferencesEdited(dark)),
    expect: () => [loaded(dark, saving: true), loaded(dark)],
  );

  blocTest<ProfileBloc, ProfileState>(
    'si el backend rechaza el cambio, se revierte y se avisa',
    setUp: () =>
        when(() => update(any(), any()))
            .thenAnswer((_) async => const Err(NetworkFailure())),
    build: () => ProfileBloc(watch, update),
    seed: () => loaded(profile.preferences),
    act: (b) => b.add(PreferencesEdited(dark)),
    expect: () => [
      loaded(dark, saving: true),
      loaded(profile.preferences, error: const NetworkFailure()),
    ],
  );
}
