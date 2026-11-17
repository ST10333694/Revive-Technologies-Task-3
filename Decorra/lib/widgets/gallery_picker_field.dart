import 'package:flutter/material.dart';

import '../services/image_service.dart';
import '../theme.dart';
import 'decor_image.dart';

const maxEventPhotos = 5;

/// Grid of up to 5 photos: already-saved links plus newly picked photos.
class GalleryPickerField extends StatelessWidget {
  const GalleryPickerField({
    super.key,
    required this.existingUrls,
    required this.picked,
    required this.enabled,
    required this.onPicked,
    required this.onRemoveExisting,
    required this.onRemovePicked,
  });

  final List<String> existingUrls;
  final List<PickedPhoto> picked;
  final bool enabled;
  final ValueChanged<PickedPhoto> onPicked;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemovePicked;

  int get _count => existingUrls.length + picked.length;

  Future<void> _add() async {
    final photo = await ImageService().pickFromGallery();
    if (photo != null) onPicked(photo);
  }

  Widget _thumb(Widget image, VoidCallback onRemove, {bool cover = false}) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: image),
        ),
        if (cover)
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: espresso.withAlpha(200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: enabled ? onRemove : null,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tiles = <Widget>[];

    for (var i = 0; i < existingUrls.length; i++) {
      tiles.add(_thumb(
        DecorImage(existingUrls[i], width: double.infinity, height: double.infinity),
        () => onRemoveExisting(i),
        cover: i == 0,
      ));
    }
    for (var i = 0; i < picked.length; i++) {
      tiles.add(_thumb(
        Image.memory(picked[i].bytes,
            fit: BoxFit.cover, width: double.infinity, height: double.infinity),
        () => onRemovePicked(i),
        cover: existingUrls.isEmpty && i == 0,
      ));
    }
    if (_count < maxEventPhotos) {
      tiles.add(InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? _add : null,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: taupe),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(Icons.add_a_photo_outlined), SizedBox(height: 4), Text('Add photo')],
          ),
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos ($_count of $maxEventPhotos)', style: text.labelLarge),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: tiles,
        ),
      ],
    );
  }
}