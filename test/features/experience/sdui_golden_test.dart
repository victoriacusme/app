// Golden tests del render SDUI. Para regenerar las imágenes:
//   flutter test --update-goldens test/features/experience/sdui_golden_test.dart
@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/design_system/design_system.dart';
import 'package:nexo_bank/features/accounts/presentation/bloc/accounts_bloc.dart';
import 'package:nexo_bank/features/experience/domain/experience_layout.dart';
import 'package:nexo_bank/features/experience/presentation/component_registry.dart';
import 'package:nexo_bank/features/fx/domain/fx_rates.dart';
import 'package:nexo_bank/features/fx/presentation/fx_cubit.dart';

import '../../helpers/accounts_fixtures.dart';

class _MockAccounts extends MockBloc<AccountsEvent, AccountsState>
    implements AccountsBloc {}

class _MockFx extends MockCubit<FxState> implements FxCubit {}

ComponentSpec _spec(String type, Map<String, dynamic> props) =>
    ComponentSpec(id: type, type: type, properties: props);

final _young = [
  _spec('greeting', {'title': 'Buenas tardes, Ana'}),
  _spec('accounts_summary', {'title': 'Tus cuentas', 'showTotal': true}),
  _spec('quick_actions', {
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
        'label': 'Recargar celular',
        'deeplink': 'app://topups',
      },
      {
        'id': 'g',
        'icon': 'target',
        'label': 'Mis metas',
        'deeplink': 'app://savings',
      },
    ],
  }),
  _spec('savings_goal', {
    'title': 'Meta: viaje a Galápagos',
    'target': '1000.00',
    'accountId': '0012',
  }),
  _spec('promo_banner', {
    'title': 'Gana 5% extra en tu primera meta',
    'subtitle': 'Solo este mes',
  }),
];

final _premium = [
  _spec('greeting', {'title': 'Buenas tardes, Carlos'}),
  _spec('quick_actions', {
    'actions': [
      {
        'id': 't',
        'icon': 'swap',
        'label': 'Transferir',
        'deeplink': 'app://transfers',
      },
      {
        'id': 'i',
        'icon': 'chart',
        'label': 'Inversiones',
        'deeplink': 'app://investments',
      },
      {
        'id': 'a',
        'icon': 'person',
        'label': 'Mi asesor',
        'deeplink': 'app://advisor',
      },
    ],
  }),
  _spec('fx_rates', {
    'base': 'USD',
    'title': 'Tipo de cambio',
    'symbols': ['EUR', 'COP', 'PEN', 'MXN'],
  }),
  _spec('promo_banner', {
    'title': 'Asesoría de inversiones sin costo',
    'subtitle': 'Agenda con tu asesor',
  }),
];

void main() {
  late _MockAccounts accounts;
  late _MockFx fx;

  setUp(() {
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
    when(() => fx.load(any())).thenAnswer((_) async {});
    when(() => fx.state).thenReturn(
      FxState(
        loading: false,
        rates: FxRates(
          base: 'USD',
          rates: const {
            'EUR': 0.888786,
            'COP': 3311.644334,
            'PEN': 3.443349,
            'MXN': 18.214153,
          },
          publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ),
    );
  });

  Future<void> render(
    WidgetTester tester,
    List<ComponentSpec> components, {
    required ThemeData theme,
  }) async {
    tester.view
      ..physicalSize = const Size(390, 1100)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final registry = ComponentRegistry.defaults();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AccountsBloc>.value(value: accounts),
          BlocProvider<FxCubit>.value(value: fx),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(Spacing.md),
              children: [for (final c in components) ?registry.build(c)],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('home joven (claro)', (tester) async {
    await render(tester, _young, theme: AppTheme.light());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_young_light.png'),
    );
  });

  testWidgets('home premium (claro)', (tester) async {
    await render(tester, _premium, theme: AppTheme.light());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_premium_light.png'),
    );
  });

  testWidgets('home joven (oscuro)', (tester) async {
    await render(tester, _young, theme: AppTheme.dark());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_young_dark.png'),
    );
  });
}
