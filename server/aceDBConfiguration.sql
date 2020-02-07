-- --------------------------------------------------------
-- Host:                         harddb.fxpal.net
-- Server version:               5.7.18-0ubuntu0.16.04.1 - (Ubuntu)
-- Server OS:                    Linux
-- HeidiSQL Version:             10.3.0.5771
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;


-- Dumping database structure for ace
CREATE DATABASE IF NOT EXISTS `ace` /*!40100 DEFAULT CHARACTER SET latin1 */;
USE `ace`;

-- Dumping structure for table ace.anchor
CREATE TABLE IF NOT EXISTS `anchor` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uuid` text,
  `url` text,
  `type` enum('image','object','none') DEFAULT 'none',
  `name` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table ace.clip
CREATE TABLE IF NOT EXISTS `clip` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` text,
  `user_uuid` text,
  `room_uuid` text,
  `uuid` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=158 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table ace.clipAnchor
CREATE TABLE IF NOT EXISTS `clipAnchor` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `anchor_uuid` text NOT NULL,
  `clip_uuid` text NOT NULL,
  `position` text,
  `uuid` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=85 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table ace.room
CREATE TABLE IF NOT EXISTS `room` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `time_ping` bigint(20) DEFAULT NULL,
  `time_request` bigint(20) DEFAULT NULL,
  `time_created` bigint(20) DEFAULT '0',
  `uuid` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=272 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table ace.user
CREATE TABLE IF NOT EXISTS `user` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `type` enum('customer','expert','none') NOT NULL DEFAULT 'none',
  `photo_url` text,
  `uuid` text NOT NULL,
  `password` text,
  `email` text,
  `name` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=269 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table ace.userRoom
CREATE TABLE IF NOT EXISTS `userRoom` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `room_uuid` text,
  `user_uuid` text,
  `time_ping` bigint(20) DEFAULT NULL,
  `uuid` text,
  `state` tinyint(4) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=424 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
