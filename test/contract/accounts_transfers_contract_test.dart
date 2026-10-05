// Contrato contra el backend real vía gateway. Se omite si no se define:
//   CONTRACT_BASE_URL=http://localhost:8080 flutter test test/contract
//
// La transferencia mueve $1,00 entre dos cuentas de `carlos` y lo devuelve,
// así que los saldos netos no cambian.
@Tags(['contract'])
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/data/snapshot.dart';
import 'package:nexo_bank/core/money/money.dart';
import 'package:nexo_bank/core/network/dio_client.dart';
import 'package:nexo_bank/core/result/result.dart';
import 'package:nexo_bank/core/security/device_id_provider.dart';
import 'package:nexo_bank/features/accounts/domain/account.dart';
import 'package:nexo_bank/features/accounts/domain/movement.dart';
import 'package:nexo_bank/features/accounts/infrastructure/account_repository_impl.dart';
import 'package:nexo_bank/features/accounts/infrastructure/accounts_local_data_source.dart';
import 'package:nexo_bank/features/accounts/infrastructure/accounts_remote_data_source.dart';
import 'package:nexo_bank/features/auth/infrastructure/auth_remote_data_source.dart';
import 'package:nexo_bank/features/auth/infrastructure/auth_repository_impl.dart';
import 'package:nexo_bank/features/notifications/domain/push_token_source.dart';
import 'package:nexo_bank/features/notifications/infrastructure/device_remote_data_source.dart';
import 'package:nexo_bank/features/transfers/domain/transfer.dart';
import 'package:nexo_bank/features/transfers/infrastructure/transfer_remote_data_source.dart';
import 'package:uuid/uuid.dart';

import '../helpers/fakes.dart';

class _FixedDeviceId extends Mock implements DeviceIdProvider {
  @override
  Future<String> get() async => 'contract-test';
}

void main() {
  final baseUrl = Platform.environment['CONTRACT_BASE_URL'];
  final skip = baseUrl == null ? 'Define CONTRACT_BASE_URL' : false;

  late Dio dio;
  late AccountRepositoryImpl accounts;
  late TransferRemoteDataSource transfers;

  setUpAll(() async {
    if (baseUrl == null) return;
    final store = InMemoryTokenStore();
    late AuthRemoteDataSource auth;
    dio = createDioClient(
      baseUrl: baseUrl,
      tokenStore: store,
      refresh: (rt) async => (await auth.refresh(rt)).toTokens(),
      onSessionExpired: () {},
    );
    auth = AuthRemoteDataSource(dio);
    final login = await AuthRepositoryImpl(
      remote: auth,
      tokenStore: store,
      deviceId: _FixedDeviceId(),
    ).login(username: 'carlos', password: 'Nexo2026*');
    expect(login.isOk, isTrue, reason: 'login de carlos');
    accounts = AccountRepositoryImpl(
      remote: AccountsRemoteDataSource(dio),
      local: AccountsLocalDataSource(InMemoryCache()),
    );
    transfers = TransferRemoteDataSource(dio);
  });

  Future<List<Account>> loadAccounts() async {
    final last = await accounts.watchAccounts().last;
    return (last as Ok<Snapshot<List<Account>>>).value.data;
  }

  test(
    'cuentas: los DTO se mapean y los números llegan enmascarados',
    () async {
      final list = await loadAccounts();

      expect(list, isNotEmpty);
      for (final a in list) {
        expect(a.maskedNumber, matches(RegExp(r'^\*{4}\d{4}$')));
        expect(a.type, isNot(AccountType.unknown));
        expect(a.status, isNot(AccountStatus.unknown));
      }
    },
    skip: skip,
  );

  test('movimientos: pagina con cursor sin repetir elementos', () async {
    final account = (await loadAccounts()).first;
    final first = await accounts.watchMovements(account.id).last;
    final page = (first as Ok<Snapshot<MovementPage>>).value.data;
    if (!page.hasMore) return;

    final next = await accounts.getMovementsPage(
      account.id,
      cursor: page.nextCursor!,
    );
    final ids = {
      ...page.items.map((m) => m.id),
      ...(next as Ok<MovementPage>).value.items.map((m) => m.id),
    };
    expect(ids.length, page.items.length + next.value.items.length);
  }, skip: skip);

  test(
    'transferencia idempotente: misma clave → misma transferencia',
    () async {
      final list = (await loadAccounts()).where((a) => a.isActive).toList();
      final source = list.firstWhere((a) => a.balance.cents >= 100);
      final target = list.firstWhere((a) => a.id != source.id);
      final draft = TransferDraft(
        source: source,
        target: target,
        amount: const Money(100, 'USD'),
        description: 'Test de contrato',
      );
      final key = const Uuid().v4();

      final first = await transfers.transferOwn(draft, idempotencyKey: key);
      final replay = await transfers.transferOwn(draft, idempotencyKey: key);

      expect(first.status, TransferStatus.completed);
      expect(replay.id, first.id);

      final after = await loadAccounts();
      expect(
        after.firstWhere((a) => a.id == source.id).balance,
        source.balance - draft.amount,
        reason: 'el reenvío no debe debitar dos veces',
      );

      // Se devuelve el dinero para dejar los saldos como estaban.
      await transfers.transferOwn(
        TransferDraft(
          source: after.firstWhere((a) => a.id == target.id),
          target: after.firstWhere((a) => a.id == source.id),
          amount: draft.amount,
          description: 'Reverso test de contrato',
        ),
        idempotencyKey: const Uuid().v4(),
      );
    },
    skip: skip,
  );

  test('misma clave con otro monto → 409 idempotency-key-reused', () async {
    final list = (await loadAccounts()).where((a) => a.isActive).toList();
    final source = list.firstWhere((a) => a.balance.cents >= 100);
    final target = list.firstWhere((a) => a.id != source.id);
    final key = const Uuid().v4();
    TransferDraft draft(int cents) => TransferDraft(
      source: source,
      target: target,
      amount: Money(cents, 'USD'),
    );

    await transfers.transferOwn(draft(1), idempotencyKey: key);
    final error = await transfers
        .transferOwn(draft(2), idempotencyKey: key)
        .then<DioException?>(
          (_) => null,
          onError: (Object e) => e as DioException,
        );

    expect(error?.response?.statusCode, 409);
    expect((error!.response!.data as Map)['code'], 'idempotency-key-reused');

    // Reverso del centavo.
    await transfers.transferOwn(
      TransferDraft(
        source: target,
        target: source,
        amount: const Money(1, 'USD'),
      ),
      idempotencyKey: const Uuid().v4(),
    );
  }, skip: skip);

  test('registro y baja del token de push del dispositivo', () async {
    final remote = DeviceRemoteDataSource(dio);
    const token = 'contract-test-token';

    await remote.register(token, DevicePlatform.android);
    // PUT es idempotente: repetirlo no falla.
    await remote.register(token, DevicePlatform.android);
    await remote.unregister(token);
    await remote.unregister(token);
  }, skip: skip);
}
