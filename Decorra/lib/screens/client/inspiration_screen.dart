import 'package:flutter/material.dart';

import '../../models/decor_theme.dart';
import '../../services/catalog_repository.dart';
import '../../services/inspiration_repository.dart';
import '../../widgets/empty_state.dart';
import 'portfolio_screen.dart';

class InspirationScreen extends StatefulWidget {
  const InspirationScreen({super.key});

  @override
  State<InspirationScreen> createState() => _InspirationScreenState();
}

class _InspirationScreenState extends State<InspirationScreen> {
  late final Stream<List<DecorTheme>> _themes = CatalogRepository().watchThemes();
  late final Stream<Set<String>> _saved = InspirationRepository().watchSaved();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Inspiration')),
      body: StreamBuilder<List<DecorTheme>>(
        stream: _themes,
        builder: (context, themeSnap) {
          return StreamBuilder<Set<String>>(
            stream: _saved,
            builder: (context, savedSnap) {
              if (themeSnap.hasError || savedSnap.hasError) {
                return const EmptyState(
                  title: 'Could not load your inspiration',
                  message: 'Check your connection and try again.',
                );
              }
              if (!themeSnap.hasData || !savedSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final ids = savedSnap.data!;
              final mine = themeSnap.data!.where((t) => ids.contains(t.id)).toList();
              if (mine.isEmpty) {
                return const EmptyState(
                  title: 'Nothing saved yet',
                  message: 'Tap the bookmark on a theme to keep it here.',
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: mine.length,
                itemBuilder: (_, i) => ThemeCard(theme: mine[i]),
              );
            },
          );
        },
      ),
    );
  }
}