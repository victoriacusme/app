import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/design_system/design_system.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('tapa los saldos al ir a segundo plano y avisa al volver', (
    tester,
  ) async {
    var backgrounded = 0;
    var foregrounded = 0;
    await tester.pumpWidget(
      localizedApp(
        home: PrivacyCover(
          onBackgrounded: () => backgrounded++,
          onForegrounded: () => foregrounded++,
          child: const Text(r'$3.092,70'),
        ),
      ),
    );
    expect(find.byKey(const Key('privacy_cover')), findsNothing);

    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.byKey(const Key('privacy_cover')), findsOneWidget);
    expect(backgrounded, 1);

    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byKey(const Key('privacy_cover')), findsNothing);
    expect(foregrounded, 1);
  });

  testWidgets('en Android un diálogo del sistema (inactive) no tapa la app', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(
      localizedApp(home: const PrivacyCover(child: Text('saldo'))),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(find.byKey(const Key('privacy_cover')), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('en iOS se tapa ya en inactive (captura del selector)', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(
      localizedApp(home: const PrivacyCover(child: Text('saldo'))),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(find.byKey(const Key('privacy_cover')), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
