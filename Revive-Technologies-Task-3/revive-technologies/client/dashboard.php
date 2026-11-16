<?php
/**
 * client/dashboard.php
 * Client's "Portfolio" home page - shows past work + their own bookings summary.
 */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_role('client');

$client_id = $_SESSION['user_id'];

// Quick stats for this client
$stmt = $pdo->prepare('SELECT COUNT(*) FROM bookings WHERE client_id = ?');
$stmt->execute([$client_id]);
$total_bookings = $stmt->fetchColumn();

$stmt = $pdo->prepare("SELECT COUNT(*) FROM bookings WHERE client_id = ? AND status = 'pending'");
$stmt->execute([$client_id]);
$pending_bookings = $stmt->fetchColumn();

$stmt = $pdo->prepare("SELECT COUNT(*) FROM quotations WHERE client_id = ? AND status = 'sent'");
$stmt->execute([$client_id]);
$pending_quotes = $stmt->fetchColumn();

$stmt = $pdo->prepare("SELECT COUNT(*) FROM messages WHERE receiver_id = ? AND is_read = 0");
$stmt->execute([$client_id]);
$unread_messages = $stmt->fetchColumn();

$stmt = $pdo->prepare("SELECT COUNT(*) FROM messages WHERE receiver_id = ? AND is_read = 0");
$stmt->execute([$client_id]);
$unread_alerts = $stmt->fetchColumn(); // reuse messages as "notifications" source too

$page_title = 'Portfolio';
$dash_role  = 'client';
$active     = 'dashboard';
$base       = '../';
include '../includes/header_dashboard.php';
?>

<div class="page-head">
    <div>
        <h2>Our Portfolio</h2>
        <p>Explore our work — South African weddings, party décor &amp; more.</p>
    </div>
    <a href="request-quote.php" class="btn btn-primary">📄 Request Quotation</a>
</div>

