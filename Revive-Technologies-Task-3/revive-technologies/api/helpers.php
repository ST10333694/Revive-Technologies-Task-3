<?php
/**
 * api/helpers.php
 * Shared tools for every API endpoint. Uses the SAME database connection
 * as the website (config/database.php) - no sessions, tokens only.
 */
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/../config/database.php';   // gives $pdo and $APP_ENV

function input(): array {
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

function respond($data, int $code = 200): void {
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

function fail(string $message, int $code = 400): void {
    respond(['error' => $message], $code);
}

function require_method(string $method): void {
    if ($_SERVER['REQUEST_METHOD'] !== $method) {
        fail('Method not allowed', 405);
    }
}

/** Create a token for a user, store only its hash, return the plain token. */
function issue_token(PDO $pdo, int $userId): string {
    $token = bin2hex(random_bytes(32));
    $stmt = $pdo->prepare(
        'INSERT INTO api_tokens (user_id, token_hash, expires_at)
         VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY))'
    );
    $stmt->execute([$userId, hash('sha256', $token)]);
    return $token;
}

/** Read "Authorization: Bearer xxx", return the logged-in user row or stop with 401. */
function auth_user(): array {
    global $pdo;
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/Bearer\s+(\S+)/i', $header, $m)) {
        fail('Not signed in', 401);
    }
    $stmt = $pdo->prepare(
        'SELECT u.user_id, u.full_name, u.email, u.phone, u.role, u.status
         FROM api_tokens t JOIN users u ON u.user_id = t.user_id
         WHERE t.token_hash = ? AND t.expires_at > NOW()'
    );
    $stmt->execute([hash('sha256', $m[1])]);
    $user = $stmt->fetch();
    if (!$user) {
        fail('Session expired, please sign in again', 401);
    }
    if ($user['status'] === 'suspended') {
        fail('Account suspended', 403);
    }
    return $user;
}

function require_api_role(array $user, string ...$roles): void {
    if (!in_array($user['role'], $roles, true)) {
        fail('You do not have permission to do that', 403);
    }
}
