-- =========================================================
-- MIGRATION
-- Adds the invitation card requests table (admin approves, updates progress, uploads finished cards).
-- =========================================================
USE revive_technologies;

CREATE TABLE IF NOT EXISTS invitation_requests (
    request_id    INT AUTO_INCREMENT PRIMARY KEY,
    client_id     INT NOT NULL,
    booking_id    INT DEFAULT NULL,
    style         VARCHAR(80) NOT NULL,                 -- e.g. "Wedding Invitation"
    host_names    VARCHAR(200) DEFAULT NULL,
    event_date    DATE NOT NULL,
    event_time    TIME DEFAULT NULL,
    venue         VARCHAR(200) DEFAULT NULL,
    colour_scheme VARCHAR(150) DEFAULT NULL,
    quantity      INT DEFAULT NULL,
    details       TEXT,
    status        ENUM('submitted','approved','in_progress','completed','rejected') NOT NULL DEFAULT 'submitted',
    stage         VARCHAR(20) DEFAULT NULL,             -- approved / design / review / final / completed
    progress      TINYINT UNSIGNED NOT NULL DEFAULT 0,  -- 0-100 shown to the client
    progress_note VARCHAR(255) DEFAULT NULL,            -- optional message from the admin
    file_path     VARCHAR(255) DEFAULT NULL,            -- finished cards (pdf / image) in uploads/invitations/
    file_name     VARCHAR(255) DEFAULT NULL,
    approved_at   DATETIME DEFAULT NULL,
    completed_at  DATETIME DEFAULT NULL,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE SET NULL
) ENGINE=InnoDB;
