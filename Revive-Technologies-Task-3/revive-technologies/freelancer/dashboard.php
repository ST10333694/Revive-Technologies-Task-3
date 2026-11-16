<?php
/**
 * freelancer/dashboard.php
 * Overview stats: total earned, jobs completed, upcoming jobs, rating.
 */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_role('freelancer');

$user_id = $_SESSION['user_id'];

$stmt = $pdo->prepare('SELECT * FROM freelancers WHERE user_id = ?');
$stmt->execute([$user_id]);
$freelancer = $stmt->fetch();
$freelancer_id = $freelancer['freelancer_id'] ?? 0;

$stmt = $pdo->prepare("SELECT COALESCE(SUM(amount),0) FROM payments WHERE freelancer_id = ? AND status = 'approved'");
$stmt->execute([$freelancer_id]);
$total_earned = $stmt->fetchColumn();

$stmt = $pdo->prepare("SELECT COUNT(*) FROM bookings WHERE freelancer_id = ? AND status = 'completed'");
$stmt->execute([$freelancer_id]);
$jobs_completed = $stmt->fetchColumn();

$stmt = $pdo->prepare("SELECT COUNT(*) FROM bookings WHERE freelancer_id = ? AND status = 'confirmed' AND event_date >= CURDATE()");
$stmt->execute([$freelancer_id]);
$upcoming_jobs = $stmt->fetchColumn();

$stmt = $pdo->prepare(
    "SELECT b.*, u.full_name AS client_name FROM bookings b
     JOIN users u ON b.client_id = u.user_id
     WHERE b.freelancer_id = ? AND b.status = 'confirmed' AND b.event_date >= CURDATE()
     ORDER BY b.event_date ASC LIMIT 5"
);
$stmt->execute([$freelancer_id]);
$upcoming_list = $stmt->fetchAll();

$stmt = $pdo->prepare("SELECT COUNT(*) FROM messages WHERE receiver_id = ? AND is_read = 0");
$stmt->execute([$user_id]);
$unread_messages = $stmt->fetchColumn();
$unread_alerts = $unread_messages;

$page_title = 'Dashboard';
$dash_role  = 'freelancer';
$active     = 'dashboard';
$base       = '../';
include '../includes/header_dashboard.php';
?>

<h2>Dashboard</h2>
<p style="color:var(--text-muted);margin-bottom:24px;">Here's an overview of your activity.</p>

<div class="stat-list">
    <div class="stat-row accent-green">
        <div class="stat-ico"><?php echo nav_icon_svg('<circle cx="12" cy="12" r="9"/><path d="M14.5 9.5c-.5-1-1.5-1.5-2.5-1.5-1.5 0-2.5.8-2.5 2s1 1.7 2.5 2 2.5.8 2.5 2-1 2-2.5 2c-1 0-2-.5-2.5-1.5M12 6.5V8m0 8v1.5"/>'); ?></div>
        <div><div class="stat-label">Total Earned</div><div class="stat-sub">From completed jobs</div></div>
        <div class="stat-num"><?php echo rand_short($total_earned); ?></div>
    </div>
    <div class="stat-row accent-blue">
        <div class="stat-ico"><?php echo nav_icon_svg('<circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/>'); ?></div>
        <div><div class="stat-label">Jobs Completed</div><div class="stat-sub">All time</div></div>
        <div class="stat-num"><?php echo (int)$jobs_completed; ?></div>
    </div>
    <div class="stat-row accent-orange">
        <div class="stat-ico"><?php echo nav_icon_svg('<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18"/>'); ?></div>
        <div><div class="stat-label">Upcoming Jobs</div><div class="stat-sub">Confirmed events</div></div>
        <div class="stat-num"><?php echo (int)$upcoming_jobs; ?></div>
    </div>
    <div class="stat-row accent-purple">
        <div class="stat-ico"><?php echo nav_icon_svg('<path d="m12 3 2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9L12 3Z"/>'); ?></div>
        <div><div class="stat-label">Rating</div><div class="stat-sub">Average client rating</div></div>
        <div class="stat-num"><?php echo number_format($freelancer['rating'] ?? 0, 1); ?></div>
    </div>
</div>

<div class="two-col">
    <div class="card">
        <div style="display:flex;justify-content:space-between;"><h3>My Upcoming Jobs</h3><a href="my-jobs.php" style="font-size:13px;">View all →</a></div>
        <?php if (empty($upcoming_list)): ?>
            <p class="empty-state">No upcoming jobs yet. Check <a href="available-jobs.php">Available Jobs</a>.</p>
        <?php else: foreach ($upcoming_list as $j): ?>
            <div class="list-item">
                <div>
                    <strong><?php echo h($j['event_type']); ?></strong><br>
                    <span style="font-size:13px;color:var(--text-muted);"><?php echo nice_date($j['event_date']); ?> &middot; <?php echo h($j['venue']); ?></span>
                </div>
            </div>
        <?php endforeach; endif; ?>
    </div>

    <div class="card">
        <h3>Your Profile</h3>
        <p><strong>Skill:</strong> <?php echo h($freelancer['skill'] ?? '-'); ?></p>
        <p><strong>Hourly Rate:</strong> <?php echo rand_format($freelancer['hourly_rate'] ?? 0); ?></p>
        <p><strong>Rating:</strong> <?php echo number_format($freelancer['rating'] ?? 0, 1); ?> ★</p>
    </div>
</div>

<?php include '../includes/footer_dashboard.php'; ?>
