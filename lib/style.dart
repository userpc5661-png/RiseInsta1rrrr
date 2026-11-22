import 'package:flutter/material.dart';

import 'catalog.dart' as cinema;

const ink = Color(0xff0e1014);
const panel = Color(0xff191c23);
const ivory = Color(0xfff5f4ed);
const subtle = Color(0xffa8a9b1);
const lime = Color(0xffd8fa77);
const tonedLime = Color(0xff2a3422);
const edge = Color(0xff343641);

class Artwork extends StatelessWidget {
  const Artwork(this.url, {super.key, this.fit = BoxFit.cover});
  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(
      color: panel,
      child: Center(
        child: Icon(Icons.local_movies_outlined, color: edge, size: 38),
      ),
    );
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return fallback;
    }
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (_, image, progress) =>
          progress == null ? image : fallback,
    );
  }
}

class Brand extends StatelessWidget {
  const Brand({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: lime,
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Icon(Icons.play_arrow_rounded, color: ink, size: 26),
      ),
      const SizedBox(width: 10),
      const Text(
        'مَشهد',
        style: TextStyle(
          fontSize: 27,
          height: 1.14,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key});
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: subtle, fontSize: 14)),
      ],
    ),
  );
}

class Tag extends StatelessWidget {
  const Tag(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 9),
    decoration: BoxDecoration(
      color: panel,
      border: Border.all(color: edge),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: const TextStyle(color: ivory, fontSize: 11)),
  );
}

class MetaLine extends StatelessWidget {
  const MetaLine(this.item, {super.key});
  final cinema.Title item;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        item.isShow ? 'مسلسل' : 'فيلم',
        style: const TextStyle(
          color: lime,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      if (item.year > 0)
        Text(
          '${item.year}',
          style: const TextStyle(color: subtle, fontSize: 13),
        ),
      if (item.rating != '0.0')
        Text(
          '★ ${item.rating}',
          textDirection: TextDirection.ltr,
          style: const TextStyle(color: subtle, fontSize: 13),
        ),
    ],
  );
}

class Poster extends StatelessWidget {
  const Poster({super.key, required this.title, required this.onTap});
  final cinema.Title title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Artwork(title.poster),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        Text(
          [
            if (title.year > 0) '${title.year}',
            if (title.genres.isNotEmpty) title.genres.first,
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: subtle),
        ),
      ],
    ),
  );
}

class TitleRail extends StatelessWidget {
  const TitleRail({
    super.key,
    required this.label,
    required this.titles,
    required this.onTitle,
    this.onAll,
    this.empty,
  });
  final String label;
  final List<cinema.Title> titles;
  final ValueChanged<cinema.Title> onTitle;
  final VoidCallback? onAll;
  final String? empty;

  @override
  Widget build(BuildContext context) {
    if (titles.isEmpty && empty == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (onAll != null)
                  TextButton(onPressed: onAll, child: const Text('الكل  ←')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (titles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(empty!, style: const TextStyle(color: subtle)),
            )
          else
            SizedBox(
              height: 221,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: titles.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) => SizedBox(
                  width: 124,
                  child: Poster(
                    title: titles[index],
                    onTap: () => onTitle(titles[index]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ErrorNotice extends StatelessWidget {
  const ErrorNotice({
    super.key,
    required this.message,
    required this.retry,
    this.onProvider,
  });
  final String message;
  final VoidCallback retry;
  final VoidCallback? onProvider;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: subtle, fontSize: 16)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(onPressed: retry, child: const Text('أعد المحاولة')),
            if (onProvider != null)
              TextButton(
                onPressed: onProvider,
                child: const Text('افتح iCinema'),
              ),
          ],
        ),
      ],
    ),
  );
}
