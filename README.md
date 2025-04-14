## Vehicle Modification System for QBCore/QBX, ESX, and Standalone via OX_LIB UI

## Requirements
- **QBCore/QBX Framework**, **ESX**, **Standalone**
- **ox_lib**
- **OxMysql**

---

## Features
- Easy-to-edit config to add additional jobs or custom job names
- Compatibility with **QBX** & **ESX** frameworks
- **Change Vehicle Extras**: Add and remove up to 20 vehicle extras
- **Custom Skins**: Change vehicle liveries
- **Standalone Compatibility**: Custom setup for servers not using QBCore or ESX

![Screenshot 2025-01-30 190859](https://github.com/user-attachments/assets/5b62ed1c-a2e7-4b71-b89a-47df75792435)
![Screenshot 2025-01-30 190647](https://github.com/user-attachments/assets/86eda620-02b0-4841-9939-d02b35a4e4d5)
![Screenshot 2025-01-30 190611](https://github.com/user-attachments/assets/dea93887-7598-4896-aee2-294e8a4d009d)

**Future Updates:**
- Additional SQL logic to save preferences for each vehicle the player uses, with updates on each change
- Compatibility with other menus, TBD based on feedback
- Complete Mod menu for useable only at PD, EMS, or other locations specified in the config

---

## COMMANDS
- `/modveh`

### Notes:
- Ensure your **ox_lib** and **OxMysql** dependencies are properly installed and configured in your server.
---

## Installation

### 1. Download the Resource
Clone or download this repository into your `resources` folder and ensure it's loaded on your server.

### 2. Configuration
Before starting your server, open the `config.lua` file in the resource folder and set the `Config.Framework` to one of the following:
- `'standalone'` 

```lua
-- Framework Selection Configuration
Config = {}
Config.Framework = 'standalone' 
```

### 3. Modify the fxmanifest.lua
Open the `fxmanifest.lua` file in the resource folder and uncomment the line for the framework you are using. Comment out the lines for the frameworks you are not using. Only one framework should be uncommented.

```lua
dependencies {
    'ox_lib'
}
```

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
```

### 5. Run Your Server
After you've updated the configuration and set up your database, you can start your server. The **Emergency Vehicle Modification System** will now be fully integrated and functional!

---
