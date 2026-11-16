<?php
/**
 * admin/quotations.php
 * Admin can:
 *   - create an itemised quotation for any booking that still needs one
 *   - edit a quotation (the client is notified of the change)
 *   - approve or reject a pending quotation (the client is notified;
 *     once approved the client can download the PDF and has 72 hours to pay the deposit)
 *   - download the PDF of any quotation
 */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_role('admin');

/** Read the line items posted by the builder form. */
function posted_items() {
    $desc = $_POST['item_desc'] ?? [];
    $qty  = $_POST['item_qty'] ?? [];
    $cost = $_POST['item_cost'] ?? [];
    $items = [];
    foreach ($desc as $i => $d) {
        $d = trim((string)$d);
        $q = (int)($qty[$i] ?? 0);
        $c = (float)($cost[$i] ?? 0);
        if ($d === '' || $q < 1 || $c < 0) continue;
        $items[] = ['description' => $d, 'qty' => $q, 'unit_cost' => $c];
    }
    return $items;
}

function save_items($pdo, $quote_id, $items) {
    $pdo->prepare('DELETE FROM quotation_items WHERE quote_id = ?')->execute([$quote_id]);
    $ins = $pdo->prepare('INSERT INTO quotation_items (quote_id, description, qty, unit_cost, sort_order) VALUES (?, ?, ?, ?, ?)');
    foreach ($items as $n => $it) {
        $ins->execute([$quote_id, $it['description'], $it['qty'], $it['unit_cost'], $n + 1]);
    }
}

function items_total($items) {
    $t = 0;
    foreach ($items as $it) $t += $it['qty'] * $it['unit_cost'];
    return $t;
}

/** Approve a pending quotation: confirm the booking, notify the client, create admin tasks. */
function approve_quotation($pdo, $quote_id) {
    $q = get_quotation($pdo, $quote_id);
    if (!$q || $q['status'] === 'accepted') return false;

    $pdo->prepare("UPDATE quotations SET status = 'accepted', approved_at = NOW() WHERE quote_id = ?")->execute([$quote_id]);
    $pdo->prepare("UPDATE bookings SET status = 'confirmed' WHERE booking_id = ?")->execute([$q['booking_id']]);

    notify(
        $pdo, $q['client_id'], 'Quotation approved',
        'Your quotation ' . quote_ref($q['quote_id'], $q['created_at']) . ' (' . $q['title'] . ') has been approved and is ready to download. A deposit is required within 72 hours to secure your booking.',
        'quotations.php'
    );

    // Tasks for the admin dashboard (skipped if the same task already exists for this booking)
    $tasks = [
        ['Prepare décor: ' . $q['client_name'] . ' - ' . $q['event_type'], $q['event_date'], $q['event_time']],
        ['Confirm deposit received: ' . $q['client_name'], date('Y-m-d', time() + 72 * 3600), date('H:i:00', time() + 72 * 3600)],
    ];
    $check = $pdo->prepare('SELECT COUNT(*) FROM tasks WHERE booking_id = ? AND title = ?');
    $ins   = $pdo->prepare('INSERT INTO tasks (title, due_date, due_time, booking_id) VALUES (?, ?, ?, ?)');
    foreach ($tasks as $t) {
        $check->execute([$q['booking_id'], $t[0]]);
        if (!$check->fetchColumn()) $ins->execute([$t[0], $t[1], $t[2], $q['booking_id']]);
    }
    return true;
}

$payment_options = [
    '50% deposit required to confirm booking. Balance due within 72 hours after approval.',
    '30% deposit required to confirm booking. Balance due on delivery.',
    'Full payment upfront.',
    'Full payment on completion.',
];

