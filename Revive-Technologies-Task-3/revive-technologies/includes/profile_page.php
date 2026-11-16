<?php
/**
 * includes/profile_page.php
 * Shared "My Profile" page for client, freelancer and admin.
 * Each portal's profile.php sets $dash_role / $active / $base and then includes this file.
 *
 * Shows a round profile picture (upload / remove), the person's name and details,
 * and settings to change details, email and password.
 */
$uid = $_SESSION['user_id'];
$photo_dir = dirname(__DIR__) . '/uploads/profiles/';

/** Delete a previously uploaded photo file (only ever inside uploads/profiles). */
function delete_profile_photo($photo_dir, $relative) {
    if ($relative && strpos($relative, 'uploads/profiles/') === 0) {
        $file = $photo_dir . basename($relative);
        if (is_file($file)) @unlink($file);
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    if (isset($_POST['upload_photo'])) {
        $f = $_FILES['photo'] ?? null;
        $types = [IMAGETYPE_JPEG => 'jpg', IMAGETYPE_PNG => 'png', IMAGETYPE_WEBP => 'webp'];
        if (!$f || $f['error'] === UPLOAD_ERR_NO_FILE) {
            set_flash('Please choose a photo first.', 'error');
        } elseif ($f['error'] !== UPLOAD_ERR_OK || $f['size'] > 3 * 1024 * 1024) {
            set_flash('That photo is too large. Please choose an image under 3 MB.', 'error');
        } else {
            $info = @getimagesize($f['tmp_name']);
            if (!$info || !isset($types[$info[2]])) {
                set_flash('Please upload a JPG, PNG or WEBP image.', 'error');
            } else {
                if (!is_dir($photo_dir)) @mkdir($photo_dir, 0755, true);
                $name = 'u' . $uid . '_' . time() . '.' . $types[$info[2]];
                if (@move_uploaded_file($f['tmp_name'], $photo_dir . $name)) {
                    $stmt = $pdo->prepare('SELECT profile_image FROM users WHERE user_id = ?');
                    $stmt->execute([$uid]);
                    delete_profile_photo($photo_dir, $stmt->fetchColumn());
                    $pdo->prepare('UPDATE users SET profile_image = ? WHERE user_id = ?')->execute(['uploads/profiles/' . $name, $uid]);
                    set_flash('Profile photo updated.');
                } else {
                    set_flash('Sorry, the photo could not be saved. Check that the uploads/profiles folder is writable.', 'error');
                }
            }
        }
    } elseif (isset($_POST['remove_photo'])) {
        $stmt = $pdo->prepare('SELECT profile_image FROM users WHERE user_id = ?');
        $stmt->execute([$uid]);
        delete_profile_photo($photo_dir, $stmt->fetchColumn());
        $pdo->prepare('UPDATE users SET profile_image = NULL WHERE user_id = ?')->execute([$uid]);
        set_flash('Profile photo removed.');

    } elseif (isset($_POST['update_profile'])) {
        $name  = trim($_POST['full_name'] ?? '');
        $phone = trim($_POST['phone'] ?? '');
        $email = trim($_POST['email'] ?? '');
        if ($name === '') {
            set_flash('Please enter your name.', 'error');
        } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            set_flash('Please enter a valid email address.', 'error');
        } else {
            $stmt = $pdo->prepare('SELECT COUNT(*) FROM users WHERE email = ? AND user_id <> ?');
            $stmt->execute([$email, $uid]);
            if ($stmt->fetchColumn() > 0) {
                set_flash('That email address is already used by another account.', 'error');
            } else {
                $pdo->prepare('UPDATE users SET full_name = ?, email = ?, phone = ? WHERE user_id = ?')->execute([$name, $email, $phone, $uid]);
                $_SESSION['full_name'] = $name;
                set_flash('Your details have been updated.');
            }
        }

    } elseif (isset($_POST['change_password'])) {
        $stmt = $pdo->prepare('SELECT password FROM users WHERE user_id = ?');
        $stmt->execute([$uid]);
        $hash = $stmt->fetchColumn();
        $new  = $_POST['new_password'] ?? '';
        if (!password_verify($_POST['current_password'] ?? '', $hash)) {
            set_flash('Your current password is incorrect.', 'error');
        } elseif (strlen($new) < 8) {
            set_flash('The new password must be at least 8 characters.', 'error');
        } elseif ($new !== ($_POST['confirm_password'] ?? '')) {
            set_flash('The new passwords do not match.', 'error');
        } else {
            $pdo->prepare('UPDATE users SET password = ? WHERE user_id = ?')->execute([password_hash($new, PASSWORD_DEFAULT), $uid]);
            set_flash('Password changed.');
        }
    }
    redirect('profile.php');
}

