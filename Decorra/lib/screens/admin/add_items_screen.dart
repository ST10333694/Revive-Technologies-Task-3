import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/decor_item.dart';
import '../../models/event_draft.dart';
import '../../services/catalog_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/item_picker.dart';
import 'review_event_screen.dart';

class AddItemsScreen extends StatefulWidget {
  const AddItemsScreen({super.key, required this.draft});

  final EventDraft draft;

  @override
  State<AddItemsScreen> createState() => _AddItemsScreenState();
}

class _AddItemsScreenState extends State<AddItemsScreen> {
  late final Stream<List<DecorItem>> _items;

  @override
  void initState() {
    super.initState();
    _items = context.read<CatalogRepository>().watchItems();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.draft.lines.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Items')),
      body: StreamBuilder<List<DecorItem>>(
        stream: _items,
        builder: (context, snap) {
          if (snap.hasError) {
            return const EmptyState(
              title: 'Could not load items',
              message: 'Check your connection and try again.',
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          // Items for this theme, plus items available in every theme.
          final themeId = widget.draft.theme?.id;
          final items =
              snap.data!.where((i) => i.themeId == null || i.themeId == themeId).toList();

          return ItemPicker(
            items: items,
            lines: widget.draft.lines,
            onChanged: () => setState(() {}),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReviewEventScreen(draft: widget.draft)),
            ),
            child: Text(count == 0 ? 'Continue without items' : 'Add to Event ($count)'),
          ),
        ),
      ),
    );
  }
}