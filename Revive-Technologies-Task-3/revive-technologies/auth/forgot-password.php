<?php
/**
 * auth/forgot-password.php
 * Password reset: generates a temporary password, stores its hash on the
 * account and shows it once on screen.
 */
require_once '../includes/functions.php';
require_once '../config/database.php';

// Shown inside the homepage pop-up (iframe) when ?embed=1
$embed = isset($_GET['embed']);
$eq    = $embed ? '?embed=1' : '';

$errors = [];
$temp_password = null;
$found_name = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = trim($_POST['email'] ?? '');

    if ($email === '') {
        $errors[] = 'Please enter your account email.';
    } else {
        $stmt = $pdo->prepare('SELECT * FROM users WHERE email = ?');
        $stmt->execute([$email]);
        $user = $stmt->fetch();

        if ($user) {
            // Generate a random 10-character temporary password.
            $temp_password = substr(bin2hex(random_bytes(6)), 0, 10);
            $hash = password_hash($temp_password, PASSWORD_DEFAULT);

            $update = $pdo->prepare('UPDATE users SET password = ? WHERE user_id = ?');
            $update->execute([$hash, $user['user_id']]);

            $found_name = $user['full_name'];
        } else {
            // Same generic message whether or not the email exists,
            // so we don't reveal which emails are registered.
            $errors[] = "If that email is registered, you'll see reset instructions below.";
        }
    }
}

$page_title = 'Forgot Password';
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Forgot Password - Bee's Events & Decor</title>
<link rel="stylesheet" href="../assets/css/style.css">
</head>
<body class="auth-page<?php echo $embed ? ' auth-embed' : ''; ?>">
<div class="auth-wrap">
    <div class="auth-card">
        <?php if (!$embed): ?><a href="../index.php" class="auth-close" aria-label="Close">&times;</a><?php endif; ?>
        <div class="auth-logo">
            <img src="../assets/img/logo.png" alt="Bee's Events & Decor" class="logo-img">
        </div>

        <h3 style="text-align:center;margin-bottom:6px;">Reset Your Password</h3>
        <p style="text-align:center;color:var(--text-muted);font-size:14px;margin-bottom:22px;">
            Enter the email on your account and we'll generate a new temporary password.
        </p>

        <?php foreach ($errors as $error): ?>
            <div class="alert alert-error"><?php echo h($error); ?></div>
        <?php endforeach; ?>

        <?php if ($temp_password): ?>
            <div class="alert alert-success">
                Hi <?php echo h($found_name); ?>, your temporary password is ready.
            </div>
            <div class="demo-box">
                <strong>🔑 Your Temporary Password</strong>
                <div class="demo-row" style="cursor:default;">
                    <span><?php echo h($temp_password); ?></span>
                </div>
                <p style="margin:8px 0 0 0;color:var(--warning);">
                    Sign in with this password, then change it from your account settings as soon as possible.
                </p>
            </div>
            <a href="login.php<?php echo $eq; ?>" class="btn btn-primary btn-block" style="margin-top:18px;">Go to Sign In</a>
        <?php else: ?>
            <form method="POST" action="forgot-password.php<?php echo $eq; ?>">
                <div class="field">
                    <label>Email address</label>
                    <input type="email" name="email" placeholder="you@example.com" required value="<?php echo h($_POST['email'] ?? ''); ?>">
                </div>
                <button type="submit" class="btn btn-primary btn-block">Send Reset</button>
            </form>
            <p style="text-align:center;margin-top:18px;font-size:14px;">
                <a href="login.php<?php echo $eq; ?>" style="color:var(--gold);font-weight:600;">&larr; Back to Sign In</a>
            </p>
        <?php endif; ?>
    </div>
</div>
<?php if (!$embed): ?>
<p class="auth-credit">Built by Revive Technologies</p>
<?php endif; ?>
</body>
</html>
