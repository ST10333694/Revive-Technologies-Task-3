<?php
/**
 * admin/inventory.php
 * Décor inventory: add items, restock by quantity, delete, with low-stock warnings.
 */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_role('admin');

// ---- Add new item ----
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'add') {
    $stmt = $pdo->prepare(
        'INSERT INTO inventory (item_name, category, total_stock, available_stock, unit_price) VALUES (?, ?, ?, ?, ?)'
    );
    $stmt->execute([
        trim($_POST['item_name']),
        trim($_POST['category']),
        (int)$_POST['total_stock'],
        (int)$_POST['total_stock'],
        (float)$_POST['unit_price'],
    ]);
    set_flash('Item added to inventory.');
    redirect('inventory.php');
}

// ---- Restock: add a quantity of new units to both total and available stock ----
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'restock') {
    $qty = max(0, (int)($_POST['quantity'] ?? 0));
    if ($qty > 0) {
        $stmt = $pdo->prepare('UPDATE inventory SET total_stock = total_stock + ?, available_stock = available_stock + ? WHERE item_id = ?');
        $stmt->execute([$qty, $qty, (int)$_POST['item_id']]);
        set_flash("Restocked: {$qty} unit(s) added.");
    } else {
        set_flash('Enter a quantity greater than 0 to restock.', 'error');
    }
    redirect('inventory.php');
}

// ---- Delete item ----
if (isset($_GET['delete'])) {
    $stmt = $pdo->prepare('DELETE FROM inventory WHERE item_id = ?');
    $stmt->execute([(int)$_GET['delete']]);
    set_flash('Item removed from inventory.');
    redirect('inventory.php');
}

$search = trim($_GET['q'] ?? '');
$sql = 'SELECT * FROM inventory';
$params = [];
if ($search !== '') {
    $sql .= ' WHERE item_name LIKE ?';
    $params[] = "%{$search}%";
}
$sql .= ' ORDER BY item_name ASC';
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$items = $stmt->fetchAll();

$total_items    = $pdo->query('SELECT COUNT(*) FROM inventory')->fetchColumn();
$out_stock      = $pdo->query('SELECT COUNT(*) FROM inventory WHERE available_stock <= 0')->fetchColumn();
$low_stock      = $pdo->query('SELECT COUNT(*) FROM inventory WHERE available_stock > 0 AND available_stock < total_stock * 0.5 AND available_stock >= total_stock * 0.25')->fetchColumn();
$critical_stock = $pdo->query('SELECT COUNT(*) FROM inventory WHERE available_stock > 0 AND available_stock < total_stock * 0.25')->fetchColumn();

function stock_status($available, $total) {
    if ($available <= 0)  return ['label' => 'Out of Stock', 'class' => 'rejected', 'bar' => 'out'];
    if ($total == 0)      return ['label' => 'In Stock',     'class' => 'active',   'bar' => 'ok'];
    $ratio = $available / $total;
    if ($ratio < 0.25) return ['label' => 'Critical',  'class' => 'rejected', 'bar' => 'crit'];
    if ($ratio < 0.5)  return ['label' => 'Low Stock', 'class' => 'pending',  'bar' => 'low'];
    return ['label' => 'In Stock', 'class' => 'active', 'bar' => 'ok'];
}

$page_title = 'Inventory';
$dash_role  = 'admin';
$active     = 'inventory';
$base       = '../';
include '../includes/header_dashboard.php';
?>

<div class="page-head">
    <div><h2>Inventory Management</h2><p>Track and manage all décor items and equipment</p></div>
</div>

<?php $needs_attention = (int)$out_stock + (int)$critical_stock + (int)$low_stock; ?>
<?php if ($needs_attention > 0): ?>
    <div class="inv-banner">
        <strong>&#9888; <?php echo $needs_attention; ?> item<?php echo $needs_attention === 1 ? '' : 's'; ?> need restocking.</strong>
        <?php
        $parts = [];
        if ($out_stock)      $parts[] = (int)$out_stock . ' out of stock';
        if ($critical_stock) $parts[] = (int)$critical_stock . ' critical (under 25%)';
        if ($low_stock)      $parts[] = (int)$low_stock . ' low (under 50%)';
        echo h(implode(' · ', $parts));
        ?>
    </div>
<?php endif; ?>

