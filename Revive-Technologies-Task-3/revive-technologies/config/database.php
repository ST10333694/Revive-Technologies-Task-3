<?php
// Local XAMPP defaults; config/database.local.php (git-ignored) overrides them on a hosted server.
$DB_HOST = 'localhost';
$DB_NAME = 'revive_technologies';
$DB_USER = 'root';
$DB_PASS = '';
$APP_ENV = 'development';

if (is_file(__DIR__ . '/database.local.php')) {
    require __DIR__ . '/database.local.php';
}

/** @var PDO $pdo  Shared database connection, available to any file that requires this one. */
try {
    $pdo = new PDO(
        "mysql:host={$DB_HOST};dbname={$DB_NAME};charset=utf8mb4",
        $DB_USER,
        $DB_PASS,
        [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]
    );
} catch (PDOException $e) {
    error_log('Database connection failed: ' . $e->getMessage());
    die($APP_ENV === 'production'
        ? 'The site is temporarily unavailable. Please try again shortly.'
        : 'Database connection failed: ' . $e->getMessage());
}
