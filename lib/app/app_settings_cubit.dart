import 'dart:async';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/customer/domain/customer_profile.dart';
import '../features/customer/domain/customer_repository.dart';
import '../l10n/l10n.dart';
import 'session_cubit.dart';

final class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.locale,
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;

  /// Idioma elegido por el cliente. `null` = el del dispositivo (antes de
  /// iniciar sesión o si no hay preferencia).
  final Locale? locale;

  /// Idioma efectivo de la app (`es` o `en`).
  String get languageCode => AppLanguages.resolve(
    locale?.languageCode ?? PlatformDispatcher.instance.locale.languageCode,
  );

  @override
  List<Object?> get props => [themeMode, notificationsEnabled, locale];
}

/// Aplica en toda la app las preferencias del cliente (tema, idioma y
/// avisos). Al iniciar sesión carga el perfil (primero de la caché) y al
/// cerrarla vuelve a los valores por defecto.
class AppSettingsCubit extends Cubit<AppSettings> {
  AppSettingsCubit({
    required SessionCubit session,
    required CustomerRepository customers,
  }) : _customers = customers,
       super(const AppSettings()) {
    _preferences = customers.preferences.listen(_apply);
    _session = session.stream.listen(_onSession);
    _onSession(session.state);
  }

  final CustomerRepository _customers;
  late final StreamSubscription<Preferences> _preferences;
  late final StreamSubscription<SessionState> _session;

  void _onSession(SessionState state) {
    switch (state) {
      case SessionAuthenticated():
        // Los errores se ignoran: las preferencias no bloquean la app.
        unawaited(_customers.watchProfile().drain<void>());
      case SessionUnauthenticated():
        emit(const AppSettings());
      case SessionUnknown():
        break;
    }
  }

  void _apply(Preferences p) => emit(
    AppSettings(
      themeMode: switch (p.theme) {
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
        ThemePreference.system => ThemeMode.system,
      },
      notificationsEnabled: p.notificationsEnabled,
      locale: Locale(AppLanguages.resolve(p.language)),
    ),
  );

  @override
  Future<void> close() async {
    await _preferences.cancel();
    await _session.cancel();
    return super.close();
  }
}
