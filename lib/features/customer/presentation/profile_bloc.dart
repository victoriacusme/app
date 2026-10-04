import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/data/snapshot.dart';
import '../../../core/result/failure.dart';
import '../../../core/result/result.dart';
import '../application/update_preferences.dart';
import '../application/watch_profile.dart';
import '../domain/customer_profile.dart';

sealed class ProfileEvent {
  const ProfileEvent();
}

final class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

final class PreferencesEdited extends ProfileEvent {
  const PreferencesEdited(this.preferences);

  final Preferences preferences;
}

enum ProfileStatus { loading, loaded, failure }

final class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.loading,
    this.profile,
    this.failure,
    this.saving = false,
    this.saveFailure,
  });

  final ProfileStatus status;
  final CustomerProfile? profile;
  final Failure? failure;
  final bool saving;

  /// El último guardado falló y se revirtió el cambio.
  final Failure? saveFailure;

  @override
  List<Object?> get props => [status, profile, failure, saving, saveFailure];
}

/// Perfil y preferencias con **edición optimista**: el cambio se ve al
/// instante y, si el backend lo rechaza, se revierte y se avisa.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._watchProfile, this._updatePreferences)
    : super(const ProfileState()) {
    on<ProfileRequested>(_onRequested, transformer: restartable());
    // sequential: los cambios se guardan en orden.
    on<PreferencesEdited>(_onEdited, transformer: sequential());
  }

  final WatchProfile _watchProfile;
  final UpdatePreferences _updatePreferences;

  Future<void> _onRequested(
    ProfileRequested event,
    Emitter<ProfileState> emit,
  ) => emit.forEach<Result<Snapshot<CustomerProfile>>>(
    _watchProfile(),
    onData: (result) => switch (result) {
      Ok(value: final s) => ProfileState(
        status: ProfileStatus.loaded,
        profile: s.data,
      ),
      Err() when state.profile != null => state,
      Err(:final failure) => ProfileState(
        status: ProfileStatus.failure,
        failure: failure,
      ),
    },
  );

  Future<void> _onEdited(
    PreferencesEdited event,
    Emitter<ProfileState> emit,
  ) async {
    final profile = state.profile;
    if (profile == null) return;
    final previous = profile.preferences;
    emit(
      ProfileState(
        status: ProfileStatus.loaded,
        profile: profile.withPreferences(event.preferences),
        saving: true,
      ),
    );

    final result = await _updatePreferences(previous, event.preferences);
    emit(switch (result) {
      Ok(value: final saved) => ProfileState(
        status: ProfileStatus.loaded,
        profile: profile.withPreferences(saved),
      ),
      Err(:final failure) => ProfileState(
        status: ProfileStatus.loaded,
        profile: profile.withPreferences(previous),
        saveFailure: failure,
      ),
    });
  }
}
