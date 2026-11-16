<?php
/**
 * freelancer/alerts.php
 * Activity feed built from real payment and booking data.
 */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_role('freelancer');
require_once '../includes/alerts_ui.php';

$user_id = $_SESSION['user_id'];
$stmt = $pdo->prepare('SELECT * FROM freelancers WHERE user_id = ?');
$stmt->execute([$user_id]);
$freelancer = $stmt->fetch();
$freelancer_id = $freelancer['freelancer_id'] ?? 0;

if (isset($_GET['mark_all_read'])) {
    $stmt = $pdo->prepare("UPDATE messages SET is_read = 1 WHERE receiver_id = ?");
    $stmt->execute([$user_id]);
    $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = ?")->execute([$user_id]);
    redirect('alerts.php');
}

$view = $_GET['view'] ?? '';
alerts_mark_viewed($pdo, $view);

$alerts = [];

// Saved notifications (application approved / rejected, etc.)
$stmt = $pdo->prepare('SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 30');
$stmt->execute([$user_id]);
foreach ($stmt->fetchAll() as $n) {
    $alerts[] = ['key' => 'n' . $n['notification_id'], 'icon' => '🔔', 'title' => $n['title'], 'detail' => $n['message'],
                 'time' => $n['created_at'], 'unread' => !$n['is_read'], 'link' => $n['link']];
}

$stmt = $pdo->prepare("SELECT * FROM payments WHERE freelancer_id = ? ORDER BY claim_date DESC LIMIT 5");
$stmt->execute([$freelancer_id]);
foreach ($stmt->fetchAll() as $p) {
    $alerts[] = [
        'key'    => 'p' . $p['payment_id'],
        'icon'   => $p['status'] === 'approved' ? '✅' : ($p['status'] === 'rejected' ? '❌' : '⏳'),
        'title'  => 'Payment ' . ucfirst($p['status']),
        'detail' => 'Your ' . rand_format($p['amount']) . ' payment claim is ' . $p['status'] . '.',
        'time'   => $p['claim_date'], 'unread' => false, 'link' => 'earnings.php',
    ];
}

$stmt = $pdo->query("SELECT * FROM bookings WHERE freelancer_id IS NULL AND status = 'pending' ORDER BY created_at DESC LIMIT 3");
foreach ($stmt->fetchAll() as $b) {
    $alerts[] = [
        'key' => 'b' . $b['booking_id'], 'icon' => '🔔', 'title' => 'New job available',
        'detail' => $b['event_type'] . ' on ' . nice_date($b['event_date']) . ' in ' . ($b['venue'] ?: 'TBC') . '. Open Available Jobs to apply.',
        'time' => $b['created_at'], 'unread' => false, 'link' => 'available-jobs.php',
    ];
}

usort($alerts, fn($a, $b) => strtotime($b['time']) <=> strtotime($a['time']));

$page_title = 'Alerts';
$dash_role  = 'freelancer';
$active     = 'alerts';
$base       = '../';
include '../includes/header_dashboard.php';
?>

<div class="page-head">
    <div><h2>Alerts</h2><p><?php echo count($alerts); ?> recent update(s)</p></div>
    <a href="?mark_all_read=1" class="btn btn-outline btn-sm">Mark all read</a>
</div>

<?php render_alerts($alerts, $view, 'freelancer', 'No alerts right now.'); ?>

<?php include '../includes/footer_dashboard.php'; ?>
