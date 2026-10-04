import 'package:equatable/equatable.dart';

import '../result/failure.dart';

/// Datos con su antigüedad, para el patrón stale-while-revalidate.
///
/// - [fromCache] = `true`: lo guardado localmente; puede llegar una
///   versión remota más nueva.
/// - [refreshFailure] != `null`: no se pudo actualizar y se muestran los
///   datos guardados.
class Snapshot<T> extends Equatable {
  const Snapshot({
    required this.data,
    required this.updatedAt,
    this.fromCache = false,
    this.refreshFailure,
  });

  final T data;
  final DateTime updatedAt;
  final bool fromCache;
  final Failure? refreshFailure;

  bool get isStale => fromCache || refreshFailure != null;

  Snapshot<T> withRefreshFailure(Failure failure) => Snapshot(
    data: data,
    updatedAt: updatedAt,
    fromCache: true,
    refreshFailure: failure,
  );

  @override
  List<Object?> get props => [data, updatedAt, fromCache, refreshFailure];
}
