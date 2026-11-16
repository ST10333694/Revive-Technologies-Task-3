-- =========================================================
-- REVIVE TECHNOLOGIES
-- Integrated Event Decorating and Freelance Management System
-- Database: revive_technologies
-- =========================================================

CREATE DATABASE IF NOT EXISTS revive_technologies CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE revive_technologies;

-- ---------------------------------------------------------
-- 1. USERS TABLE
-- Every person who can log in: client, freelancer or admin
-- ---------------------------------------------------------
CREATE TABLE users (
    user_id     INT AUTO_INCREMENT PRIMARY KEY,
    full_name   VARCHAR(120)  NOT NULL,
    email       VARCHAR(150)  NOT NULL UNIQUE,
    phone       VARCHAR(30)   DEFAULT NULL,
    profile_image VARCHAR(255) DEFAULT NULL,          -- uploaded profile photo (path under uploads/profiles/)
    password    VARCHAR(255)  NOT NULL,           -- hashed with password_hash()
    role        ENUM('client','freelancer','admin') NOT NULL DEFAULT 'client',
    status      ENUM('active','suspended')  NOT NULL DEFAULT 'active',
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 2. FREELANCER PROFILE TABLE
-- Extra details only freelancers have (linked 1-to-1 to users)
-- ---------------------------------------------------------
CREATE TABLE freelancers (
    freelancer_id   INT AUTO_INCREMENT PRIMARY KEY,
    user_id         INT NOT NULL,
    skill           VARCHAR(150) NOT NULL,          -- e.g. "Floral Design", "Lighting"
    bio             TEXT,
    hourly_rate     DECIMAL(10,2) DEFAULT 0.00,
    rating          DECIMAL(3,2) DEFAULT 0.00,      -- 0.00 - 5.00
    portfolio_files TEXT DEFAULT NULL,              -- comma-separated paths to uploaded work samples
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 3. INVENTORY TABLE
-- Décor items the company owns and rents/uses for events
-- ---------------------------------------------------------
CREATE TABLE inventory (
    item_id         INT AUTO_INCREMENT PRIMARY KEY,
    item_name       VARCHAR(150) NOT NULL,
    category        VARCHAR(80)  DEFAULT 'General',
    total_stock     INT NOT NULL DEFAULT 0,
    available_stock INT NOT NULL DEFAULT 0,
    unit_price      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 4. BOOKINGS TABLE
-- An online event/decor booking request submitted by a client
-- ---------------------------------------------------------
CREATE TABLE bookings (
    booking_id    INT AUTO_INCREMENT PRIMARY KEY,
    client_id     INT NOT NULL,
    freelancer_id INT DEFAULT NULL,                -- assigned once approved
    event_type    VARCHAR(120) NOT NULL,           -- Wedding, Corporate, Birthday...
    event_date    DATE NOT NULL,
    event_time    TIME DEFAULT NULL,               -- picked with the clock picker
    venue         VARCHAR(200) DEFAULT NULL,
    guest_count   INT DEFAULT NULL,
    notes         TEXT,
    status        ENUM('pending','quoted','confirmed','completed','cancelled') NOT NULL DEFAULT 'pending',
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (freelancer_id) REFERENCES freelancers(freelancer_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 5. QUOTATIONS TABLE
-- Digital quotation the event manager/admin sends for a booking
-- ---------------------------------------------------------
CREATE TABLE quotations (
    quote_id    INT AUTO_INCREMENT PRIMARY KEY,
    booking_id  INT NOT NULL,
    client_id   INT NOT NULL,
    title         VARCHAR(160) DEFAULT NULL,       -- e.g. "Baby Shower Styling - Dusty Pink & Sage Green"
    amount        DECIMAL(10,2) NOT NULL DEFAULT 0.00,   -- total of all line items
    details       TEXT,
    payment_terms VARCHAR(255) DEFAULT NULL,
    status        ENUM('sent','accepted','rejected') NOT NULL DEFAULT 'sent',  -- sent = pending approval, accepted = approved
    approved_at   DATETIME DEFAULT NULL,           -- set when admin approves; the 72-hour deposit window starts here
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
    FOREIGN KEY (client_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 5b. QUOTATION ITEMS TABLE
-- Itemised lines (description, qty, unit cost) for each quotation
-- ---------------------------------------------------------
CREATE TABLE quotation_items (
    item_id     INT AUTO_INCREMENT PRIMARY KEY,
    quote_id    INT NOT NULL,
    description VARCHAR(255) NOT NULL,
    qty         INT NOT NULL DEFAULT 1,
    unit_cost   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    sort_order  INT NOT NULL DEFAULT 0,
    FOREIGN KEY (quote_id) REFERENCES quotations(quote_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 6. PAYMENTS TABLE
-- Freelancer payment / cash claims for completed work
-- ---------------------------------------------------------
CREATE TABLE payments (
    payment_id    INT AUTO_INCREMENT PRIMARY KEY,
    freelancer_id INT NOT NULL,
    booking_id    INT NOT NULL,
    amount        DECIMAL(10,2) NOT NULL,
    claim_date    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status        ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
    FOREIGN KEY (freelancer_id) REFERENCES freelancers(freelancer_id) ON DELETE CASCADE,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 7. RECEIPTS TABLE
-- Issued once a client payment for a booking is finalised
-- ---------------------------------------------------------
CREATE TABLE receipts (
    receipt_id     INT AUTO_INCREMENT PRIMARY KEY,
    client_id      INT NOT NULL,
    booking_id     INT NOT NULL,
    payment_amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(60) DEFAULT 'EFT',
    issue_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 8. MESSAGES TABLE
-- Centralized messaging between clients, freelancers & admin
-- ---------------------------------------------------------
CREATE TABLE messages (
    message_id  INT AUTO_INCREMENT PRIMARY KEY,
    sender_id   INT NOT NULL,
    receiver_id INT NOT NULL,
    message     TEXT NOT NULL,
    sent_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_read     TINYINT(1) NOT NULL DEFAULT 0,
    FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 9. NOTIFICATIONS TABLE
-- In-app notifications (quotation approved, order changes, new requests...)
-- ---------------------------------------------------------
CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id         INT NOT NULL,
    title           VARCHAR(160) NOT NULL,
    message         TEXT NOT NULL,
    link            VARCHAR(200) DEFAULT NULL,      -- page (inside the user's portal) to open
    is_read         TINYINT(1) NOT NULL DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 10. TASKS TABLE
-- Admin to-do list shown as "Upcoming Tasks" on the admin dashboard
-- ---------------------------------------------------------
CREATE TABLE tasks (
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

-- ---------------------------------------------------------
-- 11. INVITATION REQUESTS TABLE
-- Clients request invitation cards; admin approves, updates progress and uploads the finished cards
-- ---------------------------------------------------------
CREATE TABLE invitation_requests (
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

-- =========================================================
-- SAMPLE / DEMO DATA
-- Sample accounts (admin, client, freelancers) share one hashed demo password
-- =========================================================
INSERT INTO users (full_name, email, phone, password, role) VALUES
('Bee''s Events & Decor', 'admin@beesevents.co.za',      '0110000000', '$2b$10$52ujA6uJAVzZ5wI.ZYVw2OYQFor4mOSVyv3Y2i3me8jpgQ6TnSAbK', 'admin'),
('Thandiwe Mokoena', 'thandiwe@client.co.za',  '0821112222', '$2b$10$52ujA6uJAVzZ5wI.ZYVw2OYQFor4mOSVyv3Y2i3me8jpgQ6TnSAbK', 'client'),
('Sipho Ndlovu',     'sipho@freelance.co.za',  '0833334444', '$2b$10$52ujA6uJAVzZ5wI.ZYVw2OYQFor4mOSVyv3Y2i3me8jpgQ6TnSAbK', 'freelancer'),
('Amara Dlamini',    'amara@freelance.co.za',  '0845556666', '$2b$10$52ujA6uJAVzZ5wI.ZYVw2OYQFor4mOSVyv3Y2i3me8jpgQ6TnSAbK', 'freelancer');

INSERT INTO freelancers (user_id, skill, bio, hourly_rate, rating) VALUES
(3, 'Floral Design & Table Styling', 'Specialises in wedding florals and elegant table settings.', 350.00, 4.8),
(4, 'Lighting & Draping',            'Expert in ambient lighting design and fabric draping for events.', 300.00, 4.6);

INSERT INTO inventory (item_name, category, total_stock, available_stock, unit_price) VALUES
('Round Tables (10-seater)', 'Furniture', 40, 32, 250.00),
('Chiavari Chairs',          'Furniture', 300, 210, 45.00),
('Fairy Light Backdrop',     'Lighting',  15, 10, 600.00),
('Gold Charger Plates',      'Tableware', 300, 260, 15.00),
('Floral Centerpieces',      'Décor',     50, 38, 180.00);

INSERT INTO bookings (client_id, freelancer_id, event_type, event_date, event_time, venue, guest_count, notes, status) VALUES
(2, 1, 'Wedding',   '2026-09-12', '10:00:00', 'The Manor House, Johannesburg', 150, 'Blush and gold theme requested.', 'confirmed'),
(2, NULL, 'Corporate Launch', '2026-10-03', '09:30:00', 'Sandton Convention Centre', 80, 'Company product launch, minimalist theme.', 'pending');

INSERT INTO quotations (booking_id, client_id, title, amount, details, payment_terms, status, approved_at) VALUES
(1, 2, 'Wedding Styling - Blush & Gold', 24500.00, 'Full wedding décor package: florals, lighting, table styling for 150 guests.',
 '50% deposit required to confirm booking. Balance due within 72 hours after approval.', 'accepted', NOW());

INSERT INTO quotation_items (quote_id, description, qty, unit_cost, sort_order) VALUES
(1, 'Floral Arch & Feature Backdrop', 1, 9500.00, 1),
(1, 'Fairy Light Backdrop', 1, 600.00, 2),
(1, 'Round Table Linens & Centrepieces (per table)', 15, 650.00, 3),
(1, 'Gold Charger Plates (per piece)', 150, 15.00, 4),
(1, 'Setup, Breakdown & On-site Labour', 1, 2400.00, 5);

INSERT INTO notifications (user_id, title, message, link) VALUES
(2, 'Quotation approved', 'Your quotation QT-001 has been approved. You can now download it. A deposit is required within 72 hours.', 'quotations.php');

INSERT INTO tasks (title, due_date, due_time, booking_id) VALUES
('Prepare décor: Thandiwe Mokoena - Wedding', '2026-09-12', '08:00:00', 1),
('Call Sandton Convention Centre about load-in times', DATE_ADD(CURDATE(), INTERVAL 2 DAY), '10:00:00', 2);

COMMIT;

-- ---------------------------------------------------------
-- 12. JOB APPLICATIONS TABLE
-- Freelancer applies for an open booking; admin reviews, accepts or rejects
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS job_applications (
    application_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id     INT NOT NULL,
    freelancer_id  INT NOT NULL,
    status         ENUM('under_review','approved','rejected') NOT NULL DEFAULT 'under_review',
    applied_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    decided_at     DATETIME DEFAULT NULL,
    UNIQUE KEY one_application (booking_id, freelancer_id),
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
    FOREIGN KEY (freelancer_id) REFERENCES freelancers(freelancer_id) ON DELETE CASCADE
) ENGINE=InnoDB;
