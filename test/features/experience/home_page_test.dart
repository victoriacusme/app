import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/app/app_settings_cubit.dart';
import 'package:nexo_bank/core/connectivity/connectivity_cubit.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/features/accounts/presentation/bloc/accounts_bloc.dart';
import 'package:nexo_bank/features/accounts/presentation/widgets/account_card.dart';
import 'package:nexo_bank/features/experience/domain/experience_layout.dart';
import 'package:nexo_bank/features/experience/presentation/experience_cubit.dart';
import 'package:nexo_bank/features/experience/presentation/home_page.dart';
import 'package:nexo_bank/core/time/app_clock.dart';
import 'package:nexo_bank/features/customer/presentation/profile_bloc.dart';
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
  late MockProfileBloc profile;

  setUpAll(() => registerFallbackValue(const AccountsRequested()));

  setUp(() {
    experience = _MockExperience();
    accounts = _MockAccounts();
    fx = _MockFx();
    profile = profileOf('Ana');
    // Saludo determinista: 15:00 → "Buenas tardes".
    AppClock.now = () => DateTime(2026, 10, 4, 15);
    addTearDown(() => AppClock.now = DateTime.now);
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
    Locale locale = const Locale('es'),
    AppSettingsCubit? settings,
  }) async {
    when(() => experience.state).thenReturn(layout);
    await pumpPage(
      tester,
      const HomePage(),
      connectivity: connectivity,
      locale: locale,
      settings: settings,
      providers: [
        BlocProvider<ExperienceCubit>.value(value: experience),
        BlocProvider<AccountsBloc>.value(value: accounts),
        BlocProvider<FxCubit>.value(value: fx),
        BlocProvider<ProfileBloc>.value(value: profile),
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

    // El saludo lo arma la app, aunque el layout de respaldo diga "Hola".
    expect(find.text('Buenas tardes, Ana'), findsOneWidget);
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
    expect(find.text('Buenas tardes, Ana'), findsOneWidget);
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

  testWidgets(
    'en inglés no se mezclan idiomas: las secciones y acciones conocidas '
    'se traducen aunque el backend las mande en español',
    (tester) async {
      await pump(
        tester,
        ExperienceLayout(
          screen: 'home',
          segment: 'YOUNG',
          components: [
            // El saludo ya lo traduce el backend.
            spec('greeting', {'title': 'Good afternoon, Ana'}),
            spec('accounts_summary', {
              'title': 'Tus cuentas',
              'showTotal': true,
            }),
            spec('quick_actions', {
              'actions': [
                {
                  'id': 'transfer',
                  'icon': 'swap',
                  'label': 'Transferir',
                  'deeplink': 'app://transfers',
                },
                {
                  'id': 'topup',
                  'icon': 'phone',
                  'label': 'Recargar celular',
                  'deeplink': 'app://topups',
                },
              ],
            }),
            // Texto por idioma (formato que puede adoptar el backend).
            spec('promo_banner', {
              'title': {'es': 'Gana 5% extra', 'en': 'Earn 5% extra'},
            }),
          ],
        ),
        locale: const Locale('en'),
      );

      expect(find.text('Good afternoon, Ana'), findsOneWidget);
      // "Meta: viaje" es un alias del cliente; la cuenta sin alias muestra el
      // tipo traducido.
      expect(find.text('Your accounts'), findsOneWidget);
      expect(find.text(r'Total balance $3,618.20'), findsOneWidget);
      expect(find.text(r'$3,092.70'), findsOneWidget);
      expect(find.text('Available balance'), findsNWidgets(2));
      expect(find.text('Savings account · ****0012'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Mobile top-up'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Earn 5% extra'), 200);
      expect(find.text('Earn 5% extra'), findsOneWidget);
      for (final spanish in [
        'Tus cuentas',
        'Transferir',
        'Saldo',
        'Principal',
      ]) {
        expect(find.textContaining(spanish), findsNothing, reason: spanish);
      }
    },
  );

  group('recarga del layout por preferencias', () {
    Future<void> pumpWith(
      WidgetTester tester,
      AppSettings initial,
      AppSettings next, {
      ExperienceLayout? layout,
    }) async {
      final settings = MockAppSettingsCubit();
      whenListen(settings, Stream.value(next), initialState: initial);
      await pump(tester, layout ?? youngHome, settings: settings);
      await tester.pump();
    }

    const es = AppSettings(locale: Locale('es'), customerLoaded: true);

    testWidgets('al cambiar de idioma se vuelve a pedir el layout', (
      tester,
    ) async {
      await pumpWith(
        tester,
        es,
        const AppSettings(locale: Locale('en'), customerLoaded: true),
      );

      verify(() => experience.load()).called(1);
    });

    testWidgets(
      'al desactivar promociones se ocultan al instante y se pide el layout',
      (tester) async {
        final withPromo = ExperienceLayout(
          screen: 'home',
          segment: 'YOUNG',
          components: [
            spec('greeting', {}),
            spec('promo_banner', {
              'title': 'Gana 5% extra en tu primera meta',
              'deeplink': 'app://savings',
            }),
          ],
        );
        await pumpWith(
          tester,
          es,
          const AppSettings(
            locale: Locale('es'),
            customerLoaded: true,
            showPromotions: false,
          ),
          layout: withPromo,
        );

        expect(find.text('Gana 5% extra en tu primera meta'), findsNothing);
        verify(() => experience.load()).called(1);
      },
    );

    testWidgets('con promociones activadas se muestran', (tester) async {
      when(() => experience.state).thenReturn(
        ExperienceLayout(
          screen: 'home',
          segment: 'YOUNG',
          components: [
            spec('promo_banner', {'title': 'x', 'deeplink': 'app://savings'}),
          ],
        ),
      );
      final settings = MockAppSettingsCubit();
      when(() => settings.state).thenReturn(es);
      await pumpPage(
        tester,
        const HomePage(),
        settings: settings,
        providers: [
          BlocProvider<ExperienceCubit>.value(value: experience),
          BlocProvider<AccountsBloc>.value(value: accounts),
          BlocProvider<FxCubit>.value(value: fx),
          BlocProvider<ProfileBloc>.value(value: profile),
        ],
      );

      expect(find.text('Gana 5% extra en tu primera meta'), findsOneWidget);
    });

    testWidgets('al cerrar sesión (valores por defecto) NO se pide el layout: '
        'saldría sin token y el backend respondería 401', (tester) async {
      await pumpWith(
        tester,
        const AppSettings(
          locale: Locale('en'),
          customerLoaded: true,
          showPromotions: false,
        ),
        const AppSettings(),
      );

      verifyNever(() => experience.load());
    });

    testWidgets('al cargar las preferencias tras el login no se recarga', (
      tester,
    ) async {
      await pumpWith(tester, const AppSettings(), es);

      verifyNever(() => experience.load());
    });
  });
}
