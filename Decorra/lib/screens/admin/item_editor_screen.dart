import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/decor_item.dart';
import '../../models/decor_theme.dart';
import '../../services/catalog_repository.dart';
import '../../services/image_service.dart';
import '../../widgets/image_picker_field.dart';

/// Add or edit a catalog item, including its photo.
class ItemEditorScreen extends StatefulWidget {
  const ItemEditorScreen({super.key, this.existing});

  final DecorItem? existing;

  @override
  State<ItemEditorScreen> createState() => _ItemEditorScreenState();
}

class _ItemEditorScreenState extends State<ItemEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _minStock;
  late final TextEditingController _unitCost;
  late final String _id;

  List<DecorTheme> _themes = const [];
  String? _themeId;
  bool _rentable = false;
  String _category = itemCategories.last;

  PickedPhoto? _picked;
  bool _removeExisting = false;
  bool _saving = false;
  String _status = '';

  static String _rands(int cents) => cents == 0
      ? ''
      : (cents % 100 == 0
            ? '${cents ~/ 100}'
            : (cents / 100).toStringAsFixed(2));

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    final repo = context.read<CatalogRepository>();
    _id = item?.id ?? repo.newItemId();
    _name = TextEditingController(text: item?.name ?? '');
    _price = TextEditingController(
      text: item == null ? '' : _rands(item.priceCents),
    );
    _stock = TextEditingController(text: item?.stock?.toString() ?? '');
    _minStock = TextEditingController(
      text: (item?.minStock ?? 0) == 0 ? '' : item!.minStock.toString(),
    );
    _unitCost = TextEditingController(
      text: item == null ? '' : _rands(item.unitCostCents),
    );
    _themeId = item?.themeId;
    _rentable = item?.rentable ?? false;
    _category = itemCategories.contains(item?.category) ? item!.category : itemCategories.last;

    repo
        .watchThemes()
        .first
        .then((list) {
          if (!mounted) return;
          setState(() {
            _themes = list;
            if (_themeId != null && !list.any((t) => t.id == _themeId)) {
              _themeId = null;
            }
          });
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _minStock.dispose();
    _unitCost.dispose();
    super.dispose();
  }

  /// "125", "125.5" and "125,50" all work. Returns null when it is not a number.
  static int? _toCents(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    return value == null ? null : (value * 100).round();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final repo = context.read<CatalogRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _saving = true;
      _status = '';
    });

    try {
      String? imageUrl = _removeExisting ? null : widget.existing?.imageUrl;
      if (_picked != null) {
        setState(() => _status = 'Uploading photo…');
        imageUrl = await ImageService().upload(_picked!, folder: 'items');
      }

      setState(() => _status = 'Saving…');
      final item = DecorItem(
        id: _id,
        name: _name.text.trim(),
        priceCents: _toCents(_price.text) ?? 0,
        themeId: _themeId,
        imageUrl: imageUrl,
        category: _category,
        rentable: _rentable,
        stock: _stock.text.trim().isEmpty
            ? null
            : int.tryParse(_stock.text.trim()),
        minStock: int.tryParse(_minStock.text.trim()) ?? 0,
        unitCostCents: _toCents(_unitCost.text) ?? 0,
      );

      var queued = false;
      try {
        await repo.saveItem(item).timeout(const Duration(seconds: 10));
      } on TimeoutException {
        queued = true;
      }

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            queued
                ? 'Saved. It will sync when you are back online.'
                : 'Changes saved',
          ),
        ),
      );
        } on ImageUploadException catch (e) {
      debugPrint('UPLOAD ERROR: ${e.message}');
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
        } catch (e) {
      debugPrint('SAVE ERROR: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    final money = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    final whole = [FilteringTextInputFormatter.digitsOnly];

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: Text(editing ? 'Edit item' : 'Add item')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ImagePickerField(
                existingUrl: _removeExisting ? null : widget.existing?.imageUrl,
                picked: _picked,
                enabled: !_saving,
                onPicked: (p) => setState(() {
                  _picked = p;
                  _removeExisting = false;
                }),
                onRemoved: () => setState(() {
                  _picked = null;
                  _removeExisting = true;
                }),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Item name'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'This field is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: money,
                decoration: const InputDecoration(
                  labelText: 'Price per item',
                  prefixText: 'R ',
                ),
                validator: (v) {
                  final cents = _toCents(v ?? '');
                  return (cents == null || cents <= 0)
                      ? 'Enter a price above zero'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                // Rebuilt once the theme list arrives, so an item's saved theme
                // is selected as soon as it exists in the list.
                key: ValueKey(_themes.length),
                initialValue: _themes.any((t) => t.id == _themeId)
                    ? _themeId
                    : null,
                decoration: const InputDecoration(labelText: 'Available for'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All themes'),
                  ),
                  for (final t in _themes)
                    DropdownMenuItem<String?>(value: t.id, child: Text(t.name)),
                ],
                onChanged: _saving ? null : (v) => setState(() => _themeId = v),
              ),
              const SizedBox(height: 4),
                 InputDecorator(
     decoration: const InputDecoration(labelText: 'Category'),
     child: DropdownButtonHideUnderline(
       child: DropdownButton<String>(
         isExpanded: true,
         value: _category,
         items: [
           for (final c in itemCategories) DropdownMenuItem(value: c, child: Text(c)),
         ],
         onChanged: _saving ? null : (v) => setState(() => _category = v ?? _category),
       ),
     ),
   ),
   const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Clients can rent this on its own'),
                value: _rentable,
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _rentable = v),
              ),
              const Divider(),
              const SizedBox(height: 8),
              TextFormField(
                controller: _stock,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: whole,
                decoration: const InputDecoration(
                  labelText: 'Stock on hand',
                  helperText: 'Leave empty if you do not track the quantity.',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minStock,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: whole,
                decoration: const InputDecoration(
                  labelText: 'Minimum stock (low-stock alert)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitCost,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: money,
                decoration: const InputDecoration(
                  labelText: 'Cost per item',
                  prefixText: 'R ',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          if (_status.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Text(_status),
                          ],
                        ],
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
