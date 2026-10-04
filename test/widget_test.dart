import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/main.dart';

void main() {
  testWidgets('La app arranca y muestra Nexo Bank', (tester) async {
    await tester.pumpWidget(const NexoBankApp());
    expect(find.text('Nexo Bank'), findsOneWidget);
  });
}
