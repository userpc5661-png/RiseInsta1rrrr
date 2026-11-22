import 'dart:convert';

import 'platform_native.dart'
    if (dart.library.js_interop) 'platform_web.dart'
    as platform;

typedef Json = Map<String, dynamic>;

Json object(Object? value) => value is Map<String, dynamic> ? value : {};
List<dynamic> array(Object? value) => value is List ? value : [];
int number(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
String string(Object? value) => value is String ? value.trim() : '';

class Title {
  Title(this.data);

  final Json data;

  int get id => number(data['id']);
  String get kind => data['type'] == 'show' ? 'show' : 'movie';
  bool get isShow => kind == 'show';
  String get key => '$kind/$id';
  String get name => string(data['title']).isNotEmpty
      ? string(data['title'])
      : string(data['original_title']);
  String get synopsis => string(data['synopsis']);
  String get poster => _artwork(data['poster']);
  String get backdrop => _artwork(data['backdrop']);
  String get hero => backdrop.isEmpty ? poster : backdrop;
  int get year => number(data['year']);
  int get episodeCount => number(data['episode_count']);
  int get subtitleCount => number(data['subtitle_count']);
  bool get streamable =>
      data['streamable'] == true || number(data['streamable']) == 1;
  String get certification => string(data['certification']);
  String get rating =>
      (double.tryParse('${data['rating']}') ?? 0).toStringAsFixed(1);
  List<String> get genres =>
      array(data['genres'])
          .map(string)
          .where((value) => value.isNotEmpty)
          .toList();
  List<Json> get episodes => array(data['episodes']).whereType<Json>().toList();

  static String _artwork(Object? value) {
    final uri = Uri.tryParse(string(value));
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return '';
    return uri.toString();
  }

  static List<Title> parse(Object? value) => [
    for (final entry in array(value).whereType<Json>())
      if (number(entry['id']) > 0 && string(entry['title']).isNotEmpty)
        Title(entry),
  ];
}

class CatalogPage {
  CatalogPage(Json data)
    : items = Title.parse(data['items']),
      page = number(data['page']),
      pages = number(data['pages']),
      total = number(data['total']);

  final List<Title> items;
  final int page, pages, total;
}

class Cinema {
  static final provider = Uri.https('icinema.live');
  static final apiOrigin = Uri.parse(
    const String.fromEnvironment(
      'CATALOG_ORIGIN',
      defaultValue: 'https://icinema.live',
    ),
  );

  static Future<Json> read(String path, [Map<String, String>? query]) async {
    final uri = apiOrigin.resolve(path).replace(queryParameters: query);
    final payload = object(jsonDecode(await platform.readJson(uri)));
    if (payload.isEmpty) {
      throw const FormatException('البيانات المستلمة غير مكتملة.');
    }
    return payload;
  }

  static Future<CatalogPage> catalog({
    required String kind,
    int page = 1,
    String sort = 'latest',
    String category = '',
  }) async {
    return CatalogPage(
      await read('/api/catalog', {
        'type': kind,
        'page': '$page',
        'limit': '30',
        'sort': sort,
        if (category.isNotEmpty) 'category': category,
      }),
    );
  }

  static Future<List<Title>> search(String query) async =>
      Title.parse((await read('/api/search', {'q': query}))['items']);

  static Future<Title> details(Title title) async =>
      Title(await read('/api/items/${title.kind}/${title.id}', {'lang': 'ar'}));

  static Uri titleLink(Title title, [int? season]) => provider.replace(
    path: title.isShow ? '/shows' : '/movies',
    queryParameters: {
      'item': '${title.id}',
      if (season != null) 'season': '$season',
    },
  );

  static Uri service(String path, [Map<String, String>? query]) =>
      provider.replace(path: path, queryParameters: query);

  static Future<void> open(Uri uri) => platform.openProvider(uri);
}

class Library {
  static const _key = 'mashhad-library-v1';

  final saved = <String, Title>{};
  final recent = <Title>[];

  Future<void> load() async {
    final value = await platform.restore(_key);
    if (value == null) return;
    final data = object(jsonDecode(value));
    saved.addEntries(
      Title.parse(data['saved']).map((title) => MapEntry(title.key, title)),
    );
    recent.addAll(Title.parse(data['recent']).take(20));
  }

  Future<void> write() => platform.persist(
    _key,
    jsonEncode({
      'saved': saved.values.map((title) => _summary(title.data)).toList(),
      'recent': recent.map((title) => _summary(title.data)).toList(),
    }),
  );

  Json _summary(Json data) => {
    for (final key in [
      'id',
      'type',
      'title',
      'original_title',
      'year',
      'poster',
      'backdrop',
      'rating',
      'genre',
      'genres',
      'streamable',
      'subtitle_count',
      'episode_count',
    ])
      if (data.containsKey(key)) key: data[key],
  };
}
