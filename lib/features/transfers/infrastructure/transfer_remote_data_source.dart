import 'package:dio/dio.dart';

import '../../../core/money/money.dart';
import '../domain/transfer.dart';

class TransferRemoteDataSource {
  TransferRemoteDataSource(this._dio);

  static const idempotencyHeader = 'Idempotency-Key';

  final Dio _dio;

  /// `RetryInterceptor` no reintenta POST: si no hay respuesta, decide el
  /// usuario (verificar estado reenviando la misma clave).
  Future<Transfer> transferOwn(
    TransferDraft draft, {
    required String idempotencyKey,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/transfers/own',
      data: {
        'sourceAccountId': draft.source.id,
        'targetAccountId': draft.target.id,
        'amount': draft.amount.toApiString(),
        'description': ?draft.description,
      },
      options: Options(headers: {idempotencyHeader: idempotencyKey}),
    );
    return transferFromJson(response.data!);
  }

  static Transfer transferFromJson(Map<String, dynamic> json) => Transfer(
    id: json['id'] as String,
    status: json['status'] == 'COMPLETED'
        ? TransferStatus.completed
        : TransferStatus.unknown,
    sourceAccountId: json['sourceAccountId'] as String,
    targetAccountId: json['targetAccountId'] as String,
    amount: Money.parse(json['amount'] as String, json['currency'] as String),
    description: json['description'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
