# Police Vehicle Modification System for QBCore/QBX

This FiveM resource enables a comprehensive vehicle modification system specifically tailored for emergency vehicles. Designed for servers running the QBCore framework, it allows players with the police job to enhance their vehicle's performance and customize appearances through an intuitive menu.

---

## Requirements

- **QBCore Framework**
- **ox_lib**
- **MySQL Database** (MariaDB or MySQL)

---

## Features

- **Performance Upgrades**: Upgrade emergency vehicles to level 4 performance.
- **Custom Skins**: Change vehicle appearances with customizable skins.
- **Toggle Extras**: Enable or disable vehicle extras.
- **Database Integration**: Save and retrieve modifications for persistence.

---

## Installation

### 1. Download the Resource
Clone or download this repository into your `resources` folder.

### 2. Set Up the Database
Run the following SQL query in your database to create the `emergency_vehicle_mods` table:

```sql
CREATE TABLE IF NOT EXISTS `emergency_vehicle_mods` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `vehicle_model` VARCHAR(255) NOT NULL,
  `performance_level` INT NOT NULL DEFAULT 4,
  `skin` INT DEFAULT NULL,
  `extras` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
