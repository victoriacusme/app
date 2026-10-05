// E2E 2 (crítico): login → transferencia propia → los saldos cambian.
//   flutter test integration_test/own_transfer_test.dart -d emulator-5554
//
// Transfiere $1,00 entre dos cuentas de `carlos` y al final lo devuelve
// por API, para que los datos de prueba no cambien.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nexo_bank/app/di.dart';
import 'package:nexo_bank/core/money/money.dart';
import 'package:nexo_bank/features/accounts/domain/account.dart';
import 'package:nexo_bank/features/accounts/presentation/widgets/account_card.dart';
import 'package:nexo_bank/features/transfers/domain/transfer.dart';
import 'package:nexo_bank/features/transfers/domain/transfer_repository.dart';
import 'package:uuid/uuid.dart';

import 'helpers.dart';

List<Account> visibleAccounts(WidgetTester tester) => tester
    .widgetList<AccountCard>(find.byType(AccountCard))
    .map((card) => card.account)
    .toList();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('carlos transfiere \$1,00 y los saldos se actualizan', (
    tester,
  ) async {
    await startApp(tester);
    await login(tester, 'carlos');
    await pumpUntil(tester, find.byType(AccountCard));

    final before = visibleAccounts(tester);
    final source = before.firstWhere((a) => a.isDefault);
    final target = before.firstWhere((a) => a.id != source.id);
    const one = Money(100, 'USD');

    // Acceso rápido "Transferir" del home SDUI.
    const transferAction = Key('quick_action_app://transfers');
    await tester.scrollUntilVisible(find.byKey(transferAction), 300);
    await tapVisible(tester, find.byKey(transferAction));
    await pumpUntil(tester, find.byKey(const Key('transfer_amount')));

    await tester.tap(find.byKey(const Key('transfer_target')));
    await pumpUntil(tester, find.textContaining(target.maskedNumber).last);
    await tester.tap(find.textContaining(target.maskedNumber).last);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byKey(const Key('transfer_amount')), '1.00');
    await tester.enterText(
      find.byKey(const Key('transfer_description')),
      'E2E',
    );
    await tapVisible(tester, find.byKey(const Key('transfer_continue')));
    await pumpUntil(tester, find.byKey(const Key('transfer_confirm')));
    expect(find.text(r'$1,00'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('transfer_confirm')));
    // Desde aquí el dinero se movió: el reverso corre aunque el test falle.
    addTearDown(() async {
      final reverse = await getIt<TransferRepository>()
          .transferBetweenOwnAccounts(
            TransferDraft(source: target, target: source, amount: one),
            idempotencyKey: const Uuid().v4(),
          );
      expect(reverse.isOk, isTrue, reason: 'reverso del E2E');
    });
    await pumpUntil(tester, find.byKey(const Key('transfer_success')));

    await tapVisible(tester, find.byKey(const Key('transfer_done')));
    Money balanceOf(String id) =>
        visibleAccounts(tester).firstWhere((a) => a.id == id).balance;

    // El home se actualiza solo tras la transferencia (invalidación).
    await pumpUntil(
      tester,
      find.byWidgetPredicate(
        (w) =>
            w is AccountCard &&
            w.account.id == source.id &&
            w.account.balance == source.balance - one,
      ),
    );
    expect(balanceOf(source.id), source.balance - one);
    expect(balanceOf(target.id), target.balance + one);
  });
}
