import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/core/connectivity/connectivity_cubit.dart';

class FakeConnectivitySource implements ConnectivitySource {
  FakeConnectivitySource({this.online = true});

  bool online;
  final controller = StreamController<bool>.broadcast();

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get onChanged => controller.stream;
}

void main() {
  late FakeConnectivitySource source;

  setUp(() => source = FakeConnectivitySource());

  blocTest<ConnectivityCubit, ConnectivityStatus>(
    'emite el estado inicial y cada cambio de red',
    build: () => ConnectivityCubit(source),
    act: (cubit) async {
      await cubit.start();
      source.controller
        ..add(false)
        ..add(true);
    },
    expect: () => const [
      ConnectivityStatus.online,
      ConnectivityStatus.offline,
      ConnectivityStatus.online,
    ],
  );
}