<p style="color:var(--text-muted);font-size:14px;margin-top:-6px;margin-bottom:18px;">Click any piece of work below to see more photos, customise it, and get an instant price estimate.</p>
<div class="grid grid-3" id="packageGrid">
    <div class="card package-card" style="padding:0;overflow:hidden;cursor:pointer;" onclick="openPackage('wedding')">
        <img src="https://images.unsplash.com/photo-1519741497674-611481863552?w=600" style="width:100%;height:230px;object-fit:cover;">
        <div style="padding:18px;">
            <span class="pill pill-quoted">Wedding</span>
            <h3 style="margin-top:12px;">Floral Arch Wedding</h3>
            <p style="color:var(--text-muted);font-size:13px;">Romantic white-wedding styling with a lush floral arch</p>
            <p style="color:var(--gold);font-weight:700;">From R 18 000</p>
            <span class="btn btn-outline btn-sm">View Package →</span>
        </div>
    </div>
    <div class="card package-card" style="padding:0;overflow:hidden;cursor:pointer;" onclick="openPackage('balloon')">
        <img src="https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=600" style="width:100%;height:230px;object-fit:cover;">
        <div style="padding:18px;">
            <span class="pill pill-quoted">Party</span>
            <h3 style="margin-top:12px;">Balloon Luxury Install</h3>
            <p style="color:var(--text-muted);font-size:13px;">Full balloon styling &amp; sculptures</p>
            <p style="color:var(--gold);font-weight:700;">From R 12 000</p>
            <span class="btn btn-outline btn-sm">View Package →</span>
        </div>
    </div>
    <div class="card package-card" style="padding:0;overflow:hidden;cursor:pointer;" onclick="openPackage('gala')">
        <img src="https://images.unsplash.com/photo-1511578314322-379afb476865?w=600" style="width:100%;height:230px;object-fit:cover;">
        <div style="padding:18px;">
            <span class="pill pill-quoted">Corporate</span>
            <h3 style="margin-top:12px;">Grand Ballroom Gala</h3>
            <p style="color:var(--text-muted);font-size:13px;">Full-scale corporate staging</p>
            <p style="color:var(--gold);font-weight:700;">From R 35 000</p>
            <span class="btn btn-outline btn-sm">View Package →</span>
        </div>
    </div>

    <!-- Extra packages, revealed by "Browse More" -->
    <div class="card package-card" style="padding:0;overflow:hidden;cursor:pointer;" onclick="openPackage('zulu')">
        <img src="https://images.unsplash.com/photo-1478146059778-26028b07395a?w=600" style="width:100%;height:230px;object-fit:cover;">
        <div style="padding:18px;">
            <span class="pill pill-quoted">Traditional</span>
            <h3 style="margin-top:12px;">Zulu Traditional Wedding</h3>
            <p style="color:var(--text-muted);font-size:13px;">Umembeso-inspired décor in red, yellow &amp; black</p>
            <p style="color:var(--gold);font-weight:700;">From R 22 000</p>
            <span class="btn btn-outline btn-sm">View Package →</span>
        </div>
    </div>
    <div class="card package-card more-package" style="display:none;padding:0;overflow:hidden;cursor:pointer;" onclick="openPackage('venda')">
        <img src="https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=600" style="width:100%;height:230px;object-fit:cover;">
        <div style="padding:18px;">
            <span class="pill pill-quoted">Traditional</span>
            <h3 style="margin-top:12px;">Venda Traditional Wedding</h3>
            <p style="color:var(--text-muted);font-size:13px;">Bold Minwenda-print styling &amp; beaded accents</p>
            <p style="color:var(--gold);font-weight:700;">From R 20 000</p>
            <span class="btn btn-outline btn-sm">View Package →</span>
        </div>
    </div>
    <div class="card package-card" style="padding:0;overflow:hidden;cursor:pointer;" onclick="openPackage('kids')">
        <img src="../assets/img/packages/kids-minnie-party.jpg" style="width:100%;height:230px;object-fit:cover;">
        <div style="padding:18px;">
            <span class="pill pill-quoted">Kids</span>
            <h3 style="margin-top:12px;">Kids' Wonderland Birthday</h3>
            <p style="color:var(--text-muted);font-size:13px;">Themed balloon backdrop, candy table &amp; more</p>
            <p style="color:var(--gold);font-weight:700;">From R 9 500</p>
            <span class="btn btn-outline btn-sm">View Package →</span>
        </div>
    </div>
    <div class="card package-card" style="padding:0;overflow:hidden;cursor:pointer;" onclick="openPackage('babyshower')">
        <img src="../assets/img/packages/gender-reveal-balloon-arches.jpg" style="width:100%;height:230px;object-fit:cover;">
        <div style="padding:18px;">
            <span class="pill pill-quoted">Party</span>
            <h3 style="margin-top:12px;">Garden Baby Shower</h3>
            <p style="color:var(--text-muted);font-size:13px;">Soft pastel florals &amp; a dreamy reveal backdrop</p>
            <p style="color:var(--gold);font-weight:700;">From R 8 500</p>
            <span class="btn btn-outline btn-sm">View Package →</span>
        </div>
    </div>
    <div class="card package-card more-package" style="display:none;padding:0;overflow:hidden;cursor:pointer;" onclick="openPackage('matric')">
        <img src="https://images.unsplash.com/photo-1511578314322-379afb476865?w=600" style="width:100%;height:230px;object-fit:cover;">
        <div style="padding:18px;">
            <span class="pill pill-quoted">Party</span>
            <h3 style="margin-top:12px;">Matric Dance &amp; Themed Parties</h3>
            <p style="color:var(--text-muted);font-size:13px;">Statement backdrop, uplighting &amp; a photo wall</p>
            <p style="color:var(--gold);font-weight:700;">From R 15 000</p>
            <span class="btn btn-outline btn-sm">View Package →</span>
        </div>
    </div>
    <div class="card package-card more-package" style="display:none;padding:0;overflow:hidden;cursor:pointer;" onclick="openPackage('castle')">
        <img src="https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=600" alt="Jumping Castles &amp; Play Zone" style="width:100%;height:230px;object-fit:cover;">
        <div style="padding:18px;">
            <span class="pill pill-quoted">Kids</span>
            <h3 style="margin-top:12px;">Jumping Castles &amp; Play Zone</h3>
            <p style="color:var(--text-muted);font-size:13px;">Bouncy castle hire, slides &amp; a supervised play area</p>
            <p style="color:var(--gold);font-weight:700;">From R 4 500</p>
            <span class="btn btn-outline btn-sm">View Package →</span>
        </div>
    </div>
    <div class="card package-card more-package" style="display:none;padding:0;overflow:hidden;cursor:pointer;" onclick="openPackage('chandelier')">
        <img src="../assets/img/packages/white-floral-ballroom.jpg" alt="Crystal Chandeliers &amp; Draping" style="width:100%;height:230px;object-fit:cover;">
        <div style="padding:18px;">
            <span class="pill pill-quoted">Lighting</span>
            <h3 style="margin-top:12px;">Crystal Chandeliers &amp; Draping</h3>
            <p style="color:var(--text-muted);font-size:13px;">Hanging crystal chandeliers with ceiling drapes &amp; warm glow</p>
            <p style="color:var(--gold);font-weight:700;">From R 16 000</p>
            <span class="btn btn-outline btn-sm">View Package →</span>
        </div>
    </div>
    <div class="card package-card more-package" style="display:none;padding:0;overflow:hidden;cursor:pointer;" onclick="openPackage('xhosa')">
        <img src="../assets/img/packages/blue-white-shweshwe-table.jpg" alt="Xhosa Traditional Wedding" style="width:100%;height:230px;object-fit:cover;">
        <div style="padding:18px;">
            <span class="pill pill-quoted">Traditional</span>
            <h3 style="margin-top:12px;">Traditional Setup - Shweshwe Blue &amp; White</h3>
            <p style="color:var(--text-muted);font-size:13px;">Shweshwe runners, royal-blue napkins, ghost chairs &amp; white tables</p>
            <p style="color:var(--gold);font-weight:700;">From R 21 000</p>
            <span class="btn btn-outline btn-sm">View Package →</span>
        </div>
    </div>
    <div class="card package-card more-package" style="display:none;padding:0;overflow:hidden;cursor:pointer;" onclick="openPackage('engagement')">
        <img src="../assets/img/packages/terracotta-lobola-lounge.jpg" alt="Engagement &amp; Lobola Celebration" style="width:100%;height:230px;object-fit:cover;">
        <div style="padding:18px;">
            <span class="pill pill-quoted">Wedding</span>
            <h3 style="margin-top:12px;">Lobola &amp; Engagement - Terracotta &amp; Gold</h3>
            <p style="color:var(--text-muted);font-size:13px;">Monogram arch backdrop, velvet couple lounge, woven baskets &amp; orange rose tables</p>
            <p style="color:var(--gold);font-weight:700;">From R 14 000</p>
            <span class="btn btn-outline btn-sm">View Package →</span>
        </div>
    </div>
    <div class="card package-card more-package" style="display:none;padding:0;overflow:hidden;cursor:pointer;" onclick="openPackage('birthday')">
        <img src="https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=600" alt="Milestone Birthday (21st &amp; 40th)" style="width:100%;height:230px;object-fit:cover;">
        <div style="padding:18px;">
            <span class="pill pill-quoted">Party</span>
            <h3 style="margin-top:12px;">Milestone Birthday (21st &amp; 40th)</h3>
            <p style="color:var(--text-muted);font-size:13px;">Statement balloon wall, neon sign, dessert table &amp; lounge seating</p>
            <p style="color:var(--gold);font-weight:700;">From R 13 500</p>
            <span class="btn btn-outline btn-sm">View Package →</span>
        </div>
    </div>
    <div class="card package-card more-package" style="display:none;padding:0;overflow:hidden;cursor:pointer;" onclick="openPackage('reveal')">
        <img src="../assets/img/packages/gender-reveal-pink-blue.jpg" alt="Gender Reveal Party" style="width:100%;height:230px;object-fit:cover;">
        <div style="padding:18px;">
            <span class="pill pill-quoted">Baby</span>
            <h3 style="margin-top:12px;">Gender Reveal Party</h3>
            <p style="color:var(--text-muted);font-size:13px;">Pink &amp; blue balloon arches, "Girl or Boy" backdrop, cake pedestals &amp; dessert stands</p>
            <p style="color:var(--gold);font-weight:700;">From R 7 500</p>
            <span class="btn btn-outline btn-sm">View Package →</span>
        </div>
    </div>
