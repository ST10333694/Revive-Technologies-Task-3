<?php
/**
 * admin/invitations.php
 * Submitted invitation card requests.
 * Admin can approve / reject a request, move it through the stages (the client sees the
 * progress bar and message update), and upload the finished cards. The client can only
 * download once the request is marked Completed.
 */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_role('admin');

$upload_dir = dirname(__DIR__) . '/uploads/invitations/';
$stages = invitation_stages();

function load_request($pdo, $id) {
    $stmt = $pdo->prepare('SELECT r.*, u.full_name AS client_name FROM invitation_requests r JOIN users u ON r.client_id = u.user_id WHERE r.request_id = ?');
    $stmt->execute([(int)$id]);
    return $stmt->fetch();
}

/** Remove a stored file (only inside uploads/invitations). */
function remove_invitation_file($dir, $relative) {
    if ($relative) {
        $file = $dir . basename($relative);
        if (is_file($file)) @unlink($file);
    }
}

// ---------------------------------------------------------------- actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $rid = (int)($_POST['request_id'] ?? 0);
    $req = load_request($pdo, $rid);
    $action = $_POST['action'] ?? '';

    if (!$req) {
        set_flash('Request not found.', 'error');
        redirect('invitations.php');
    }

    // Approve
    if ($action === 'approve' && $req['status'] === 'submitted') {
        $pdo->prepare("UPDATE invitation_requests SET status = 'approved', stage = 'approved', progress = ?, approved_at = NOW() WHERE request_id = ?")
            ->execute([$stages['approved'][1], $rid]);
        notify($pdo, $req['client_id'], 'Invitation cards approved',
            'Your ' . $req['style'] . ' request has been approved. Our designers will start soon - you can follow the progress on the Invitation Cards page.', 'invitations.php');
        $pdo->prepare('INSERT INTO tasks (title, due_date) VALUES (?, ?)')
            ->execute(['Design invitation cards: ' . $req['client_name'] . ' - ' . $req['style'], date('Y-m-d', strtotime('+3 days'))]);
        set_flash('Request approved and the client was notified. A task was added to your dashboard.');
        redirect('invitations.php?filter=active');
    }

    // Reject
    if ($action === 'reject' && $req['status'] === 'submitted') {
        $reason = substr(trim($_POST['note'] ?? ''), 0, 255);
        $pdo->prepare("UPDATE invitation_requests SET status = 'rejected', stage = NULL, progress = 0, progress_note = ? WHERE request_id = ?")
            ->execute([$reason ?: null, $rid]);
        notify($pdo, $req['client_id'], 'Invitation cards not approved',
            'Your ' . $req['style'] . ' request was not approved.' . ($reason ? ' ' . $reason : ''), 'invitations.php');
        set_flash('Request rejected and the client was notified.');
        redirect('invitations.php');
    }

    // Update progress / upload finished cards
    if ($action === 'update' && in_array($req['status'], ['approved', 'in_progress', 'completed'], true)) {
        $stage_key = $_POST['stage'] ?? '';
        if (!isset($stages[$stage_key])) {
            set_flash('Please choose a stage.', 'error');
            redirect('invitations.php?filter=active');
        }
        [$stage_label, $percent, $new_status] = $stages[$stage_key];
        $note = substr(trim($_POST['note'] ?? ''), 0, 255);

        // Optional file upload
        $file_path = $req['file_path'];
        $file_name = $req['file_name'];
        [$ext, $err] = check_invitation_upload($_FILES['cards_file'] ?? null);
        if ($ext) {
            if (!is_dir($upload_dir)) @mkdir($upload_dir, 0755, true);
            $stored = 'inv' . $rid . '_' . time() . '.' . $ext;
            if (@move_uploaded_file($_FILES['cards_file']['tmp_name'], $upload_dir . $stored)) {
                remove_invitation_file($upload_dir, $req['file_path']);
                $file_path = 'uploads/invitations/' . $stored;
                $file_name = substr(preg_replace('/[^A-Za-z0-9._ -]+/', '_', $_FILES['cards_file']['name']), 0, 200);
            } else {
                set_flash('The file could not be saved. Check that the uploads/invitations folder is writable.', 'error');
                redirect('invitations.php?filter=active');
            }
        } elseif ($err !== 'no file') {
            set_flash($err, 'error');
            redirect('invitations.php?filter=active');
        }

        if ($new_status === 'completed' && !$file_path) {
            set_flash('Upload the finished invitation cards before marking the request as completed.', 'error');
            redirect('invitations.php?filter=active');
        }

        $pdo->prepare('UPDATE invitation_requests SET status = ?, stage = ?, progress = ?, progress_note = ?, file_path = ?, file_name = ?, completed_at = ? WHERE request_id = ?')
            ->execute([$new_status, $stage_key, $percent, $note ?: null, $file_path, $file_name, $new_status === 'completed' ? date('Y-m-d H:i:s') : null, $rid]);

        if ($new_status === 'completed') {
            notify($pdo, $req['client_id'], 'Your invitation cards are ready',
                'Your ' . $req['style'] . ' cards are complete. You can now download them from the Invitation Cards page.', 'invitations.php');
            set_flash('Marked as completed. The client can now download the cards.');
        } else {
            notify($pdo, $req['client_id'], 'Invitation card update',
                'Your ' . $req['style'] . ' cards: ' . $stage_label . ' (' . $percent . '% complete).' . ($note ? ' ' . $note : ''), 'invitations.php');
            set_flash('Progress updated and the client was notified.');
        }
        redirect('invitations.php?filter=' . ($new_status === 'completed' ? 'completed' : 'active'));
    }

    redirect('invitations.php');
}

