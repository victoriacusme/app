import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_bank/core/data/snapshot.dart';
import 'package:nexo_bank/core/result/failure.dart';
import 'package:nexo_bank/core/result/result.dart';
import 'package:nexo_bank/features/fx/domain/fx_rates.dart';
import 'package:nexo_bank/features/fx/domain/fx_repository.dart';
import 'package:nexo_bank/features/fx/infrastructure/fx_repository_impl.dart';
import 'package:nexo_bank/features/fx/presentation/fx_cubit.dart';

class _MockFx extends Mock implements FxRepository {}

void main() {
  test('lee la respuesta del proveedor (open.er-api.com)', () {
    final rates = FxRepositoryImpl.fromJson({
      'result': 'success',
      'base_code': 'USD',
      'time_last_update_utc': 'Sun, 04 Oct 2026 00:02:32 +0000',
      'rates': {'EUR': 0.888786, 'COP': 3311},
    });

    expect(rates.base, 'USD');
    expect(rates.rates['COP'], 3311.0);
    expect(rates.publishedAt, DateTime.utc(2026, 10, 4, 0, 2, 32));
  });

  late _MockFx repo;
  final rates = FxRates(
    base: 'USD',
    rates: const {'EUR': 0.9},
    publishedAt: DateTime.utc(2026),
  );
  setUp(() => repo = _MockFx());

  blocTest<FxCubit, FxState>(
    'si el servicio externo falla y no hay caché, la sección se oculta',
    setUp: () =>
        when(() => repo.watchLatest('USD'))
            .thenAnswer((_) => Stream.value(const Err(TimeoutFailure()))),
    build: () => FxCubit(repo),
    act: (c) => c.load('USD'),
    verify: (c) => expect(c.state.hidden, isTrue),
  );

  blocTest<FxCubit, FxState>(
    'con caché y fallo: muestra lo guardado marcado como viejo',
    setUp: () => when(() => repo.watchLatest('USD')).thenAnswer(
      (_) => Stream.value(
        Ok(
          Snapshot(
            data: rates,
            updatedAt: DateTime.utc(2026),
            fromCache: true,
            refreshFailure: const NetworkFailure(),
          ),
        ),
      ),
    ),
    build: () => FxCubit(repo),
    act: (c) => c.load('USD'),
    expect: () => [FxState(loading: false, rates: rates, stale: true)],
  );
}
