import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/features/customer/domain/customer_profile.dart';
import 'package:nexo_bank/features/customer/infrastructure/customer_dtos.dart';
import 'package:nexo_bank/features/customer/presentation/profile_bloc.dart';
import 'package:nexo_bank/features/customer/presentation/profile_page.dart';

import '../../helpers/customer_fixtures.dart';
import '../../helpers/pump_app.dart';

class _MockProfile extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

void main() {
  late _MockProfile bloc;
  final profile = CustomerDtos.profile(profileJson());
  final loaded = ProfileState(status: ProfileStatus.loaded, profile: profile);

  setUpAll(() => registerFallbackValue(const ProfileRequested()));
  setUp(() => bloc = _MockProfile());

  Future<void> pump(WidgetTester tester) => pumpPage(
    tester,
    const ProfilePage(),
    providers: [BlocProvider<ProfileBloc>.value(value: bloc)],
  );

  testWidgets('muestra datos enmascarados y el segmento', (tester) async {
    when(() => bloc.state).thenReturn(loaded);
    await pump(tester);

    expect(find.text('Lucía Paredes'), findsOneWidget);
    expect(find.text('Cliente Emprendedor'), findsOneWidget);
    expect(find.text('******6789'), findsOneWidget);
    expect(find.text('*********7665'), findsOneWidget);
  });

  testWidgets('cambiar el tema envía la preferencia nueva', (tester) async {
    when(() => bloc.state).thenReturn(loaded);
    await pump(tester);

    await tester.tap(find.text('Oscuro'));

    final event =
        verify(() => bloc.add(captureAny())).captured.single
            as PreferencesEdited;
    expect(event.preferences.theme, ThemePreference.dark);
  });

  testWidgets('si falla el guardado avisa con un mensaje', (tester) async {
    whenListen(
      bloc,
      Stream.value(
        ProfileState(
          status: ProfileStatus.loaded,
          profile: profile,
          saveFailure: const NetworkFailure(),
        ),
      ),
      initialState: loaded,
    );
    await pump(tester);
    await tester.pump();

    expect(find.textContaining('No pudimos guardar'), findsOneWidget);
  });
}
