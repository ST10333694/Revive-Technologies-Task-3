<?php
/**
 * includes/header_dashboard.php
 * Shared topbar for the Client / Freelancer / Admin portals.
 * Reads: $page_title, $dash_role, $active, $base, and optionally $unread_messages / $unread_alerts.
 */
$nav_items = [
    'client' => [
        'dashboard'   => ['label' => 'Portfolio',        'href' => 'dashboard.php'],
        'submit'      => ['label' => 'Submit Design',    'href' => 'submit-design.php'],
        'invitations' => ['label' => 'Invitation Cards', 'href' => 'invitations.php'],
        'quotations'  => ['label' => 'My Quotations',    'href' => 'quotations.php'],
        'messages'    => ['label' => 'Messages',         'href' => 'messages.php'],
        'alerts'      => ['label' => 'Notifications',    'href' => 'notifications.php'],
        'quote'       => ['label' => 'Request Quote',    'href' => 'request-quote.php'],
        'profile'     => ['label' => 'My Profile',       'href' => 'profile.php'],
    ],
    'freelancer' => [
        'dashboard' => ['label' => 'Dashboard',      'href' => 'dashboard.php'],
        'available' => ['label' => 'Available Jobs', 'href' => 'available-jobs.php'],
        'myjobs'    => ['label' => 'My Jobs',        'href' => 'my-jobs.php'],
        'messages'  => ['label' => 'Messages',       'href' => 'messages.php'],
        'alerts'    => ['label' => 'Notifications',  'href' => 'alerts.php'],
        'earnings'  => ['label' => 'Earnings',       'href' => 'earnings.php'],
        'profile'   => ['label' => 'My Profile',     'href' => 'profile.php'],
    ],
    'admin' => [
        'dashboard'   => ['label' => 'Dashboard',     'href' => 'dashboard.php'],
        'quotations'  => ['label' => 'Quotations',    'href' => 'quotations.php'],
        'invitations' => ['label' => 'Invitation Cards', 'href' => 'invitations.php'],
        'inventory'   => ['label' => 'Inventory',     'href' => 'inventory.php'],
        'calendar'    => ['label' => 'Calendar',      'href' => 'calendar.php'],
        'freelancers' => ['label' => 'Freelancers',   'href' => 'freelancers.php'],
        'messages'    => ['label' => 'Messages',      'href' => 'messages.php'],
        'alerts'      => ['label' => 'Notifications', 'href' => 'alerts.php'],
        'profile'     => ['label' => 'My Profile',    'href' => 'profile.php'],
    ],
];

// The four pill buttons shown directly in the bar. Everything else lives in the Menu dropdown.
$nav_primary = [
    'client'     => ['dashboard', 'messages', 'alerts', 'profile'],
    'freelancer' => ['dashboard', 'messages', 'alerts', 'profile'],
    'admin'      => ['dashboard', 'quotations', 'messages', 'alerts'],
];

// Live badge counts (unread messages + unread notifications) for whoever is logged in.
if (isset($pdo) && isset($_SESSION['user_id'])) {
    $stmt = $pdo->prepare('SELECT COUNT(*) FROM messages WHERE receiver_id = ? AND is_read = 0');
    $stmt->execute([$_SESSION['user_id']]);
    $unread_messages = (int)$stmt->fetchColumn();
    $stmt = $pdo->prepare('SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0');
    $stmt->execute([$_SESSION['user_id']]);
    $unread_alerts = (int)$stmt->fetchColumn();
}
$unread_messages = $unread_messages ?? 0;
$unread_alerts   = $unread_alerts   ?? 0;

$portal_labels = ['client' => 'Client Portal', 'freelancer' => 'Freelancer Portal', 'admin' => 'Admin'];