// ---------------------------------------------------------------- actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    // Approve / reject
    if (isset($_POST['approve_quote'])) {
        approve_quotation($pdo, (int)$_POST['approve_quote']);
        set_flash('Quotation approved. The client has been notified and can now download it.');
        redirect('quotations.php');
    }
    if (isset($_POST['reject_quote'])) {
        $qid = (int)$_POST['reject_quote'];
        $q = get_quotation($pdo, $qid);
        if ($q && $q['status'] === 'sent') {
            $pdo->prepare("UPDATE quotations SET status = 'rejected' WHERE quote_id = ?")->execute([$qid]);
            $pdo->prepare("UPDATE bookings SET status = 'pending' WHERE booking_id = ?")->execute([$q['booking_id']]);
            notify($pdo, $q['client_id'], 'Quotation not approved',
                'Your quotation ' . quote_ref($q['quote_id'], $q['created_at']) . ' was not approved. Our team will send you a revised quotation.', 'quotations.php');
            set_flash('Quotation rejected. The booking is back in the "needs a quote" list and the client was notified.');
        }
        redirect('quotations.php');
    }

    // Create or update a quotation
    if (isset($_POST['save_quotation'])) {
        $title   = trim($_POST['title'] ?? '');
        $terms   = trim($_POST['payment_terms'] ?? '');
        $details = trim($_POST['details'] ?? '');
        $items   = posted_items();
        $edit_id = (int)($_POST['quote_id'] ?? 0);

        if ($title === '' || empty($items)) {
            set_flash('Please give the quotation a title and at least one item with a quantity.', 'error');
            redirect($edit_id ? 'quotations.php?edit=' . $edit_id : 'quotations.php');
        }
        $amount = items_total($items);

        if ($edit_id) {
            $q = get_quotation($pdo, $edit_id);
            if ($q) {
                $pdo->prepare('UPDATE quotations SET title = ?, amount = ?, details = ?, payment_terms = ? WHERE quote_id = ?')
                    ->execute([$title, $amount, $details, $terms, $edit_id]);
                save_items($pdo, $edit_id, $items);
                notify($pdo, $q['client_id'], 'Your quotation was updated',
                    'Changes were made to quotation ' . quote_ref($q['quote_id'], $q['created_at']) . ' (' . $title . '). The new total is ' . rand_short($amount) . '.', 'quotations.php');
                set_flash('Quotation updated and the client was notified.');
            }
            redirect('quotations.php');
        }

        $booking_id = (int)($_POST['booking_id'] ?? 0);
        $stmt = $pdo->prepare('SELECT client_id FROM bookings WHERE booking_id = ?');
        $stmt->execute([$booking_id]);
        $booking = $stmt->fetch();

        if ($booking) {
            $pdo->prepare("INSERT INTO quotations (booking_id, client_id, title, amount, details, payment_terms, status) VALUES (?, ?, ?, ?, ?, ?, 'sent')")
                ->execute([$booking_id, $booking['client_id'], $title, $amount, $details, $terms]);
            $new_id = (int)$pdo->lastInsertId();
            save_items($pdo, $new_id, $items);
            $pdo->prepare("UPDATE bookings SET status = 'quoted' WHERE booking_id = ?")->execute([$booking_id]);

            if (!empty($_POST['approve_now'])) {
                approve_quotation($pdo, $new_id);
                set_flash('Quotation created and approved. The client has been notified.');
            } else {
                notify($pdo, $booking['client_id'], 'New quotation prepared',
                    'A quotation (' . $title . ') has been prepared for your booking. You will be able to download it once it has been approved.', 'quotations.php');
                set_flash('Quotation created (pending approval). The client has been notified.');
            }
        }
        redirect('quotations.php');
    }
}

// ---------------------------------------------------------------- data for the page
$edit = null;
if (isset($_GET['edit'])) $edit = get_quotation($pdo, (int)$_GET['edit']);

$filter = $_GET['filter'] ?? 'all';
$where  = '';
if (in_array($filter, ['pending', 'approved', 'rejected'], true)) {
    $map = ['pending' => 'sent', 'approved' => 'accepted', 'rejected' => 'rejected'];
    $where = "WHERE q.status = '" . $map[$filter] . "'";
}
$ids = $pdo->query("SELECT q.quote_id FROM quotations q {$where} ORDER BY q.created_at DESC")->fetchAll(PDO::FETCH_COLUMN);
$quotations = [];
foreach ($ids as $qid) $quotations[] = get_quotation($pdo, $qid);

$total_count    = $pdo->query("SELECT COUNT(*) FROM quotations")->fetchColumn();
$approved_count = $pdo->query("SELECT COUNT(*) FROM quotations WHERE status='accepted'")->fetchColumn();
$approval_rate  = $total_count ? round($approved_count / $total_count * 100) : 0;

// Bookings still needing a quote
$unquoted = $pdo->query(
    "SELECT b.*, u.full_name AS client_name FROM bookings b JOIN users u ON b.client_id = u.user_id
     WHERE b.status = 'pending' ORDER BY b.created_at DESC"
)->fetchAll();

