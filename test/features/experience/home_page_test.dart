import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/connectivity/connectivity_cubit.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/features/accounts/presentation/bloc/accounts_bloc.dart';
import 'package:nexo_bank/features/accounts/presentation/widgets/account_card.dart';
import 'package:nexo_bank/features/experience/domain/experience_layout.dart';
import 'package:nexo_bank/features/experience/presentation/experience_cubit.dart';
import 'package:nexo_bank/features/experience/presentation/home_page.dart';
import 'package:nexo_bank/features/fx/presentation/fx_cubit.dart';

import '../../helpers/accounts_fixtures.dart';
import '../../helpers/pump_app.dart';

class _MockExperience extends MockCubit<ExperienceLayout?>
    implements ExperienceCubit {}

class _MockAccounts extends MockBloc<AccountsEvent, AccountsState>
    implements AccountsBloc {}

class _MockFx extends MockCubit<FxState> implements FxCubit {}

void main() {
  late _MockExperience experience;
  late _MockAccounts accounts;
  late _MockFx fx;

  setUpAll(() => registerFallbackValue(const AccountsRequested()));

  setUp(() {
    experience = _MockExperience();
    accounts = _MockAccounts();
    fx = _MockFx();
    when(() => accounts.state).thenReturn(
      AccountsState(
        status: AccountsStatus.loaded,
        accounts: [
          account('0011', cents: 309270, alias: 'Ahorros', isDefault: true),
          account('0012', cents: 52550, alias: 'Meta: viaje'),
        ],
        updatedAt: DateTime.now(),
      ),
    );
    when(() => fx.state).thenReturn(const FxState());
    when(() => fx.load(any())).thenAnswer((_) async {});
    when(() => experience.load()).thenAnswer((_) async {});
  });

  ComponentSpec spec(String type, Map<String, dynamic> props) =>
      ComponentSpec(id: type, type: type, properties: props);

  Future<void> pump(
    WidgetTester tester,
    ExperienceLayout? layout, {
    ConnectivityCubit? connectivity,
  }) async {
    when(() => experience.state).thenReturn(layout);
    await pumpPage(
      tester,
      const HomePage(),
      connectivity: connectivity,
      providers: [
        BlocProvider<ExperienceCubit>.value(value: experience),
        BlocProvider<AccountsBloc>.value(value: accounts),
        BlocProvider<FxCubit>.value(value: fx),
      ],
    );
  }

  final youngHome = ExperienceLayout(
    screen: 'home',
    segment: 'YOUNG',
    components: [
      spec('greeting', {'title': 'Buenas tardes, Ana'}),
      spec('accounts_summary', {'title': 'Tus cuentas', 'showTotal': true}),
      spec('quick_actions', {
        'actions': [
          {
            'id': 't',
            'icon': 'swap',
            'label': 'Transferir',
            'deeplink': 'app://transfers',
          },
          {
            'id': 'r',
            'icon': 'phone',
            'label': 'Recargar',
            'deeplink': 'app://topups',
          },
        ],
      }),
      spec('savings_goal', {
        'title': 'Meta: viaje a Galápagos',
        'target': '1000.00',
        'accountId': '0012',
      }),
      spec('cash_flow_chart', {'title': 'Tipo que la app no conoce'}),
    ],
  );

  testWidgets('dibuja los componentes del layout e ignora los desconocidos', (
    tester,
  ) async {
    await pump(tester, youngHome);

    expect(find.text('Buenas tardes, Ana'), findsOneWidget);
    expect(find.byType(AccountCard), findsNWidgets(2));
    expect(find.text(r'Saldo total $3.618,20'), findsOneWidget);
    expect(find.text('Transferir'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('53 %'), 200);
    expect(find.text(r'$525,50 de $1.000,00'), findsOneWidget);
    expect(find.text('Tipo que la app no conoce'), findsNothing);
  });

  testWidgets('mientras no hay layout muestra el skeleton', (tester) async {
    await pump(tester, null);

    expect(find.byType(AccountCardSkeleton), findsWidgets);
  });

  testWidgets('las acciones rápidas navegan por deep link', (tester) async {
    await pump(tester, youngHome);

    await tester.tap(find.text('Transferir'));
    await tester.pumpAndSettle();

    expect(find.text('ruta:/transfer'), findsOneWidget);
  });

  testWidgets('un deep link sin pantalla avisa "disponible pronto"', (
    tester,
  ) async {
    await pump(tester, youngHome);

    await tester.tap(find.text('Recargar'));
    await tester.pump();

    expect(find.textContaining('disponible pronto'), findsOneWidget);
  });

  testWidgets('degradación: con el layout de respaldo y cuentas desde caché, '
      'el home sigue siendo usable', (tester) async {
    when(() => accounts.state).thenReturn(
      AccountsState(
        status: AccountsStatus.loaded,
        accounts: [account('0011', alias: 'Ahorros')],
        updatedAt: DateTime.now().subtract(const Duration(minutes: 3)),
        fromCache: true,
        refreshFailure: const NetworkFailure(),
      ),
    );
    await pump(
      tester,
      ExperienceLayout(
        screen: 'home',
        segment: 'STANDARD',
        isFallback: true,
        components: [
          spec('greeting', {'title': 'Hola'}),
          spec('accounts_summary', {'title': 'Tus cuentas'}),
        ],
      ),
    );

    expect(find.text('Hola'), findsOneWidget);
    expect(find.byType(AccountCard), findsOneWidget);
    expect(find.textContaining('No pudimos actualizar'), findsOneWidget);
  });

  testWidgets('si el tipo de cambio falla, solo esa sección se oculta', (
    tester,
  ) async {
    when(() => fx.state).thenReturn(const FxState(loading: false));
    await pump(
      tester,
      ExperienceLayout(
        screen: 'home',
        segment: 'PREMIUM',
        components: [
          spec('greeting', {'title': 'Hola, Carlos'}),
          spec('fx_rates', {
            'base': 'USD',
            'title': 'Tipo de cambio',
            'symbols': ['EUR'],
          }),
          spec('accounts_summary', {'title': 'Tus cuentas'}),
        ],
      ),
    );

    expect(find.text('Tipo de cambio'), findsNothing);
    expect(find.text('Hola, Carlos'), findsOneWidget);
    expect(find.byType(AccountCard), findsNWidgets(2));
    verify(() => fx.load('USD')).called(1);
  });

  testWidgets('al volver la conexión refresca layout y cuentas', (
    tester,
  ) async {
    final connectivity = MockConnectivityCubit();
    whenListen(
      connectivity,
      Stream.fromIterable([ConnectivityStatus.online]),
      initialState: ConnectivityStatus.offline,
    );
    whenListen(
      accounts,
      const Stream<AccountsState>.empty(),
      initialState: accounts.state,
    );
    await pump(tester, youngHome, connectivity: connectivity);
    await tester.pump();

    verify(() => accounts.add(const AccountsRequested())).called(1);
    verify(() => experience.load()).called(1);
  });
}
