<?php
/**
 * includes/auth_check.php
 * Role-based access control: require_role() limits a page to one logged-in role.
 */

function require_role($role) {
    if (!is_logged_in()) {
        set_flash('Please sign in to continue.', 'error');
        redirect('../auth/login.php');
    }

    if (($_SESSION['role'] ?? null) !== $role) {
        set_flash('You do not have permission to view that page.', 'error');
        redirect('../index.php');
    }
}