// Values for the form (blank, or the quotation being edited)
$form_title   = $edit['title'] ?? '';
$form_terms   = $edit['payment_terms'] ?? $payment_options[0];
$form_details = $edit['details'] ?? '';
$form_items   = $edit['items'] ?? [['description' => '', 'qty' => 1, 'unit_cost' => '']];
if (!in_array($form_terms, $payment_options, true)) $payment_options[] = $form_terms;

$page_title = 'Quotations';
$dash_role  = 'admin';
$active     = 'quotations';
$base       = '../';
include '../includes/header_dashboard.php';
?>

<div class="page-head">
    <div><h2>Quotations</h2><p>Create, approve and track client quotations</p></div>
</div>

<?php if ($edit || !empty($unquoted)): ?>
<h3><?php echo $edit ? 'Edit Quotation ' . h(quote_ref($edit['quote_id'], $edit['created_at'])) : 'Create a Quotation'; ?></h3>
<div class="card" style="max-width:760px;margin-bottom:28px;">
    <form method="POST" action="quotations.php">
        <input type="hidden" name="save_quotation" value="1">
        <?php if ($edit): ?>
            <input type="hidden" name="quote_id" value="<?php echo (int)$edit['quote_id']; ?>">
            <div class="field">
                <label>Booking</label>
                <input type="text" disabled value="<?php echo h($edit['client_name'] . ' - ' . $edit['event_type'] . ' (' . nice_date($edit['event_date']) . ')'); ?>">
            </div>
        <?php else: ?>
            <div class="field">
                <label>Booking</label>
                <select name="booking_id" required>
                    <?php foreach ($unquoted as $b): ?>
                        <option value="<?php echo (int)$b['booking_id']; ?>">
                            <?php echo h($b['client_name']); ?> - <?php echo h($b['event_type']); ?> (<?php echo nice_date($b['event_date']); ?><?php echo $b['event_time'] ? ' ' . nice_time($b['event_time']) : ''; ?>)
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>
        <?php endif; ?>

        <div class="field">
            <label>Quotation Title</label>
            <input type="text" name="title" value="<?php echo h($form_title); ?>" placeholder="e.g. Baby Shower Styling - Dusty Pink &amp; Sage Green" required>
        </div>

        <div class="field" data-items-builder>
            <label>Itemised Breakdown</label>
            <div class="items-head"><span>Item / Description</span><span>Qty</span><span>Unit cost (R)</span><span style="text-align:right;">Subtotal</span><span></span></div>
            <div class="item-rows">
                <?php foreach ($form_items as $it): ?>
                    <div class="item-row">
                        <input type="text" name="item_desc[]" value="<?php echo h($it['description']); ?>" placeholder="e.g. Custom Floral Feature Backdrop (3m x 2.5m)">
                        <input type="number" class="item-qty" name="item_qty[]" min="1" step="1" value="<?php echo (int)$it['qty']; ?>">
                        <input type="number" class="item-cost" name="item_cost[]" min="0" step="0.01" value="<?php echo h($it['unit_cost']); ?>" placeholder="0.00">
                        <span class="item-sub">R 0</span>
                        <button type="button" class="item-del" title="Remove line">&times;</button>
                    </div>
                <?php endforeach; ?>
            </div>
            <button type="button" class="btn btn-outline btn-sm" data-add-item>+ Add item</button>
            <div class="items-total"><span>TOTAL</span><strong>R 0</strong></div>
        </div>

        <div class="field"><label>Payment Terms</label>
            <select name="payment_terms">
                <?php foreach ($payment_options as $opt): ?>
                    <option value="<?php echo h($opt); ?>" <?php echo $opt === $form_terms ? 'selected' : ''; ?>><?php echo h($opt); ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <div class="field"><label>Notes (optional)</label><textarea name="details" placeholder="Anything else to record about this quotation..."><?php echo h($form_details); ?></textarea></div>

        <?php if (!$edit): ?>
            <label style="display:flex;align-items:center;gap:8px;font-weight:400;text-transform:none;font-size:14px;margin-bottom:16px;">
                <input type="checkbox" name="approve_now" value="1"> Approve immediately (client can download it right away)
            </label>
        <?php endif; ?>

        <div style="display:flex;gap:10px;">
            <button type="submit" class="btn btn-primary" style="flex:1;"><?php echo $edit ? 'Save Changes' : '+ Create Quotation'; ?></button>
            <?php if ($edit): ?><a href="quotations.php" class="btn btn-outline">Cancel</a><?php endif; ?>
        </div>
    </form>
</div>
<?php endif; ?>

