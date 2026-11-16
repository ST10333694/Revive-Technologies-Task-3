<?php
/**
 * admin/alerts.php
 * Business-wide activity feed: new quotation requests, freelancer
 * applications, payments received, and upcoming events.
 */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_role('admin');
require_once '../includes/alerts_ui.php';

if (isset($_GET['mark_all_read'])) {
    $stmt = $pdo->prepare("UPDATE messages SET is_read = 1 WHERE receiver_id = ?");
    $stmt->execute([$_SESSION['user_id']]);
    $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = ?");
    $stmt->execute([$_SESSION['user_id']]);
    redirect('alerts.php');
}

$view = $_GET['view'] ?? '';
alerts_mark_viewed($pdo, $view);

$alerts = [];

// Saved notifications (new requests from clients, freelancer applications, etc.)
$stmt = $pdo->prepare('SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 30');
$stmt->execute([$_SESSION['user_id']]);
foreach ($stmt->fetchAll() as $n) {
    $alerts[] = ['key' => 'n' . $n['notification_id'], 'icon' => '🔔', 'title' => $n['title'], 'detail' => $n['message'],
                 'time' => $n['created_at'], 'unread' => !$n['is_read'], 'link' => $n['link']];
}

$stmt = $pdo->query(
    "SELECT p.*, u.full_name FROM payments p
     JOIN freelancers f ON p.freelancer_id = f.freelancer_id JOIN users u ON f.user_id = u.user_id
     WHERE p.status = 'pending' ORDER BY p.claim_date DESC LIMIT 5"
);
foreach ($stmt->fetchAll() as $p) {
    $alerts[] = ['key' => 'p' . $p['payment_id'], 'icon' => '💲', 'title' => 'Payment claim received',
                 'detail' => $p['full_name'] . ' submitted a claim for ' . rand_format($p['amount']) . '. Open Freelancers to approve or reject it.',
                 'time' => $p['claim_date'], 'unread' => false, 'link' => 'freelancers.php'];
}

$stmt = $pdo->query("SELECT * FROM inventory WHERE available_stock < total_stock * 0.25 LIMIT 5");
foreach ($stmt->fetchAll() as $i) {
    $alerts[] = ['key' => 's' . $i['item_id'], 'icon' => '⚠️', 'title' => 'Critical stock level',
                 'detail' => $i['item_name'] . ' is critically low (' . (int)$i['available_stock'] . ' left).',
                 'time' => $i['updated_at'], 'unread' => false, 'link' => 'inventory.php'];
}

usort($alerts, fn($a, $b) => strtotime($b['time']) <=> strtotime($a['time']));

$page_title = 'Alerts';
$dash_role  = 'admin';
$active     = 'alerts';
$base       = '../';
include '../includes/header_dashboard.php';
?>

<div class="page-head">
    <div><h2>Notifications</h2><p><?php echo count($alerts); ?> recent update(s)</p></div>
    <a href="?mark_all_read=1" class="btn btn-outline btn-sm">Mark all read</a>
</div>

<?php render_alerts($alerts, $view, 'admin', 'No notifications right now.'); ?>

<?php include '../includes/footer_dashboard.php'; ?>
