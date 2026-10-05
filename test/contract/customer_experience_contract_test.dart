// Contrato de perfil, SDUI, tipo de cambio y registro contra el backend
// real vía gateway. Se omite si no se define CONTRACT_BASE_URL:
//   CONTRACT_BASE_URL=http://localhost:8080 flutter test test/contract
//
// El registro crea un usuario nuevo en cada ejecución, así que solo corre
// si además se define CONTRACT_REGISTER=1.
@Tags(['contract'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/data/snapshot.dart';
import 'package:nexo_bank/core/network/dio_client.dart';
import 'package:nexo_bank/core/result/result.dart';
import 'package:nexo_bank/core/security/device_id_provider.dart';
import 'package:nexo_bank/features/auth/domain/registration.dart';
import 'package:nexo_bank/features/auth/domain/session.dart';
import 'package:nexo_bank/features/auth/infrastructure/auth_remote_data_source.dart';
import 'package:nexo_bank/features/auth/infrastructure/auth_repository_impl.dart';
import 'package:nexo_bank/features/customer/domain/customer_profile.dart';
import 'package:nexo_bank/features/customer/infrastructure/customer_remote_data_source.dart';
import 'package:nexo_bank/features/customer/infrastructure/customer_repository_impl.dart';
import 'package:nexo_bank/features/experience/domain/experience_layout.dart';
import 'package:nexo_bank/features/experience/infrastructure/experience_repository_impl.dart';
import 'package:nexo_bank/features/experience/presentation/component_registry.dart';
import 'package:nexo_bank/features/fx/domain/fx_rates.dart';
import 'package:nexo_bank/features/fx/infrastructure/fx_repository_impl.dart';

import '../helpers/fakes.dart';

class _FixedDeviceId extends Mock implements DeviceIdProvider {
  @override
  Future<String> get() async => 'contract-test';
}

void main() {
  final baseUrl = Platform.environment['CONTRACT_BASE_URL'];
  final skip = baseUrl == null ? 'Define CONTRACT_BASE_URL' : false;
  final skipRegister = baseUrl == null
      ? 'Define CONTRACT_BASE_URL'
      : Platform.environment['CONTRACT_REGISTER'] == null
      ? 'Define CONTRACT_REGISTER=1 (crea un usuario)'
      : false;

  /// Inicia sesión y devuelve los repositorios con ese usuario.
  Future<
    ({
      CustomerRepositoryImpl customers,
      ExperienceRepositoryImpl experience,
      FxRepositoryImpl fx,
      AuthRepositoryImpl auth,
    })
  >
  as(String? username) async {
    final store = InMemoryTokenStore();
    late AuthRemoteDataSource remote;
    final dio = createDioClient(
      baseUrl: baseUrl!,
      tokenStore: store,
      refresh: (rt) async => (await remote.refresh(rt)).toTokens(),
      onSessionExpired: () {},
    );
    remote = AuthRemoteDataSource(dio);
    final auth = AuthRepositoryImpl(
      remote: remote,
      tokenStore: store,
      deviceId: _FixedDeviceId(),
    );
    if (username != null) {
      final login = await auth.login(username: username, password: 'Nexo2026*');
      expect(login.isOk, isTrue, reason: 'login de $username');
    }
    return (
      customers: CustomerRepositoryImpl(
        remote: CustomerRemoteDataSource(dio),
        cache: InMemoryCache(),
      ),
      experience: ExperienceRepositoryImpl(
        dio: dio,
        cache: InMemoryCache(),
        loadFallback: () async => throw StateError('no debería usarse'),
      ),
      fx: FxRepositoryImpl(dio: dio, cache: InMemoryCache()),
      auth: auth,
    );
  }

  test(
    'cada segmento recibe un home distinto y la app sabe dibujarlo',
    () async {
      final registry = ComponentRegistry.defaults();
      final layouts = <String, ExperienceLayout>{};
      for (final user in ['ana', 'carlos', 'lucia']) {
        final repos = await as(user);
        layouts[user] = await repos.experience.watchHome().last;
      }

      expect(layouts['ana']!.segment, 'YOUNG');
      expect(layouts['carlos']!.segment, 'PREMIUM');
      expect(layouts['lucia']!.segment, 'ENTREPRENEUR');
      final types = {
        for (final e in layouts.entries)
          e.key: e.value.components.map((c) => c.type).toSet(),
      };
      expect(types['ana'], contains('savings_goal'));
      expect(types['carlos'], contains('fx_rates'));
      expect(types['ana'], isNot(equals(types['carlos'])));

      // Todo componente conocido debe poder construirse con sus props reales.
      for (final layout in layouts.values) {
        for (final c in layout.components.where(
          (c) => registry.supports(c.type),
        )) {
          expect(
            registry.build(c),
            isNotNull,
            reason: '${c.type}: ${c.properties}',
          );
        }
      }
    },
    skip: skip,
  );

  test('el perfil llega enmascarado y las preferencias se guardan', () async {
    final repos = await as('lucia');
    final snapshot = await repos.customers.watchProfile().last;
    final profile = (snapshot as Ok<Snapshot<CustomerProfile>>).value.data;

    expect(profile.maskedIdNumber, startsWith('*'));
    expect(profile.maskedPhone, startsWith('*'));

    // Cambia una preferencia y la deja como estaba.
    final original = profile.preferences;
    final toggled = original.copyWith(showPromotions: !original.showPromotions);
    final saved = await repos.customers.updatePreferences(original, toggled);
    expect((saved as Ok<Preferences>).value, toggled);
    await repos.customers.updatePreferences(toggled, original);
  }, skip: skip);

  test('tipo de cambio desde el servicio externo vía gateway', () async {
    final repos = await as(null);
    final snapshot = await repos.fx.watchLatest('USD').last;
    final rates = (snapshot as Ok<Snapshot<FxRates>>).value.data;

    expect(rates.base, 'USD');
    expect(rates.rates.keys, containsAll(['EUR', 'COP', 'PEN', 'MXN']));
  }, skip: skip);

  test('registro: crea la cuenta y deja la sesión iniciada', () async {
    final repos = await as(null);
    final username =
        'contrato.${DateTime.now().millisecondsSinceEpoch % 100000000}';

    final result = await repos.auth.register(
      Registration(
        fullName: 'Prueba Contrato',
        idNumber: '0102030405',
        birthDate: DateTime(1995, 5, 10),
        email: 'contrato@nexo.ec',
        phone: '0991234567',
        username: username,
        password: 'Clave2026x',
      ),
    );

    expect(result, isA<Ok<Session>>());
  }, skip: skipRegister);
}
