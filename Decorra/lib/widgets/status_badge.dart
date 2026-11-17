import 'package:flutter/material.dart';

import '../models/quote.dart';
import '../theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.color = sand});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: const TextStyle(fontSize: 11, color: espresso)),
    );
  }
}

Color quoteStatusColor(QuoteStatus s) => switch (s) {
      QuoteStatus.newRequest => sand,
      QuoteStatus.inProgress => taupe,
      QuoteStatus.draft => taupe.withAlpha(120),
      QuoteStatus.sent => sand,
      QuoteStatus.approved => sage,
      QuoteStatus.declined => const Color(0xFFE6B8B3),
      QuoteStatus.depositPaid => sage,
      QuoteStatus.eventInProgress => taupe,
      QuoteStatus.completed => sage,
    };