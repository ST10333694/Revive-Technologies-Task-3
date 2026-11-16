<?php
/**
 * client/pay-deposit.php
 * Deposit summary for a client whose quotation has been approved (booking status 'confirmed').
 * Shows the amount owed and the next steps.
 */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_role('client');

$client_id  = $_SESSION['user_id'];
$booking_id = (int)($_GET['booking_id'] ?? 0);

$stmt = $pdo->prepare('SELECT * FROM bookings WHERE booking_id = ? AND client_id = ?');
$stmt->execute([$booking_id, $client_id]);
$booking = $stmt->fetch();

if (!$booking) {
    set_flash('Booking not found.', 'error');
    redirect('dashboard.php');
}

$stmt = $pdo->prepare("SELECT * FROM quotations WHERE booking_id = ? AND status = 'accepted' ORDER BY created_at DESC LIMIT 1");
$stmt->execute([$booking_id]);
$quote = $stmt->fetch();

$quoted_amount = $quote['amount'] ?? 0;
$deposit_pct    = deposit_percent($quote['payment_terms'] ?? '');
$deposit_amount = $quoted_amount * $deposit_pct / 100;
$deadline       = deposit_deadline($quote['approved_at'] ?? null);

$page_title = 'Pay Deposit';
$dash_role  = 'client';
$active     = 'dashboard';
$base       = '../';
include '../includes/header_dashboard.php';
?>

<div class="page-head">
    <div>
        <h2>Pending Deposit</h2>
        <p><?php echo h($booking['event_type']); ?> &middot; <?php echo nice_date($booking['event_date']); ?></p>
    </div>
    <a href="dashboard.php" class="btn btn-outline btn-sm">&larr; Back to Portfolio</a>
</div>

<div class="card" style="max-width:520px;">
    <?php if ($quote): ?>
        <div class="list-item" style="padding-left:0;padding-right:0;">
            <span>Approved Quote Total</span>
            <strong><?php echo rand_format($quoted_amount); ?></strong>
        </div>
        <?php if ($deadline): ?>
        <div class="deposit-banner" style="margin:0 0 10px 0;">⏰ Deposit required within 72 hours (by <?php echo date('d M Y, H:i', $deadline); ?>).</div>
        <?php endif; ?>
        <div class="list-item" style="padding-left:0;padding-right:0;">
            <span>Deposit Due (<?php echo (int)$deposit_pct; ?>%)</span>
            <strong style="color:var(--gold);font-size:20px;"><?php echo rand_format($deposit_amount); ?></strong>
        </div>
    <?php else: ?>
        <p class="empty-state">No approved quotation found for this booking yet.</p>
    <?php endif; ?>

    <div class="alert alert-success" style="margin-top:18px;">
        Payment processing isn't connected yet — this is a placeholder screen. Once a payment gateway (e.g. PayFast, Yoco or Ozow) is set up, this button will take you to a real secure payment page.
    </div>

    <button type="button" class="btn btn-primary btn-block" disabled style="opacity:.6;cursor:not-allowed;">Pay Deposit &mdash; Coming Soon</button>
</div>

<?php include '../includes/footer_dashboard.php'; ?>
