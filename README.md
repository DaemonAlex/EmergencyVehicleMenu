# Vehicle Modification System - Standalone Version

## Overview
This is a standalone FiveM script for modifying emergency and civilian vehicles with an intuitive menu system powered by ox_lib.

## Requirements
- **Standalone** (No framework required)
- **ox_lib**
- **OxMysql**

---

## Features
- **Fully Standalone**: No framework dependencies required
- **Change Vehicle Extras**: Toggle up to 20 vehicle extras
- **Custom Skins**: Apply any available vehicle livery
- **Door Controls**: Individual door, hood, and trunk control
- **Configuration Saving**: Save your favorite vehicle setups
- **Auto-apply**: Automatically apply saved configurations when entering vehicles
- **User-friendly UI**: Clean and intuitive menu design

![Screenshot 2025-01-30 190859](https://github.com/user-attachments/assets/5b62ed1c-a2e7-4b71-b89a-47df75792435)
![Screenshot 2025-01-30 190647](https://github.com/user-attachments/assets/86eda620-02b0-4841-9939-d02b35a4e4d5)
![Screenshot 2025-01-30 190611](https://github.com/user-attachments/assets/dea93887-7598-4896-aee2-294e8a4d009d)

**Future Updates:**
- Additional SQL logic to save preferences for each vehicle the player uses, with updates on each change
- Compatibility with other menus, TBD based on feedback
- Complete Mod menu for useable only at PD, EMS, or other locations specified in the config
- Vehicle color customization options

---

## COMMANDS
- `/modveh` (Customizable in config.lua)

### Notes:
- Ensure your **ox_lib** and **OxMysql** dependencies are properly installed and configured in your server.

---

## Installation

### 1. Download the Resource
Clone or download this repository into your `resources` folder and ensure it's loaded on your server.

### 2. Database Setup
The script will automatically create the required database table on first run. If you prefer to create it manually, run:

```sql
CREATE TABLE IF NOT EXISTS `emergency_vehicle_mods` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `vehicle_model` VARCHAR(255) NOT NULL,
    `skin` VARCHAR(255) DEFAULT NULL,
    `extras` TEXT DEFAULT NULL,
    `player_id` VARCHAR(255) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `vehicle_model_unique` (`vehicle_model`)
);
