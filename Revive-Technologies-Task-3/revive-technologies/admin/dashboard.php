<?php
/**
 * admin/dashboard.php
 * Business overview: stat rows, upcoming tasks (tick them off when done),
 * recent bookings and low-stock alerts.
 */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_role('admin');

// ---------------------------------------------------------------- task actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['complete_task'])) {
        $pdo->prepare('UPDATE tasks SET is_complete = 1, completed_at = NOW() WHERE task_id = ?')->execute([(int)$_POST['complete_task']]);
        set_flash('Task marked as complete.');
    } elseif (isset($_POST['reopen_task'])) {
        $pdo->prepare('UPDATE tasks SET is_complete = 0, completed_at = NULL WHERE task_id = ?')->execute([(int)$_POST['reopen_task']]);
        set_flash('Task moved back to upcoming.');
    } elseif (isset($_POST['add_task'])) {
        $title = trim($_POST['task_title'] ?? '');
        $date  = $_POST['task_date'] ?? '';
        $time  = clean_time($_POST['task_time'] ?? '');
        if ($title !== '' && preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
            $pdo->prepare('INSERT INTO tasks (title, due_date, due_time) VALUES (?, ?, ?)')->execute([$title, $date, $time]);
            set_flash('Task added.');
        } else {
            set_flash('Please enter a task name and a due date.', 'error');
        }
    }
    redirect('dashboard.php');
}

// ---------------------------------------------------------------- stats
$active_bookings = $pdo->query("SELECT COUNT(*) FROM bookings WHERE status IN ('confirmed','quoted')")->fetchColumn();
$new_this_week   = $pdo->query("SELECT COUNT(*) FROM bookings WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)")->fetchColumn();

$pending_quotes  = $pdo->query("SELECT COUNT(*) FROM bookings WHERE status IN ('pending','quoted')")->fetchColumn();
$urgent_quotes   = $pdo->query("SELECT COUNT(*) FROM bookings WHERE status IN ('pending','quoted') AND event_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 14 DAY)")->fetchColumn();

$active_freelancers = $pdo->query("SELECT COUNT(*) FROM users WHERE role = 'freelancer' AND status = 'active'")->fetchColumn();
$on_assignment      = $pdo->query("SELECT COUNT(DISTINCT freelancer_id) FROM bookings WHERE freelancer_id IS NOT NULL AND status = 'confirmed' AND event_date >= CURDATE()")->fetchColumn();

$critical_stock = $pdo->query("SELECT COUNT(*) FROM inventory WHERE available_stock < total_stock * 0.25")->fetchColumn();

$recent_bookings = $pdo->query(
    "SELECT b.*, u.full_name AS client_name FROM bookings b JOIN users u ON b.client_id = u.user_id
     ORDER BY b.created_at DESC LIMIT 5"
)->fetchAll();

$low_stock = $pdo->query(
    "SELECT * FROM inventory WHERE available_stock < total_stock * 0.5 ORDER BY available_stock ASC LIMIT 5"
)->fetchAll();

$open_tasks = $pdo->query(
    "SELECT * FROM tasks WHERE is_complete = 0 ORDER BY due_date ASC, due_time IS NULL, due_time ASC, task_id ASC LIMIT 12"
)->fetchAll();
$done_tasks = $pdo->query(
    "SELECT * FROM tasks WHERE is_complete = 1 ORDER BY completed_at DESC LIMIT 4"
)->fetchAll();

$page_title = 'Dashboard';
$dash_role  = 'admin';
$active     = 'dashboard';
$base       = '../';
include '../includes/header_dashboard.php';

function stat_icon($path) {
    return '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' . $path . '</svg>';
}
$now = time();
?>

<h2>Dashboard</h2>
<p style="color:var(--text-muted);margin-bottom:24px;">Welcome back — here's your business at a glance.</p>

<div class="stat-list">
    <a class="stat-row accent-blue" href="calendar.php">
        <div class="stat-ico"><?php echo stat_icon('<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18"/>'); ?></div>
        <div><div class="stat-label">Active Bookings</div><div class="stat-sub">+<?php echo (int)$new_this_week; ?> this week</div></div>
        <div class="stat-num"><?php echo (int)$active_bookings; ?></div>
    </a>
    <a class="stat-row accent-orange" href="quotations.php">
        <div class="stat-ico"><?php echo stat_icon('<path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M17 21H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h7l5 5v11a2 2 0 0 1-2 2Z"/><path d="M9 13h6M9 17h6"/>'); ?></div>
        <div><div class="stat-label">Pending Quotations</div><div class="stat-sub"><?php echo (int)$urgent_quotes; ?> urgent</div></div>
        <div class="stat-num"><?php echo (int)$pending_quotes; ?></div>
    </a>
    <a class="stat-row accent-purple" href="freelancers.php">
        <div class="stat-ico"><?php echo stat_icon('<circle cx="9" cy="8" r="3.2"/><path d="M3.5 20a5.5 5.5 0 0 1 11 0"/><circle cx="17.5" cy="9.5" r="2.6"/><path d="M15.2 13.2a4.6 4.6 0 0 1 6.3 4.3"/>'); ?></div>
        <div><div class="stat-label">Active Freelancers</div><div class="stat-sub"><?php echo (int)$on_assignment; ?> on assignment</div></div>
        <div class="stat-num"><?php echo (int)$active_freelancers; ?></div>
    </a>
    <a class="stat-row accent-red" href="inventory.php">
        <div class="stat-ico"><?php echo stat_icon('<path d="M21 8 12 3 3 8l9 5 9-5Z"/><path d="M3 8v8l9 5 9-5V8"/><path d="M12 13v8"/>'); ?></div>
        <div><div class="stat-label">Critical Stock Items</div><div class="stat-sub">Needs restocking</div></div>
        <div class="stat-num"><?php echo (int)$critical_stock; ?></div>
    </a>
