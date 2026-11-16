<?php
/**
 * includes/packages_data.php
 * Package catalogue shown on the client Portfolio page and the admin "Manage Packages" page.
 */
$IMG = 'https://images.unsplash.com/photo-';
$Q   = '?w=700&auto=format&fit=crop&q=75';

$packages = [
    [
        'key'   => 'wedding',
        'title' => 'Floral Arch Wedding',
        'tag'   => 'Wedding',
        'short' => 'Garden-inspired florals, aisle styling and soft ambient lighting.',
        'desc'  => "A romantic, garden-inspired wedding with a statement floral arch at the ceremony, styled aisle, table centrepieces and soft ambient lighting for the reception. We tailor the flowers and colour palette to your season and venue, so the day feels like you.",
        'includes' => ['Floral ceremony arch', 'Aisle styling and petal runner', 'Guest table centrepieces', 'Head table and cake table styling', 'Ambient fairy and uplighting', 'Full setup and breakdown crew'],
        'base'  => 18000,
        'images'=> [$IMG.'1519741497674-611481863552'.$Q, $IMG.'1772127822562-a898d9f5733c'.$Q, $IMG.'1519167758481-83f550bb49b3'.$Q],
    ],
    [
        'key'   => 'zulu',
        'title' => 'Zulu Traditional Wedding',
        'tag'   => 'Traditional',
        'short' => 'Umembeso and umabo styling built around Zulu heritage.',
        'desc'  => "Honour Zulu heritage with decor planned around your family's customs, whether it is the umembeso gift-giving ceremony or the umabo wedding day. We style the marquee and presentation areas with handwoven grass mats (amacansi), clay pot (ukhamba) centrepieces, woven baskets and beadwork-inspired table runners in classic Zulu bead colours, softened with warm lighting and natural greenery. Our team meets your elders or family representatives beforehand so seating, entrances and ceremonial areas follow the right protocol.",
        'includes' => ['Marquee or tent draping in earthy tones', 'Handwoven mat and basket styling', 'Clay pot and beadwork-inspired centrepieces', 'Umembeso gift-presentation display area', 'Head table and family seating layout', 'Entrance and procession styling', 'Warm festoon and uplighting'],
        'base'  => 22000,
        'images'=> [$IMG.'1661332517932-2d441bfb2994'.$Q, $IMG.'1660675133902-acd1b057f75d'.$Q, $IMG.'1618999114008-fbf937170cdb'.$Q],
    ],
    [
        'key'   => 'venda',
        'title' => 'Venda Traditional Wedding',
        'tag'   => 'Traditional',
        'short' => 'Bold Tshivenda-inspired colour, patterns and natural textures.',
        'desc'  => "A vibrant celebration built around the bold colours and geometric patterns found in traditional Venda cloth. We drape the marquee and dress the tables in rich patterned fabrics, add woven and carved wooden accents, clay pots and fresh greenery, and light the space warmly for the evening. Every layout is agreed with the family first, so ceremonial areas, seating order and entrances respect your customs.",
        'includes' => ['Patterned fabric draping and table linen', 'Woven and carved wooden accents', 'Clay pot and greenery centrepieces', 'Ceremonial area styling', 'Head table and family seating layout', 'Entrance and procession styling', 'Warm festoon and uplighting'],
        'base'  => 22000,
        'images'=> [$IMG.'1618999114008-fbf937170cdb'.$Q, $IMG.'1660675133902-acd1b057f75d'.$Q, $IMG.'1772127822562-a898d9f5733c'.$Q],
    ],
    [
        'key'   => 'heritage',
        'title' => 'Custom Heritage Ceremony',
        'tag'   => 'Traditional',
        'short' => 'Xhosa, Sotho, Tswana, Tsonga, Ndebele and more, designed with your family.',
        'desc'  => "Every culture has its own colours, symbols and protocol, so this package starts with a consultation. Tell us about your family's traditions, whether Xhosa, Sotho, Tswana, Tsonga, Ndebele or another, and we design the colour palette, ceremonial areas, seating and entrances around them, using authentic fabrics, beadwork-inspired accents and natural materials.",
        'includes' => ['One-on-one cultural consultation', 'Custom colour palette and fabric draping', 'Ceremonial area and entrance styling', 'Family and elders seating layout', 'Natural-material centrepieces', 'Lighting to suit day or evening events'],
        'base'  => 20000,
        'images'=> [$IMG.'1660675133902-acd1b057f75d'.$Q, $IMG.'1661332517932-2d441bfb2994'.$Q, $IMG.'1772127822562-a898d9f5733c'.$Q],
    ],
    [
        'key'   => 'lobola',
        'title' => 'Lobola & Engagement Celebration',
        'tag'   => 'Traditional',
        'short' => 'An elegant setup for lobola negotiations, engagements and family introductions.',
        'desc'  => "An intimate, elegant setup for lobola (ilobolo) negotiations, engagement parties and family introductions. A welcoming entrance, a negotiation table styled for both families, comfortable seating for elders, a gift-display table and a refreshments station, all finished in the couple's chosen colours.",
        'includes' => ['Welcome entrance styling', 'Negotiation and family tables', 'Elders and guest seating', 'Gift-display table', 'Refreshments station styling', 'Florals in your chosen colours'],
        'base'  => 8500,
        'images'=> [$IMG.'1661332517932-2d441bfb2994'.$Q, $IMG.'1772127822562-a898d9f5733c'.$Q, $IMG.'1519741497674-611481863552'.$Q],
    ],
    [
        'key'   => 'kids',
        'title' => 'Kids Birthday Wonderland',
        'tag'   => 'Kids',
        'short' => 'Jungle safari, unicorn, space, dinosaur, princess or your own theme.',
        'desc'  => "Bring your child's dream party to life. Choose jungle safari, unicorn, space explorer, dinosaur, princess or a theme of your own. We build a full themed backdrop with balloon garland, styled kids' tables, a dessert table, a play and photo corner and a custom name sign. Everything is child-safe and ready before the first guest arrives.",
        'includes' => ['Themed backdrop with balloon garland', 'Kids table and chair styling', 'Dessert and cake table', 'Play and photo corner', 'Custom name sign', 'Setup and breakdown crew'],
        'base'  => 9500,
        'images'=> [$IMG.'1530103862676-de8c9debad1d'.$Q, $IMG.'1464366400600-7168b8af9bc3'.$Q, $IMG.'1478146059778-26028b07395a'.$Q],
    ],
    [
        'key'   => 'baby',
        'title' => 'Baby Shower & Gender Reveal',
        'tag'   => 'Baby Shower',
        'short' => 'Soft, photo-ready styling with a memorable reveal moment.',
        'desc'  => "Sweet, soft and made for photos. Pastel or neutral styling for baby showers, plus a dramatic reveal moment such as a hidden-colour balloon pop or a confetti reveal. Includes a welcome sign, a wishes and guest-book table, dessert and drinks styling and a balloon arch backdrop.",
        'includes' => ['Balloon arch backdrop', 'Welcome sign', 'Wishes and guest-book table', 'Dessert and drinks styling', 'Reveal moment set-up', 'Setup and breakdown crew'],
        'base'  => 11000,
        'images'=> [$IMG.'1519225421980-715cb0215aed'.$Q, $IMG.'1530103862676-de8c9debad1d'.$Q, $IMG.'1464366400600-7168b8af9bc3'.$Q],
    ],
    [
        'key'   => 'milestone',
        'title' => 'Adult Milestone Birthday',
        'tag'   => 'Party',
        'short' => '21st, 30th, 40th, 50th, 60th and beyond, styled to impress.',
        'desc'  => "Mark 21st, 30th, 40th, 50th, 60th birthdays and beyond in style. We dress the venue with a statement balloon install showing the milestone number, a glam backdrop, cocktail lounge seating, a dessert and champagne display and a photo wall. Choose gold and black, rose gold, tropical, or a theme of your own.",
        'includes' => ['Milestone number balloon install', 'Glam backdrop and photo wall', 'Cocktail lounge seating', 'Dessert and champagne display', 'Table styling and centrepieces', 'Setup and breakdown crew'],
        'base'  => 14000,
        'images'=> [$IMG.'1478146059778-26028b07395a'.$Q, $IMG.'1511578314322-379afb476865'.$Q, $IMG.'1530103862676-de8c9debad1d'.$Q],
    ],
    [
        'key'   => 'balloon',
        'title' => 'Balloon Luxury Install',
        'tag'   => 'Party',
        'short' => 'Sculpted garlands, arches, columns and oversize balloon pieces.',
        'desc'  => "Bold, sculpted balloon work: organic garlands, arches, columns and oversize sculptures in colours matched to your event. Ideal for birthdays, engagements, bridal showers and product launches. Includes a design consultation, full installation and breakdown.",
        'includes' => ['Design consultation', 'Organic garland or arch', 'Balloon columns', 'One oversize sculpture', 'Colour matching to your theme', 'Installation and breakdown'],
        'base'  => 12000,
        'images'=> [$IMG.'1530103862676-de8c9debad1d'.$Q, $IMG.'1464366400600-7168b8af9bc3'.$Q, $IMG.'1478146059778-26028b07395a'.$Q],
    ],
    [
        'key'   => 'gala',
        'title' => 'Grand Ballroom Gala',
        'tag'   => 'Corporate',
        'short' => 'Full-scale staging for galas, award evenings and year-end functions.',
        'desc'  => "Full-scale staging for corporate galas, award ceremonies and year-end functions: stage and podium design, dramatic uplighting, premium table linen and centrepieces, branded signage and backdrops, entrance styling and a dedicated on-site crew from setup to breakdown.",
        'includes' => ['Stage and podium design', 'Dramatic uplighting', 'Premium linen and centrepieces', 'Branded signage and backdrops', 'Entrance styling', 'Dedicated on-site crew'],
        'base'  => 35000,
        'images'=> [$IMG.'1511578314322-379afb476865'.$Q, $IMG.'1519167758481-83f550bb49b3'.$Q, $IMG.'1519741497674-611481863552'.$Q],
    ],
];

// Same list keyed by 'key' for the JavaScript on the client page
$packages_by_key = [];
foreach ($packages as $p) {
    $packages_by_key[$p['key']] = $p;
}
