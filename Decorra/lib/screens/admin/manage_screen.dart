import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/decor_item.dart';
import '../../models/decor_theme.dart';
import '../../services/catalog_repository.dart';
import '../../widgets/decor_image.dart';
import '../../widgets/empty_state.dart';
import 'item_editor_screen.dart';
import 'theme_editor_screen.dart';

/// Decorator: add, edit and remove themes (the portfolio) and items.
class ManageScreen extends StatefulWidget {
  const ManageScreen({super.key, this.initialTab = 0});

  /// 0 = Themes, 1 = Items.
  final int initialTab;

  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  late final Stream<List<DecorTheme>> _themes;
  late final Stream<List<DecorItem>> _items;

  @override
  void initState() {
    super.initState();
    _tabs.index = widget.initialTab.clamp(0, 1);
    final repo = context.read<CatalogRepository>();
    _themes = repo.watchThemes();
    _items = repo.watchItems();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Future<bool> _confirmDelete(String what, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $what?'),
        content: Text('"$name" will be removed for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CatalogRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services and items'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Themes'),
            Tab(text: 'Items'),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (context, _) => FloatingActionButton.extended(
          onPressed: () => _open(
            _tabs.index == 0
                ? const ThemeEditorScreen()
                : const ItemEditorScreen(),
          ),
          icon: const Icon(Icons.add),
          label: Text(_tabs.index == 0 ? 'Add theme' : 'Add item'),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // Themes
          StreamBuilder<List<DecorTheme>>(
            stream: _themes,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final themes = snap.data!;
              if (themes.isEmpty) {
                return const EmptyState(
                  title: 'No themes yet',
                  message:
                      'No themes yet. Add your first theme for clients to browse.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                itemCount: themes.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final theme = themes[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: DecorImage(theme.imageUrl, width: 56, height: 56),
                    title: Text(theme.name),
                    subtitle: theme.tags.isEmpty
                        ? null
                        : Text(theme.tags.join(', ')),
                    onTap: () => _open(ThemeEditorScreen(existing: theme)),
                    trailing: IconButton(
                      tooltip: 'Delete theme ${theme.name}',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (await _confirmDelete('theme', theme.name)) {
                          try {
                            await repo.deleteTheme(theme.id);
                          } catch (_) {
                            _toast(
                                'Could not delete. Check your connection.');
                          }
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
          // Items
          StreamBuilder<List<DecorItem>>(
            stream: _items,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snap.data!;
              if (items.isEmpty) {
                return const EmptyState(
                  title: 'No items yet',
                  message:
                      'Add items that clients can pick for their quotes.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: DecorImage(item.imageUrl, width: 56, height: 56),
                    title: Text(item.name),
                    subtitle: Text(
                      '${moneyText(item.priceCents)}'
                      '${item.rentable ? ' · Rentable' : ''}'
                      '${item.stock != null ? ' · ${item.stock} in stock' : ''}',
                    ),
                    onTap: () => _open(ItemEditorScreen(existing: item)),
                    trailing: IconButton(
                      tooltip: 'Delete item ${item.name}',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (await _confirmDelete('item', item.name)) {
                          try {
                            await repo.deleteItem(item.id);
                          } catch (_) {
                            _toast(
                                'Could not delete. Check your connection.');
                          }
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}