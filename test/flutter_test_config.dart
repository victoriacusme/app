import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';

/// Configuración global de los tests: datos de fechas para es y en.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting();
  await testMain();
}