// Small inline icon (24x24 stroke icons) shown before each nav label.
$nav_icons = [
    'dashboard'   => '<path d="M3 9.5 12 3l9 6.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1V9.5Z"/>',
    'submit'      => '<path d="M12 16V4M12 4 7 9M12 4l5 5"/><path d="M4 16v3a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-3"/>',
    'invitations' => '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/>',
    'messages'    => '<path d="M21 11.5a8.38 8.38 0 0 1-8.5 8.5 8.5 8.5 0 0 1-4-1L3 20l1-4.5A8.38 8.38 0 0 1 21 11.5Z"/>',
    'alerts'      => '<path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/>',
    'quote'       => '<path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M17 21H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h7l5 5v11a2 2 0 0 1-2 2Z"/><path d="M9 13h6M9 17h6"/>',
    'available'   => '<rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>',
    'myjobs'      => '<rect x="3" y="3" width="18" height="18" rx="2"/><path d="m8 12 3 3 5-6"/>',
    'earnings'    => '<circle cx="12" cy="12" r="9"/><path d="M12 7v10M9 9.5c0-1.2 1.2-2 3-2s3 .8 3 2-1.2 1.5-3 2-3 .9-3 2.1 1.3 1.9 3 1.9 3-.7 3-1.9"/>',
    'quotations'  => '<path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M17 21H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h7l5 5v11a2 2 0 0 1-2 2Z"/><path d="M9 13h6M9 17h6"/>',
    'inventory'   => '<path d="M21 8 12 3 3 8l9 5 9-5Z"/><path d="M3 8v8l9 5 9-5V8"/><path d="M12 13v8"/>',
    'calendar'    => '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18"/>',
    'profile'     => '<circle cx="12" cy="8" r="3.6"/><path d="M4.5 20.5a7.5 7.5 0 0 1 15 0"/>',
    'logout'      => '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5M21 12H9"/>',
    'freelancers' => '<circle cx="9" cy="8" r="3.2"/><path d="M3.5 20a5.5 5.5 0 0 1 11 0"/><circle cx="17.5" cy="9.5" r="2.6"/><path d="M15.2 13.2a4.6 4.6 0 0 1 6.3 4.3"/>',
];
function nav_icon_svg($markup) {
    return '<svg class="nav-icon" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' . $markup . '</svg>';
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?php echo h($page_title ?? 'Dashboard'); ?> - Bee's Events & Decor</title>
<link rel="stylesheet" href="<?php echo $base; ?>assets/css/style.css">
</head>
<body class="dash-page role-<?php echo h($dash_role); ?>">
<div class="dash-bg" aria-hidden="true" style="background-image:url('<?php echo $base; ?>assets/img/hero-bg.jpg');"></div>

<?php $who = $dash_role === 'admin' ? 'Admin' : trim($_SESSION['full_name'] ?? ''); ?>
<div class="dash-topbar">
    <div class="container">
        <a class="dash-brand" href="dashboard.php">
            <span class="dash-logo-tile"><img src="<?php echo $base; ?>assets/img/logo-icon.png" alt="Bee's Events & Decor"></span>
            <span class="dash-brand-divider"></span>
            <span class="dash-brand-text">
                <span class="dash-brand-name">Bee's Events</span>
                <span class="dash-brand-sub">&amp; Décor &middot; <?php echo h($who); ?></span>
            </span>
        </a>

        <div class="dash-nav">
            <?php foreach ($nav_primary[$dash_role] as $key): $item = $nav_items[$dash_role][$key]; ?>
                <a href="<?php echo h($item['href']); ?>" class="nav-pill <?php echo $active === $key ? 'active' : ''; ?>">
                    <?php echo nav_icon_svg($nav_icons[$key] ?? ''); ?>
                    <?php echo h($item['label']); ?>
                    <?php if ($key === 'messages' && $unread_messages > 0): ?><span class="badge-count"><?php echo (int)$unread_messages; ?></span><?php endif; ?>
                    <?php if ($key === 'alerts' && $unread_alerts > 0): ?><span class="badge-count"><?php echo (int)$unread_alerts; ?></span><?php endif; ?>
                </a>
            <?php endforeach; ?>
        </div>

        <div class="menu-wrap">
            <button type="button" class="menu-btn" id="menuBtn" aria-haspopup="true" aria-expanded="false" aria-controls="menuPanel">
                <svg class="icon-open" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 7h16M4 12h16M4 17h16"/></svg>
                <svg class="icon-close" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>
                Menu
                <?php if (($unread_messages + $unread_alerts) > 0): ?><span class="menu-dot"></span><?php endif; ?>
            </button>
            <div class="menu-panel" id="menuPanel" role="menu">
                <?php foreach ($nav_items[$dash_role] as $key => $item): ?>
                    <a href="<?php echo h($item['href']); ?>" role="menuitem" class="<?php echo $active === $key ? 'active' : ''; ?>">
                        <?php echo nav_icon_svg($nav_icons[$key] ?? ''); ?>
                        <span><?php echo h($item['label']); ?></span>
                        <?php if ($key === 'messages' && $unread_messages > 0): ?><span class="badge-count"><?php echo (int)$unread_messages; ?></span><?php endif; ?>
                        <?php if ($key === 'alerts' && $unread_alerts > 0): ?><span class="badge-count"><?php echo (int)$unread_alerts; ?></span><?php endif; ?>
                    </a>
                <?php endforeach; ?>
                <div class="menu-sep"></div>
                <a href="<?php echo $base; ?>auth/logout.php" role="menuitem" class="menu-logout">
                    <?php echo nav_icon_svg($nav_icons['logout']); ?>
                    <span>Logout</span>
                </a>
            </div>
        </div>
    </div>
</div>

<div class="dash-body">
<div class="container">

<?php $flash = get_flash(); ?>
<?php if ($flash): ?>
    <div class="alert alert-<?php echo $flash['type'] === 'error' ? 'error' : 'success'; ?>">
        <?php echo h($flash['message']); ?>
    </div>
<?php endif; ?>
