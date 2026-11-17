import 'package:flutter/material.dart';

import '../theme.dart';

class _Group {
  const _Group(this.title, this.entries);
  final String title;
  final List<(String, String)> entries;
}

const _groups = <_Group>[
  _Group('Furniture & seating', [
    ('Tables', 'Round banquet tables, rectangular trestle tables, or high cocktail tables depending on the seating layout.'),
    ('Seating', 'Stylish chairs that match the event\'s aesthetic (such as Tiffany, Ghost, Wimbledon, or Phoenix chairs) or standard chairs dressed with fitted covers and ties.'),
    ('Lounge pockets', 'Ottomans, couches, coffee tables, and scatter cushions to create comfortable mingling and relaxation zones.'),
  ]),
  _Group('Table styling', [
    ('Tablecloths', 'Floor-length tablecloths in neutral base colours (white, black, ivory, or charcoal) to hide table legs and create a clean canvas.'),
    ('Overlays & runners', 'Accent-coloured runners (chiffon, cheesecloth, satin, or velvet) to add texture and introduce the event\'s colour palette.'),
    ('Cloth napkins & rings', 'Coordinated fabric napkins (folded or tied) to elevate the individual place setting.'),
    ('Underplates (charger plates)', 'Gold, silver, glass, black, or woven rattan charger plates to anchor each guest\'s place setting.'),
    ('Crockery, cutlery & glassware', 'Coordinated plates, metallic cutlery (gold, rose gold, black, or stainless steel), and wine, champagne, and water glasses.'),
    ('Table numbers & holders', 'Clear, acrylic, wooden, or metallic table numbers so guests can easily find their seats.'),
  ]),
  _Group('Centrepieces & florals', [
    ('Centrepiece vessels & stands', 'Low floral bowls, tall gold or black geometric stands, vases, or mirror plates that add height without blocking sightlines across the table.'),
    ('Florals & greenery', 'Fresh seasonal blooms, high-quality artificial silk arrangements, or foliage garlands.'),
    ('Candles & holders', 'Pillar candles in glass hurricane cylinders, taper candles in candlesticks, or LED votives for warmth and table-level glow.'),
  ]),
  _Group('Backdrops & décor', [
    ('Main backdrop / feature wall', 'A flower arch, shimmer wall, mesh circle, or draped frame positioned behind the main table, stage, or photo area.'),
    ('Plinths & display stands', 'Cylindrical or geometric plinths used to showcase cakes, welcome arrangements, awards, or product displays.'),
    ('Draping', 'Ceiling, wall, or entrance draping to soften plain hall walls or transform marquees.'),
  ]),
  _Group('Signage', [
    ('Welcome board & easel', 'A custom printed board (perspex, wood, or mirror) displayed on an easel at the entrance to set the tone.'),
    ('Seating chart & menus', 'Clear guest seating boards at the entrance and printed menus at each table.'),
    ('Directional signs', 'Simple signage pointing guests toward bars, restrooms, or outdoor spaces.'),
  ]),
  _Group('Lighting', [
    ('Uplighting (par cans)', 'Wireless LED lights placed along walls or behind draping to wash the venue in the event\'s theme colours.'),
    ('Overhead & string lighting', 'Fairy lights, festoon bulbs, or chandeliers to create atmosphere once the sun goes down.'),
  ]),
  _Group('Entrance & service', [
    ('Entrance carpets & stanchions', 'Aisle runners or red/white entrance carpets paired with bollards and ropes to guide guest flow.'),
    ('Beverage & service accents', 'Stylish ice buckets, wine tubs, drink dispensers, and decorative trays so practical service items blend seamlessly into the décor.'),
  ]),
];

/// "What we provide" section shown on every event.
class ProvidedServices extends StatelessWidget {
  const ProvidedServices({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: taupe.withAlpha(128)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text('What we provide', style: text.titleMedium),
          subtitle: Text('Included in every event', style: text.bodySmall),
          children: [
            for (final g in _groups) ...[
              const SizedBox(height: 12),
              Text(g.title, style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              for (final (name, detail) in g.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$name: ',
                          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: detail, style: text.bodyMedium),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}