<?php
/**
 * includes/header_public.php
 * Navbar shown on the public website (index.php) for visitors
 * who are not logged in yet.
 */
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?php echo isset($page_title) ? h($page_title) . ' - Bee\'s Events & Decor' : 'Bee\'s Events & Decor'; ?></title>
<link rel="stylesheet" href="assets/css/style.css">
</head>
<body>

<nav class="navbar">
    <div class="container">
        <a href="index.php" class="brand">
            <img src="assets/img/logo-icon.png" alt="Bee's Events & Decor" class="logo-img">
            <span class="brand-name">Bee's Events &amp; Decor</span>
        </a>
        <div class="nav-right">
            <div class="nav-actions">
                <a href="auth/login.php" class="btn btn-outline btn-sm">Sign In</a>
                <a href="auth/register.php" class="btn btn-primary btn-sm">Register</a>
            </div>
            <button type="button" class="pub-menu-btn" id="pubMenuBtn" aria-label="Menu" aria-expanded="false" aria-controls="pubMenu">
                <svg class="icon-open" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 7h16M4 12h16M4 17h16"/></svg>
                <svg class="icon-close" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>
            </button>
        </div>
    </div>

    <div class="pub-menu" id="pubMenu">
        <div class="container">
            <a href="index.php#services">Services</a>
            <a href="index.php#gallery">Gallery</a>
            <a href="index.php#testimonials">Testimonials</a>
            <a href="index.php#contact">Contact</a>
            <div class="pub-menu-actions">
                <a href="auth/login.php" class="btn btn-outline">Sign In</a>
                <a href="auth/register.php" class="btn btn-primary">Register</a>
            </div>
        </div>
    </div>
</nav>

<!-- Sign in / Register pop-up (loads auth/login.php or auth/register.php inside, see footer_public.php) -->
<div class="auth-modal" id="authModal" aria-hidden="true">
    <div class="auth-modal-card" role="dialog" aria-modal="true" aria-label="Sign in or register">
        <button type="button" class="auth-modal-x" id="authModalClose" aria-label="Close">&times;</button>
        <iframe id="authFrame" title="Sign in or register" src="about:blank" scrolling="no"></iframe>
    </div>
</div>

<main>
