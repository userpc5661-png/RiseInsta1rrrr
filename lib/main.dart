import 'package:flutter/material.dart';

import 'catalog.dart' as cinema;
import 'discovery.dart';
import 'style.dart';

void main() => runApp(const Mashhad());

class Mashhad extends StatelessWidget {
  const Mashhad({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'مَشهد',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      colorScheme: const ColorScheme.dark(
        primary: lime,
        onPrimary: ink,
        surface: panel,
        onSurface: ivory,
        outline: edge,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: ink,
        indicatorColor: tonedLime,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: edge),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: edge),
        ),
      ),
    ),
    builder: (context, child) =>
        Directionality(textDirection: TextDirection.rtl, child: child!),
    home: const Shell(),
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final shelf = cinema.Library();
  late final Future<void> _loaded;
  late final Future<cinema.Json> _home;
  int tab = 0;
  String browseKind = 'movie';
  var browseKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loaded = shelf.load().catchError((Object _) {});
    _home = cinema.Cinema.read('/api/home');
    _home.ignore();
  }

  void browse(String kind) => setState(() {
    browseKind = kind;
    browseKey = UniqueKey();
    tab = 1;
  });

  void toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> toggle(cinema.Title title) async {
    await _loaded;
    if (!mounted) return;
    setState(() {
      if (shelf.saved.containsKey(title.key)) {
        shelf.saved.remove(title.key);
      } else {
        shelf.saved[title.key] = title;
      }
    });
    try {
      await shelf.write();
    } catch (_) {
      toast('تعذّر حفظ التغيير على هذا الجهاز.');
    }
  }

  void showDetails(cinema.Title title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailScreen(
          summary: title,
          shelf: shelf,
          onSave: toggle,
          onWatch: (item, season) async {
            final target = cinema.Cinema.titleLink(item, season);
            final opening = cinema.Cinema.open(target);
            try {
              await opening;
              await _loaded;
              if (!mounted) return;
              setState(() {
                shelf.recent.removeWhere((entry) => entry.key == item.key);
                shelf.recent.insert(0, item);
                if (shelf.recent.length > 20) shelf.recent.removeLast();
              });
              await shelf.write();
            } catch (_) {
              toast('تعذّر فتح عنوان المشاهدة أو حفظه.');
            }
          },
          onTitle: showDetails,
        ),
      ),
    );
  }

  Future<void> open(String path, [Map<String, String>? query]) async {
    try {
      await cinema.Cinema.open(cinema.Cinema.service(path, query));
    } catch (_) {
      toast('تعذّر فتح صفحة الخدمة.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: [
          HomeScreen(
            initial: _home,
            onTitle: showDetails,
            onBrowse: browse,
            onProvider: () => open('/'),
          ),
          BrowseScreen(
            key: browseKey,
            initialKind: browseKind,
            onTitle: showDetails,
          ),
          FutureBuilder<void>(
            future: _loaded,
            builder: (context, snapshot) => SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 34),
                children: [
                  const PageHeading(
                    'مكتبتي',
                    'العناوين التي تهمّك، في مكان واحد',
                  ),
                  TitleRail(
                    label: 'قائمتي',
                    titles: shelf.saved.values.toList().reversed.toList(),
                    onTitle: showDetails,
                    empty: 'احفظ أي عنوان من صفحة التفاصيل.',
                  ),
                  TitleRail(
                    label: 'آخر ما فتحت',
                    titles: shelf.recent,
                    onTitle: showDetails,
                    empty: 'تظهر هنا العناوين التي فتحتها للمشاهدة.',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: () => open('/'),
                      icon: const Icon(Icons.history_rounded),
                      label: const Text('متابعة المشاهدة في iCinema'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 34),
              children: [
                const PageHeading('المزيد', 'حسابك وتفاعلاتك على iCinema'),
                for (final item in [
                  (
                    Icons.groups_2_outlined,
                    'غرف المشاهدة',
                    'ادخل غرفة أو تابع المشاهدة مع أصدقائك',
                    '/rooms',
                  ),
                  (
                    Icons.forum_outlined,
                    'المجتمع',
                    'المنشورات والتعليقات والأصدقاء',
                    '/feed',
                  ),
                  (
                    Icons.person_search_outlined,
                    'الأشخاص',
                    'اعثر على حسابات وأصدقاء',
                    '/people',
                  ),
                  (
                    Icons.live_tv_rounded,
                    'البث المباشر',
                    'القنوات المتاحة في iCinema',
                    '/live-tv',
                  ),
                  (
                    Icons.playlist_add_rounded,
                    'اطلب عنواناً',
                    'أرسل طلب فيلم أو مسلسل',
                    '/request',
                  ),
                  (
                    Icons.account_circle_outlined,
                    'الدخول إلى حساب iCinema',
                    'الحساب والتقدم والمفضلة على الخدمة',
                    '/login',
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      color: panel,
                      child: ListTile(
                        leading: Icon(item.$1, color: lime),
                        title: Text(
                          item.$2,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          item.$3,
                          style: const TextStyle(color: subtle),
                        ),
                        trailing: const Icon(
                          Icons.open_in_new_rounded,
                          size: 17,
                        ),
                        onTap: () => open(item.$4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => setState(() => tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: lime),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded, color: lime),
            label: 'استكشف',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded, color: lime),
            label: 'مكتبتي',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_horiz_rounded, color: lime),
            label: 'المزيد',
          ),
        ],
      ),
    );
  }
}

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.summary,
    required this.shelf,
    required this.onSave,
    required this.onWatch,
    required this.onTitle,
  });

  final cinema.Title summary;
  final cinema.Library shelf;
  final Future<void> Function(cinema.Title) onSave;
  final Future<void> Function(cinema.Title, int?) onWatch;
  final ValueChanged<cinema.Title> onTitle;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<cinema.Title> result;
  int? season;

  @override
  void initState() {
    super.initState();
    result = cinema.Cinema.details(widget.summary);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FutureBuilder<cinema.Title>(
      future: result,
      builder: (context, snapshot) {
        final item = snapshot.data ?? widget.summary;
        final seasons =
            item.episodes
                .map((episode) => cinema.number(episode['season']))
                .toSet()
                .toList()
              ..sort();
        final selected = season ?? seasons.firstOrNull;
        final episodes =
            item.episodes
                .where(
                  (episode) => cinema.number(episode['season']) == selected,
                )
                .toList()
              ..sort(
                (a, b) => cinema
                    .number(a['episode'])
                    .compareTo(cinema.number(b['episode'])),
              );
        final related = cinema.Title.parse(item.data['related']);
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 290,
              pinned: true,
              backgroundColor: ink,
              leading: const BackButton(),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Artwork(item.hero, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x770e1014), Color(0x100e1014), ink],
                          stops: [0, .48, 1],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MetaLine(item),
                    const SizedBox(height: 9),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 37,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => widget.onWatch(item, selected),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(
                              item.streamable
                                  ? 'افتح المشاهدة'
                                  : 'تحقّق من التوفر',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.outlined(
                          tooltip: widget.shelf.saved.containsKey(item.key)
                              ? 'أزل من قائمتي'
                              : 'احفظ في قائمتي',
                          onPressed: () async {
                            await widget.onSave(item);
                            if (mounted) setState(() {});
                          },
                          icon: Icon(
                            widget.shelf.saved.containsKey(item.key)
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: lime,
                          ),
                        ),
                      ],
                    ),
                    if (item.certification.isNotEmpty ||
                        item.subtitleCount > 0) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (item.certification.isNotEmpty)
                            Tag(item.certification),
                          if (item.subtitleCount > 0)
                            Tag('${item.subtitleCount} ترجمات'),
                        ],
                      ),
                    ],
                    if (item.synopsis.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          item.synopsis,
                          style: const TextStyle(
                            fontSize: 15,
                            color: subtle,
                            height: 1.65,
                          ),
                        ),
                      ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    if (snapshot.hasError)
                      ErrorNotice(
                        message: 'تعذّر جلب باقي التفاصيل.',
                        retry: () => setState(
                          () => result = cinema.Cinema.details(widget.summary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (seasons.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الحلقات',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final value in seasons)
                            ChoiceChip(
                              label: Text('الموسم $value'),
                              selected: selected == value,
                              onSelected: (_) => setState(() => season = value),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (final episode in episodes)
                        EpisodeTile(
                          episode: episode,
                          onOpen: () => widget.onWatch(item, selected),
                        ),
                    ],
                  ),
                ),
              ),
            if (related.isNotEmpty)
              SliverToBoxAdapter(
                child: TitleRail(
                  label: 'أعمال مشابهة',
                  titles: related,
                  onTitle: widget.onTitle,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 36)),
          ],
        );
      },
    ),
  );
}

class EpisodeTile extends StatelessWidget {
  const EpisodeTile({super.key, required this.episode, required this.onOpen});
  final cinema.Json episode;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final number = cinema.number(episode['episode']);
    final subtitles = cinema.number(episode['subtitle_count']);
    final runtime = cinema.number(episode['runtime']);
    final name = cinema.string(episode['title']);
    final available =
        episode['streamable'] == true ||
        cinema.number(episode['streamable']) == 1;
    return Card(
      color: panel,
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 74,
            height: 52,
            child: Artwork(cinema.string(episode['still'])),
          ),
        ),
        title: Text(name.isEmpty ? 'الحلقة $number' : '$number · $name'),
        subtitle: Text(
          [
            if (!available) 'غير متاحة للمشاهدة حالياً',
            if (runtime > 0) '$runtime د',
            if (subtitles > 0) '$subtitles ترجمات',
          ].join('  ·  '),
        ),
        trailing: Icon(
          available ? Icons.open_in_new_rounded : Icons.info_outline,
          size: 19,
          color: available ? lime : subtle,
        ),
        onTap: onOpen,
      ),
    );
  }
}
