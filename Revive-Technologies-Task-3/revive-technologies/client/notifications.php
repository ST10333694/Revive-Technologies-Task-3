<?php
/**
 * client/notifications.php
 * In-app notifications for this client: quotation approved / declined,
 * quotation updated, freelancer assigned, job completed, etc.
 * Rows are written by notify() in includes/functions.php whenever
 * something about the client's order changes.
 */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_role('client');
require_once '../includes/alerts_ui.php';

$client_id = $_SESSION['user_id'];

if (isset($_GET['mark_all_read'])) {
    $stmt = $pdo->prepare('UPDATE notifications SET is_read = 1 WHERE user_id = ?');
    $stmt->execute([$client_id]);
    redirect('notifications.php');
}

$view = $_GET['view'] ?? '';
alerts_mark_viewed($pdo, $view);

$stmt = $pdo->prepare('SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC, notification_id DESC LIMIT 50');
$stmt->execute([$client_id]);
$alerts = [];
$unread_count = 0;
foreach ($stmt->fetchAll() as $n) {
    if (!$n['is_read']) $unread_count++;
    $alerts[] = ['key' => 'n' . $n['notification_id'], 'icon' => '🔔', 'title' => $n['title'], 'detail' => $n['message'],
                 'time' => $n['created_at'], 'unread' => !$n['is_read'], 'link' => $n['link']];
}

$page_title = 'Notifications';
$dash_role  = 'client';
$active     = 'alerts';
$base       = '../';
include '../includes/header_dashboard.php';
?>

<div class="page-head">
    <div>
        <h2>Notifications</h2>
        <p><?php echo $unread_count; ?> unread &middot; <?php echo count($alerts); ?> update(s) &middot; click one to read the full message</p>
    </div>
    <a href="?mark_all_read=1" class="btn btn-outline btn-sm">Mark all read</a>
</div>

<?php render_alerts($alerts, $view, 'client', "No notifications yet. We'll let you know here when your quotation is approved or anything changes on your order."); ?>

<?php include '../includes/footer_dashboard.php'; ?>
