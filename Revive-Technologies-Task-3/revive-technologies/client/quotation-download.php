<?php
/**
 * client/quotation-download.php?id=QUOTE_ID
 * Sends the quotation as a PDF - but ONLY if it belongs to this client
 * and has been approved by the admin.
 */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_once '../includes/pdf.php';
require_role('client');

$quote = get_quotation($pdo, (int)($_GET['id'] ?? 0), $_SESSION['user_id']);

if (!$quote) {
    set_flash('Quotation not found.', 'error');
    redirect('quotations.php');
}
if ($quote['status'] !== 'accepted') {
    set_flash('Download will be available after approval.', 'error');
    redirect('quotations.php');
}

output_quotation_pdf($quote);