</div>

<div class="two-col">
    <div class="card">
        <h3>Upcoming Tasks</h3>
        <p style="color:var(--text-muted);font-size:13px;margin-top:-6px;">Tick a task when it's done. Tasks are added automatically when you approve a quotation.</p>

        <?php if (empty($open_tasks)): ?>
            <p class="empty-state" style="padding:24px;">🎉 You're all caught up.</p>
        <?php else: foreach ($open_tasks as $t):
            $due_ts  = strtotime($t['due_date'] . ' ' . ($t['due_time'] ?: '23:59:59'));
            $overdue = $due_ts < $now;
        ?>
            <form method="POST" action="dashboard.php" class="task-row">
                <button type="submit" name="complete_task" value="<?php echo (int)$t['task_id']; ?>" class="task-check" title="Mark complete" aria-label="Mark complete">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"><path d="m5 12 5 5 9-10"/></svg>
                </button>
                <div class="task-body">
                    <div class="task-title"><?php echo h($t['title']); ?></div>
                    <div class="task-due <?php echo $overdue ? 'task-overdue' : ''; ?>">
                        <?php echo $overdue ? 'Overdue · ' : ''; ?><?php echo nice_date($t['due_date']); ?><?php echo $t['due_time'] ? ' · 🕒 ' . nice_time($t['due_time']) : ''; ?>
                    </div>
                </div>
            </form>
        <?php endforeach; endif; ?>

        <?php if (!empty($done_tasks)): ?>
            <div class="sub-head">Recently completed</div>
            <?php foreach ($done_tasks as $t): ?>
                <form method="POST" action="dashboard.php" class="task-row done">
                    <span class="task-check"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"><path d="m5 12 5 5 9-10"/></svg></span>
                    <div class="task-body"><div class="task-title"><?php echo h($t['title']); ?></div></div>
                    <button type="submit" name="reopen_task" value="<?php echo (int)$t['task_id']; ?>" class="link-btn">Undo</button>
                </form>
            <?php endforeach; ?>
        <?php endif; ?>

        <form method="POST" action="dashboard.php" class="task-add">
            <input type="hidden" name="add_task" value="1">
            <div class="field"><label>New Task</label><input type="text" name="task_title" placeholder="e.g. Collect balloons from supplier" required></div>
            <div class="form-grid">
                <div class="field"><label>Due Date</label><input type="date" name="task_date" value="<?php echo date('Y-m-d'); ?>" required></div>
                <div class="field"><label>Due Time</label><input type="text" name="task_time" data-clock placeholder="Select time"></div>
            </div>
            <button type="submit" class="btn btn-primary btn-sm">+ Add Task</button>
        </form>
    </div>

    <div>
        <div class="card" style="margin-bottom:24px;">
            <div style="display:flex;justify-content:space-between;"><h3>Recent Bookings</h3><a href="quotations.php" style="font-size:13px;">View all →</a></div>
            <?php if (empty($recent_bookings)): ?>
                <p class="empty-state">No bookings yet.</p>
            <?php else: foreach ($recent_bookings as $b): ?>
                <div class="list-item">
                    <div>
                        <strong><?php echo h($b['client_name']); ?></strong><br>
                        <span style="font-size:13px;color:var(--text-muted);">BK-<?php echo str_pad($b['booking_id'],3,'0',STR_PAD_LEFT); ?> &middot; <?php echo nice_date($b['event_date']); ?><?php echo !empty($b['event_time']) ? ' · ' . nice_time($b['event_time']) : ''; ?></span>
                    </div>
                    <span class="pill pill-<?php echo h($b['status']); ?>"><?php echo ucfirst(h($b['status'])); ?></span>
                </div>
            <?php endforeach; endif; ?>
        </div>

        <div class="card" style="margin-bottom:24px;">
            <div style="display:flex;justify-content:space-between;"><h3>Low Stock Alerts</h3><a href="inventory.php" style="font-size:13px;">Manage →</a></div>
            <?php if (empty($low_stock)): ?>
                <p class="empty-state">All inventory levels look healthy.</p>
            <?php else: foreach ($low_stock as $item): ?>
                <div class="list-item">
                    <div>
                        <strong><?php echo h($item['item_name']); ?></strong><br>
                        <span style="font-size:13px;color:var(--danger);">Current: <?php echo (int)$item['available_stock']; ?> | Total: <?php echo (int)$item['total_stock']; ?></span>
                    </div>
                    <a href="inventory.php" class="btn btn-danger btn-sm">Restock</a>
                </div>
            <?php endforeach; endif; ?>
        </div>

        <div class="card">
            <h3>Manage Packages</h3>
            <p style="color:var(--text-muted);font-size:13px;margin-top:-6px;margin-bottom:16px;">Review the sample packages shown to clients on their portfolio page.</p>
            <a href="packages.php" class="btn btn-outline btn-block">View Packages →</a>
        </div>
    </div>
</div>

<?php include '../includes/footer_dashboard.php'; ?>
