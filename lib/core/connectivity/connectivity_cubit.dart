import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ConnectivityStatus { unknown, online, offline }

/// Fuente de cambios de red, separada para poder probar el cubit.
abstract interface class ConnectivitySource {
  Future<bool> isOnline();
  Stream<bool> get onChanged;
}

class ConnectivityPlusSource implements ConnectivitySource {
  ConnectivityPlusSource([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _online(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async =>
      _online(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onChanged =>
      _connectivity.onConnectivityChanged.map(_online).distinct();
}

/// Estado global de la red. Ojo: "online" significa que hay una interfaz
/// de red activa, no que el backend responda; eso lo resuelven el retry,
/// el circuit breaker y la caché.
class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  ConnectivityCubit(this._source) : super(ConnectivityStatus.unknown);

  final ConnectivitySource _source;
  StreamSubscription<bool>? _subscription;

  Future<void> start() async {
    _subscription ??= _source.onChanged.listen(_set);
    _set(await _source.isOnline());
  }

  void _set(bool online) =>
      emit(online ? ConnectivityStatus.online : ConnectivityStatus.offline);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
