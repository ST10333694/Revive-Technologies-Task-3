-- =========================================================
-- MIGRATION
-- Adds job applications: freelancers apply, admin reviews / accepts / rejects.
-- (The site also creates this table automatically the first time it is needed.)
-- =========================================================
USE revive_technologies;

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