</div>
<div style="text-align:center;margin-top:22px;">
    <button type="button" class="btn btn-outline" id="browseMoreBtn" onclick="toggleMorePackages()">Browse More Packages ↓</button>
</div>

<!-- ============ Package detail / customise / quote modal ============ -->
<div id="packageModal" class="pkg-modal-backdrop" onclick="if(event.target===this) closePackage()">
    <div class="pkg-modal">
        <button type="button" class="pkg-modal-close" onclick="closePackage()">&times;</button>

        <div id="pkgStepView">
            <h2 id="pkgTitle" style="margin-bottom:4px;"></h2>
            <p id="pkgDesc" style="color:var(--text-muted);margin-bottom:16px;"></p>
            <div class="grid grid-3" id="pkgGallery" style="margin-bottom:22px;"></div>

            <h4 style="margin-bottom:10px;">Customise Your Theme</h4>
            <div class="form-grid">
                <div class="field">
                    <label>Colour Theme</label>
                    <select id="pkgTheme">
                        <option value="0">Classic White &amp; Gold</option>
                        <option value="1500">Blush &amp; Ivory (+R 1,500)</option>
                        <option value="1500">Emerald &amp; Gold (+R 1,500)</option>
                        <option value="2200">Black &amp; Gold Luxe (+R 2,200)</option>
                    </select>
                </div>
                <div class="field">
                    <label>Guest Count</label>
                    <input type="number" id="pkgGuests" value="100" min="10">
                </div>
            </div>
            <div class="field">
                <label>Add-ons</label>
                <label style="display:flex;align-items:center;gap:8px;font-weight:400;text-transform:none;font-size:14px;margin-bottom:6px;"><input type="checkbox" class="pkg-addon" value="3500" data-label="Fresh floral upgrade"> Fresh floral upgrade (+R 3,500)</label>
                <label style="display:flex;align-items:center;gap:8px;font-weight:400;text-transform:none;font-size:14px;margin-bottom:6px;"><input type="checkbox" class="pkg-addon" value="2800" data-label="Fairy light canopy"> Fairy light canopy (+R 2,800)</label>
                <label style="display:flex;align-items:center;gap:8px;font-weight:400;text-transform:none;font-size:14px;"><input type="checkbox" class="pkg-addon" value="1900" data-label="Photo backdrop wall"> Photo backdrop wall (+R 1,900)</label>
            </div>

            <button type="button" class="btn btn-primary btn-block" style="margin-top:18px;" onclick="calculateQuote()">Get Quote Breakdown</button>
        </div>

        <div id="pkgStepQuote" style="display:none;">
            <h2 style="margin-bottom:16px;">Your Quote Breakdown</h2>
            <div class="table-wrap" style="margin-bottom:20px;">
                <table class="data-table" id="pkgBreakdownTable"></table>
            </div>
            <div style="display:flex;justify-content:space-between;align-items:center;padding:14px 18px;background:var(--cream);border-radius:var(--radius);margin-bottom:20px;">
                <strong>Estimated Total</strong>
                <strong id="pkgTotal" style="font-size:20px;color:var(--gold);"></strong>
            </div>
            <div style="display:flex;gap:12px;">
                <button type="button" class="btn btn-outline btn-block" onclick="backToCustomise()">&larr; Back</button>
                <button type="button" class="btn btn-primary btn-block" onclick="submitPackageQuote()">Submit Quote Request</button>
            </div>
        </div>
    </div>
