<?php
/** freelancer/profile.php - shared profile page (see includes/profile_page.php) */
require_once '../includes/functions.php';
require_once '../config/database.php';
require_once '../includes/auth_check.php';
require_role('freelancer');

$dash_role = 'freelancer';
$active    = 'profile';
$base      = '../';
require '../includes/profile_page.php';
