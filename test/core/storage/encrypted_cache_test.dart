import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:nexo_bank/core/storage/encrypted_cache.dart';

void main() {
  late Directory dir;
  late HiveEncryptedCache cache;
  final key = List<int>.generate(32, (i) => i);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nexo_cache_test');
    Hive.init(dir.path);
    cache = await HiveEncryptedCache.openWithKey(key, boxName: 'test_box');
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('guarda y lee JSON con su fecha', () async {
    final savedAt = DateTime.utc(2026, 10, 4, 12);
    await cache.write('accounts:list', {
      'items': [
        {'id': '1', 'balance': '10.00'},
      ],
    }, savedAt: savedAt);

    final entry = await cache.read('accounts:list');

    expect(entry!.savedAt, savedAt);
    expect((entry.data! as Map)['items'], hasLength(1));
  });

  test('el archivo en disco está cifrado', () async {
    await cache.write('k', {'balance': '987654.32'});
    await Hive.close();

    final bytes = await File('${dir.path}/test_box.hive').readAsBytes();
    expect(String.fromCharCodes(bytes), isNot(contains('987654.32')));
  });

  test('deleteWhere y clear borran entradas', () async {
    await cache.write('accounts:movements:a', 1);
    await cache.write('accounts:movements:b', 2);
    await cache.write('accounts:list', 3);

    await cache.deleteWhere((k) => k.endsWith(':a'));
    expect(await cache.read('accounts:movements:a'), isNull);
    expect(await cache.read('accounts:movements:b'), isNotNull);

    await cache.clear();
    expect(await cache.read('accounts:list'), isNull);
  });
}
