import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'app/session_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  final session = getIt<SessionCubit>();
  unawaited(session.restore());
  runApp(NexoApp(sessionCubit: session));
}
