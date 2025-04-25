# Vehicle Modification System - Standalone Version

## Overview
A powerful standalone FiveM script for modifying emergency and civilian vehicles with an intuitive menu system powered by ox_lib. Easily customize vehicle liveries, performance, appearance, and more with a clean, user-friendly interface.

## Requirements
- **Standalone Mode** - No framework dependencies required
- **ox_lib** - For UI components
- **OxMysql** - For database operations

---

## Key Features

### Core Functionality
- **Framework Flexible**: Works in standalone mode, QB-Core/Qbox, or ESX
- **Vehicle Liveries**: Apply standard and custom YFT liveries to vehicles
- **Custom Livery Management**: Add, remove, and organize custom liveries directly in-game
- **Performance Upgrades**: Engine, brakes, transmission, suspension, armor, and turbo
- **Appearance Customization**: Colors, wheels, window tints, neon lights, and more
- **Vehicle Extras**: Toggle up to 20 vehicle extras
- **Door Controls**: Individual control for doors, hood, and trunk

### User Experience
- **Intuitive UI**: Clean menu system with status indicators
- **Search Functionality**: Find specific liveries quickly with built-in search
- **Preview Options**: See changes before applying them
- **Configuration Saving**: Save your favorite vehicle setups
- **Auto-apply**: Automatically apply saved configurations when entering vehicles

### Administration
- **Job-Based Permissions**: Restrict access to authorized departments
- **Database Integration**: Save and load configurations across server restarts

![Vehicle Menu Overview](https://github.com/user-attachments/assets/5b62ed1c-a2e7-4b71-b89a-47df75792435)
![Livery Selection](https://github.com/user-attachments/assets/86eda620-02b0-4841-9939-d02b35a4e4d5)
![Color Options](https://github.com/user-attachments/assets/dea93887-7598-4896-aee2-294e8a4d009d)

## Commands
- `/modveh` - Open the vehicle modification menu (can be customized in config.lua)
- Default keybind: `F7` (customizable)

## Permissions
Access to the vehicle modification menu is restricted to authorized departments. By default, these include:

| Emergency Services | Law Enforcement | Support Services |
|-------------------|-----------------|------------------|
| `ambulance` | `police` | `mechanic` |
| `fire` | `sheriff` | `standalone` |
| | `bcso` | |
| | `sast` | |
| | `lscso` | |
| | `pbpd` | |
| | `sspd` | |
| | `gspd` | |
| | `papd` | |
| | `sagw` | |
| | `highway` | |

## Configuration
The `config.lua` file allows you to customize various aspects of the script:

```lua
Config.Framework = 'standalone' -- Options: 'qb-core', 'qbx-core', 'esx', 'standalone'
Config.Debug = false -- Enable/disable debug mode
Config.JobAccess = {} -- Define job permissions

resource_folder/
├── client.lua
├── config.lua
├── fxmanifest.lua
├── server.lua
└── stream/
    └── [vehiclemodelname]/  -- Different for each vehicle based on model name
        ├── liveries/
        │   ├── vehicle_livery1.yft
        │   ├── vehicle_livery2.yft
        │   └── ...
        ├── model/
        │   ├── vehicle.yft
        │   └── ...
        └── modparts/
            ├── vehicle_lightbar_standard.yft
            └── ...

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

CREATE TABLE IF NOT EXISTS `custom_liveries` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `vehicle_model` VARCHAR(255) NOT NULL,
    `livery_name` VARCHAR(255) NOT NULL,
    `livery_file` VARCHAR(255) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
);
```
### 3. Add Custom Liveries
Place your YFT livery files in the appropriate folders within the stream directory:
- For police vehicles: `stream/police/liveries/`
- For ambulances: `stream/ambulance/liveries/`
- For other vehicles: `stream/[vehiclemodel]/liveries/`

## Coming Soon
- Vehicle-specific configuration profiles
- Advanced permission system
- Image preview for liveries
- Comprehensive livery management panel
- Additional SQL logic to save preferences for each vehicle
