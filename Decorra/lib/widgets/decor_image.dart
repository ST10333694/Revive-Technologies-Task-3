import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// Shows a photo from its https link. Photos are cached on the phone after
/// the first load, so the portfolio opens fast and works offline afterwards.
class DecorImage extends StatelessWidget {
  const DecorImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.radius = 12,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final link = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: link == null || link.isEmpty
            ? const _Placeholder()
            : CachedNetworkImage(
                imageUrl: link,
                fit: fit,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (_, _) => const _Placeholder(),
                errorWidget: (_, _, _) => const _Placeholder(broken: true),
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.broken = false});
  final bool broken;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: taupe.withValues(alpha: 0.25),
      alignment: Alignment.center,
      child: Icon(
        broken ? Icons.broken_image_outlined : Icons.image_outlined,
        color: taupe,
      ),
    );
  }
}
