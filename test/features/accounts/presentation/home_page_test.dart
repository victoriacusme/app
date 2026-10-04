import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/connectivity/connectivity_cubit.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/design_system/design_system.dart';
import 'package:nexo_bank/features/accounts/presentation/bloc/accounts_bloc.dart';
import 'package:nexo_bank/features/accounts/presentation/pages/home_page.dart';
import 'package:nexo_bank/features/accounts/presentation/widgets/account_card.dart';

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
    ConnectivityCubit? connectivity,
  }) async {
    when(() => bloc.state).thenReturn(state);
    await pumpPage(
      tester,
      const HomePage(),
      connectivity: connectivity,
      providers: [BlocProvider<AccountsBloc>.value(value: bloc)],
    );
  }

  testWidgets('mientras carga muestra skeletons', (tester) async {
    await pump(tester, const AccountsState());

    expect(find.byType(AccountCardSkeleton), findsNWidgets(2));
    expect(find.byType(AccountCard), findsNothing);
  });

  testWidgets('muestra las cuentas con número enmascarado y saldo', (
    tester,
  ) async {
    await pump(
      tester,
      AccountsState(
        status: AccountsStatus.loaded,
        accounts: [
          account('4521', cents: 309270, alias: 'Ahorros', isDefault: true),
          account('7834', cents: 52550),
        ],
        updatedAt: DateTime.now(),
      ),
    );

    expect(find.byType(AccountCard), findsNWidgets(2));
    expect(find.text(r'$3.092,70'), findsOneWidget);
    expect(find.textContaining('****4521'), findsOneWidget);
    expect(find.byKey(const Key('home_transfer_button')), findsOneWidget);
    expect(find.byType(StaleDataBanner), findsNothing);
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

  testWidgets('datos viejos tras fallar el refresco: banner y datos visibles', (
    tester,
  ) async {
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
    expect(find.textContaining('No pudimos actualizar'), findsOneWidget);
    expect(find.textContaining('hace 5 min'), findsOneWidget);
    expect(find.byType(AccountCard), findsOneWidget);
  });

  testWidgets('al recuperar la conexión refresca solo', (tester) async {
    final connectivity = MockConnectivityCubit();
    whenListen(
      connectivity,
      Stream.fromIterable([ConnectivityStatus.online]),
      initialState: ConnectivityStatus.offline,
    );
    await pump(
      tester,
      AccountsState(
        status: AccountsStatus.loaded,
        accounts: [account('1')],
        updatedAt: DateTime.now(),
      ),
      connectivity: connectivity,
    );
    await tester.pump();

    verify(() => bloc.add(const AccountsRequested())).called(1);
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