</div>

<script>
const PACKAGES = {
    wedding: {
        title: 'Floral Arch Wedding',
        desc: 'A romantic South African wedding setup featuring a lush floral arch as the ceremony centrepiece, elegant table styling with fine china and soft candlelight, and warm ambient lighting strung through the reception space for an unforgettable golden-hour glow.',
        base: 18000,
        images: [
            'https://images.unsplash.com/photo-1519741497674-611481863552?w=500',
            'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=500',
            'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=500'
        ]
    },
    balloon: {
        title: 'Balloon Luxury Install',
        desc: 'Bold, colourful organic balloon garlands and sculptural installs built around your chosen palette, perfect for birthdays, gender reveals, product launches and playful celebrations that need a real "wow" moment for photos.',
        base: 12000,
        images: [
            'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=500',
            'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=500',
            'https://images.unsplash.com/photo-1478146059778-26028b07395a?w=500'
        ]
    },
    gala: {
        title: 'Grand Ballroom Gala',
        desc: 'Full-scale corporate staging with dramatic uplighting, a branded stage backdrop, premium linens and centrepieces, and coordinated seating layouts designed for galas, award nights, product launches and conferences.',
        base: 35000,
        images: [
            'https://images.unsplash.com/photo-1511578314322-379afb476865?w=500',
            'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=500',
            'https://images.unsplash.com/photo-1519741497674-611481863552?w=500'
        ]
    },
    zulu: {
        title: 'Zulu Traditional Wedding',
        desc: 'A vibrant Umembeso-inspired setup honouring Zulu heritage through the bold red, yellow, black and blue of the Zulu flag — beaded table runners and centrepiece accents, animal-print styling touches, woven grass mats, and a dedicated staging table for the traditional gift display and lobola ceremony.',
        base: 22000,
        images: [
            'https://images.unsplash.com/photo-1478146059778-26028b07395a?w=500',
            'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=500',
            'https://images.unsplash.com/photo-1511578314322-379afb476865?w=500'
        ]
    },
    venda: {
        title: 'Venda Traditional Wedding',
        desc: 'An elegant tribute to Venda heritage built around bold, intricately patterned Minwenda-print drapes and table runners in red, yellow and blue, paired with beaded centrepiece accents echoing the bride\'s traditional headpiece, and warm earthy lighting for an authentic ceremonial atmosphere.',
        base: 20000,
        images: [
            'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=500',
            'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=500',
            'https://images.unsplash.com/photo-1519741497674-611481863552?w=500'
        ]
    },
    kids: {
        title: "Kids' Wonderland Birthday",
        desc: 'A playful wonderland built around your child\'s favourite theme — from safari to superheroes to princesses — with a colourful balloon backdrop wall, a styled candy and dessert table, themed table settings, and fun photo props for the little guests.',
        base: 9500,
        images: [
            '../assets/img/packages/kids-minnie-party.jpg',
            'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=500',
            'https://images.unsplash.com/photo-1478146059778-26028b07395a?w=500'
        ]
    },
    babyshower: {
        title: 'Garden Baby Shower',
        desc: 'A soft, romantic garden-style setup with pastel floral arrangements, a beautifully styled dessert and favours table, elegant seating for guests, and a dreamy photo-worthy backdrop for the gender reveal or baby shower moment.',
        base: 8500,
        images: [
            '../assets/img/packages/gender-reveal-balloon-arches.jpg',
            '../assets/img/packages/gender-reveal-pink-blue.jpg'
        ]
    },
    matric: {
        title: 'Matric Dance & Themed Parties',
        desc: 'Bold, modern styling built for milestone celebrations — a statement backdrop for entrance photos, dramatic coloured uplighting, a relaxed lounge area with styled seating, and a dedicated photo wall to make the night unforgettable.',
        base: 15000,
        images: [
            'https://images.unsplash.com/photo-1511578314322-379afb476865?w=500',
            'https://images.unsplash.com/photo-1511578314322-379afb476865?w=500',
            'https://images.unsplash.com/photo-1519741497674-611481863552?w=500'
        ]
    },
    castle: {
        title: 'Jumping Castles & Play Zone',
        desc: 'A full play zone for kids built around bright, safe inflatable jumping castles with soft-play flooring, an optional slide combo, a styled party table with balloons, and a dedicated supervisor to keep the little ones safe and the parents relaxed. Sized to suit gardens, halls and school events.',
        base: 4500,
        images: [
            'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=500',
            'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=500',
            'https://images.unsplash.com/photo-1478146059778-26028b07395a?w=500'
        ]
    },
    chandelier: {
        title: 'Crystal Chandeliers & Draping',
        desc: 'Statement hanging crystal chandeliers set against flowing white or ivory ceiling drapes, with warm lighting that turns any hall, marquee or tent into a ballroom. Ideal for weddings, galas and formal dinners, and installed and taken down safely by our rigging team.',
        base: 16000,
        images: [
            '../assets/img/packages/white-floral-ballroom.jpg',
            'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=500',
            'https://images.unsplash.com/photo-1519741497674-611481863552?w=500'
        ]
    },
    xhosa: {
        title: 'Traditional Setup - Shweshwe Blue &amp; White',
        desc: 'A fresh blue-and-white traditional table setup built around Shweshwe-print table runners: long white tables, royal-blue napkins, pearl-rim charger plates, crystal glassware, small floral posies, clear ghost chairs and white lounge seating on a neat grass-mat floor. Ideal for traditional weddings, umembeso, engagement lunches and family celebrations.',
        base: 21000,
        images: [
            '../assets/img/packages/blue-white-shweshwe-table.jpg'
        ]
    },
    engagement: {
        title: 'Lobola &amp; Engagement - Terracotta &amp; Gold',
        desc: 'A warm terracotta-and-gold setup for lobola negotiations and engagement celebrations: a velvet couple lounge in front of a monogrammed arch backdrop with woven basket wall art, long family tables with rattan placemats and gold cutlery, orange rose centrepieces, pampas grass and candelabras inside a draped marquee.',
        base: 14000,
        images: [
            '../assets/img/packages/terracotta-lobola-lounge.jpg',
            '../assets/img/packages/terracotta-long-table.jpg'
        ]
    },
    birthday: {
        title: 'Milestone Birthday (21st & 40th)',
        desc: 'Make the big birthday count: a statement balloon wall with a custom neon sign, a styled dessert and drinks table, lounge seating, a photo area and a colour palette of your choice, all set up and packed down for you.',
        base: 13500,
        images: [
            'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=500',
            'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=500',
            'https://images.unsplash.com/photo-1511578314322-379afb476865?w=500'
        ]
    },
    reveal: {
        title: 'Gender Reveal Party',
        desc: 'A playful pink-and-blue reveal setup: a split pastel backdrop with a "Girl or Boy" sign, organic balloon arches in pink, blue and cream with flower and sparkle accents, white cylinder pedestals with cake, cake pops and dessert stands, and a photo-ready corner for the big moment. Can be set up in a garden, hall or tent.',
        base: 7500,
        images: [
            '../assets/img/packages/gender-reveal-pink-blue.jpg',
            '../assets/img/packages/gender-reveal-balloon-arches.jpg'
        ]
    }
};
document.addEventListener('DOMContentLoaded', function () {
    // if a package photo fails to load, show a soft placeholder instead of a broken image
    document.querySelectorAll('#packageGrid img').forEach(function (img) {
        img.addEventListener('error', function () { img.src = '../assets/img/hero-bg.jpg'; }, { once: true });
    });
});
let currentPkg = null;
let morePackagesShown = false;

