import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/core/money/money.dart';
import 'package:nexo_bank/core/network/dio_client.dart';
import 'package:nexo_bank/features/transfers/domain/transfer.dart';
import 'package:nexo_bank/features/transfers/infrastructure/transfer_remote_data_source.dart';

import '../../../helpers/accounts_fixtures.dart';
import '../../../helpers/fakes.dart';

void main() {
  late FakeHttpAdapter adapter;
  late TransferRemoteDataSource remote;
  final draft = TransferDraft(
    source: account('1'),
    target: account('2'),
    amount: const Money(2550, 'USD'),
    description: 'Ahorro',
  );

  setUp(() {
    final dio = createDioClient(
      baseUrl: 'http://test',
      tokenStore: InMemoryTokenStore(tokens('1')),
      refresh: (_) async => tokens('2'),
      onSessionExpired: () {},
      retryDelay: (_) async {},
    );
    adapter = FakeHttpAdapter(
      (_) async => const FakeResponse(201, {
        'id': 't-1',
        'status': 'COMPLETED',
        'sourceAccountId': '1',
        'targetAccountId': '2',
        'amount': '25.50',
        'currency': 'USD',
        'description': 'Ahorro',
        'createdAt': '2026-10-04T15:00:00Z',
      }),
    );
    dio.httpClientAdapter = adapter;
    remote = TransferRemoteDataSource(dio);
  });

  test('envía Idempotency-Key y el monto como texto', () async {
    final transfer = await remote.transferOwn(draft, idempotencyKey: 'key-1');

    final request = adapter.requests.single;
    expect(request.headers['Idempotency-Key'], 'key-1');
    expect(request.data, {
      'sourceAccountId': '1',
      'targetAccountId': '2',
      'amount': '25.50',
      'description': 'Ahorro',
    });
    expect(jsonEncode(request.data), isNot(contains('25.5,')));
    expect(transfer.amount, const Money(2550, 'USD'));
    expect(transfer.status, TransferStatus.completed);
  });

  test('un 503 en el POST no se reintenta', () async {
    adapter.handler = (_) async => const FakeResponse(503);

    await expectLater(
      remote.transferOwn(draft, idempotencyKey: 'key-1'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, hasLength(1));
  });
}
