<?php
/**
 * admin/quotation-download.php?id=QUOTE_ID
 * Admin can download the PDF of any quotation (approved or not).
 */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_once '../includes/pdf.php';
require_role('admin');

$quote = get_quotation($pdo, (int)($_GET['id'] ?? 0));
if (!$quote) {
    set_flash('Quotation not found.', 'error');
    redirect('quotations.php');
}
output_quotation_pdf($quote);
