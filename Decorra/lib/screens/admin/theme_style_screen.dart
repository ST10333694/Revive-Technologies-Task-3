import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/decor_theme.dart';
import '../../models/event_draft.dart';
import '../../services/catalog_repository.dart';
import '../../theme.dart';
import '../../widgets/decor_image.dart';
import '../../widgets/empty_state.dart';
import 'add_items_screen.dart';

class ThemeStyleScreen extends StatefulWidget {
  const ThemeStyleScreen({super.key, required this.draft});

  final EventDraft draft;

  @override
  State<ThemeStyleScreen> createState() => _ThemeStyleScreenState();
}

class _ThemeStyleScreenState extends State<ThemeStyleScreen> {
  late final Stream<List<DecorTheme>> _themes;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _themes = context.read<CatalogRepository>().watchThemes();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Theme & Style')),
      body: StreamBuilder<List<DecorTheme>>(
        stream: _themes,
        builder: (context, snap) {
          if (snap.hasError) {
            return const EmptyState(
              title: 'Could not load themes',
              message: 'Check your connection and try again.',
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final all = snap.data!;
          if (all.isEmpty) {
            return const EmptyState(
              title: 'No themes yet',
              message: 'You can add themes under More, then Service and item management. '
                  'Or continue without a theme.',
            );
          }

          final tags = <String>{for (final t in all) ...t.tags}.toList()..sort();
          final visible =
              _filter == 'All' ? all : all.where((t) => t.tags.contains(_filter)).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Choose a theme for your event.', style: text.bodyMedium),
                ),
              ),
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    for (final label in ['All', ...tags])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: _filter == label,
                          onSelected: (_) => setState(() => _filter = label),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final theme = visible[i];
                    final selected = widget.draft.theme?.id == theme.id;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => widget.draft.theme = selected ? null : theme),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected ? espresso : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: DecorImage(theme.imageUrl, width: double.infinity),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            theme.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: selected
                                ? text.labelLarge?.copyWith(fontWeight: FontWeight.w700)
                                : text.labelLarge,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddItemsScreen(draft: widget.draft)),
            ),
            child: const Text('Next: Add Items'),
          ),
        ),
      ),
    );
  }
}