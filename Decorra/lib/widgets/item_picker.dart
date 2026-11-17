import 'package:flutter/material.dart';

import '../models/decor_event.dart';
import '../models/decor_item.dart';
import 'decor_image.dart';
import 'empty_state.dart';

/// Category chips plus a list of items with a tick box and quantity stepper.
/// It edits [lines] directly and calls [onChanged] after every change.
///
/// [maxFor] lets the caller cap the quantity, e.g. subtract stock already
/// reserved on the same date by other committed quotes (FR38).
class ItemPicker extends StatefulWidget {
  const ItemPicker({
    super.key,
    required this.items,
    required this.lines,
    required this.onChanged,
    this.maxFor,
    this.reservedFor,
  });

  final List<DecorItem> items;
  final Map<String, EventLine> lines;
  final VoidCallback onChanged;

  /// Effective orderable quantity for [item]. Defaults to `item.maxOrderable`.
  final int Function(DecorItem item)? maxFor;

  /// Quantity of [item] already reserved on this event's date, for the hint.
  final int Function(DecorItem item)? reservedFor;

  @override
  State<ItemPicker> createState() => _ItemPickerState();
}

class _ItemPickerState extends State<ItemPicker> {
  String _filter = 'All';

  int _max(DecorItem item) => (widget.maxFor?.call(item) ?? item.maxOrderable)
      .clamp(0, DecorItem.maxQuantity)
      .toInt();

  void _toggle(DecorItem item, bool selected) {
    setState(() {
      if (selected) {
        widget.lines[item.id] = EventLine(
          itemId: item.id,
          name: item.name,
          unitCents: item.priceCents,
          quantity: 1,
        );
      } else {
        widget.lines.remove(item.id);
      }
    });
    widget.onChanged();
  }

  void _setQuantity(DecorItem item, int quantity) {
    final line = widget.lines[item.id];
    if (line == null) return;
    setState(() => widget.lines[item.id] = line.withQuantity(quantity));
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const EmptyState(
        title: 'No items yet',
        message: 'Add items under Profile, then Service and item management.',
      );
    }
    final visible = _filter == 'All'
        ? widget.items
        : widget.items.where((i) => i.category == _filter).toList();

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              for (final label in ['All', ...itemCategories])
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
          child: visible.isEmpty
              ? const EmptyState(title: 'Nothing in this category yet')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const Divider(height: 24),
                  itemBuilder: (context, i) {
                    final item = visible[i];
                    final line = widget.lines[item.id];
                    final selected = line != null;
                    final quantity = line?.quantity ?? 1;
                    final max = _max(item);
                    final outOfStock = max == 0;
                    final reserved = widget.reservedFor?.call(item) ?? 0;

                    return Row(
                      children: [
                        DecorImage(item.imageUrl, width: 56, height: 56),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: Theme.of(context).textTheme.titleSmall),
                              Text(
                                outOfStock
                                    ? 'Out of stock on this date'
                                    : moneyText(item.priceCents),
                              ),
                              if (reserved > 0 && !outOfStock)
                                Text(
                                  '$reserved reserved on this date',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        if (selected)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Fewer ${item.name}',
                                icon: const Icon(Icons.remove),
                                onPressed:
                                    quantity > 1 ? () => _setQuantity(item, quantity - 1) : null,
                              ),
                              Text('$quantity'),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: 'More ${item.name}',
                                icon: const Icon(Icons.add),
                                onPressed: quantity < max
                                    ? () => _setQuantity(item, quantity + 1)
                                    : null,
                              ),
                            ],
                          ),
                        Checkbox(
                          value: selected,
                          onChanged: outOfStock ? null : (v) => _toggle(item, v ?? false),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}