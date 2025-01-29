## Emergency Vehicle Modification System for QBCore/QBX via OX_LIB UI

## Requirements
- **QBCore/QBX Framework**
- **ox_lib**
- **OxMysql**

---

## Features

- **Change Vehicle Extras**: Ada and remove up to 20 Veh Extras
- **Custom Skins**: Change vehicle liveries.
- **Database Integration**: Save and retrieve modifications for user veh preference persistence.

---

## COMMANDS
 /modvehicle

---

## Installation

### 1. Download the Resource
Clone or download this repository into your `resources` folder and ensure.

### 2. Set Up the Database
Run the following SQL query in your database to create the `emergency_vehicle_mods` table:

```sql
CREATE TABLE IF NOT EXISTS `emergency_vehicle_mods` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `vehicle_model` VARCHAR(255) NOT NULL,
    `performance_level` INT DEFAULT 4,
    `skin` INT DEFAULT NULL,
    `extras` TEXT DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `vehicle_model_index` (`vehicle_model`)
);
