<?php
/**
 * GET  /api/bookings.php  -> client: own bookings | freelancer: assigned bookings | admin: all
 * POST /api/bookings.php  -> client creates a booking request (status 'pending')
 */
require_once __DIR__ . '/helpers.php';
$user = auth_user();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if ($user['role'] === 'client') {
        $stmt = $pdo->prepare('SELECT * FROM bookings WHERE client_id = ? ORDER BY event_date DESC');
        $stmt->execute([$user['user_id']]);
    } elseif ($user['role'] === 'freelancer') {
        $stmt = $pdo->prepare(
            'SELECT b.* FROM bookings b JOIN freelancers f ON f.freelancer_id = b.freelancer_id
             WHERE f.user_id = ? ORDER BY b.event_date DESC'
        );
        $stmt->execute([$user['user_id']]);
    } else {
        $stmt = $pdo->query('SELECT * FROM bookings ORDER BY event_date DESC');
    }
    respond($stmt->fetchAll());
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    require_api_role($user, 'client');
    $d = input();
    $eventType = trim($d['event_type'] ?? '');
    $eventDate = $d['event_date'] ?? '';
    if ($eventType === '') fail('Event type is required');
    $dt = DateTime::createFromFormat('Y-m-d', $eventDate);
    if (!$dt || $dt->format('Y-m-d') !== $eventDate) fail('Event date must look like 2026-12-31');

    $stmt = $pdo->prepare(
        "INSERT INTO bookings (client_id, event_type, event_date, venue, guest_count, notes, status)
         VALUES (?, ?, ?, ?, ?, ?, 'pending')"
    );
    $stmt->execute([
        $user['user_id'], $eventType, $eventDate,
        trim($d['venue'] ?? ''), (int)($d['guest_count'] ?? 0), trim($d['notes'] ?? ''),
    ]);
    respond(['message' => 'Booking request submitted', 'booking_id' => (int)$pdo->lastInsertId()], 201);
}

fail('Method not allowed', 405);
