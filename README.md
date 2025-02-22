## Emergency Vehicle Modification System for QBCore/QBX, ESX, and Standalone via OX_LIB UI

## Requirements
- **QBCore/QBX Framework**, **ESX**, **Standalone**
- **ox_lib**
- **OxMysql**

---

## Features
- Easy-to-edit config to add additional jobs or custom job names
-  Compatibility with **QBX** & **ESX** frameworks
- **Change Vehicle Extras**: Add and remove up to 20 vehicle extras
- **Custom Skins**: Change vehicle liveries
- **Database Integration**: Save and retrieve modifications for user vehicle preference persistence
- **Job-based Access**: Only allows first responders (police/ambulance) to modify emergency vehicles
- **Standalone Compatibility**: Custom setup for servers not using QBCore or ESX

![Screenshot 2025-01-30 190859](https://github.com/user-attachments/assets/5b62ed1c-a2e7-4b71-b89a-47df75792435)
![Screenshot 2025-01-30 190647](https://github.com/user-attachments/assets/86eda620-02b0-4841-9939-d02b35a4e4d5)
![Screenshot 2025-01-30 190611](https://github.com/user-attachments/assets/dea93887-7598-4896-aee2-294e8a4d009d)

**Future Updates:**

- Additional SQL logic to save preferences for each vehicle the player uses, with updates on each change
- Compatibility with other menus (TBD based on feedback)
- Complete Mod menu for useable only at PD, EMS, or other locations specified in the config

---

## COMMANDS
- `/modveh`

### Notes:
- Ensure your **ox_lib** and **OxMysql** dependencies are properly installed and configured in your server.
- **ox_lib** interface for vehicle modification will need to be set up on your server. This part is essential for interacting with the modification menu, which can be customized to your preferences.
---

## Installation

### 1. Download the Resource
Clone or download this repository into your `resources` folder and ensure it's loaded on your server.

### 2. Configuration
Before starting your server, open the `config.lua` file in the resource folder and set the `Config.Framework` to one of the following:
- `'qb-core'` for **QBCore/QBX**
- `'esx'` for **ESX**
- `'standalone'` for a **custom setup** without a framework

```lua
-- Framework Selection Configuration
Config = {}
Config.Framework = 'qb-core' -- Change this to 'esx' or 'standalone' as needed

### 3. Set Up the Database
Run the appropriate SQL script for your server's framework to create the `emergency_vehicle_mods` table.

#### For QBCore:
Run the SQL code in `qbcore_sql.sql`:
```sql
CREATE TABLE IF NOT EXISTS `emergency_vehicle_mods` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `vehicle_model` VARCHAR(255) NOT NULL,
    `skin` VARCHAR(255) DEFAULT NULL,
    `extras` TEXT DEFAULT NULL,
    `player_id` VARCHAR(255) NOT NULL,  -- Tracks player by identifier (optional)
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `vehicle_model_unique` (`vehicle_model`)
);

#### For ESX:
Run the SQL code in `esx_sql.sql`:
```sql
CREATE TABLE IF NOT EXISTS `emergency_vehicle_mods` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `vehicle_model` VARCHAR(255) NOT NULL,
    `skin` VARCHAR(255) DEFAULT NULL,
    `extras` TEXT DEFAULT NULL,
    `player_id` VARCHAR(255) NOT NULL,  -- Tracks player by identifier (optional)
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `vehicle_model_unique` (`vehicle_model`)
);

#### For Standalone:
Run the SQL code in `standalone_sql.sql`:
```sql
CREATE TABLE IF NOT EXISTS `emergency_vehicle_mods` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `vehicle_model` VARCHAR(255) NOT NULL,
    `skin` VARCHAR(255) DEFAULT NULL,
    `extras` TEXT DEFAULT NULL,
    `player_id` VARCHAR(255) NOT NULL,  -- Tracks player by identifier (optional)
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `vehicle_model_unique` (`vehicle_model`)
);
### 4. Run Your Server
After you've updated the configuration and set up your database, you can start your server. The **Emergency Vehicle Modification System** will now be fully integrated and functional!

---

