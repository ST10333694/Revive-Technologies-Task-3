<?php
/**
 * client/invitations.php
 * Client requests custom invitation card designs.
 * Stored as a booking with event_type = 'Invitation Cards: <style>'.
 */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_role('client');

$client_id = $_SESSION['user_id'];

$card_styles = [
    'wedding'    => ['Wedding Invitation',      'From R 350/set of 50'],
    'birthday'   => ['Birthday Party Invite',   'From R 250/set of 50'],
    'babyshower' => ['Baby Shower Invite',      'From R 280/set of 50'],
    'reveal'     => ['Gender Reveal Invite',    'From R 300/set of 50'],
    'traditional'=> ['Traditional Ceremony',    'From R 400/set of 50'],
    'corporate'  => ['Corporate Event Invite',  'From R 500/set of 50'],
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $style       = $_POST['card_style'] ?? 'wedding';
    $styleLabel  = $card_styles[$style][0] ?? 'Invitation Cards';
    $host_names  = trim($_POST['host_names'] ?? '');
    $event_date  = $_POST['event_date'] ?? date('Y-m-d');
    $event_time  = clean_time($_POST['event_time'] ?? '');
    $venue       = trim($_POST['venue'] ?? '');
    $colour      = trim($_POST['colour_scheme'] ?? '');
    $quantity    = trim($_POST['quantity'] ?? '');
    $extra_info  = trim($_POST['additional_info'] ?? '');

    $notes = "Card style: {$styleLabel}\nHost(s): {$host_names}\nColour/Theme: {$colour}\nQuantity: {$quantity}\nNotes: {$extra_info}";

    // The booking keeps the request visible in the admin's quotation list (so the cards can be priced)...
    $stmt = $pdo->prepare(
        "INSERT INTO bookings (client_id, event_type, event_date, event_time, venue, guest_count, notes, status)
         VALUES (?, ?, ?, ?, ?, NULL, ?, 'pending')"
    );
    $stmt->execute([$client_id, 'Invitation Cards: ' . $styleLabel, $event_date, $event_time, $venue, $notes]);
    $booking_id = (int)$pdo->lastInsertId();

    // ...and this record is what the admin approves, updates the progress of, and finally uploads the finished cards to.
    $stmt = $pdo->prepare(
        "INSERT INTO invitation_requests (client_id, booking_id, style, host_names, event_date, event_time, venue, colour_scheme, quantity, details)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    );
    $stmt->execute([$client_id, $booking_id, $styleLabel, $host_names, $event_date, $event_time, $venue, $colour, $quantity !== '' ? (int)$quantity : null, $extra_info]);

    notify_admins($pdo, 'New invitation card request', ($_SESSION['full_name'] ?? 'A client') . ' requested ' . $styleLabel . '.', 'invitations.php');

    set_flash('Your invitation card request has been sent to our design team. You can follow its progress below.');
    redirect('invitations.php#my-requests');
}

// This client's submitted card requests
$stmt = $pdo->prepare('SELECT * FROM invitation_requests WHERE client_id = ? ORDER BY created_at DESC');
$stmt->execute([$client_id]);
$my_requests = $stmt->fetchAll();

$page_title = 'Invitation Cards';
$dash_role  = 'client';
$active     = 'invitations';
$base       = '../';
include '../includes/header_dashboard.php';
?>

<h2>Request Invitation Cards</h2>
<p style="color:var(--text-muted);margin-bottom:24px;">Let us design beautiful, personalised invitation cards for your event. Choose a style and fill in your details.</p>

<form method="POST" action="invitations.php">
    <p style="color:var(--gold);font-weight:700;font-size:13px;text-transform:uppercase;">1. Choose a Card Style</p>
    <div class="grid grid-3" style="margin-bottom:28px;">
        <?php foreach ($card_styles as $key => $info): ?>
        <label class="role-option" style="text-align:left;">
            <input type="radio" name="card_style" value="<?php echo $key; ?>" style="display:none;" <?php echo $key === 'wedding' ? 'checked' : ''; ?>>
            <strong><?php echo h($info[0]); ?></strong>
            <p style="font-size:12px;color:var(--text-muted);margin:6px 0;">Personalised design, printed and ready for your event.</p>
            <span style="color:var(--success);font-weight:700;font-size:13px;"><?php echo h($info[1]); ?></span>
        </label>
        <?php endforeach; ?>
    </div>

    <p style="color:var(--gold);font-weight:700;font-size:13px;text-transform:uppercase;">2. Your Event Details</p>
    <div class="card" style="max-width:700px;">
        <div class="form-grid">
            <div class="field"><label>Your Name</label><input type="text" value="<?php echo h($_SESSION['full_name']); ?>" disabled></div>
            <div class="field"><label>Phone / WhatsApp</label><input type="tel" name="phone" placeholder="+27 XX XXX XXXX"></div>
        </div>
        <div class="field"><label>Event / Host Name(s)</label><input type="text" name="host_names" placeholder="e.g. Thabo &amp; Nomvula, or Sipho's 30th"></div>
        <div class="form-grid">
            <div class="field"><label>Event Date</label><input type="date" name="event_date" required></div>
            <div class="field"><label>Event Start Time</label><input type="text" name="event_time" data-clock placeholder="Select time"></div>
        </div>
        <div class="field"><label>Venue / Location</label><input type="text" name="venue" placeholder="Venue name &amp; city"></div>
        <div class="field"><label>Colour Scheme / Theme</label><input type="text" name="colour_scheme" placeholder="e.g. Dusty rose &amp; gold, Blue &amp; white"></div>
        <div class="field"><label>Quantity Needed</label><input type="number" name="quantity" placeholder="e.g. 100"></div>
        <div class="field"><label>Additional Information</label><textarea name="additional_info" placeholder="Any special wording, RSVP details, dress code..."></textarea></div>
        <button type="submit" class="btn btn-primary btn-block">✉️ Submit Card Request</button>
    </div>
</form>

<!-- ============ Submitted card requests ============ -->
<h3 class="inv-section-title" id="my-requests">Your Invitation Card Requests</h3>
<p style="color:var(--text-muted);margin-bottom:18px;">Follow the progress of your cards here. You can download them once our team has approved and completed them.</p>

<?php if (empty($my_requests)): ?>
    <div class="card empty-state">You haven't requested any invitation cards yet. Fill in the form above to get started.</div>
<?php else: foreach ($my_requests as $r):
    [$status_label, $status_class] = invitation_status_info($r['status']);
    $stages = invitation_stages();
    $stage_label = $r['stage'] && isset($stages[$r['stage']]) ? $stages[$r['stage']][0] : null;
    $done = $r['status'] === 'completed';
?>
    <div class="card inv-card">
        <div class="inv-head">
            <div>
                <p class="inv-title"><?php echo h($r['style']); ?><?php echo $r['host_names'] ? ' &middot; ' . h($r['host_names']) : ''; ?></p>
                <div class="inv-meta">
                    Requested <?php echo nice_date($r['created_at']); ?>
                    &middot; Event: <?php echo nice_date($r['event_date']); ?><?php echo !empty($r['event_time']) ? ' at ' . nice_time($r['event_time']) : ''; ?>
                    <?php echo $r['quantity'] ? ' &middot; ' . (int)$r['quantity'] . ' cards' : ''; ?>
                </div>
            </div>
            <span class="pill pill-<?php echo $status_class; ?>"><?php echo h($status_label); ?></span>
        </div>

        <?php if ($r['status'] === 'rejected'): ?>
            <div class="inv-note">This request was not approved.<?php echo $r['progress_note'] ? ' ' . h($r['progress_note']) : ' Our team will contact you if anything can be adjusted.'; ?></div>

        <?php else: ?>
            <div class="progress-track"><div class="progress-fill <?php echo $done ? 'done' : ''; ?>" style="width:<?php echo (int)$r['progress']; ?>%;"></div></div>

            <?php if ($r['status'] === 'submitted'): ?>
                <div class="inv-stage">⏳ Request received - waiting for approval by our team.</div>
            <?php elseif ($done): ?>
                <div class="inv-stage">🎉 Your invitation cards are ready!</div>
            <?php else: ?>
                <div class="inv-stage">🎨 Creation of your invitation cards is still in progress.</div>
                <div class="inv-meta"><?php echo h($stage_label ?: 'In progress'); ?> &middot; <?php echo (int)$r['progress']; ?>% complete</div>
            <?php endif; ?>

            <?php if (!empty($r['progress_note'])): ?><div class="inv-note"><?php echo h($r['progress_note']); ?></div><?php endif; ?>

            <div class="inv-actions">
                <?php if ($done && !empty($r['file_path'])): ?>
                    <a class="btn-download" href="invitation-download.php?id=<?php echo (int)$r['request_id']; ?>">
                        <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 4v12m0 0-4-4m4 4 4-4"/><path d="M4 20h16"/></svg>
                        Download Invitation Cards
                    </a>
                <?php else: ?>
                    <button type="button" class="btn-download" disabled>Download Invitation Cards</button>
                    <span class="q-note">Download will be available once your cards are completed.</span>
                <?php endif; ?>
            </div>
        <?php endif; ?>
    </div>
<?php endforeach; endif; ?>

<?php include '../includes/footer_dashboard.php'; ?>
