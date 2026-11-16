<?php
require_once __DIR__ . '/helpers.php';
require_method('POST');

$d = input();
$name  = trim($d['full_name'] ?? '');
$email = trim($d['email'] ?? '');
$phone = trim($d['phone'] ?? '');
$pass  = $d['password'] ?? '';
$role  = ($d['role'] ?? 'client') === 'freelancer' ? 'freelancer' : 'client';  // admin can never self-register
$skill = trim($d['skill'] ?? '');

if ($name === '') fail('Please enter your name');
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) fail('Please enter a valid email address');
if (strlen($pass) < 6) fail('Password must be at least 6 characters');
if ($role === 'freelancer' && $skill === '') fail('Please tell us your main skill');

$stmt = $pdo->prepare('SELECT user_id FROM users WHERE email = ?');
$stmt->execute([$email]);
if ($stmt->fetch()) fail('That email address is already registered', 409);

$pdo->beginTransaction();
try {
    $stmt = $pdo->prepare('INSERT INTO users (full_name, email, phone, password, role) VALUES (?, ?, ?, ?, ?)');
    $stmt->execute([$name, $email, $phone, password_hash($pass, PASSWORD_DEFAULT), $role]);
    $userId = (int)$pdo->lastInsertId();

    if ($role === 'freelancer') {
        $stmt = $pdo->prepare('INSERT INTO freelancers (user_id, skill, bio, hourly_rate, rating) VALUES (?, ?, ?, 0, 0)');
        $stmt->execute([$userId, $skill, '']);
    }
    $pdo->commit();
} catch (Throwable $e) {
    $pdo->rollBack();
    error_log($e->getMessage());
    fail('Could not create the account', 500);
}

respond([
    'token' => issue_token($pdo, $userId),
    'user'  => ['user_id' => $userId, 'full_name' => $name, 'email' => $email, 'phone' => $phone, 'role' => $role],
], 201);