// ---------------------------------------------------------------- list
$filter = $_GET['filter'] ?? 'all';
$where = '';
if ($filter === 'new')            $where = "WHERE r.status = 'submitted'";
elseif ($filter === 'active')     $where = "WHERE r.status IN ('approved','in_progress')";
elseif ($filter === 'completed')  $where = "WHERE r.status = 'completed'";
elseif ($filter === 'rejected')   $where = "WHERE r.status = 'rejected'";

$requests = $pdo->query(
    "SELECT r.*, u.full_name AS client_name, u.email AS client_email
     FROM invitation_requests r JOIN users u ON r.client_id = u.user_id
     {$where} ORDER BY FIELD(r.status,'submitted','approved','in_progress','completed','rejected'), r.created_at DESC"
)->fetchAll();

$counts = $pdo->query("SELECT status, COUNT(*) c FROM invitation_requests GROUP BY status")->fetchAll(PDO::FETCH_KEY_PAIR);
$new_count    = (int)($counts['submitted'] ?? 0);
$active_count = (int)($counts['approved'] ?? 0) + (int)($counts['in_progress'] ?? 0);

$page_title = 'Invitation Cards';
$dash_role  = 'admin';
$active     = 'invitations';
$base       = '../';
include '../includes/header_dashboard.php';
?>

<div class="page-head">
    <div>
        <h2>Invitation Card Requests</h2>
        <p><?php echo $new_count; ?> awaiting approval &middot; <?php echo $active_count; ?> in progress</p>
    </div>
</div>

<div class="tab-filter">
    <a href="?filter=all" class="<?php echo $filter === 'all' ? 'active' : ''; ?>">All</a>
    <a href="?filter=new" class="<?php echo $filter === 'new' ? 'active' : ''; ?>">New (<?php echo $new_count; ?>)</a>
    <a href="?filter=active" class="<?php echo $filter === 'active' ? 'active' : ''; ?>">In Progress (<?php echo $active_count; ?>)</a>
    <a href="?filter=completed" class="<?php echo $filter === 'completed' ? 'active' : ''; ?>">Completed</a>
    <a href="?filter=rejected" class="<?php echo $filter === 'rejected' ? 'active' : ''; ?>">Rejected</a>
</div>

<?php if (empty($requests)): ?>
    <div class="card empty-state">No invitation card requests found for this filter.</div>
<?php else: foreach ($requests as $r):
    [$status_label, $status_class] = invitation_status_info($r['status']);
    $done = $r['status'] === 'completed';