function toggleMorePackages() {
    morePackagesShown = !morePackagesShown;
    document.querySelectorAll('.more-package').forEach(card => {
        card.style.display = morePackagesShown ? '' : 'none';
        if (morePackagesShown) {
            // trigger the same fade/slide-in treatment used across the site
            card.classList.add('reveal');
            requestAnimationFrame(() => requestAnimationFrame(() => card.classList.add('in-view')));
        }
    });
    document.getElementById('browseMoreBtn').textContent = morePackagesShown
        ? 'Show Fewer Packages ↑'
        : 'Browse More Packages ↓';
}

function openPackage(key) {
    currentPkg = key;
    const p = PACKAGES[key];
    document.getElementById('pkgTitle').textContent = p.title;
    document.getElementById('pkgDesc').textContent = p.desc;
    document.getElementById('pkgGallery').innerHTML = p.images.map(src =>
        `<img src="${src}" style="width:100%;height:130px;object-fit:cover;border-radius:8px;">`
    ).join('');
    document.getElementById('pkgStepView').style.display = 'block';
    document.getElementById('pkgStepQuote').style.display = 'none';
    document.getElementById('packageModal').classList.add('open');
}
function closePackage() {
    document.getElementById('packageModal').classList.remove('open');
}
function calculateQuote() {
    const p = PACKAGES[currentPkg];
    const themeSelect = document.getElementById('pkgTheme');
    const themeCost = Number(themeSelect.value) || 0;
    const themeLabel = themeSelect.options[themeSelect.selectedIndex].text.replace(/\s*\(\+.*\)/, '');
    const guests = Number(document.getElementById('pkgGuests').value) || 0;
    const addons = Array.from(document.querySelectorAll('.pkg-addon:checked'));

    let rows = `<tr><th>Item</th><th>Amount</th></tr>`;
    rows += `<tr><td>${p.title} (base package)</td><td>R ${p.base.toLocaleString()}</td></tr>`;
    rows += `<tr><td>Theme: ${themeLabel}</td><td>${themeCost ? 'R ' + themeCost.toLocaleString() : 'Included'}</td></tr>`;
    let total = p.base + themeCost;
    addons.forEach(a => {
        rows += `<tr><td>${a.dataset.label}</td><td>R ${Number(a.value).toLocaleString()}</td></tr>`;
        total += Number(a.value);
    });
    if (guests > 100) {
        const extraGuestFee = (guests - 100) * 45;
        rows += `<tr><td>Extra guests (${guests - 100} beyond 100)</td><td>R ${extraGuestFee.toLocaleString()}</td></tr>`;
        total += extraGuestFee;
    }
    document.getElementById('pkgBreakdownTable').innerHTML = rows;
    document.getElementById('pkgTotal').textContent = 'R ' + total.toLocaleString();
    document.getElementById('pkgStepView').style.display = 'none';
    document.getElementById('pkgStepQuote').style.display = 'block';
    window._pkgTotal = total;
    window._pkgGuests = guests;
    window._pkgThemeLabel = themeLabel;
    window._pkgAddonLabels = addons.map(a => a.dataset.label).join(', ');
}
function backToCustomise() {
    document.getElementById('pkgStepView').style.display = 'block';
    document.getElementById('pkgStepQuote').style.display = 'none';
}
function submitPackageQuote() {
    const p = PACKAGES[currentPkg];
    const notes = `Theme: ${window._pkgThemeLabel}. Add-ons: ${window._pkgAddonLabels || 'None'}. Estimated total: R ${window._pkgTotal.toLocaleString()}.`;
    const params = new URLSearchParams({
        package: currentPkg,
        event_type: p.title,
        guest_count: window._pkgGuests,
        notes: notes
    });
    window.location.href = 'request-quote.php?' + params.toString();
}
</script>

