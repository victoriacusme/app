import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../design_system/design_system.dart';
import 'router.dart';
import 'session_cubit.dart';

class NexoApp extends StatefulWidget {
  const NexoApp({required this.sessionCubit, super.key});

  final SessionCubit sessionCubit;

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
    return BlocProvider.value(
      value: widget.sessionCubit,
      child: MaterialApp.router(
        title: 'Nexo Bank',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: _router,
      ),
    );
  }
}
