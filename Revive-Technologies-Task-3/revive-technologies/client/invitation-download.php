<?php
/**
 * client/invitation-download.php?id=REQUEST_ID
 * Sends the finished invitation cards - only to the client who requested them,
 * and only once the admin has marked the request as completed.
 */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_role('client');

$stmt = $pdo->prepare('SELECT * FROM invitation_requests WHERE request_id = ? AND client_id = ?');
$stmt->execute([(int)($_GET['id'] ?? 0), $_SESSION['user_id']]);
$req = $stmt->fetch();

if (!$req || $req['status'] !== 'completed' || empty($req['file_path'])) {
    set_flash('Your invitation cards can be downloaded once they have been approved and completed.', 'error');
    redirect('invitations.php#my-requests');
}
send_invitation_file($req);
