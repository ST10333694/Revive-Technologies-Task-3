-- =========================================================
-- MIGRATION
-- Adds: event times, itemised quotations, notifications, admin tasks
-- =========================================================
USE revive_technologies;

ALTER TABLE users      ADD COLUMN profile_image VARCHAR(255) DEFAULT NULL AFTER phone;

-- The admin account is named "Bee's Events & Decor" (admin@beesevents.co.za)
UPDATE users SET full_name = 'Bee''s Events & Decor', email = 'admin@beesevents.co.za' WHERE email = 'admin@revive.co.za';

ALTER TABLE bookings   ADD COLUMN event_time TIME DEFAULT NULL AFTER event_date;

ALTER TABLE quotations
    ADD COLUMN title         VARCHAR(160) DEFAULT NULL AFTER client_id,
    ADD COLUMN payment_terms VARCHAR(255) DEFAULT NULL AFTER details,
    ADD COLUMN approved_at   DATETIME DEFAULT NULL AFTER status;

-- Quotations that were already accepted keep working: treat their created date as the approval date
UPDATE quotations SET approved_at = created_at WHERE status = 'accepted' AND approved_at IS NULL;

CREATE TABLE IF NOT EXISTS quotation_items (
    item_id     INT AUTO_INCREMENT PRIMARY KEY,
    quote_id    INT NOT NULL,
    description VARCHAR(255) NOT NULL,
    qty         INT NOT NULL DEFAULT 1,
    unit_cost   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    sort_order  INT NOT NULL DEFAULT 0,
    FOREIGN KEY (quote_id) REFERENCES quotations(quote_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id         INT NOT NULL,
    title           VARCHAR(160) NOT NULL,
    message         TEXT NOT NULL,
    link            VARCHAR(200) DEFAULT NULL,
    is_read         TINYINT(1) NOT NULL DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tasks (
    task_id      INT AUTO_INCREMENT PRIMARY KEY,
    title        VARCHAR(200) NOT NULL,
    due_date     DATE NOT NULL,
    due_time     TIME DEFAULT NULL,
    booking_id   INT DEFAULT NULL,
    is_complete  TINYINT(1) NOT NULL DEFAULT 0,
    completed_at DATETIME DEFAULT NULL,
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Payment terms wording: balance now due within 72 hours after approval
UPDATE quotations SET payment_terms = REPLACE(payment_terms, 'Balance due 7 days before the event.', 'Balance due within 72 hours after approval.');