$stmt = $pdo->prepare('SELECT full_name, email, phone, role, profile_image, created_at FROM users WHERE user_id = ?');
$stmt->execute([$uid]);
$me = $stmt->fetch();

// Initials for the placeholder circle
$initials = '';
foreach (array_slice(preg_split('/\s+/', trim($me['full_name'])), 0, 2) as $part) {
    $initials .= mb_strtoupper(mb_substr($part, 0, 1));
}

$extra = [];
if ($dash_role === 'freelancer') {
    $stmt = $pdo->prepare('SELECT skill, hourly_rate, rating FROM freelancers WHERE user_id = ?');
    $stmt->execute([$uid]);
    $extra = $stmt->fetch() ?: [];
}

$page_title = 'My Profile';
include __DIR__ . '/header_dashboard.php';
?>

<div class="profile-wrap">

    <div class="card profile-hero">
        <div class="avatar-xl-wrap">
            <?php if (!empty($me['profile_image'])): ?>
                <img class="avatar-xl" src="<?php echo $base . h($me['profile_image']); ?>" alt="Profile photo of <?php echo h($me['full_name']); ?>">
            <?php else: ?>
                <div class="avatar-xl avatar-initials"><?php echo h($initials ?: '?'); ?></div>
            <?php endif; ?>

            <form method="POST" action="profile.php" enctype="multipart/form-data" id="photoForm">
                <input type="hidden" name="upload_photo" value="1">
                <input type="file" name="photo" id="photoInput" accept="image/jpeg,image/png,image/webp" hidden>
                <label for="photoInput" class="avatar-camera" title="Change profile photo" aria-label="Change profile photo">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.5 4h-5L8 6H5a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-3l-1.5-2Z"/><circle cx="12" cy="13" r="3.5"/></svg>
                </label>
            </form>
        </div>

        <div class="profile-info">
            <h2><?php echo h($me['full_name']); ?></h2>
            <span class="pill pill-quoted"><?php echo $dash_role === 'admin' ? 'Admin' : ucfirst(h($me['role'])); ?></span>
            <ul class="profile-details">
                <li><span>Email</span><?php echo h($me['email']); ?></li>
                <li><span>Phone</span><?php echo h($me['phone'] ?: 'Not added yet'); ?></li>
                <?php if (!empty($extra['skill'])): ?><li><span>Skill</span><?php echo h($extra['skill']); ?></li><?php endif; ?>
                <?php if (!empty($extra['hourly_rate'])): ?><li><span>Hourly rate</span><?php echo h(rand_format($extra['hourly_rate'])); ?></li><?php endif; ?>
                <li><span>Member since</span><?php echo nice_date($me['created_at']); ?></li>
            </ul>
            <?php if (!empty($me['profile_image'])): ?>
                <form method="POST" action="profile.php" data-confirm="Remove your profile photo?">
                    <button type="submit" name="remove_photo" value="1" class="link-btn">Remove photo</button>
                </form>
            <?php else: ?>
                <p class="profile-hint">Click the camera to add a profile picture (JPG, PNG or WEBP, up to 3 MB).</p>
            <?php endif; ?>
        </div>
    </div>

    <h3 class="profile-section-title">Settings</h3>
    <div class="two-col" style="grid-template-columns:1fr 1fr;">
        <div class="card">
            <h3>Edit Details</h3>
            <form method="POST" action="profile.php">
                <input type="hidden" name="update_profile" value="1">
                <div class="field"><label>Full Name</label><input type="text" name="full_name" value="<?php echo h($me['full_name']); ?>" required></div>
                <div class="field"><label>Email</label><input type="email" name="email" value="<?php echo h($me['email']); ?>" required></div>
                <div class="field"><label>Phone / WhatsApp</label><input type="tel" name="phone" value="<?php echo h($me['phone']); ?>" placeholder="+27 XX XXX XXXX"></div>
                <button type="submit" class="btn btn-primary">Save Changes</button>
            </form>
        </div>
        <div class="card">
            <h3>Change Password</h3>
            <form method="POST" action="profile.php">
                <input type="hidden" name="change_password" value="1">
                <div class="field"><label>Current Password</label><input type="password" name="current_password" required></div>
                <div class="field"><label>New Password</label><input type="password" name="new_password" minlength="8" required></div>
                <div class="field"><label>Confirm New Password</label><input type="password" name="confirm_password" minlength="8" required></div>
                <button type="submit" class="btn btn-outline">Update Password</button>
            </form>
        </div>
    </div>
</div>

<script>
// Choosing a photo uploads it straight away
document.getElementById('photoInput').addEventListener('change', function () {
    if (this.files.length) document.getElementById('photoForm').submit();
});
</script>

<?php include __DIR__ . '/footer_dashboard.php'; ?>
