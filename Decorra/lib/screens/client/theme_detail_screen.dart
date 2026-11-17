import 'package:flutter/material.dart';

import '../../models/decor_theme.dart';
import '../../services/inspiration_repository.dart';
import 'customize_theme_screen.dart';
import '../../widgets/theme_image.dart';

class ThemeDetailScreen extends StatefulWidget {
  const ThemeDetailScreen({super.key, required this.theme});

  final DecorTheme theme;

  @override
  State<ThemeDetailScreen> createState() => _ThemeDetailScreenState();
}

class _ThemeDetailScreenState extends State<ThemeDetailScreen> {
  final _repo = InspirationRepository();
  late final Stream<Set<String>> _saved = _repo.watchSaved();

  void _toggle(bool save) {
    final messenger = ScaffoldMessenger.of(context);
    _repo.toggle(widget.theme.id, save: save).catchError((_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not update. Check your connection.')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.name),
        actions: [
          StreamBuilder<Set<String>>(
            stream: _saved,
            builder: (context, snap) {
              final isSaved = snap.data?.contains(t.id) ?? false;
              return IconButton(
                tooltip: isSaved ? 'Remove from inspiration' : 'Save to inspiration',
                icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                onPressed: () => _toggle(!isSaved),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(aspectRatio: 16 / 10, child: ThemeImage(t.imageUrl)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name, style: text.titleLarge),
                if (t.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [for (final tag in t.tags) Chip(label: Text(tag))],
                  ),
                ],
                if (t.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(t.description, style: text.bodyLarge),
                ],
                if (t.items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Includes ${t.items.length} ${t.items.length == 1 ? 'item' : 'items'}',
                    style: text.bodyMedium,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomizeThemeScreen(
                        themeId: t.id,
                        themeName: t.name,
                        defaults: t.items,
                      ),
                    ),
                  ),
                  child: const Text('Customize this theme'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}