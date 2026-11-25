SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
SET time_zone = '+00:00';
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP DATABASE IF EXISTS `sdms`;
CREATE DATABASE `sdms` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `sdms`;

CREATE TABLE `users` (
  `userid`     INT NOT NULL AUTO_INCREMENT,
  `username`   VARCHAR(50)  NOT NULL,
  `name`       VARCHAR(100) DEFAULT NULL,
  `email`      VARCHAR(100) DEFAULT NULL,
  `contact`    VARCHAR(15)  DEFAULT NULL,
  `password`   VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`userid`),
  UNIQUE KEY `uq_users_username` (`username`),
  UNIQUE KEY `uq_users_email` (`email`)
) ENGINE=InnoDB;

CREATE TABLE `user_roles` (
  `role_id` INT NOT NULL AUTO_INCREMENT,
  `userid`  INT NOT NULL,
  `role`    ENUM('admin','user') NOT NULL DEFAULT 'user',
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `uq_user_roles_user` (`userid`),
  CONSTRAINT `fk_user_roles_user` FOREIGN KEY (`userid`) REFERENCES `users`(`userid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `notifications` (
  `notification_id` INT NOT NULL AUTO_INCREMENT,
  `user_id`    INT NOT NULL,
  `message`    VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status`     ENUM('unread','read') NOT NULL DEFAULT 'unread',
  PRIMARY KEY (`notification_id`),
  KEY `idx_notifications_user` (`user_id`),
  CONSTRAINT `fk_notifications_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`userid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `otp` (
  `otp_id`     INT NOT NULL AUTO_INCREMENT,
  `userid`     INT NOT NULL,
  `otp_code`   VARCHAR(6) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` DATETIME NOT NULL,
  `is_used`    TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`otp_id`),
  KEY `idx_otp_user` (`userid`),
  CONSTRAINT `fk_otp_user` FOREIGN KEY (`userid`) REFERENCES `users`(`userid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `society` (
  `society_id`   INT NOT NULL AUTO_INCREMENT,
  `society_name` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`society_id`),
  UNIQUE KEY `uq_society_name` (`society_name`)
) ENGINE=InnoDB;

CREATE TABLE `buildings` (
  `building_id`   INT NOT NULL AUTO_INCREMENT,
  `society_id`    INT NOT NULL,
  `building_name` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`building_id`),
  UNIQUE KEY `uq_building_per_society` (`society_id`,`building_name`),
  CONSTRAINT `fk_buildings_society` FOREIGN KEY (`society_id`) REFERENCES `society`(`society_id`) ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `flats` (
  `flat_id`     INT NOT NULL AUTO_INCREMENT,
  `flat_number` VARCHAR(10) NOT NULL,
  `building_id` INT NOT NULL,
  PRIMARY KEY (`flat_id`),
  UNIQUE KEY `uq_flat_per_building` (`building_id`,`flat_number`),
  CONSTRAINT `fk_flats_building` FOREIGN KEY (`building_id`) REFERENCES `buildings`(`building_id`) ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `residents` (
  `resident_id` INT NOT NULL AUTO_INCREMENT,
  `userid`      INT NOT NULL,
  `name`        VARCHAR(100) NOT NULL,
  `flat_id`     INT NOT NULL,
  `contact`     VARCHAR(15) DEFAULT NULL,
  `email`       VARCHAR(100) DEFAULT NULL,
  PRIMARY KEY (`resident_id`),
  UNIQUE KEY `uq_residents_userid` (`userid`),
  UNIQUE KEY `uq_residents_email` (`email`),
  KEY `idx_residents_flat` (`flat_id`),
  CONSTRAINT `fk_residents_user` FOREIGN KEY (`userid`) REFERENCES `users`(`userid`) ON UPDATE CASCADE,
  CONSTRAINT `fk_residents_flat` FOREIGN KEY (`flat_id`) REFERENCES `flats`(`flat_id`) ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `contacts` (
  `contact_id`   INT NOT NULL AUTO_INCREMENT,
  `resident_id`  INT NOT NULL,
  `contact_name` VARCHAR(100) NOT NULL,
  `phone`        VARCHAR(15) DEFAULT NULL,
  PRIMARY KEY (`contact_id`),
  KEY `idx_contacts_resident` (`resident_id`),
  CONSTRAINT `fk_contacts_resident` FOREIGN KEY (`resident_id`) REFERENCES `residents`(`resident_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `complaints` (
  `complaint_id`      INT NOT NULL AUTO_INCREMENT,
  `resident_id`       INT NOT NULL,
  `complaint_details` TEXT NOT NULL,
  `date_logged`       DATE NOT NULL DEFAULT (CURRENT_DATE),
  `status`            ENUM('Pending','Resolved') NOT NULL DEFAULT 'Pending',
  PRIMARY KEY (`complaint_id`),
  KEY `idx_complaints_resident` (`resident_id`),
  CONSTRAINT `fk_complaints_resident` FOREIGN KEY (`resident_id`) REFERENCES `residents`(`resident_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `payments` (
  `payment_id`   INT NOT NULL AUTO_INCREMENT,
  `resident_id`  INT NOT NULL,
  `payment_name` VARCHAR(100) NOT NULL,
  `payment_date` DATE NOT NULL,
  `amount`       DECIMAL(10,2) NOT NULL,
  `status`       ENUM('Pending','Paid') NOT NULL DEFAULT 'Pending',
  PRIMARY KEY (`payment_id`),
  KEY `idx_payments_resident` (`resident_id`),
  CONSTRAINT `chk_payments_amount` CHECK (`amount` > 0),
  CONSTRAINT `fk_payments_resident` FOREIGN KEY (`resident_id`) REFERENCES `residents`(`resident_id`) ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `transactions` (
  `transaction_id`   INT NOT NULL AUTO_INCREMENT,
  `payment_id`       INT NOT NULL,
  `transaction_date` DATE NOT NULL,
  `method`           VARCHAR(50) NOT NULL,
  PRIMARY KEY (`transaction_id`),
  KEY `idx_transactions_payment` (`payment_id`),
  CONSTRAINT `fk_transactions_payment` FOREIGN KEY (`payment_id`) REFERENCES `payments`(`payment_id`) ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `facilities` (
  `facility_id`   INT NOT NULL AUTO_INCREMENT,
  `facility_name` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`facility_id`),
  UNIQUE KEY `uq_facility_name` (`facility_name`)
) ENGINE=InnoDB;

CREATE TABLE `bookings` (
  `booking_id`   INT NOT NULL AUTO_INCREMENT,
  `resident_id`  INT NOT NULL,
  `facility_id`  INT NOT NULL,
  `booking_date` DATE NOT NULL,
  `status`       ENUM('Pending','Accepted','Rejected','Cancelled') NOT NULL DEFAULT 'Pending',
  PRIMARY KEY (`booking_id`),
  KEY `idx_bookings_resident` (`resident_id`),
  KEY `idx_bookings_facility_date` (`facility_id`,`booking_date`),
  CONSTRAINT `fk_bookings_resident` FOREIGN KEY (`resident_id`) REFERENCES `residents`(`resident_id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_bookings_facility` FOREIGN KEY (`facility_id`) REFERENCES `facilities`(`facility_id`) ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `events` (
  `event_id`   INT NOT NULL AUTO_INCREMENT,
  `society_id` INT NOT NULL,
  `event_name` VARCHAR(100) NOT NULL,
  `event_date` DATE NOT NULL,
  PRIMARY KEY (`event_id`),
  KEY `idx_events_society` (`society_id`),
  CONSTRAINT `fk_events_society` FOREIGN KEY (`society_id`) REFERENCES `society`(`society_id`) ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `staff` (
  `staff_id`    INT NOT NULL AUTO_INCREMENT,
  `building_id` INT NOT NULL,
  `name`        VARCHAR(100) NOT NULL,
  `role`        VARCHAR(50) DEFAULT NULL,
  PRIMARY KEY (`staff_id`),
  KEY `idx_staff_building` (`building_id`),
  CONSTRAINT `fk_staff_building` FOREIGN KEY (`building_id`) REFERENCES `buildings`(`building_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `security_logs` (
  `log_id`      INT NOT NULL AUTO_INCREMENT,
  `resident_id` INT NOT NULL,
  `entry_time`  DATETIME NOT NULL,
  `exit_time`   DATETIME DEFAULT NULL,
  PRIMARY KEY (`log_id`),
  KEY `idx_security_logs_resident` (`resident_id`),
  CONSTRAINT `chk_security_logs_time` CHECK (`exit_time` IS NULL OR `exit_time` >= `entry_time`),
  CONSTRAINT `fk_security_logs_resident` FOREIGN KEY (`resident_id`) REFERENCES `residents`(`resident_id`) ON UPDATE CASCADE
) ENGINE=InnoDB;

INSERT INTO `users` (`userid`, `username`, `name`, `email`, `contact`, `password`, `created_at`) VALUES
(9, 'user1', 'Md. Rahim', 'rahim@example.com', '01857102597', '$2y$10$Pe/KCpC1KDSlmOBTlkL9Q.TmPW4wM2NzigZVMhkFU0ezfZAbgPWXW', '2026-10-15 15:54:28'),
(10, 'user2', 'Ayesha Siddiqua', 'ayesha@example.com', NULL, '$2y$10$GIe4TRQZocrhTU0Swe/TDe2gIlcy/NeBScAFYlf4OhhWx.jMNWKCu', '2026-10-15 15:54:28'),
(11, 'user3', 'Tanvir Hossain', 'tanvir@example.com', NULL, '$2y$10$zDteoLDhp7cxzryVDgNwzuDwbKVGf7oKkYCDBW.x0/z0wAdtxJzbm', '2026-10-15 15:54:28'),
(12, 'user4', 'Nasrin Akter', 'nasrin@example.com', NULL, '$2y$10$dOOGD2OZOHB4DQH6m6FDv.oLlLaKUN7WDWDaxvav06wpcTUm03mUe', '2026-10-15 15:54:28'),
(13, 'user5', 'Rafiq Islam', 'rafiq@example.com', NULL, '$2y$10$kFWzI4YWlnQyAaH445C9Bujc3IFJn51tXmkJmYIeRyk0SHwq.fMxO', '2026-10-15 15:54:28'),
(14, 'user6', 'Shahidul Alam', 'shahidul@example.com', NULL, '$2y$10$rHJiemlBAu8mOBEy9WrebumyLHa7ZeutytWq58sk56tu8uyy9MRJa', '2026-10-15 17:24:21'),
(15, 'user7', 'Sumaiya Rahman', 'sumaiya@example.com', NULL, '$2y$10$xYAgCi8MbP/qJCYzqnWYt.1Y359TCaAHc4Wz7U.tHRP4mM3VNN0CK', '2026-10-15 17:24:21'),
(16, 'user8', 'Ashikur Rahman', 'ashikur@example.com', NULL, '$2y$10$EMrIA8Ayme08sj48klQsHuXe7bkARmxri/2iHigAWqm7xuIQfeU2G', '2026-10-15 17:24:21'),
(17, 'user9', 'Mehnaz Sultana', 'mehnaz@example.com', '01700000009', '$2y$10$7Knncy18gWnvQXx/9M53UOXRsw.gQoj/kamAyzV4KOuY5Zntt5QXG', '2026-10-15 17:24:21'),
(18, 'user10', 'Jahirul Islam', 'jahirul@example.com', NULL, '$2y$10$sph4nPb4OfBVVuYhMYYPquslTGQL75cFYC31/7/GC/4i.rp16lCE.', '2026-10-15 17:24:21'),
(22, 'sumaiya', 'mst.sumaiya aziz', 'sumaiya@gmail.com', NULL, '$2y$10$k0UwhXJO/z4H.UPPPm5eQeSNIoXg9fUOyn76PiLxQ7nhWsmWehXMa', '2026-10-18 06:26:59'),
(24, 'hridita', 'sanjida momotaz', 'sanjida.momotaz@gmail.com', NULL, '$2y$10$Iu3A1Z9Lmit6/AVSJJG0DevcU5VhV/qj4Vr/fX5nZWN3YQTn5lK.6', '2026-10-18 06:30:13'),
(30, 'masud', NULL, NULL, NULL, '$2y$10$iLbguSeU8kAfUXj.T.IfHer9kYPKRxpRFvCs642QNRLb6ZDTR8/vK', '2026-10-18 16:44:06'),
(34, 'mahtab07', 'Mahtab Bin Kashem', 'mahtabbk7@gmail.com', '01975602537', '$2y$10$kgB.Uf8zbTrNZGJsqr15a.Wqw7h7paFw.h9V7wTjteJ1hutpb6CmG', '2026-10-25 13:37:54'),
(35, 'hello', 'hello1', 'hello@gmail.com', '01975602537', '$2y$10$cm5f61CpYjBU8okvt1QOKOh1ldTill0hkPe01vUqaEO0SGczDnMjy', '2026-10-29 05:37:14'),
(36, 'hri', 'hridita bim', 'mahtab.kashem@northsouth.edu', '01975602531', '$2y$10$xmzWYKAuJVwBwW7HQP8tK.VZuQazDKsm63.2gR8stDjgDfqbZLCHC', '2026-10-29 05:43:07'),
(37, 'tushar', 'Tushar Dipu', 'tushar.basak@northsouth.edu', '01857102597', '$2y$10$xS6MOxL5nBwT3AgNovOxu.q8dqtJCUXvJkKGHjeNiLY58pYUYo0Uu', '2026-10-29 05:46:32'),
(38, 'forhad', 'imtiaj forhad', 'forhad@gmail.com', '01975602538', '$2y$10$8p6pBWruJOHY7ay/dNphuOLoQt7QuLytPEiTXYI1Wvzug9EKT0MkW', '2026-10-29 16:26:38'),
(39, 'sunny', 'mahmud bin kashem', 'mahmud@gmail.com', '01676136364', '$2y$10$hAeo1SPS7kjrIGlXSmHPUuXdKE8ikilLX7nzyaLjsr8exf/92hNvS', '2026-11-02 15:13:16'),
(40, 'pranto', 'kazi hasib', 'hasib@gmail.com', '01825815770', '$2y$10$MrIogTwpEPmn/ihEaLXfDeTORBKkzGp1sKhzHxqxcPQzOka8EudZO', '2026-11-02 15:17:27'),
(41, 'forhad1', 'rafsat forhad', 'forhadbk@gmail.com', '01975602537', '$2y$10$pxdtIjbLd2RaIUt5LomVjO0mnxoeb1Pb4HLL4WN9KgiknRpPy8AfG', '2026-11-06 16:45:10'),
(42, 'mahmud21391', 'mahmud bin kashem', 'mahmud21391@gmail.com', '01676136364', '$2y$10$NaLQTS0dcbET9Qbq19IriuHtZBj/iJNLJ4P40W2vNZBAL1rxdV6RW', '2026-11-08 11:05:57'),
(43, 'mahmud21', 'mahmud sunny', 'bristibilash74@gmail.com', '01857102597', '$2y$10$Jx1KVgXhz.0mmgSymmkMTO4cQnRJ3nfu0gs6dv6B7WDlG5fcghucG', '2026-11-08 16:50:16'),
(44, 'hridita1', 'hridita red', 'hridired@gmail.com', '0183616651', '$2y$10$wCsudERsPrVha52YUR4Xr.nwv9AgBdgQ0ENbnT238ATuoJiV8QlvS', '2026-11-08 17:43:02'),
(45, 'rafsat', 'rafsat wairan', 'wairanrafsat@gmail.com', '01975602537', '$2y$10$a0VGygOZEQTQ7om0WY06numgg37MbkXzt0rz62whsikQKxeDYfvXS', '2026-11-10 05:13:47'),
(46, 'hrired', 'sanjida momotaj', 'sanjida.momotaz1@northsouth.edu', '02223212354', '$2y$10$n3p63oZUFzA6CAh0O6DoO.19l1Pp1I9WHgnXZ9khZvy9L152z3Etm', '2026-11-10 06:56:43'),
(47, 'hell', 'sanjida momotaz', 'sanjida.moemotaz1@northsouth.edu', '02223212354', '$2y$10$AxF2jHswmgnZ1cn/Xz25RO3uW24lOlm4uMsihZS8Wk.A4YkzQunIS', '2026-11-11 10:37:24'),
(48, 'q', 'q', 'sumaiyaaqziz@gmail.com', '01975602537', '$2y$10$Dfs0IKJIc6xszDNS9owxVelhWp911jOU0g221hZy/zSvN63yMOqXe', '2026-11-11 10:38:12'),
(49, 'zidan', 'zidan', 'zidansanjid@gmail.com', '01555555555', '$2y$10$NY4zl/lbDTJLFGvHhEfLpOWwuMVsOMdTiEppobXsdnfym2.Xmueya', '2026-11-20 18:04:40'),
(50, 'mahtab.kashem@northsouth.edu', 'mahtab', 'mahtab.kashem1@northsouth.edu', '01555555555', '$2y$10$tLgugWoGlNe8Q3Q2XxOAjOjcbBklIZ6HQ3E.wVnW5pT3CQh2C2bwi', '2026-11-22 17:56:16'),
(51, 'minhaz', 'Minhajul Hoque', 'minhaz.fahim.c11@gmail.com', '01522107574', '$2y$10$Mq2LVGbflnj99rSZtHZk0uCFHypD5DCFpLpQ7lTpV2VL/ZkxT/hHu', '2026-11-24 08:39:45');

INSERT INTO `user_roles` (`role_id`, `userid`, `role`) VALUES
(1, 9, 'user'),
(2, 10, 'user'),
(3, 11, 'user'),
(4, 12, 'user'),
(5, 13, 'user'),
(6, 14, 'user'),
(7, 15, 'user'),
(8, 16, 'user'),
(9, 17, 'user'),
(10, 18, 'user'),
(11, 22, 'user'),
(12, 24, 'user'),
(13, 30, 'user'),
(14, 34, 'admin'),
(15, 35, 'user'),
(16, 36, 'user'),
(17, 37, 'user'),
(18, 38, 'user'),
(19, 39, 'user'),
(20, 40, 'user'),
(21, 41, 'user'),
(22, 42, 'user'),
(23, 43, 'user'),
(24, 44, 'user'),
(25, 45, 'user'),
(26, 46, 'user'),
(27, 47, 'user'),
(28, 48, 'user'),
(29, 49, 'user'),
(30, 50, 'user'),
(31, 51, 'user');

INSERT INTO `society` (`society_id`, `society_name`) VALUES
(1, 'Dhaka Residential Society'),
(2, 'Chittagong Hill Society'),
(3, 'Sylhet Urban Society'),
(4, 'Gazipur Green Society'),
(5, 'Comilla Central Society'),
(6, 'Khulna Eco Society');

INSERT INTO `buildings` (`building_id`, `society_id`, `building_name`) VALUES
(1, 1, 'Building A'),
(2, 1, 'Building B'),
(3, 2, 'Building C'),
(4, 3, 'Building D'),
(5, 1, 'Building E'),
(6, 2, 'Building F'),
(7, 3, 'Building G');

INSERT INTO `flats` (`flat_id`, `flat_number`, `building_id`) VALUES
(1, 'A1', 1),
(2, 'A2', 1),
(3, 'B1', 2),
(4, 'C1', 3),
(5, 'D1', 4),
(6, 'D2', 4),
(7, 'E1', 5),
(8, 'E2', 5),
(9, 'F1', 6),
(10, 'G1', 7),
(11, 'G2', 7),
(12, 'G3', 7);

INSERT INTO `residents` (`resident_id`, `userid`, `name`, `flat_id`, `contact`, `email`) VALUES
(101, 9, 'Md. Rahim Alam', 1, '01700000001', 'rahim@example.com'),
(102, 10, 'Ayesha Siddiqua', 2, '01700000002', 'ayesha@example.com'),
(103, 11, 'Tanvir Hossain', 3, '01700000003', 'tanvir@example.com'),
(105, 13, 'Rafiq Islam', 5, '01700000005', 'rafiq@example.com'),
(106, 14, 'Shahidul Alam', 6, '01700000006', 'shahidul@example.com'),
(107, 15, 'Sumaiya Rahman', 1, '01700000007', 'sumaiya@example.com'),
(109, 17, 'Mehnaz Sultana', 3, '01700000009', 'mehnaz@example.com'),
(110, 18, 'Jahirul Islam', 4, '01700000010', 'jahirul@example.com'),
(113, 34, 'Mahtab Bin Kashem', 5, '01975602537', 'mahtabbk7@gmail.com'),
(122, 44, 'hridita red', 4, '01975602537', 'hriditared@gmail.com'),
(123, 45, 'rafsat wairan', 3, '01857102597', 'wairanrafsat@gmail.com'),
(124, 46, 'sanjida momotaz', 4, '02223212354', 'sanjida.momotaz1@northsouth.edu'),
(125, 40, 'kazi hasib', 7, '02223212354', 'pranto@gmail.com'),
(126, 57, 'tushar basak', 1, '01825815770', 'tushar.basak@northsouth.edu');

INSERT INTO `contacts` (`contact_id`, `resident_id`, `contact_name`, `phone`) VALUES
(6, 101, 'Guardian of Rahim', '01800000001'),
(7, 102, 'Guardian of Ayesha', '01800000002'),
(8, 103, 'Guardian of Tanvir', '01800000003'),
(10, 105, 'Guardian of Rafiq', '01800000005'),
(16, 106, 'Guardian of Shahidul', '01800000006'),
(17, 107, 'Guardian of Sumaiya', '01800000007'),
(19, 109, 'Guardian of Mehnaz', '01800000009'),
(20, 110, 'Guardian of Jahirul', '01800000010');

INSERT INTO `complaints` (`complaint_id`, `resident_id`, `complaint_details`, `date_logged`, `status`) VALUES
(6, 101, 'Water leakage in bathroom', '2026-10-04', 'Resolved'),
(7, 102, 'Broken elevator', '2026-10-05', 'Resolved'),
(8, 103, 'Noise complaint from neighbors', '2026-10-06', 'Resolved'),
(10, 105, 'Street light broken', '2026-10-08', 'Resolved'),
(11, 106, 'AC malfunctioning in lobby', '2026-10-11', 'Resolved'),
(12, 107, 'Water supply disruption', '2026-10-12', 'Resolved'),
(14, 109, 'Street light issue near entrance', '2026-10-14', 'Resolved'),
(15, 110, 'Loud noises from rooftop', '2026-10-15', 'Resolved'),
(17, 101, 'My neighbor from a1 is very loud', '2026-11-09', 'Resolved');

INSERT INTO `payments` (`payment_id`, `resident_id`, `payment_name`, `payment_date`, `amount`, `status`) VALUES
(100, 101, 'teya de', '2026-11-07', '100.00', 'Paid'),
(101, 102, 'teya de', '2026-11-07', '100.00', 'Pending'),
(103, 103, 'teya de', '2026-11-07', '100.00', 'Pending'),
(105, 105, 'teya de', '2026-11-07', '100.00', 'Pending'),
(106, 106, 'teya de', '2026-11-07', '100.00', 'Pending'),
(107, 107, 'teya de', '2026-11-07', '100.00', 'Pending'),
(109, 109, 'teya de', '2026-11-07', '100.00', 'Pending'),
(110, 110, 'teya de', '2026-11-07', '100.00', 'Pending'),
(111, 113, 'teya de', '2026-11-07', '100.00', 'Paid'),
(116, 113, 'rent', '2026-11-06', '12222.00', 'Pending'),
(118, 101, 'maintenance', '2026-11-10', '100.00', 'Paid'),
(119, 102, 'maintenance', '2026-11-10', '100.00', 'Pending'),
(120, 103, 'maintenance', '2026-11-10', '100.00', 'Pending'),
(122, 105, 'maintenance', '2026-11-10', '100.00', 'Pending'),
(123, 106, 'maintenance', '2026-11-10', '100.00', 'Pending'),
(124, 107, 'maintenance', '2026-11-10', '100.00', 'Pending'),
(126, 109, 'maintenance', '2026-11-10', '100.00', 'Pending'),
(127, 110, 'maintenance', '2026-11-10', '100.00', 'Pending'),
(130, 113, 'maintenance', '2026-11-10', '100.00', 'Pending'),
(146, 122, 'rent', '2026-11-12', '450.00', 'Pending'),
(147, 123, 'teya de', '2026-11-12', '100.00', 'Paid'),
(148, 124, 'maintenance', '2026-11-12', '100.00', 'Paid'),
(149, 126, 'ta', '2026-12-10', '100.00', 'Paid');

INSERT INTO `transactions` (`transaction_id`, `payment_id`, `transaction_date`, `method`) VALUES
(1, 100, '2026-11-07', 'Not recorded'),
(2, 111, '2026-11-07', 'Not recorded'),
(3, 118, '2026-11-10', 'Not recorded'),
(4, 147, '2026-11-12', 'Not recorded'),
(5, 148, '2026-11-12', 'Not recorded'),
(6, 149, '2026-12-10', 'Not recorded');

INSERT INTO `facilities` (`facility_id`, `facility_name`) VALUES
(1, 'Community Hall'),
(2, 'Swimming Pool'),
(3, 'Gymnasium'),
(4, 'Tennis Court'),
(5, 'Basketball Court'),
(6, 'Library'),
(7, 'Rooftop Garden');

INSERT INTO `bookings` (`booking_id`, `resident_id`, `facility_id`, `booking_date`, `status`) VALUES
(11, 101, 1, '2026-10-20', 'Accepted'),
(12, 102, 2, '2026-10-25', 'Rejected'),
(13, 103, 3, '2026-10-30', 'Cancelled'),
(15, 105, 4, '2026-11-09', 'Accepted'),
(16, 106, 5, '2026-10-27', 'Accepted'),
(17, 107, 6, '2026-11-04', 'Accepted'),
(19, 109, 5, '2026-11-14', 'Accepted'),
(20, 110, 6, '2026-11-19', 'Accepted'),
(21, 101, 4, '2026-10-16', 'Pending'),
(22, 101, 6, '2026-11-05', 'Pending'),
(23, 101, 4, '2026-11-04', 'Pending'),
(24, 101, 1, '2026-10-28', 'Cancelled'),
(25, 101, 7, '2026-10-21', 'Cancelled'),
(26, 101, 1, '2026-11-05', 'Cancelled'),
(27, 101, 7, '2026-11-06', 'Cancelled'),
(28, 113, 4, '2026-11-04', 'Cancelled'),
(29, 113, 5, '2026-11-05', 'Cancelled'),
(30, 113, 4, '2026-11-03', 'Cancelled'),
(31, 113, 1, '2026-10-29', 'Cancelled'),
(32, 113, 3, '2026-10-16', 'Cancelled'),
(33, 113, 4, '2026-11-05', 'Accepted'),
(34, 101, 4, '2026-11-12', 'Cancelled'),
(35, 101, 4, '2026-11-10', 'Accepted'),
(36, 123, 4, '2026-11-13', 'Accepted'),
(37, 124, 3, '2026-11-11', 'Accepted'),
(38, 101, 3, '2026-12-03', 'Accepted'),
(39, 126, 4, '2026-11-20', 'Accepted');

INSERT INTO `events` (`event_id`, `society_id`, `event_name`, `event_date`) VALUES
(1, 1, 'Independence Day Celebration', '2026-03-26'),
(2, 2, 'Eid Gathering', '2026-03-21'),
(3, 3, 'Pohela Boishakh Festival', '2026-04-14'),
(4, 1, 'Community Clean-up', '2026-11-01'),
(5, 2, 'Winter Picnic', '2026-12-15'),
(6, 3, 'Blood Donation Drive', '2026-12-20');

INSERT INTO `staff` (`staff_id`, `building_id`, `name`, `role`) VALUES
(1, 1, 'Kamrul Islam', 'Security Guard'),
(2, 2, 'Marium Begum', 'Cleaner'),
(3, 3, 'Abul Kalam', 'Electrician'),
(4, 4, 'Salma Khan', 'Gardener'),
(5, 5, 'Rubel Ahmed', 'Plumber'),
(6, 6, 'Lamia Khatun', 'Gardener'),
(7, 7, 'Sakib Ali', 'Electrician');

INSERT INTO `security_logs` (`log_id`, `resident_id`, `entry_time`, `exit_time`) VALUES
(6, 101, '2026-10-14 08:00:00', '2026-10-14 18:00:00'),
(7, 102, '2026-10-14 09:00:00', '2026-10-14 19:00:00'),
(8, 103, '2026-10-14 10:00:00', '2026-10-14 20:00:00'),
(10, 105, '2026-10-14 06:00:00', '2026-10-14 16:00:00');

INSERT INTO `notifications` (`notification_id`, `user_id`, `message`, `created_at`, `status`) VALUES
(1, 24, 'pay rent please', '2026-10-27 15:18:05', 'read'),
(2, 34, 'pay rent please', '2026-10-27 15:18:05', 'read'),
(3, 30, 'pay rent please', '2026-10-27 15:18:05', 'unread'),
(4, 22, 'pay rent please', '2026-10-27 15:18:05', 'unread'),
(5, 18, 'pay rent please', '2026-10-27 15:18:05', 'unread'),
(6, 34, 'A new resident application has been submitted by name( mahmud bin kashem ) contact( 01676136364 ) email( mahmud21391@gmail.com ) flat( 2 ).', '2026-11-08 11:15:47', 'read'),
(7, 42, 'you are resident in the system', '2026-11-08 11:29:06', 'read'),
(8, 9, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'read'),
(9, 10, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'unread'),
(10, 11, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'unread'),
(11, 12, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'unread'),
(12, 13, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'unread'),
(13, 14, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'unread'),
(14, 15, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'unread'),
(15, 16, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'unread'),
(16, 17, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'unread'),
(17, 18, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'unread'),
(18, 22, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'unread'),
(19, 24, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'unread'),
(20, 34, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'read'),
(21, 37, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'unread'),
(22, 38, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'unread'),
(23, 39, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'unread'),
(24, 40, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'unread'),
(25, 42, 'you have a payment. payment name: maintenance, amount: 100, last date: 2026-11-10', '2026-11-08 11:41:45', 'read'),
(26, 42, 'you have a new payment. payment name: rent, amount: 1200, last date: 2026-11-11', '2026-11-08 13:37:12', 'unread'),
(27, 34, 'A new resident application has been submitted by name( hridita red ) contact( 01975602537 ) email( hriditared@gmail.com ) flat( 3 ).', '2026-11-08 17:44:14', 'read'),
(28, 44, 'you are resident in the system', '2026-11-08 17:46:06', 'unread'),
(29, 44, 'you have a new payment. payment name: rent, amount: 450, last date: 2026-11-12', '2026-11-08 17:46:42', 'unread'),
(30, 34, 'A new resident application has been submitted by name( rafsat wairan ) contact( 01857102597 ) email( wairanrafsat@gmail.com ) flat( 3 ).', '2026-11-10 05:23:50', 'read'),
(31, 45, 'you are resident in the system', '2026-11-10 05:26:08', 'read'),
(32, 45, 'you have a new payment. payment name: teya de, amount: 100, last date: 2026-11-12', '2026-11-10 05:28:19', 'unread'),
(33, 34, 'A new resident application has been submitted by name( sanjida momotaz ) contact( 02223212354 ) email( sanjida.momotaz1@northsouth.edu ) flat( 4 ).', '2026-11-10 06:58:45', 'read'),
(34, 46, 'you are resident in the system', '2026-11-10 07:00:27', 'read'),
(35, 46, 'you have a new payment. payment name: maintenance, amount: 100, last date: 2026-11-12', '2026-11-10 07:01:35', 'read'),
(36, 34, 'A new resident application has been submitted by name( sanjida momotaz ) contact( 02223212354 ) email( sanjida.momotaz1@northsouth.edu ) flat( 2 ).', '2026-11-11 07:29:44', 'read'),
(37, 40, 'you are resident in the system', '2026-11-11 07:31:19', 'unread'),
(38, 34, 'A new resident application has been submitted by name( Tushar Basak ) contact( 01857102597 ) email( tushar.basak@northsouth.edu ) flat( 1 ).', '2026-11-19 04:49:12', 'read'),
(39, 37, 'you are resident in the system', '2026-11-19 04:50:13', 'unread'),
(40, 37, 'you have a new payment. payment name: ta, amount: 100, last date: 2026-12-10', '2026-11-19 04:50:43', 'unread');

SET FOREIGN_KEY_CHECKS = 1;
