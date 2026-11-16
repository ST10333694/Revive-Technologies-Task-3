<?php
/**
 * GET  /api/quotations.php                              -> client: own quotes | admin: all
 * POST /api/quotations.php {quote_id, decision}         -> client accepts/rejects ('accepted' | 'rejected')
 */
require_once __DIR__ . '/helpers.php';
$user = auth_user();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    require_api_role($user, 'client', 'admin');
    $sql = 'SELECT q.*, b.event_type, b.event_date, b.venue
            FROM quotations q JOIN bookings b ON b.booking_id = q.booking_id';
    if ($user['role'] === 'client') {
        $stmt = $pdo->prepare($sql . ' WHERE q.client_id = ? ORDER BY q.created_at DESC');
        $stmt->execute([$user['user_id']]);
    } else {
        $stmt = $pdo->query($sql . ' ORDER BY q.created_at DESC');
    }
    respond($stmt->fetchAll());
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    require_api_role($user, 'client');
    $d = input();
    $quoteId  = (int)($d['quote_id'] ?? 0);
    $decision = ($d['decision'] ?? '') === 'accepted' ? 'accepted' : 'rejected';

    $stmt = $pdo->prepare('SELECT * FROM quotations WHERE quote_id = ? AND client_id = ?');
    $stmt->execute([$quoteId, $user['user_id']]);
    $quote = $stmt->fetch();
    if (!$quote) fail('Quotation not found', 404);
    if ($quote['status'] !== 'sent') fail('This quotation has already been answered', 409);

    // Same rules as client/quotations.php on the website
    $pdo->beginTransaction();
    $pdo->prepare('UPDATE quotations SET status = ? WHERE quote_id = ?')->execute([$decision, $quoteId]);
    $pdo->prepare('UPDATE bookings SET status = ? WHERE booking_id = ?')
        ->execute([$decision === 'accepted' ? 'confirmed' : 'cancelled', $quote['booking_id']]);
    $pdo->commit();

    respond(['message' => "Quotation $decision"]);
}

fail('Method not allowed', 405);