<div class="grid grid-4" style="margin-bottom:28px;">
    <div class="card stat-card"><div class="num"><?php echo (int)$total_items; ?></div><div class="label">Total Items</div></div>
    <div class="card stat-card"><div class="num" style="color:var(--warning);"><?php echo (int)$low_stock; ?></div><div class="label">Low Stock</div></div>
    <div class="card stat-card"><div class="num" style="color:var(--danger);"><?php echo (int)$critical_stock; ?></div><div class="label">Critical Stock</div></div>
    <div class="card stat-card"><div class="num" style="color:var(--danger);"><?php echo (int)$out_stock; ?></div><div class="label">Out of Stock</div></div>
</div>

<h3>Add New Item</h3>
<div class="card" style="max-width:640px;margin-bottom:28px;">
    <form method="POST" action="inventory.php">
        <input type="hidden" name="action" value="add">
        <div class="form-grid">
            <div class="field"><label>Item Name</label><input type="text" name="item_name" required></div>
            <div class="field"><label>Category</label><input type="text" name="category" placeholder="Furniture, Décor, Tableware, Linens" required></div>
        </div>
        <div class="form-grid">
            <div class="field"><label>Total Stock</label><input type="number" name="total_stock" required></div>
            <div class="field"><label>Unit Cost (R)</label><input type="number" step="0.01" name="unit_price" required></div>
        </div>
        <button type="submit" class="btn btn-primary btn-block">+ Add Item</button>
    </form>
</div>

<form method="GET" action="inventory.php" class="search-box">
    <input type="text" name="q" placeholder="Search inventory items..." value="<?php echo h($search); ?>">
    <button type="submit" class="btn btn-outline">Search</button>
</form>

<div class="table-wrap inv-wrap">
<table class="data-table inv-table">
    <thead>
    <tr><th>Item</th><th>Category</th><th>In Stock</th><th>Unit Cost</th><th>Status</th><th>Actions</th></tr>
    </thead>
    <tbody>
    <?php if (empty($items)): ?>
        <tr><td colspan="6" class="empty-state">No inventory items found.</td></tr>
    <?php else: foreach ($items as $item):
        $status    = stock_status($item['available_stock'], $item['total_stock']);
        $min_stock = (int)round($item['total_stock'] * 0.5);
        $pct       = $item['total_stock'] > 0 ? min(100, max(0, round($item['available_stock'] / $item['total_stock'] * 100))) : 100;
        $needs     = $status['bar'] !== 'ok';
    ?>
        <tr class="<?php echo $needs ? 'inv-row-' . $status['bar'] : ''; ?>">
            <td data-label="Item"><strong><?php echo h($item['item_name']); ?></strong><br><span class="inv-code">INV-<?php echo str_pad($item['item_id'],3,'0',STR_PAD_LEFT); ?></span></td>
            <td data-label="Category"><?php echo h($item['category']); ?></td>
            <td data-label="In Stock">
                <strong><?php echo (int)$item['available_stock']; ?></strong> <span class="inv-code">/ <?php echo (int)$item['total_stock']; ?> &middot; min <?php echo $min_stock; ?></span>
                <div class="inv-bar"><span class="inv-bar-fill inv-bar-<?php echo $status['bar']; ?>" style="width:<?php echo $pct; ?>%"></span></div>
            </td>
            <td data-label="Unit Cost"><?php echo rand_format($item['unit_price']); ?></td>
            <td data-label="Status">
                <span class="pill pill-<?php echo $status['class']; ?>"><?php echo $status['label']; ?></span>
                <?php if ($needs): ?><div class="inv-hint">Only <?php echo (int)$item['available_stock']; ?> left &mdash; below the minimum of <?php echo $min_stock; ?></div><?php endif; ?>
            </td>
            <td data-label="Actions">
                <div class="inv-actions">
                    <form method="POST" action="inventory.php" class="inv-restock">
                        <input type="hidden" name="action" value="restock">
                        <input type="hidden" name="item_id" value="<?php echo (int)$item['item_id']; ?>">
                        <input type="number" name="quantity" min="1" placeholder="Qty" required aria-label="Quantity to add">
                        <button type="submit" class="btn btn-outline btn-sm">Restock</button>
                    </form>
                    <a href="?delete=<?php echo (int)$item['item_id']; ?>" class="btn btn-danger btn-sm" onclick="return confirm('Delete this item?');">Delete</a>
                </div>
            </td>
        </tr>
    <?php endforeach; endif; ?>
    </tbody>
</table>
</div>

<?php include '../includes/footer_dashboard.php'; ?>
