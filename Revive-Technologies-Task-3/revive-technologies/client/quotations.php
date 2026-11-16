<?php
/**
 * client/quotations.php
 * Lists this client's quotations with an itemised breakdown.
 * The PDF can only be downloaded once the admin has approved the quotation.
 */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_role('client');

$client_id = $_SESSION['user_id'];

$ids = $pdo->prepare('SELECT quote_id FROM quotations WHERE client_id = ? ORDER BY created_at DESC');
$ids->execute([$client_id]);
$quotations = [];
foreach ($ids->fetchAll(PDO::FETCH_COLUMN) as $qid) {
    $quotations[] = get_quotation($pdo, $qid, $client_id);
}

$page_title = 'My Quotations';
$dash_role  = 'client';
$active     = 'quotations';
$base       = '../';
include '../includes/header_dashboard.php';

$doc_icon = '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M17 21H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h7l5 5v11a2 2 0 0 1-2 2Z"/><path d="M9 13h6M9 17h6"/></svg>';
$dl_icon  = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 4v12m0 0-4-4m4 4 4-4"/><path d="M4 20h16"/></svg>';
?>

<h2>My Quotations</h2>
<p style="color:var(--text-muted);margin-bottom:24px;">Quotations prepared by our team for your events. You can download each one once it has been approved.</p>

<?php if (empty($quotations)): ?>
    <div class="card empty-state">No quotations yet. <a href="request-quote.php" style="text-decoration:underline;">Request a quotation</a> to get started.</div>
<?php else: foreach ($quotations as $q):
    $approved = $q['status'] === 'accepted';
    $rejected = $q['status'] === 'rejected';
    $pill_class = $approved ? 'approved' : ($rejected ? 'rejected' : 'pending');
    $pill_text  = $approved ? 'Approved' : ($rejected ? 'Not approved' : 'Pending');
    $grand = (float)$q['amount'];
?>
    <div class="card q-card">
        <div class="q-head">
            <div class="q-head-left">
                <div class="q-doc-icon"><?php echo $doc_icon; ?></div>
                <div>
                    <p class="q-title"><?php echo h($q['title']); ?></p>
                    <div class="q-meta">
                        <?php echo h(quote_ref($q['quote_id'], $q['created_at'])); ?>
                        &middot; Issued <?php echo nice_date($q['created_at']); ?>
                        &middot; Event: <?php echo nice_date($q['event_date']); ?><?php echo !empty($q['event_time']) ? ' at ' . nice_time($q['event_time']) : ''; ?>
                    </div>
                </div>
            </div>
            <div class="q-head-right">
                <div class="q-total"><?php echo rand_short($grand); ?></div>
                <span class="pill pill-<?php echo $pill_class; ?>"><?php echo $pill_text; ?></span>
            </div>
        </div>

        <div class="q-sep"></div>
        <button type="button" class="q-toggle">
            <span class="q-toggle-label">Hide itemised breakdown</span>
            <span class="chev">&#9650;</span>
        </button>

        <div class="q-breakdown">
            <div class="q-table-scroll">
                <table class="q-table">
                    <thead>
                        <tr><th>Item / Description</th><th>Qty</th><th>Unit Cost</th><th>Subtotal</th></tr>
                    </thead>
                    <tbody>
                        <?php foreach ($q['items'] as $it): ?>
                            <tr>
                                <td><?php echo h($it['description']); ?></td>
                                <td><?php echo (int)$it['qty']; ?></td>
                                <td><?php echo rand_short($it['unit_cost']); ?></td>
                                <td><?php echo rand_short($it['qty'] * $it['unit_cost']); ?></td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                    <tfoot>
                        <tr><td colspan="3">TOTAL</td><td><?php echo rand_short($grand); ?></td></tr>
                    </tfoot>
                </table>
            </div>

            <div class="terms-box">
                <strong>Payment Terms</strong>
                <?php echo h($q['payment_terms']); ?>
            </div>
        </div>

        <?php if ($approved): ?>
            <?php $deadline = deposit_deadline($q['approved_at'] ?: $q['created_at']); ?>
            <div class="deposit-banner">
                <span>⏰ Deposit required within 72 hours<?php echo $deadline ? ' (by ' . date('d M Y, H:i', $deadline) . ')' : ''; ?>.</span>
                <a href="pay-deposit.php?booking_id=<?php echo (int)$q['booking_id']; ?>">View deposit details &rarr;</a>
            </div>
            <div class="q-actions">
                <a class="btn-download" href="quotation-download.php?id=<?php echo (int)$q['quote_id']; ?>"><?php echo $dl_icon; ?> Download PDF</a>
            </div>
        <?php elseif ($rejected): ?>
            <div class="q-actions">
                <button type="button" class="btn-download" disabled><?php echo $dl_icon; ?> Download PDF</button>
                <span class="q-note">This quotation was not approved. Our team will be in touch with a revised quote.</span>
            </div>
        <?php else: ?>
            <div class="q-actions">
                <button type="button" class="btn-download" disabled><?php echo $dl_icon; ?> Download PDF</button>
                <span class="q-note">Download will be available after approval.</span>
            </div>
        <?php endif; ?>
    </div>
<?php endforeach; endif; ?>

<?php include '../includes/footer_dashboard.php'; ?>
