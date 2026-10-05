import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/connectivity/connectivity_cubit.dart';
import '../core/navigation/deep_links.dart';
import '../design_system/design_system.dart';
import '../l10n/l10n.dart';
import 'app_lock_cubit.dart';
import 'app_settings_cubit.dart';
import 'router.dart';
import 'session_cubit.dart';

class NexoApp extends StatefulWidget {
  const NexoApp({
    required this.sessionCubit,
    required this.connectivityCubit,
    required this.settingsCubit,
    required this.lockCubit,
    this.deepLinks = const Stream.empty(),
    this.initialDeepLink,
    super.key,
  });

  final SessionCubit sessionCubit;
  final ConnectivityCubit connectivityCubit;
  final AppSettingsCubit settingsCubit;
  final AppLockCubit lockCubit;

  /// Deep links que llegan mientras la app corre (p. ej. al tocar una
  /// notificación).
  final Stream<String> deepLinks;

  /// Deep link con el que se abrió la app en frío.
  final String? initialDeepLink;

  @override
  State<NexoApp> createState() => _NexoAppState();
}

class _NexoAppState extends State<NexoApp> {
  late final GoRouter _router = createRouter(
    widget.sessionCubit,
    widget.lockCubit,
  );
  late final StreamSubscription<String> _links;
  late final StreamSubscription<SessionState> _session;
  late final StreamSubscription<AppLockState> _lock;

  /// Ruta pendiente hasta que haya sesión (el login va primero).
  String? _pending;

  @override
  void initState() {
    super.initState();
    _pending = _routeOf(widget.initialDeepLink);
    _links = widget.deepLinks.listen((link) {
      _pending = _routeOf(link);
      _openPending();
    });
    _session = widget.sessionCubit.stream.listen((_) => _openPending());
    _lock = widget.lockCubit.stream.listen((_) => _openPending());
  }

  static String? _routeOf(String? link) =>
      link == null ? null : DeepLinks.routeFor(link);

  void _openPending() {
    final route = _pending;
    if (route == null ||
        widget.sessionCubit.state is! SessionAuthenticated ||
        widget.lockCubit.state.locked) {
      return;
    }
    _pending = null;
    // Se espera a que el router aplique la redirección al home.
    WidgetsBinding.instance.addPostFrameCallback((_) => _router.push(route));
  }

  @override
  void dispose() {
    unawaited(_links.cancel());
    unawaited(_session.cancel());
    unawaited(_lock.cancel());
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.sessionCubit),
        BlocProvider.value(value: widget.connectivityCubit),
        BlocProvider.value(value: widget.settingsCubit),
        BlocProvider.value(value: widget.lockCubit),
      ],
      child: BlocBuilder<AppSettingsCubit, AppSettings>(
        buildWhen: (a, b) => a.themeMode != b.themeMode || a.locale != b.locale,
        builder: (context, settings) => MaterialApp.router(
          onGenerateTitle: (context) => context.l10n.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.themeMode,
          // Idioma del cliente o, antes del login, el del dispositivo; si el
          // dispositivo está en otro idioma, español.
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: (device, supported) =>
              Locale(AppLanguages.resolve(device?.languageCode)),
          routerConfig: _router,
          builder: (context, child) => PrivacyCover(
            onBackgrounded: widget.lockCubit.onBackgrounded,
            onForegrounded: widget.lockCubit.onForegrounded,
            child: _OfflineFrame(child: child!),
          ),
        ),
      ),
    );
  }
}

/// Muestra el banner "Sin conexión" encima de cualquier pantalla.
class _OfflineFrame extends StatelessWidget {
  const _OfflineFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final offline = context.select(
      (ConnectivityCubit c) => c.state == ConnectivityStatus.offline,
    );
    return Column(
      children: [
        if (offline) const OfflineBanner(key: Key('offline_banner')),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: offline,
            child: child,
          ),
        ),
      ],
    );
  }
}
