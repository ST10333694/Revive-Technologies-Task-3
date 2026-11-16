<?php
/**
 * admin/messages.php
 * Admin sees a list of conversations (one per client/freelancer who
 * has messaged in) and can open one to reply.
 */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_role('admin');

$admin_id = $_SESSION['user_id'];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && !empty($_POST['message']) && !empty($_POST['to'])) {
    $stmt = $pdo->prepare('INSERT INTO messages (sender_id, receiver_id, message) VALUES (?, ?, ?)');
    $stmt->execute([$admin_id, (int)$_POST['to'], trim($_POST['message'])]);
    redirect('messages.php?with=' . (int)$_POST['to']);
}

// Everyone who has exchanged a message with the admin (newest first), with unread counts
$stmt = $pdo->prepare(
    "SELECT u.user_id, u.full_name, u.role, u.profile_image,
        (SELECT message FROM messages m2 WHERE (m2.sender_id=u.user_id AND m2.receiver_id=?) OR (m2.sender_id=? AND m2.receiver_id=u.user_id) ORDER BY m2.sent_at DESC LIMIT 1) AS last_message,
        (SELECT sent_at FROM messages m3 WHERE (m3.sender_id=u.user_id AND m3.receiver_id=?) OR (m3.sender_id=? AND m3.receiver_id=u.user_id) ORDER BY m3.sent_at DESC LIMIT 1) AS last_time,
        (SELECT COUNT(*) FROM messages m4 WHERE m4.sender_id=u.user_id AND m4.receiver_id=? AND m4.is_read=0) AS unread
     FROM users u
     WHERE u.user_id IN (
        SELECT sender_id FROM messages WHERE receiver_id = ?
        UNION
        SELECT receiver_id FROM messages WHERE sender_id = ?
     )
     ORDER BY last_time DESC"
);
$stmt->execute([$admin_id, $admin_id, $admin_id, $admin_id, $admin_id, $admin_id, $admin_id]);
$conversations = $stmt->fetchAll();

// Everyone the admin could start a new conversation with (clients and freelancers)
$stmt = $pdo->prepare("SELECT user_id, full_name, role, profile_image FROM users WHERE role <> 'admin' AND user_id <> ? ORDER BY role, full_name");
$stmt->execute([$admin_id]);
$contacts = $stmt->fetchAll();

$with = isset($_GET['with']) ? (int)$_GET['with'] : ($conversations[0]['user_id'] ?? null);

$messages = [];
$with_user = null;
if ($with) {
    $stmt = $pdo->prepare('SELECT user_id, full_name, role, profile_image FROM users WHERE user_id = ? AND role <> \'admin\'');
    $stmt->execute([$with]);
    $with_user = $stmt->fetch();

    if ($with_user) {
        $stmt = $pdo->prepare("UPDATE messages SET is_read = 1 WHERE sender_id = ? AND receiver_id = ?");
        $stmt->execute([$with, $admin_id]);

        $stmt = $pdo->prepare(
            "SELECT * FROM messages WHERE (sender_id=? AND receiver_id=?) OR (sender_id=? AND receiver_id=?) ORDER BY sent_at ASC"
        );
        $stmt->execute([$admin_id, $with, $with, $admin_id]);
        $messages = $stmt->fetchAll();
    }
}

/** Small round avatar: the profile photo if there is one, otherwise initials. */
function msg_avatar($u, $base) {
    if (!empty($u['profile_image'])) {
        return '<img class="msg-avatar" src="' . $base . h($u['profile_image']) . '" alt="">';
    }
    $ini = '';
    foreach (array_slice(preg_split('/\s+/', trim($u['full_name'])), 0, 2) as $part) $ini .= mb_strtoupper(mb_substr($part, 0, 1));
    return '<span class="msg-avatar msg-avatar-ini">' . h($ini) . '</span>';
}

$page_title = 'Messages';
$dash_role  = 'admin';
$active     = 'messages';
$base       = '../';
include '../includes/header_dashboard.php';
?>

