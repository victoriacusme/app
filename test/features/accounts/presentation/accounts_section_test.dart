import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/features/accounts/domain/account.dart';
import 'package:nexo_bank/features/accounts/presentation/bloc/accounts_bloc.dart';
import 'package:nexo_bank/features/accounts/presentation/widgets/account_card.dart';
import 'package:nexo_bank/features/accounts/presentation/widgets/accounts_section.dart';

import '../../../helpers/accounts_fixtures.dart';
import '../../../helpers/pump_app.dart';

class _MockAccountsBloc extends MockBloc<AccountsEvent, AccountsState>
    implements AccountsBloc {}

void main() {
  late _MockAccountsBloc bloc;

  setUpAll(() => registerFallbackValue(const AccountsRequested()));
  setUp(() => bloc = _MockAccountsBloc());

  Future<void> pump(
    WidgetTester tester,
    AccountsState state, {
    bool showTotal = false,
  }) async {
    when(() => bloc.state).thenReturn(state);
    await pumpPage(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: AccountsSection(showTotal: showTotal),
        ),
      ),
      providers: [BlocProvider<AccountsBloc>.value(value: bloc)],
    );
  }

  testWidgets('mientras carga muestra skeletons', (tester) async {
    await pump(tester, const AccountsState());

    expect(find.byType(AccountCardSkeleton), findsNWidgets(2));
  });

  testWidgets('muestra cuentas, número enmascarado y total sin las inactivas', (
    tester,
  ) async {
    await pump(
      tester,
      AccountsState(
        status: AccountsStatus.loaded,
        accounts: [
          account('4521', cents: 309270, alias: 'Ahorros', isDefault: true),
          account('7834', cents: 52550),
          account('9999', cents: 100000, status: AccountStatus.blocked),
        ],
        updatedAt: DateTime.now(),
      ),
      showTotal: true,
    );

    expect(find.byType(AccountCard), findsNWidgets(3));
    expect(find.text(r'$3.092,70'), findsOneWidget);
    expect(find.textContaining('****4521'), findsOneWidget);
    expect(find.text(r'Saldo total $3.618,20'), findsOneWidget);
  });

  testWidgets('error sin datos: ErrorView con reintento', (tester) async {
    await pump(
      tester,
      const AccountsState(
        status: AccountsStatus.failure,
        failure: NetworkFailure(),
      ),
    );

    await tester.tap(find.text('Reintentar'));

    verify(() => bloc.add(const AccountsRequested())).called(1);
  });

  testWidgets('datos viejos: banner y datos visibles', (tester) async {
    await pump(
      tester,
      AccountsState(
        status: AccountsStatus.loaded,
        accounts: [account('1')],
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        fromCache: true,
        refreshFailure: const NetworkFailure(),
      ),
    );

    expect(find.byKey(const Key('accounts_stale_banner')), findsOneWidget);
    expect(find.textContaining('hace 5 min'), findsOneWidget);
    expect(find.byType(AccountCard), findsOneWidget);
  });

  testWidgets('tocar una cuenta navega a sus movimientos', (tester) async {
    await pump(
      tester,
      AccountsState(
        status: AccountsStatus.loaded,
        accounts: [account('1')],
        updatedAt: DateTime.now(),
      ),
    );

    await tester.tap(find.byType(AccountCard));
    await tester.pumpAndSettle();

    expect(find.text('ruta:/accounts/1'), findsOneWidget);
  });
}
