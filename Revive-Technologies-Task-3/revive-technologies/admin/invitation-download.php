<?php
/** admin/invitation-download.php?id=REQUEST_ID - admin can download any uploaded invitation file. */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_role('admin');

$stmt = $pdo->prepare('SELECT * FROM invitation_requests WHERE request_id = ?');
$stmt->execute([(int)($_GET['id'] ?? 0)]);
$req = $stmt->fetch();
if (!$req || empty($req['file_path'])) {
    set_flash('No file has been uploaded for that request yet.', 'error');
    redirect('invitations.php');
}
send_invitation_file($req);
