import 'dart:async';

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
    this.showPromotions = true,
    this.language,
    this.customerLoaded = false,
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;

  /// El cliente quiere ver promociones en su inicio.
  final bool showPromotions;

  /// Idioma registrado en el backend para el cliente (el del teléfono, que
  /// la app le informa). El backend lo usa para los textos de los push.
  final String? language;

  /// Las preferencias vienen del cliente con sesión (no son los valores por
  /// defecto de antes del login o después del logout).
  final bool customerLoaded;

  @override
  List<Object?> get props => [
    themeMode,
    notificationsEnabled,
    showPromotions,
    language,
    customerLoaded,
  ];
}

/// Aplica en toda la app las preferencias del cliente (tema, avisos y
/// promociones). Al iniciar sesión carga el perfil (primero de la caché) y
/// al cerrarla vuelve a los valores por defecto.
///
/// **El idioma no es una preferencia de la app: es el del teléfono.** Este
/// cubit solo mantiene al backend al tanto ([deviceLanguageChanged]), para
/// que los push lleguen en el mismo idioma que la app.
class AppSettingsCubit extends Cubit<AppSettings> {
  AppSettingsCubit({
    required SessionCubit session,
    required CustomerRepository customers,
    String Function()? deviceLanguage,
  }) : _customers = customers,
       _deviceLanguage = deviceLanguage ?? AppLanguages.device,
       super(const AppSettings()) {
    _preferences = customers.preferences.listen(_apply);
    _session = session.stream.listen(_onSession);
    _onSession(session.state);
  }

  final CustomerRepository _customers;
  final String Function() _deviceLanguage;
  late final StreamSubscription<Preferences> _preferences;
  late final StreamSubscription<SessionState> _session;
  Preferences? _current;

  /// Idioma de la app (el del teléfono): `es` o `en`.
  String get languageCode => _deviceLanguage();

  void _onSession(SessionState state) {
    switch (state) {
      case SessionAuthenticated():
        // Los errores se ignoran: las preferencias no bloquean la app.
        unawaited(_customers.watchProfile().drain<void>());
      case SessionUnauthenticated():
        _current = null;
        emit(const AppSettings());
      case SessionUnknown():
        break;
    }
  }

  void _apply(Preferences p) {
    _current = p;
    emit(
      AppSettings(
        themeMode: switch (p.theme) {
          ThemePreference.light => ThemeMode.light,
          ThemePreference.dark => ThemeMode.dark,
          ThemePreference.system => ThemeMode.system,
        },
        notificationsEnabled: p.notificationsEnabled,
        showPromotions: p.showPromotions,
        language: p.language,
        customerLoaded: true,
      ),
    );
    _syncLanguage();
  }

  /// El cliente cambió el idioma del teléfono.
  void deviceLanguageChanged() => _syncLanguage();

  /// Si el backend tiene otro idioma registrado, se le informa el del
  /// teléfono. La respuesta vuelve por [CustomerRepository.preferences].
  void _syncLanguage() {
    final current = _current;
    final device = _deviceLanguage();
    if (current == null || current.language == device) return;
    unawaited(
      _customers.updatePreferences(current, current.copyWith(language: device)),
    );
  }

  @override
  Future<void> close() async {
    await _preferences.cancel();
    await _session.cancel();
    return super.close();
  }
}
