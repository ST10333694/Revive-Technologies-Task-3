<?php
/**
 * Client/freelancer chat with the first admin account (same as the website).
 * GET  /api/messages.php            -> conversation, oldest first (marks admin messages as read)
 * POST /api/messages.php {message}  -> send a message to the admin
 */
require_once __DIR__ . '/helpers.php';
$user = auth_user();
require_api_role($user, 'client', 'freelancer');

$admin = $pdo->query("SELECT user_id, full_name FROM users WHERE role = 'admin' ORDER BY user_id LIMIT 1")->fetch();
if (!$admin) fail('No admin account available', 404);
$adminId = (int)$admin['user_id'];
$me = (int)$user['user_id'];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $text = trim(input()['message'] ?? '');
    if ($text === '') fail('Message cannot be empty');
    $pdo->prepare('INSERT INTO messages (sender_id, receiver_id, message) VALUES (?, ?, ?)')->execute([$me, $adminId, $text]);
    respond(['message' => 'Sent', 'message_id' => (int)$pdo->lastInsertId()], 201);
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $pdo->prepare('UPDATE messages SET is_read = 1 WHERE sender_id = ? AND receiver_id = ?')->execute([$adminId, $me]);
    $stmt = $pdo->prepare(
        'SELECT message_id, sender_id, receiver_id, message, sent_at, is_read FROM messages
         WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)
         ORDER BY sent_at ASC'
    );
    $stmt->execute([$me, $adminId, $adminId, $me]);
    respond(['admin' => $admin, 'messages' => $stmt->fetchAll()]);
}

fail('Method not allowed', 405);