?>
    <div class="card inv-card">
        <div class="inv-head">
            <div>
                <p class="inv-title"><?php echo h($r['style']); ?> &middot; <?php echo h($r['client_name']); ?></p>
                <div class="inv-meta">
                    <?php echo $r['host_names'] ? h($r['host_names']) . ' &middot; ' : ''; ?>
                    Event: <?php echo nice_date($r['event_date']); ?><?php echo !empty($r['event_time']) ? ' at ' . nice_time($r['event_time']) : ''; ?>
                    <?php echo $r['venue'] ? ' &middot; ' . h($r['venue']) : ''; ?>
                </div>
                <div class="inv-meta">
                    Requested <?php echo nice_date($r['created_at']); ?>
                    <?php echo $r['quantity'] ? ' &middot; ' . (int)$r['quantity'] . ' cards' : ''; ?>
                    <?php echo $r['colour_scheme'] ? ' &middot; Theme: ' . h($r['colour_scheme']) : ''; ?>
                </div>
                <?php if (!empty($r['details'])): ?><div class="inv-details"><?php echo h($r['details']); ?></div><?php endif; ?>
            </div>
            <span class="pill pill-<?php echo $status_class; ?>"><?php echo h($status_label); ?></span>
        </div>

        <?php if (!in_array($r['status'], ['submitted', 'rejected'], true)): ?>
            <div class="progress-track"><div class="progress-fill <?php echo $done ? 'done' : ''; ?>" style="width:<?php echo (int)$r['progress']; ?>%;"></div></div>
            <div class="inv-meta">
                <?php echo h(($r['stage'] && isset($stages[$r['stage']])) ? $stages[$r['stage']][0] : 'In progress'); ?> &middot; <?php echo (int)$r['progress']; ?>%
                <?php if (!empty($r['file_name'])): ?>
                    &middot; File: <a href="invitation-download.php?id=<?php echo (int)$r['request_id']; ?>" style="text-decoration:underline;"><?php echo h($r['file_name']); ?></a>
                <?php endif; ?>
            </div>
            <?php if (!empty($r['progress_note'])): ?><div class="inv-note">Note to client: <?php echo h($r['progress_note']); ?></div><?php endif; ?>
        <?php elseif ($r['status'] === 'rejected' && !empty($r['progress_note'])): ?>
            <div class="inv-note">Reason given: <?php echo h($r['progress_note']); ?></div>
        <?php endif; ?>

        <?php if ($r['status'] === 'submitted'): ?>
            <form method="POST" action="invitations.php" class="inv-admin-form">
                <input type="hidden" name="request_id" value="<?php echo (int)$r['request_id']; ?>">
                <div class="field"><label>Message if rejecting (optional)</label><input type="text" name="note" maxlength="255" placeholder="e.g. We can't produce this style by your event date"></div>
                <div class="inv-actions" style="margin-top:0;">
                    <button type="submit" name="action" value="approve" class="btn btn-success btn-sm">✓ Approve Request</button>
                    <button type="submit" name="action" value="reject" class="btn btn-danger btn-sm" onclick="return confirm('Reject this request? The client will be notified.');">Reject</button>
                </div>
            </form>

        <?php elseif (in_array($r['status'], ['approved', 'in_progress', 'completed'], true)): ?>
            <form method="POST" action="invitations.php" enctype="multipart/form-data" class="inv-admin-form">
                <input type="hidden" name="request_id" value="<?php echo (int)$r['request_id']; ?>">
                <input type="hidden" name="action" value="update">
                <div class="form-grid">
                    <div class="field">
                        <label>Progress stage</label>
                        <select name="stage">
                            <?php foreach ($stages as $key => $st): ?>
                                <option value="<?php echo h($key); ?>" <?php echo $r['stage'] === $key ? 'selected' : ''; ?>><?php echo h($st[0]); ?> (<?php echo (int)$st[1]; ?>%)</option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="field">
                        <label>Finished cards (PDF, JPG, PNG)<?php echo !empty($r['file_name']) ? ' - replaces current file' : ''; ?></label>
                        <input type="file" name="cards_file" accept=".pdf,image/jpeg,image/png,image/webp">
                    </div>
                </div>
                <div class="field"><label>Message to the client (optional)</label><input type="text" name="note" maxlength="255" value="<?php echo h($r['progress_note']); ?>" placeholder="e.g. Your draft is almost ready - printing next week"></div>
                <button type="submit" class="btn btn-primary btn-sm">Update Progress</button>
                <span class="q-note" style="margin-left:10px;">Choose "Completed" and upload the cards to let the client download them.</span>
            </form>
        <?php endif; ?>
    </div>
<?php endforeach; endif; ?>

<?php include '../includes/footer_dashboard.php'; ?>
