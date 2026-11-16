<?php
/**
 * includes/functions.php
 * -------------------------------------------------
 * Small reusable helper functions.
 * -------------------------------------------------
 */

// Start the session once, on every page, before any HTML is sent.
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

/** Escape output to prevent XSS when printing user data in HTML. */
function h($string) {
    return htmlspecialchars($string ?? '', ENT_QUOTES, 'UTF-8');
}

/** Is someone currently logged in? */
function is_logged_in() {
    return isset($_SESSION['user_id']);
}

/** Redirect to another page and stop executing the current script. */
function redirect($path) {
    header("Location: {$path}");
    exit;
}

/** Format a number as South African Rand, e.g. R 1,250.00 */
function rand_format($amount) {
    return 'R ' . number_format((float)$amount, 2);
}

/** Format a date as "12 Sep 2026" */
function nice_date($date) {
    return date('d M Y', strtotime($date));
}

/** Flash message helper - stores a message to show once on the next page load. */
function set_flash($message, $type = 'success') {
    $_SESSION['flash'] = ['message' => $message, 'type' => $type];
}

function get_flash() {
    if (!empty($_SESSION['flash'])) {
        $flash = $_SESSION['flash'];
        unset($_SESSION['flash']);
        return $flash;
    }
    return null;
}

/** Format a number as short Rand with space thousands, e.g. R 15 500 (used on quotations). */
function rand_short($amount) {
    return 'R ' . number_format((float)$amount, 0, '.', ' ');
}

/** Format a TIME / datetime value as "14:30". Returns '' when empty. */
function nice_time($time) {
    return $time ? date('H:i', strtotime($time)) : '';
}

/** Reference number shown on a quotation, e.g. QT-2026-087 */
function quote_ref($quote_id, $created_at = null) {
    $year = $created_at ? date('Y', strtotime($created_at)) : date('Y');
    return 'QT-' . $year . '-' . str_pad((int)$quote_id, 3, '0', STR_PAD_LEFT);
}

/** Deposit percentage hidden inside a payment-terms sentence ("50% deposit ..." => 50). */
function deposit_percent($terms) {
    if (preg_match('/(\d{1,3})\s*%\s*deposit/i', (string)$terms, $m)) return min(100, (int)$m[1]);
    if (stripos((string)$terms, 'upfront') !== false) return 100;
    return 30;
}

/** The moment the 72-hour deposit window closes for an approved quotation. */
function deposit_deadline($approved_at) {
    return $approved_at ? strtotime($approved_at) + 72 * 3600 : null;
}

/**
 * Save an in-app notification for one user.
 * $link is a page inside that user's portal, e.g. 'quotations.php'.
 */
function notify($pdo, $user_id, $title, $message, $link = null) {
    $stmt = $pdo->prepare('INSERT INTO notifications (user_id, title, message, link) VALUES (?, ?, ?, ?)');
    $stmt->execute([(int)$user_id, $title, $message, $link]);
}

/** Notify every admin account. */
function notify_admins($pdo, $title, $message, $link = null) {
    $ids = $pdo->query("SELECT user_id FROM users WHERE role = 'admin'")->fetchAll(PDO::FETCH_COLUMN);
    foreach ($ids as $id) notify($pdo, $id, $title, $message, $link);
}

/** Accepts "14:30", "14:30:00" or "" and returns a clean HH:MM:SS string or null. */
function clean_time($value) {
    $value = trim((string)$value);
    if (!preg_match('/^([01]?\d|2[0-3]):([0-5]\d)(:[0-5]\d)?$/', $value, $m)) return null;
    return sprintf('%02d:%02d:00', (int)$m[1], (int)$m[2]);
}

/**
 * Load one quotation with its booking, client and line items.
 * Pass $client_id to make sure a client can only ever load their own.
 */
function get_quotation($pdo, $quote_id, $client_id = null) {
    $sql = "SELECT q.*, b.event_type, b.event_date, b.event_time, b.venue, u.full_name AS client_name, u.email AS client_email
            FROM quotations q
            JOIN bookings b ON q.booking_id = b.booking_id
            JOIN users u ON q.client_id = u.user_id
            WHERE q.quote_id = ?";
    $params = [(int)$quote_id];
    if ($client_id !== null) { $sql .= ' AND q.client_id = ?'; $params[] = (int)$client_id; }
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $quote = $stmt->fetch();
    if (!$quote) return null;

    $stmt = $pdo->prepare('SELECT * FROM quotation_items WHERE quote_id = ? ORDER BY sort_order, item_id');
    $stmt->execute([(int)$quote_id]);
    $quote['items'] = $stmt->fetchAll();

    // Quotations created before itemised lines existed: show one summary line.
    if (empty($quote['items'])) {
        $quote['items'] = [[
            'description' => trim($quote['details'] ?? '') !== '' ? trim(strtok($quote['details'], "\n")) : 'Décor package',
            'qty' => 1,
            'unit_cost' => $quote['amount'],
        ]];
    }
    if (empty($quote['title'])) $quote['title'] = $quote['event_type'] . ' Styling';
    if (empty($quote['payment_terms'])) $quote['payment_terms'] = '50% deposit required to confirm booking. Balance due within 72 hours after approval.';
    return $quote;
}


