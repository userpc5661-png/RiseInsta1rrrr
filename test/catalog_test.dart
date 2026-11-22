import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mashhad/catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog separates identical numeric IDs by media kind', () {
    final catalog = CatalogPage({
      'page': 2,
      'pages': 43,
      'total': 1029,
      'items': [
        {'id': 42, 'type': 'show', 'title': 'A series', 'streamable': 1},
        {'id': 42, 'type': 'movie', 'title': 'A film', 'streamable': true},
        {'id': -1, 'title': 'Invalid'},
      ],
    });
    expect(catalog.items.map((value) => value.key), ['show/42', 'movie/42']);
    expect(catalog.items.every((value) => value.streamable), isTrue);
    expect(catalog.page, 2);
    expect(catalog.pages, 43);
    expect(catalog.total, 1029);
  });

  test('official links preserve the movie or show and selected season', () {
    final show = Title({'id': 42, 'type': 'show', 'title': 'A series'});
    final movie = Title({'id': 42, 'type': 'movie', 'title': 'A film'});
    expect(
      Cinema.titleLink(show, 2).toString(),
      'https://icinema.live/shows?item=42&season=2',
    );
    expect(
      Cinema.titleLink(movie).toString(),
      'https://icinema.live/movies?item=42',
    );
  });

  test(
    'the library restores favorites and retains only summary fields',
    () async {
      const channel = MethodChannel('com.mashhad.app/browser');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      String? savedData;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'persist') {
          savedData = (call.arguments as Map)['value'] as String;
        }
        if (call.method == 'restore') return savedData;
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      final title = Title({
        'id': 42,
        'type': 'show',
        'title': 'A series',
        'episodes': [
          {'id': 301},
        ],
      });
      final original = Library();
      original.saved[title.key] = title;
      original.recent.add(title);
      await original.write();
      expect(
        (jsonDecode(savedData!)['saved'] as List).single.containsKey(
          'episodes',
        ),
        isFalse,
      );

      final restored = Library();
      await restored.load();
      expect(restored.saved['show/42']?.name, 'A series');
      expect(restored.recent.single.key, 'show/42');
    },
  );
}