<div class="tab-filter">
    <a href="?filter=all" class="<?php echo $filter === 'all' ? 'active' : ''; ?>">All</a>
    <a href="?filter=pending" class="<?php echo $filter === 'pending' ? 'active' : ''; ?>">Pending</a>
    <a href="?filter=approved" class="<?php echo $filter === 'approved' ? 'active' : ''; ?>">Approved</a>
    <a href="?filter=rejected" class="<?php echo $filter === 'rejected' ? 'active' : ''; ?>">Rejected</a>
</div>

<?php if (empty($quotations)): ?>
    <div class="card empty-state">No quotations found for this filter.</div>
<?php else: foreach ($quotations as $q):
    $pill = $q['status'] === 'sent' ? 'pending' : ($q['status'] === 'accepted' ? 'approved' : 'rejected');
    $label = $q['status'] === 'sent' ? 'Pending' : ($q['status'] === 'accepted' ? 'Approved' : 'Rejected');
?>
    <div class="card q-card">
        <div class="q-head">
            <div>
                <span class="q-meta"><?php echo h(quote_ref($q['quote_id'], $q['created_at'])); ?></span>
                <p class="q-title"><?php echo h($q['title']); ?></p>
                <div class="q-meta"><?php echo h($q['client_name']); ?> &middot; <?php echo h($q['event_type']); ?> &middot; <?php echo nice_date($q['event_date']); ?><?php echo !empty($q['event_time']) ? ' at ' . nice_time($q['event_time']) : ''; ?></div>
            </div>
            <div class="q-head-right">
                <div class="q-total"><?php echo rand_short($q['amount']); ?></div>
                <span class="pill pill-<?php echo $pill; ?>"><?php echo $label; ?></span>
            </div>
        </div>

        <div class="q-sep" style="margin-bottom:6px;"></div>
        <details>
            <summary style="cursor:pointer;font-size:12px;letter-spacing:.08em;text-transform:uppercase;color:#6b6762;font-weight:600;padding:6px 0;">View itemised breakdown</summary>
            <div class="q-table-scroll">
                <table class="q-table">
                    <thead><tr><th>Item / Description</th><th>Qty</th><th>Unit Cost</th><th>Subtotal</th></tr></thead>
                    <tbody>
                        <?php foreach ($q['items'] as $it): ?>
                            <tr><td><?php echo h($it['description']); ?></td><td><?php echo (int)$it['qty']; ?></td><td><?php echo rand_short($it['unit_cost']); ?></td><td><?php echo rand_short($it['qty'] * $it['unit_cost']); ?></td></tr>
                        <?php endforeach; ?>
                    </tbody>
                    <tfoot><tr><td colspan="3">TOTAL</td><td><?php echo rand_short($q['amount']); ?></td></tr></tfoot>
                </table>
            </div>
            <div class="terms-box"><strong>Payment Terms</strong><?php echo h($q['payment_terms']); ?></div>
        </details>

        <div class="admin-q-actions">
            <?php if ($q['status'] === 'sent'): ?>
                <form method="POST" action="quotations.php" data-confirm="Approve this quotation? The client will be notified and can download it.">
                    <button type="submit" name="approve_quote" value="<?php echo (int)$q['quote_id']; ?>" class="btn btn-success btn-sm">✓ Approve</button>
                </form>
                <form method="POST" action="quotations.php" data-confirm="Reject this quotation? The booking will go back to 'needs a quote'.">
                    <button type="submit" name="reject_quote" value="<?php echo (int)$q['quote_id']; ?>" class="btn btn-danger btn-sm">Reject</button>
                </form>
            <?php endif; ?>
            <a href="?edit=<?php echo (int)$q['quote_id']; ?>" class="btn btn-outline btn-sm">Edit</a>
            <a href="quotation-download.php?id=<?php echo (int)$q['quote_id']; ?>" class="btn btn-outline btn-sm">Download PDF</a>
        </div>
    </div>
<?php endforeach; endif; ?>

<div class="stat-list" style="margin-top:26px;max-width:800px;">
    <div class="stat-row accent-green">
        <div class="stat-ico"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/></svg></div>
        <div><div class="stat-label">Approval Rate</div><div class="stat-sub"><?php echo (int)$approved_count; ?> of <?php echo (int)$total_count; ?> quotations approved</div></div>
        <div class="stat-num"><?php echo $approval_rate; ?>%</div>
    </div>
</div>

<?php include '../includes/footer_dashboard.php'; ?>
