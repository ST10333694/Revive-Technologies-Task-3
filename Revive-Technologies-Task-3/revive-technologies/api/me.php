<?php
require_once __DIR__ . '/helpers.php';
require_method('GET');
respond(['user' => auth_user()]);
