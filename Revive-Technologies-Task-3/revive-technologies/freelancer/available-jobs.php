<?php
/**
 * freelancer/available-jobs.php
 * Shows bookings that are confirmed but have no freelancer assigned yet.
 * Applying sends an application to the admin (status: under review / approved / rejected).
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

ensure_job_applications_table($pdo);

// Apply for a job: this only sends an application. The admin decides whether to accept it.
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['booking_id'])) {
    $booking_id = (int)$_POST['booking_id'];
    $b = $pdo->prepare("SELECT event_type, event_date FROM bookings WHERE booking_id = ? AND freelancer_id IS NULL AND status IN ('pending','confirmed')");
    $b->execute([$booking_id]);
    $job = $b->fetch();
    if (!$job || !$freelancer_id) {
        set_flash('Sorry, that job is no longer available.', 'error');
    } else {
        $ins = $pdo->prepare("INSERT IGNORE INTO job_applications (booking_id, freelancer_id) VALUES (?, ?)");
        $ins->execute([$booking_id, $freelancer_id]);
        if ($ins->rowCount() > 0) {
            notify_admins($pdo, 'New job application',
                $_SESSION['full_name'] . ' applied for the ' . $job['event_type'] . ' on ' . nice_date($job['event_date']) . '. Open Freelancers to review, accept or reject.', 'freelancers.php');
            set_flash('Application sent! Its status is now "Under review" until the admin responds.');
        } else {
            set_flash('You have already applied for this job.', 'error');
        }
    }
    redirect('available-jobs.php');
}

// Jobs still open (nobody assigned yet), with this freelancer's application status if any
$stmt = $pdo->prepare(
    "SELECT b.*, u.full_name AS client_name, a.status AS application_status
     FROM bookings b
     JOIN users u ON b.client_id = u.user_id
     LEFT JOIN job_applications a ON a.booking_id = b.booking_id AND a.freelancer_id = ?
     WHERE b.freelancer_id IS NULL AND b.status IN ('pending','confirmed')
     ORDER BY b.event_date ASC"
);
$stmt->execute([$freelancer_id]);
$jobs = $stmt->fetchAll();

// Every application this freelancer has made
$stmt = $pdo->prepare(
    "SELECT a.*, b.event_type, b.event_date, b.venue, u.full_name AS client_name
     FROM job_applications a
     JOIN bookings b ON a.booking_id = b.booking_id
     JOIN users u ON b.client_id = u.user_id
     WHERE a.freelancer_id = ? ORDER BY a.applied_at DESC"
);
$stmt->execute([$freelancer_id]);
$applications = $stmt->fetchAll();

$page_title = 'Available Jobs';
$dash_role  = 'freelancer';
$active     = 'available';
$base       = '../';
include '../includes/header_dashboard.php';
?>

<h2>Available Jobs</h2>
<p style="color:var(--text-muted);margin-bottom:24px;">Browse open positions and apply. The admin will review your application.</p>

<?php if (!empty($applications)): ?>
<h3 style="margin-bottom:12px;">My Applications</h3>
<?php foreach ($applications as $a): [$a_label, $a_class] = application_status_info($a['status']); ?>
    <div class="card" style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;flex-wrap:wrap;gap:10px;">
        <div>
            <strong><?php echo h($a['event_type']); ?></strong> for <?php echo h($a['client_name']); ?><br>
            <span style="font-size:13px;color:var(--text-muted);">📅 <?php echo nice_date($a['event_date']); ?> &middot; <?php echo h($a['venue'] ?: 'TBC'); ?> &middot; Applied <?php echo nice_date($a['applied_at']); ?></span>
        </div>
        <div style="text-align:right;">
            <span class="pill pill-<?php echo $a_class; ?>"><?php echo h($a_label); ?></span>
            <?php if ($a['status'] === 'approved'): ?><div style="font-size:12px;margin-top:4px;"><a href="my-jobs.php">View in My Jobs →</a></div><?php endif; ?>
        </div>
    </div>
<?php endforeach; ?>
<h3 style="margin:28px 0 12px 0;">Open Jobs</h3>
<?php endif; ?>

<?php if (empty($jobs)): ?>
    <div class="card empty-state">No open jobs right now - check back soon!</div>
<?php else: foreach ($jobs as $j): ?>
    <div class="card" style="display:flex;justify-content:space-between;align-items:center;margin-bottom:14px;flex-wrap:wrap;gap:10px;">
        <div>
            <span class="pill pill-quoted"><?php echo h($j['event_type']); ?></span>
            <h3 style="margin-top:8px;"><?php echo h($j['event_type']); ?> for <?php echo h($j['client_name']); ?></h3>
            <p style="color:var(--text-muted);font-size:13px;">
                📅 <?php echo nice_date($j['event_date']); ?> &nbsp; 📍 <?php echo h($j['venue'] ?: 'TBC'); ?>
                <?php if ($j['guest_count']): ?> &nbsp; 👥 <?php echo (int)$j['guest_count']; ?> guests<?php endif; ?>
            </p>
        </div>
        <?php if ($j['application_status']): [$s_label, $s_class] = application_status_info($j['application_status']); ?>
            <span class="pill pill-<?php echo $s_class; ?>"><?php echo h($s_label); ?></span>
        <?php else: ?>
            <form method="POST" action="available-jobs.php">
                <input type="hidden" name="booking_id" value="<?php echo (int)$j['booking_id']; ?>">
                <button type="submit" class="btn btn-primary">Apply Now</button>
            </form>
        <?php endif; ?>
    </div>
<?php endforeach; endif; ?>

<?php include '../includes/footer_dashboard.php'; ?>
