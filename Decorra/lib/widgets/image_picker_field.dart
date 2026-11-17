import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/image_service.dart';
import 'decor_image.dart';

/// Lets the decorator pick, replace or remove one photo.
///
/// It only *holds* the choice. The upload happens when the form is saved, so
/// backing out of the form never leaves stray photos behind.
class ImagePickerField extends StatelessWidget {
  const ImagePickerField({
    super.key,
    required this.existingUrl,
    required this.picked,
    required this.onPicked,
    required this.onRemoved,
    this.enabled = true,
  });

  /// The photo already saved on the theme/item, if any.
  final String? existingUrl;

  /// A photo chosen in this form that has not been uploaded yet.
  final PickedPhoto? picked;
  final ValueChanged<PickedPhoto> onPicked;
  final VoidCallback onRemoved;
  final bool enabled;

  bool get _hasImage =>
      picked != null || (existingUrl != null && existingUrl!.isNotEmpty);

  Future<void> _choose(BuildContext context) async {
    try {
      final photo = await ImageService().pickFromGallery();
      if (photo != null) onPicked(photo);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open that photo. Try another one.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = picked?.bytes;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 96,
            height: 96,
            child: bytes != null
                ? Image.memory(bytes, fit: BoxFit.cover)
                : DecorImage(existingUrl, width: 96, height: 96),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Photo', style: Theme.of(context).textTheme.labelLarge),
              TextButton.icon(
                onPressed: enabled ? () => _choose(context) : null,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(_hasImage ? 'Change photo' : 'Choose photo'),
              ),
              if (_hasImage)
                TextButton(
                  onPressed: enabled ? onRemoved : null,
                  child: const Text('Remove photo'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