<div class="msg-layout">

    <!-- Conversation list -->
    <aside class="msg-side">
        <div class="msg-side-head">
            <h2>Messages</h2>
            <button type="button" class="msg-new-btn" data-open-modal="newChat" title="Start a new conversation" aria-label="Start a new conversation">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>
            </button>
        </div>
        <div class="msg-search"><input type="search" placeholder="Search conversations" data-filter-input="convList"></div>

        <div class="msg-list" id="convList">
            <?php if (empty($conversations)): ?>
                <p class="empty-state" style="padding:30px 16px;">No conversations yet.<br>Tap <strong>+</strong> to start one.</p>
            <?php else: foreach ($conversations as $c): ?>
                <a href="?with=<?php echo (int)$c['user_id']; ?>" class="msg-item <?php echo $with == $c['user_id'] ? 'active' : ''; ?>" data-filter-item="<?php echo h(strtolower($c['full_name'] . ' ' . $c['role'])); ?>">
                    <?php echo msg_avatar($c, $base); ?>
                    <span class="msg-item-body">
                        <span class="msg-item-top">
                            <strong><?php echo h($c['full_name']); ?></strong>
                            <em><?php echo $c['last_time'] ? date('D', strtotime($c['last_time'])) : ''; ?></em>
                        </span>
                        <span class="msg-item-preview"><?php echo h($c['last_message']); ?></span>
                    </span>
                    <?php if ($c['unread'] > 0): ?><span class="badge-count msg-unread"><?php echo (int)$c['unread']; ?></span><?php endif; ?>
                </a>
            <?php endforeach; endif; ?>
        </div>
    </aside>

    <!-- Open conversation -->
    <section class="chat-box msg-main">
        <?php if ($with_user): ?>
            <div class="chat-header">
                <?php echo msg_avatar($with_user, $base); ?>
                <div>
                    <strong><?php echo h($with_user['full_name']); ?></strong>
                    <div style="font-size:12px;color:var(--text-muted);"><?php echo ucfirst($with_user['role']); ?></div>
                </div>
            </div>
            <div class="chat-messages">
                <?php if (empty($messages)): ?>
                    <p style="text-align:center;color:var(--text-muted);margin:auto;">No messages yet &mdash; say hello to <?php echo h(explode(' ', $with_user['full_name'])[0]); ?> 👋</p>
                <?php endif; ?>
                <?php foreach ($messages as $m): ?>
                    <div class="msg <?php echo $m['sender_id'] == $admin_id ? 'msg-me' : 'msg-them'; ?>">
                        <?php echo h($m['message']); ?>
                        <span class="msg-time"><?php echo date('D H:i', strtotime($m['sent_at'])); ?></span>
                    </div>
                <?php endforeach; ?>
            </div>
            <form method="POST" action="messages.php" class="chat-input">
                <input type="hidden" name="to" value="<?php echo (int)$with_user['user_id']; ?>">
                <input type="text" name="message" placeholder="Type a message..." required autocomplete="off">
                <button type="submit" class="btn btn-primary" aria-label="Send"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m22 2-7 20-4-9-9-4 20-7Z"/><path d="M22 2 11 13"/></svg></button>
            </form>
        <?php else: ?>
            <div class="empty-state msg-empty">
                <div style="font-size:42px;">💬</div>
                <p>Select a conversation, or tap <strong>+</strong> to start a new one.</p>
            </div>
        <?php endif; ?>
    </section>
</div>

<!-- New conversation picker -->
<div class="modal-overlay" id="newChat" aria-hidden="true">
    <div class="modal-card" role="dialog" aria-label="Start a new conversation">
        <div class="modal-head">
            <h3>New conversation</h3>
            <button type="button" class="modal-x" data-close-modal aria-label="Close">&times;</button>
        </div>
        <div class="msg-search"><input type="search" placeholder="Search clients and freelancers" data-filter-input="contactList"></div>
        <div class="msg-list" id="contactList" style="max-height:340px;">
            <?php if (empty($contacts)): ?>
                <p class="empty-state">No clients or freelancers yet.</p>
            <?php else: foreach ($contacts as $c): ?>
                <a href="?with=<?php echo (int)$c['user_id']; ?>" class="msg-item" data-filter-item="<?php echo h(strtolower($c['full_name'] . ' ' . $c['role'])); ?>">
                    <?php echo msg_avatar($c, $base); ?>
                    <span class="msg-item-body">
                        <span class="msg-item-top"><strong><?php echo h($c['full_name']); ?></strong></span>
                        <span class="msg-item-preview"><?php echo ucfirst($c['role']); ?></span>
                    </span>
                </a>
            <?php endforeach; endif; ?>
        </div>
    </div>
</div>

<?php include '../includes/footer_dashboard.php'; ?>