/**
 * Redirect after sign-in / register. When the page is shown inside the homepage pop-up
 * (iframe, ?embed=1) the whole browser window has to move, not just the pop-up.
 */
function auth_redirect($url, $embed = false) {
    if ($embed) {
        echo '<!DOCTYPE html><html><head><meta charset="utf-8"></head><body><script>window.top.location.href = ' . json_encode($url) . ';</script>'
           . '<noscript><a href="' . h($url) . '" target="_top">Continue</a></noscript></body></html>';
        exit;
    }
    redirect($url);
}


/** The steps an invitation card request goes through: key => [label shown to the client, progress %, status saved]. */
function invitation_stages() {
    return [
        'approved'  => ['Approved - design starting soon',     5,   'approved'],
        'design'    => ['Design in progress',                  30,  'in_progress'],
        'review'    => ['Draft being refined',                 60,  'in_progress'],
        'final'     => ['Final touches & print preparation',   85,  'in_progress'],
        'completed' => ['Completed - ready to download',       100, 'completed'],
    ];
}

/** [label, pill css class] for an invitation request status. */
function invitation_status_info($status) {
    $map = [
        'submitted'   => ['Awaiting approval', 'pending'],
        'approved'    => ['Approved',          'approved'],
        'in_progress' => ['In progress',       'quoted'],
        'completed'   => ['Completed',         'approved'],
        'rejected'    => ['Not approved',      'rejected'],
    ];
    return $map[$status] ?? [ucfirst($status), 'pending'];
}

/** Check an uploaded finished-card file. Returns [ext, null] or [null, error message]. */
function check_invitation_upload($file) {
    if (!$file || $file['error'] === UPLOAD_ERR_NO_FILE) return [null, 'no file'];
    if ($file['error'] !== UPLOAD_ERR_OK || $file['size'] > 10 * 1024 * 1024) return [null, 'The file is too large (10 MB maximum).'];
    $head = file_get_contents($file['tmp_name'], false, null, 0, 5);
    if ($head === '%PDF-') return ['pdf', null];
    $info = @getimagesize($file['tmp_name']);
    $types = [IMAGETYPE_JPEG => 'jpg', IMAGETYPE_PNG => 'png', IMAGETYPE_WEBP => 'webp'];
    if ($info && isset($types[$info[2]])) return [$types[$info[2]], null];
    return [null, 'Please upload a PDF, JPG, PNG or WEBP file.'];
}

/** Send a finished invitation file to the browser as a download (caller has already checked permission). */
function send_invitation_file($req) {
    $path = dirname(__DIR__) . '/uploads/invitations/' . basename($req['file_path'] ?? '');
    if (empty($req['file_path']) || !is_file($path)) { http_response_code(404); echo 'File not found.'; exit; }
    $ext  = strtolower(pathinfo($path, PATHINFO_EXTENSION));
    $mime = ['pdf' => 'application/pdf', 'jpg' => 'image/jpeg', 'png' => 'image/png', 'webp' => 'image/webp'][$ext] ?? 'application/octet-stream';
    $name = preg_replace('/[^A-Za-z0-9._-]+/', '_', $req['file_name'] ?: ('invitation-cards.' . $ext));
    while (ob_get_level() > 0) ob_end_clean();
    header('Content-Type: ' . $mime);
    header('Content-Disposition: attachment; filename="' . $name . '"');
    header('Content-Length: ' . filesize($path));
    readfile($path);
    exit;
}


/** Make sure the job_applications table exists (so an old database keeps working without a manual migration). */
function ensure_job_applications_table($pdo) {
    static $done = false;
    if ($done) return;
    $pdo->exec("CREATE TABLE IF NOT EXISTS job_applications (
        application_id INT AUTO_INCREMENT PRIMARY KEY,
        booking_id     INT NOT NULL,
        freelancer_id  INT NOT NULL,
        status         ENUM('under_review','approved','rejected') NOT NULL DEFAULT 'under_review',
        applied_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        decided_at     DATETIME DEFAULT NULL,
        UNIQUE KEY one_application (booking_id, freelancer_id),
        FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
        FOREIGN KEY (freelancer_id) REFERENCES freelancers(freelancer_id) ON DELETE CASCADE
    ) ENGINE=InnoDB");
    $done = true;
}

/** [label, pill css class] for a job application status. */
function application_status_info($status) {
    $map = [
        'under_review' => ['Under review', 'pending'],
        'approved'     => ['Approved',     'approved'],
        'rejected'     => ['Rejected',     'rejected'],
    ];
    return $map[$status] ?? [ucfirst($status), 'pending'];
}
