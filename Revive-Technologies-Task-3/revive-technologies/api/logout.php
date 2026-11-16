<?php
require_once __DIR__ . '/helpers.php';
require_method('POST');
auth_user();
preg_match('/Bearer\s+(\S+)/i', $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '', $m);
$pdo->prepare('DELETE FROM api_tokens WHERE token_hash = ?')->execute([hash('sha256', $m[1])]);
respond(['message' => 'Signed out']);
