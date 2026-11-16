<?php
/**
 * includes/alerts_ui.php
 * Shared notification list used by the client, freelancer and admin pages.
 * Every notification is a clickable card; clicking it opens the full message
 * (and marks it as read). Each alert is an array with:
 *   key (string, unique: "n12" = row 12 of the notifications table, others free-form),
 *   icon, title, detail (plain text, escaped here), time, unread (bool), link (page in that portal or null)
 */

/** Pages a notification is allowed to send each role to. */
function alerts_allowed_links($role) {
    $map = [
        'client'     => ['quotations.php' => 'My Quotations', 'invitations.php' => 'Invitation Cards', 'messages.php' => 'Messages', 'dashboard.php' => 'Portfolio', 'notifications.php' => 'Notifications'],
        'freelancer' => ['my-jobs.php' => 'My Jobs', 'available-jobs.php' => 'Available Jobs', 'earnings.php' => 'Earnings', 'messages.php' => 'Messages', 'dashboard.php' => 'Dashboard', 'alerts.php' => 'Notifications'],
        'admin'      => ['freelancers.php' => 'Freelancers', 'quotations.php' => 'Quotations', 'invitations.php' => 'Invitation Cards', 'messages.php' => 'Messages', 'inventory.php' => 'Inventory', 'calendar.php' => 'Calendar', 'dashboard.php' => 'Dashboard', 'alerts.php' => 'Notifications'],
    ];
    return $map[$role] ?? [];
}

/** Opening a saved notification (?view=n12) marks it read. */
function alerts_mark_viewed($pdo, $view) {
    if (preg_match('/^n(\d+)$/', (string)$view, $m)) {
        $pdo->prepare('UPDATE notifications SET is_read = 1 WHERE notification_id = ? AND user_id = ?')
            ->execute([(int)$m[1], $_SESSION['user_id']]);
    }
}

/** Print the opened message (if any) and the clickable list. */
function render_alerts($alerts, $view, $role, $empty_text) {
    $allowed  = alerts_allowed_links($role);
    $selected = null;
    foreach ($alerts as $a) if ($a['key'] === $view) { $selected = $a; break; }

    if ($selected): ?>
        <div class="card notif-detail">
            <div class="notif-detail-top">
                <div class="notif-ico"><?php echo $selected['icon']; ?></div>
                <div style="flex:1;min-width:0;">
                    <h3 style="margin:0 0 4px 0;"><?php echo h($selected['title']); ?></h3>
                    <span style="font-size:12px;color:var(--text-muted);"><?php echo date('d M Y, H:i', strtotime($selected['time'])); ?></span>
                </div>
                <a href="?" class="notif-close" aria-label="Close message">&times;</a>
            </div>
            <p class="notif-full"><?php echo nl2br(h($selected['detail'])); ?></p>
            <div style="display:flex;gap:10px;flex-wrap:wrap;">
                <?php if (!empty($selected['link']) && isset($allowed[$selected['link']])): ?>
                    <a href="<?php echo h($selected['link']); ?>" class="btn btn-primary btn-sm">Go to <?php echo h($allowed[$selected['link']]); ?> &rarr;</a>
                <?php endif; ?>
                <a href="?" class="btn btn-outline btn-sm">Close</a>
            </div>
        </div>
    <?php endif;

    if (empty($alerts)): ?>
        <div class="card empty-state"><?php echo h($empty_text); ?></div>
    <?php else: foreach ($alerts as $a): ?>
        <a class="card notif notif-click <?php echo $a['unread'] ? 'unread' : ''; ?> <?php echo $a['key'] === $view ? 'selected' : ''; ?>" href="?view=<?php echo h(rawurlencode($a['key'])); ?>">
            <div class="notif-ico"><?php echo $a['unread'] ? '🔴' : $a['icon']; ?></div>
            <div style="min-width:0;">
                <strong><?php echo h($a['title']); ?></strong>
                <p class="notif-msg"><?php echo h($a['detail']); ?></p>
                <span style="font-size:12px;color:var(--text-muted);"><?php echo date('d M Y, H:i', strtotime($a['time'])); ?></span>
                <span class="notif-link">Read full message &rarr;</span>
            </div>
        </a>
    <?php endforeach; endif;
}
