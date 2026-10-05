import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../domain/fx_rates.dart';
import '../domain/fx_repository.dart';

final class FxState extends Equatable {
  const FxState({this.loading = true, this.rates, this.stale = false});

  final bool loading;
  final FxRates? rates;
  final bool stale;

  /// Sin datos (ni guardados) la sección se oculta.
  bool get hidden => !loading && rates == null;

  @override
  List<Object?> get props => [loading, rates, stale];
}

/// Estado propio de la sección de tipo de cambio: si el servicio externo
/// falla, solo esta sección se degrada (se oculta o muestra datos viejos).
class FxCubit extends Cubit<FxState> {
  FxCubit(this._repository) : super(const FxState());

  final FxRepository _repository;

  Future<void> load(String base) => _repository
      .watchLatest(base)
      .forEach(
        (result) => emit(switch (result) {
          Ok(value: final s) => FxState(
            loading: false,
            rates: s.data,
            stale: s.refreshFailure != null,
          ),
          Err() => FxState(loading: false, rates: state.rates, stale: true),
        }),
      );
}
