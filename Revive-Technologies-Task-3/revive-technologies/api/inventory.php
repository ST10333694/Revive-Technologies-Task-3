<?php
/** GET /api/inventory.php -> décor items (read-only; any signed-in user) */
require_once __DIR__ . '/helpers.php';
auth_user();
require_method('GET');
respond($pdo->query('SELECT item_id, item_name, category, total_stock, available_stock, unit_price FROM inventory ORDER BY category, item_name')->fetchAll());