<h3 style="margin:34px 0 16px 0;">My Recent Bookings</h3>
<div class="table-wrap">
<table class="data-table">
    <tr><th>Event Type</th><th>Date</th><th>Venue</th><th>Status</th></tr>
    <?php
    $stmt = $pdo->prepare('SELECT * FROM bookings WHERE client_id = ? ORDER BY created_at DESC LIMIT 5');
    $stmt->execute([$client_id]);
    $bookings = $stmt->fetchAll();
    ?>
    <?php if (empty($bookings)): ?>
        <tr><td colspan="4" class="empty-state">You haven't made any booking requests yet. <a href="request-quote.php">Request a quotation</a> to get started.</td></tr>
    <?php else: foreach ($bookings as $b): ?>
        <tr>
            <td><?php echo h($b['event_type']); ?></td>
            <td><?php echo nice_date($b['event_date']); ?></td>
            <td><?php echo h($b['venue']); ?></td>
            <td>
                <?php if ($b['status'] === 'confirmed'): ?>
                    <a href="pay-deposit.php?booking_id=<?php echo (int)$b['booking_id']; ?>" class="pill pill-pending" style="cursor:pointer;">Pending Deposit →</a>
                <?php else: ?>
                    <span class="pill pill-<?php echo h($b['status']); ?>"><?php echo ucfirst(h($b['status'])); ?></span>
                <?php endif; ?>
            </td>
        </tr>
    <?php endforeach; endif; ?>
