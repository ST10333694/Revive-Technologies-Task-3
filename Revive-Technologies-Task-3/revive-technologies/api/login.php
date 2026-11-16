<?php
require_once __DIR__ . '/helpers.php';
require_method('POST');

$d = input();
$email = trim($d['email'] ?? '');
$password = $d['password'] ?? '';
if ($email === '' || $password === '') fail('Email and password are required');

$stmt = $pdo->prepare('SELECT * FROM users WHERE email = ?');
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user || !password_verify($password, $user['password'])) fail('Incorrect email or password', 401);
if ($user['status'] === 'suspended') fail('Your account has been suspended', 403);

respond([
    'token' => issue_token($pdo, (int)$user['user_id']),
    'user'  => [
        'user_id'   => (int)$user['user_id'],
        'full_name' => $user['full_name'],
        'email'     => $user['email'],
        'phone'     => $user['phone'],
        'role'      => $user['role'],
    ],
]);
