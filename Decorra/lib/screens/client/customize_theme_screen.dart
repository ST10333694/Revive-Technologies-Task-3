import 'package:flutter/material.dart';

import '../../models/decor_event.dart';
import '../../models/decor_item.dart';
import '../../models/decor_theme.dart';
import '../../models/quote_draft.dart';
import '../../services/catalog_repository.dart';
import '../../services/draft_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/theme_image.dart';
import 'event_details_screen.dart';

/// Step 1 of a quote request: choose items and quantities.
/// Start from a theme (themeId, themeName, defaults) or resume a [draft].
class CustomizeThemeScreen extends StatefulWidget {
  const CustomizeThemeScreen({
    super.key,
    required this.themeId,
    required this.themeName,
    this.defaults = const [],
    this.draft,
  });

  final String themeId;
  final String themeName;
  final List<ThemeItem> defaults;
  final QuoteDraft? draft;

  @override
  State<CustomizeThemeScreen> createState() => _CustomizeThemeScreenState();
}

class _CustomizeThemeScreenState extends State<CustomizeThemeScreen> {
  late final Stream<List<DecorItem>> _items = CatalogRepository().watchItems();
  late final String _draftId = widget.draft?.id ?? DraftRepository().newId();
  Map<String, int>? _qty;
  Set<String>? _pinned;

  Map<String, int> _initial() {
    final d = widget.draft;
    if (d != null) return {for (final l in d.lines) l.itemId: l.quantity};
    return {for (final t in widget.defaults) t.itemId: t.quantity};
  }

  int _quantityOf(DecorItem item) =>
      (_qty?[item.id] ?? 0).clamp(0, item.maxOrderable).toInt();

  List<EventLine> _lines(List<DecorItem> items) => [
        for (final i in items)
          if (_quantityOf(i) > 0)
            EventLine(
              itemId: i.id,
              name: i.name,
              unitCents: i.priceCents,
              quantity: _quantityOf(i),
            ),
      ];

  void _next(List<EventLine> lines) {
    final base = widget.draft ??
        QuoteDraft(id: _draftId, themeId: widget.themeId, themeName: widget.themeName);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(draft: base.copyWith(lines: lines)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return StreamBuilder<List<DecorItem>>(
      stream: _items,
      builder: (context, snap) {
        final appBar = AppBar(title: const Text('Customize Theme'));
        if (snap.hasError) {
          return Scaffold(
            appBar: appBar,
            body: const EmptyState(
              title: 'Could not load the items',
              message: 'Check your connection and try again.',
            ),
          );
        }
        if (!snap.hasData) {
          return Scaffold(appBar: appBar, body: const Center(child: CircularProgressIndicator()));
        }

        final qty = _qty ??= _initial();
        final pinned = _pinned ??= qty.keys.toSet();
        final items = snap.data!
            .where((i) => i.themeId == null || i.themeId == widget.themeId || pinned.contains(i.id))
            .toList();
        final lines = _lines(items);
        final subtotal = lines.fold<int>(0, (sum, l) => sum + l.lineCents);

        return Scaffold(
          appBar: appBar,
          body: items.isEmpty
              ? const EmptyState(
                  title: 'No items available',
                  message: 'Your decorator has not added items for this theme yet.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Text(widget.themeName, style: text.titleLarge);
                    }
                    final item = items[index - 1];
                    final q = _quantityOf(item);
                    final max = item.maxOrderable;
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(width: 56, height: 56, child: ThemeImage(item.imageUrl)),
                        ),
                        title: Text(item.name),
                        subtitle: Text(
                          max == 0
                              ? 'Out of stock'
                              : '${moneyText(item.priceCents)} each'
                                  '${item.stock != null ? ' · ${item.stock} available' : ''}',
                        ),
                        trailing: max == 0
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Fewer',
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: q == 0 ? null : () => setState(() => qty[item.id] = q - 1),
                                  ),
                                  Text('$q'),
                                  IconButton(
                                    tooltip: 'More',
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: q >= max ? null : () => setState(() => qty[item.id] = q + 1),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Items (excl. VAT)', style: text.bodySmall),
                        Text(moneyText(subtotal), style: text.titleMedium),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
                    onPressed: lines.isEmpty ? null : () => _next(lines),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}