</table>
</div>

<div class="stat-list" style="margin-top:36px;">
    <div class="stat-row accent-blue">
        <div class="stat-ico"><?php echo nav_icon_svg('<path d="M21 8 12 3 3 8l9 5 9-5Z"/><path d="M3 8v8l9 5 9-5V8"/><path d="M12 13v8"/>'); ?></div>
        <div><div class="stat-label">Active Bookings</div><div class="stat-sub">Your confirmed &amp; quoted events</div></div>
        <div class="stat-num"><?php echo (int)$total_bookings; ?></div>
    </div>
    <div class="stat-row accent-orange">
        <div class="stat-ico"><?php echo nav_icon_svg('<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 3"/>'); ?></div>
        <div><div class="stat-label">Pending Requests</div><div class="stat-sub">Waiting for a quotation</div></div>
        <div class="stat-num"><?php echo (int)$pending_bookings; ?></div>
    </div>
    <div class="stat-row accent-green">
        <div class="stat-ico"><?php echo nav_icon_svg('<path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M17 21H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h7l5 5v11a2 2 0 0 1-2 2Z"/><path d="M9 13h6M9 17h6"/>'); ?></div>
        <div><div class="stat-label">Quotations Awaiting Approval</div><div class="stat-sub">Download opens once approved</div></div>
        <div class="stat-num"><?php echo (int)$pending_quotes; ?></div>
    </div>
</div>

<?php include '../includes/footer_dashboard.php'; ?>
