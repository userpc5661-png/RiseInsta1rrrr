import 'dart:async';

import 'package:flutter/material.dart';

import 'catalog.dart' as cinema;
import 'style.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.initial,
    required this.onTitle,
    required this.onBrowse,
    required this.onProvider,
  });
  final Future<cinema.Json> initial;
  final ValueChanged<cinema.Title> onTitle;
  final ValueChanged<String> onBrowse;
  final VoidCallback onProvider;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<cinema.Json> home = widget.initial;
  late Future<cinema.CatalogPage> movies = cinema.Cinema.catalog(kind: 'movie')
    ..ignore();
  late Future<cinema.CatalogPage> shows = cinema.Cinema.catalog(kind: 'show')
    ..ignore();
  int featured = 0;

  Future<void> refresh() async {
    setState(() {
      featured = 0;
      home = cinema.Cinema.read('/api/home')..ignore();
      movies = cinema.Cinema.catalog(kind: 'movie')..ignore();
      shows = cinema.Cinema.catalog(kind: 'show')..ignore();
    });
    await Future.wait<Object?>([home, movies, shows]).onError((_, _) => []);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 26),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 15),
            child: Row(
              children: [
                const Brand(),
                const Spacer(),
                IconButton.outlined(
                  tooltip: 'ابحث عن عنوان',
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () => widget.onBrowse('movie'),
                ),
              ],
            ),
          ),
          FutureBuilder<cinema.Json>(
            future: home,
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (data == null) {
                return snapshot.hasError
                    ? ErrorNotice(
                        message: 'تعذّر الاتصال بكتالوج iCinema.',
                        retry: refresh,
                        onProvider: widget.onProvider,
                      )
                    : const SizedBox(
                        height: 245,
                        child: Center(child: CircularProgressIndicator()),
                      );
              }
              final heroes = cinema.Title.parse(data['heroes']);
              if (heroes.isEmpty) return const SizedBox.shrink();
              final index = featured % heroes.length;
              return _Feature(
                item: heroes[index],
                index: index,
                count: heroes.length,
                onTap: () => widget.onTitle(heroes[index]),
                onNext: heroes.length > 1
                    ? () => setState(() => featured++)
                    : null,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 17, 20, 1),
            child: Row(
              children: [
                Expanded(
                  child: _Shortcut(
                    title: 'الأفلام',
                    icon: Icons.movie_outlined,
                    onTap: () => widget.onBrowse('movie'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _Shortcut(
                    title: 'المسلسلات',
                    icon: Icons.view_week_outlined,
                    onTap: () => widget.onBrowse('show'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _Shortcut(
                    title: 'أنمي',
                    icon: Icons.auto_awesome_outlined,
                    onTap: () => widget.onBrowse('anime'),
                  ),
                ),
              ],
            ),
          ),
          _AsyncRail(
            label: 'وصل حديثاً · أفلام',
            load: movies,
            onTitle: widget.onTitle,
            onAll: () => widget.onBrowse('movie'),
          ),
          _AsyncRail(
            label: 'وصل حديثاً · مسلسلات',
            load: shows,
            onTitle: widget.onTitle,
            onAll: () => widget.onBrowse('show'),
          ),
          FutureBuilder<cinema.Json>(
            future: home,
            builder: (context, snapshot) => TitleRail(
              label: 'الأكثر مشاهدة',
              titles: cinema.Title.parse(snapshot.data?['top'])
                  .take(18)
                  .toList(),
              onTitle: widget.onTitle,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AsyncRail extends StatelessWidget {
  const _AsyncRail({
    required this.label,
    required this.load,
    required this.onTitle,
    required this.onAll,
  });
  final String label;
  final Future<cinema.CatalogPage> load;
  final ValueChanged<cinema.Title> onTitle;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) => FutureBuilder<cinema.CatalogPage>(
    future: load,
    builder: (context, snapshot) => TitleRail(
      label: label,
      titles: snapshot.data?.items.take(18).toList() ?? [],
      onTitle: onTitle,
      onAll: onAll,
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.item,
    required this.index,
    required this.count,
    required this.onTap,
    required this.onNext,
  });
  final cinema.Title item;
  final int index, count;
  final VoidCallback onTap;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: constraints.maxWidth > 700 ? 395 : 346,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Artwork(item.hero),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0, .42, 1],
                    colors: [
                      Color(0x16121115),
                      Color(0x53121115),
                      Color(0xff0e1014),
                    ],
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [.15, .47, 1],
                    colors: [
                      Colors.transparent,
                      Color(0x54101014),
                      Color(0xee111218),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
                top: 15,
                start: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: .85),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'مختارات اليوم',
                    style: TextStyle(
                      color: lime,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                bottom: 18,
                start: 17,
                end: 17,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MetaLine(item),
                    const SizedBox(height: 8),
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 39,
                        fontWeight: FontWeight.w900,
                        height: 1.07,
                        letterSpacing: -.7,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('استكشف العنوان'),
                        ),
                        const Spacer(),
                        if (onNext != null)
                          Text(
                            '${index + 1} / $count',
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(color: subtle, fontSize: 12),
                          ),
                        if (onNext != null)
                          IconButton(
                            onPressed: onNext,
                            tooltip: 'التالي',
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.title,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
      foregroundColor: ivory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: lime, size: 20),
        const SizedBox(height: 4),
        Text(title),
      ],
    ),
  );
}

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({
    super.key,
    required this.initialKind,
    required this.onTitle,
  });
  final String initialKind;
  final ValueChanged<cinema.Title> onTitle;

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final search = TextEditingController();
  final titles = <cinema.Title>[];
  late String kind = widget.initialKind;
  String sort = 'latest';
  String query = '';
  Timer? debounce;
  int request = 0;
  int page = 0, pages = 0, total = 0;
  bool loading = true, failed = false;

  @override
  void initState() {
    super.initState();
    load(reset: true);
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  Future<void> load({required bool reset}) async {
    if (!reset && (loading || page >= pages || query.isNotEmpty)) return;
    final token = ++request;
    final currentQuery = query;
    final nextPage = reset ? 1 : page + 1;
    setState(() {
      failed = false;
      loading = true;
      if (reset) {
        titles.clear();
        page = 0;
        pages = 0;
        total = 0;
      }
    });
    try {
      final isCatalog = currentQuery.isEmpty;
      final response = isCatalog
          ? await cinema.Cinema.catalog(
              kind: kind == 'movie' ? 'movie' : 'show',
              category: kind == 'anime' || kind == 'kdrama' ? kind : '',
              sort: sort,
              page: nextPage,
            )
          : null;
      final items =
          response?.items ??
          (currentQuery.length > 1
              ? await cinema.Cinema.search(currentQuery)
              : <cinema.Title>[]);
      if (!mounted || token != request) return;
      setState(() {
        final keys = titles.map((title) => title.key).toSet();
        titles.addAll(items.where((title) => keys.add(title.key)));
        page = response?.page ?? 1;
        pages = response?.pages ?? 1;
        total = response?.total ?? items.length;
        loading = false;
      });
    } catch (_) {
      if (!mounted || token != request) return;
      setState(() {
        failed = true;
        loading = false;
      });
    }
  }

  void searchFor(String text) {
    debounce?.cancel();
    query = text.trim();
    request++;
    setState(() {
      loading = true;
      failed = false;
      titles.clear();
    });
    debounce = Timer(
      const Duration(milliseconds: 380),
      () => load(reset: true),
    );
  }

  void filter(String value) {
    debounce?.cancel();
    search.clear();
    query = '';
    kind = value;
    load(reset: true);
  }

  String get resultCount {
    final digits = total.toString();
    return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '٬');
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: PageHeading('استكشف', 'ابحث في كتالوج الأفلام والمسلسلات'),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: search,
                  maxLength: 100,
                  onChanged: searchFor,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    counterText: '',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'امسح البحث',
                            onPressed: () {
                              search.clear();
                              searchFor('');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    hintText: 'اسم فيلم أو مسلسل',
                  ),
                ),
                const SizedBox(height: 13),
                if (query.isEmpty)
                  Wrap(
                    spacing: 7,
                    runSpacing: 4,
                    children: [
                      for (final entry in [
                        ('movie', 'الأفلام'),
                        ('show', 'المسلسلات'),
                        ('anime', 'أنمي'),
                        ('kdrama', 'دراما كورية'),
                      ])
                        ChoiceChip(
                          label: Text(entry.$2),
                          selected: entry.$1 == kind,
                          onSelected: (_) => filter(entry.$1),
                        ),
                    ],
                  ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        loading ? 'جارٍ التحميل…' : '$resultCount عنوان',
                        style: const TextStyle(color: subtle),
                      ),
                    ),
                    if (query.isEmpty)
                      DropdownButton<String>(
                        value: sort,
                        underline: const SizedBox.shrink(),
                        borderRadius: BorderRadius.circular(10),
                        items: [
                          for (final item in [
                            ('latest', 'الأحدث'),
                            ('rating', 'الأعلى تقييماً'),
                            ('views', 'الأكثر مشاهدة'),
                            ('year', 'سنة الإصدار'),
                          ])
                            DropdownMenuItem(
                              value: item.$1,
                              child: Text(item.$2),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          sort = value;
                          load(reset: true);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (titles.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 185,
                mainAxisSpacing: 16,
                crossAxisSpacing: 11,
                childAspectRatio: .62,
              ),
              itemCount: titles.length,
              itemBuilder: (context, index) => Poster(
                title: titles[index],
                onTap: () => widget.onTitle(titles[index]),
              ),
            ),
          ),
        if (loading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        if (failed)
          SliverToBoxAdapter(
            child: ErrorNotice(
              message: 'تعذّر تحميل النتائج من iCinema.',
              retry: () => load(reset: titles.isEmpty),
            ),
          ),
        if (!failed && !loading && titles.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                query.length == 1
                    ? 'اكتب حرفين على الأقل.'
                    : 'ما فيه نتائج لهذا البحث.',
                style: const TextStyle(color: subtle),
              ),
            ),
          ),
        if (!loading && !failed && query.isEmpty && page < pages)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: OutlinedButton(
                onPressed: () => load(reset: false),
                child: const Text('اعرض المزيد'),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 22)),
      ],
    ),
  );
}
