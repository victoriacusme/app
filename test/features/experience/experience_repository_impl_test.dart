import 'dart:io';

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_bank/features/experience/domain/experience_layout.dart';
import 'package:nexo_bank/features/experience/infrastructure/experience_repository_impl.dart';

import '../../helpers/fakes.dart';

Map<String, dynamic> layoutJson(List<String> types) => {
  'screen': 'home',
  'segment': 'YOUNG',
  'components': [
    for (final t in types) {'id': t, 'type': t, 'props': <String, dynamic>{}},
  ],
};

void main() {
  late FakeHttpAdapter adapter;
  late InMemoryCache cache;
  late ExperienceRepositoryImpl repository;
  const fallback =
      '{"screen":"home","segment":"STANDARD","components":'
      '[{"id":"f","type":"greeting","props":{"title":"Hola"}}]}';

  setUp(() {
    adapter = FakeHttpAdapter(
      (_) async => FakeResponse(200, layoutJson(['greeting'])),
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter;
    cache = InMemoryCache();
    repository = ExperienceRepositoryImpl(
      dio: dio,
      cache: cache,
      loadFallback: () async => fallback,
    );
  });

  test('sin caché: emite el layout del backend y lo guarda', () async {
    final layouts = await repository.watchHome().toList();

    expect(layouts.single.components.single.type, 'greeting');
    expect(layouts.single.isFallback, isFalse);
    expect(cache.entries['experience:home'], isNotNull);
  });

  test('con caché: emite la caché y luego el layout nuevo', () async {
    await cache.write('experience:home', {
      'etag': '"v1"',
      'json': layoutJson(['promo_banner']),
    });
    adapter.handler = (_) async => FakeResponse(200, layoutJson(['fx_rates']));

    final layouts = await repository.watchHome().toList();

    expect(layouts.map((l) => l.components.single.type), [
      'promo_banner',
      'fx_rates',
    ]);
    expect(adapter.requests.single.headers['If-None-Match'], '"v1"');
  });

  test('304 (no cambió): se queda con la caché sin re-emitir', () async {
    await cache.write('experience:home', {
      'etag': '"v1"',
      'json': layoutJson(['promo_banner']),
    });
    adapter.handler = (_) async => const FakeResponse(304);

    final layouts = await repository.watchHome().toList();

    expect(layouts, hasLength(1));
    expect(layouts.single.components.single.type, 'promo_banner');
  });

  test('ms-customer caído y sin caché: usa el layout de respaldo', () async {
    adapter.handler = (_) async => const FakeResponse(503);

    final layouts = await repository.watchHome().toList();

    expect(layouts.single.isFallback, isTrue);
    expect(layouts.single.components.single.properties['title'], 'Hola');
  });

  test('ms-customer caído con caché: se queda con la caché', () async {
    await cache.write('experience:home', {
      'etag': null,
      'json': layoutJson(['savings_goal']),
    });
    adapter.handler = (_) async => const FakeResponse(503);

    final layouts = await repository.watchHome().toList();

    expect(layouts.single.isFallback, isFalse);
    expect(layouts.single.components.single.type, 'savings_goal');
  });

  for (final lang in ['es', 'en']) {
    test('el JSON de respaldo ($lang) incluido en la app es válido', () async {
      final json = jsonDecode(
        await File('assets/experience/home_fallback_$lang.json').readAsString(),
      ) as Map<String, dynamic>;

      final layout = ExperienceRepositoryImpl.fromJson(json);

      expect(
        layout.components.map((c) => c.type),
        containsAll(['greeting', 'accounts_summary', 'quick_actions']),
      );
    });
  }

  test('componentes sin type se descartan al leer', () {
    final layout = ExperienceRepositoryImpl.fromJson({
      'components': [
        {'id': 'x'},
        {
          'id': 'y',
          'type': 'greeting',
          'props': {'title': 'Hola'},
        },
      ],
    });

    expect(layout.components, [
      const ComponentSpec(
        id: 'y',
        type: 'greeting',
        properties: {'title': 'Hola'},
      ),
    ]);
  });
}
