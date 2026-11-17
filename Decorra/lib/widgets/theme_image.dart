import 'package:flutter/material.dart';

import '../theme.dart';

/// A theme photo from its public link, with a plain placeholder when there is none.
class ThemeImage extends StatelessWidget {
  const ThemeImage(this.url, {super.key});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: double.infinity,
      color: sand.withAlpha(90),
      child: const Icon(Icons.image_outlined, size: 36, color: taupe),
    );
    final link = url;
    if (link == null || link.isEmpty) return placeholder;
    return Image.network(
      link,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}