import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/features/accounts/presentation/bloc/accounts_bloc.dart';
import 'package:nexo_bank/features/accounts/presentation/bloc/movements_bloc.dart';
import 'package:nexo_bank/features/accounts/presentation/pages/movements_page.dart';
import 'package:nexo_bank/features/accounts/presentation/widgets/movement_tile.dart';

import '../../../helpers/accounts_fixtures.dart';
import '../../../helpers/pump_app.dart';

class _MockAccountsBloc extends MockBloc<AccountsEvent, AccountsState>
    implements AccountsBloc {}

class _MockMovementsBloc extends MockBloc<MovementsEvent, MovementsState>
    implements MovementsBloc {}

void main() {
  late _MockAccountsBloc accounts;
  late _MockMovementsBloc movements;

  setUpAll(() => registerFallbackValue(const MovementsRequested()));

  setUp(() {
    accounts = _MockAccountsBloc();
    movements = _MockMovementsBloc();
    when(() => accounts.state).thenReturn(
      AccountsState(
        status: AccountsStatus.loaded,
        accounts: [account('1', alias: 'Ahorros')],
      ),
    );
  });

  Future<void> pump(WidgetTester tester, MovementsState state) async {
    when(() => movements.state).thenReturn(state);
    await pumpPage(
      tester,
      const MovementsPage(accountId: '1'),
      providers: [
        BlocProvider<AccountsBloc>.value(value: accounts),
        BlocProvider<MovementsBloc>.value(value: movements),
      ],
    );
  }

  testWidgets('agrupa por día y muestra montos con signo', (tester) async {
    final now = DateTime.now();
    await pump(
      tester,
      MovementsState(
        status: MovementsStatus.loaded,
        items: [
          movement('a', bookedAt: now, credit: true),
          movement('b', bookedAt: now.subtract(const Duration(days: 1))),
        ],
        updatedAt: now,
      ),
    );

    expect(find.text('Ahorros'), findsWidgets);
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Ayer'), findsOneWidget);
    expect(find.byType(MovementTile), findsNWidgets(2));
    expect(find.text(r'+$10,00'), findsOneWidget);
    expect(find.text(r'-$10,00'), findsOneWidget);
    expect(find.text('No hay más movimientos'), findsOneWidget);
  });

  testWidgets('sin movimientos muestra el estado vacío', (tester) async {
    await pump(
      tester,
      MovementsState(status: MovementsStatus.loaded, updatedAt: DateTime.now()),
    );

    expect(find.textContaining('aún no tiene movimientos'), findsOneWidget);
  });

  testWidgets('al llegar al final pide la siguiente página', (tester) async {
    await pump(
      tester,
      MovementsState(
        status: MovementsStatus.loaded,
        items: [
          for (var i = 0; i < 20; i++)
            movement('m$i', bookedAt: DateTime.now()),
        ],
        nextCursor: 'c1',
        updatedAt: DateTime.now(),
      ),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pump();

    verify(() => movements.add(const MovementsNextPageRequested()))
        .called(greaterThan(0));
  });
}
