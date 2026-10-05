import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/core/time/app_clock.dart';
import 'package:nexo_bank/features/customer/presentation/profile_bloc.dart';
import 'package:nexo_bank/features/experience/presentation/components/greeting_component.dart';

import '../../helpers/pump_app.dart';

void main() {
  late DateTime now;

  setUp(() {
    now = DateTime(2026, 10, 5, 8);
    AppClock.now = () => now;
  });
  tearDown(() => AppClock.now = DateTime.now);

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    localizedApp(
      home: BlocProvider<ProfileBloc>.value(
        value: profileOf('Ana'),
        child: const Scaffold(body: GreetingComponent()),
      ),
    ),
  );

  testWidgets('al volver a la app de noche ya no dice "Buenos días"', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Buenos días, Ana'), findsOneWidget);

    // La app quedó en segundo plano desde la mañana.
    now = DateTime(2026, 10, 5, 21);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('Buenas noches, Ana'), findsOneWidget);
  });

  testWidgets('con la app abierta cambia sola al llegar la tarde', (
    tester,
  ) async {
    now = DateTime(2026, 10, 5, 11, 59);
    await pump(tester);
    expect(find.text('Buenos días, Ana'), findsOneWidget);

    now = DateTime(2026, 10, 5, 12);
    await tester.pump(const Duration(minutes: 1));

    expect(find.text('Buenas tardes, Ana'), findsOneWidget);
  });

  test('el próximo cambio de franja es a las 5, 12 o 19 horas', () {
    DateTime at(int d, int h) => DateTime(2026, 10, d, h);
    expect(GreetingComponent.nextChange(at(5, 3)), at(5, 5));
    expect(GreetingComponent.nextChange(at(5, 8)), at(5, 12));
    expect(GreetingComponent.nextChange(at(5, 12)), at(5, 19));
    expect(GreetingComponent.nextChange(at(5, 22)), at(6, 5));
  });
}
