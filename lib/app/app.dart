import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/connectivity/connectivity_cubit.dart';
import '../design_system/design_system.dart';
import 'router.dart';
import 'session_cubit.dart';

class NexoApp extends StatefulWidget {
  const NexoApp({
    required this.sessionCubit,
    required this.connectivityCubit,
    super.key,
  });

  final SessionCubit sessionCubit;
  final ConnectivityCubit connectivityCubit;

  @override
  State<NexoApp> createState() => _NexoAppState();
}

class _NexoAppState extends State<NexoApp> {
  late final GoRouter _router = createRouter(widget.sessionCubit);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.sessionCubit),
        BlocProvider.value(value: widget.connectivityCubit),
      ],
      child: MaterialApp.router(
        title: 'Nexo Bank',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: _router,
        builder: (context, child) => _OfflineFrame(child: child!),
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
