import 'package:flutter/material.dart';

import '../../models/decor_theme.dart';
import '../../services/catalog_repository.dart';
import '../../theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/theme_image.dart';
import 'theme_detail_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late final Stream<List<DecorTheme>> _themes = CatalogRepository().watchThemes();
  String _query = '';
  String? _tag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      body: StreamBuilder<List<DecorTheme>>(
        stream: _themes,
        builder: (context, snap) {
          if (snap.hasError) {
            return const EmptyState(
              title: 'Could not load the portfolio',
              message: 'Check your connection and try again.',
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final all = snap.data!;
          if (all.isEmpty) {
            return const EmptyState(
              title: 'No themes yet',
              message: 'Your decorator has not added any themes.',
            );
          }

          final tags = {for (final t in all) ...t.tags}.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
          final q = _query.trim().toLowerCase();
          final shown = all.where((t) {
            if (_tag != null && !t.tags.contains(_tag)) return false;
            if (q.isEmpty) return true;
            return t.name.toLowerCase().contains(q) ||
                t.description.toLowerCase().contains(q);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search themes',
                  ),
                ),
              ),
              if (tags.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: _tag == null,
                          onSelected: (_) => setState(() => _tag = null),
                        ),
                      ),
                      for (final tag in tags)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(tag),
                            selected: _tag == tag,
                            onSelected: (_) =>
                                setState(() => _tag = _tag == tag ? null : tag),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: shown.isEmpty
                    ? const EmptyState(title: 'No themes match your search')
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: shown.length,
                        itemBuilder: (_, i) => ThemeCard(theme: shown[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A theme tile with its photo and name. Opens the theme details.
class ThemeCard extends StatelessWidget {
  const ThemeCard({super.key, required this.theme});

  final DecorTheme theme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ThemeDetailScreen(theme: theme)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: taupe.withAlpha(128)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ThemeImage(theme.imageUrl)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                theme.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}