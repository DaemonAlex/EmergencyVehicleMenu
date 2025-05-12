# Vehicle Modification System - Standalone Version

## Overview
A powerful standalone FiveM script for modifying emergency vehicles with an intuitive menu system powered by ox_lib. Easily customize vehicle liveries, performance, appearance, and more with a clean, user-friendly interface. Access is restricted to designated garage locations.

## Requirements
- **Standalone Mode** - No framework dependencies required
- **ox_lib** - For UI components
- **OxMysql** - For database operations

---

## Key Features

### Core Functionality
- **Location-Based Access Control**: Modify vehicles only at designated police and fire department garages
- **Emergency Vehicle Support**: Automatically detects emergency vehicles using multiple methods
- **Vehicle Liveries**: Apply standard and custom YFT liveries to vehicles
- **Custom Livery Management**: Add, remove, and organize custom liveries directly in-game
- **Performance Upgrades**: Engine, brakes, transmission, suspension, armor, and turbo
- **Appearance Customization**: Colors, wheels, window tints, neon lights, and more
- **Vehicle Extras**: Toggle up to 20 vehicle extras
- **Door Controls**: Individual control for doors, hood, and trunk

### User Experience
- **Intuitive UI**: Clean menu system with status indicators
- **Visual Zone Indicators**: Map blips and ground markers show available modification locations
- **Interactive Access**: Press E to open the menu when in a garage with an emergency vehicle
- **Search Functionality**: Find specific liveries quickly with built-in search
- **Configuration Saving**: Save your favorite vehicle setups
- **Auto-apply**: Automatically apply saved configurations when entering vehicles

### Administration
- **Easy Configuration**: Add or remove modification zones through simple config edits
- **Zone Types**: Different visual indicators for police and fire department garages
- **Customizable Features**: Enable or disable specific modification types
- **Database Integration**: Save and load configurations across server restarts

![Vehicle Menu Overview](https://github.com/user-attachments/assets/5b62ed1c-a2e7-4b71-b89a-47df75792435)
![Livery Selection](https://github.com/user-attachments/assets/86eda620-02b0-4841-9939-d02b35a4e4d5)
![Color Options](https://github.com/user-attachments/assets/dea93887-7598-4896-aee2-294e8a4d009d)

## Commands and Controls
- `/modveh` - Open the vehicle modification menu (when in a modification zone)
- Default keybind: `F7` (customizable)
- Press `E` when in a modification zone to open the menu

## Access Control
Access to the vehicle modification menu is restricted to:
1. **Location-Based**: Must be within designated modification zones at police or fire stations
2. **Vehicle-Based**: Only emergency vehicles can be modified (configurable)

This approach provides natural security by restricting access to garages that should already be physically secured in-game.

## Configuration
The `config.lua` file allows you to customize various aspects of the script:

```lua
Config.Debug = true
-- Location-based authorization for vehicle modifications
Config.ModificationZones = {
   -- Police Department Locations (add additional locations using the same format)
   {
       name = "Mission Row Police Department Garage",
       coords = vector3(454.6, -1017.4, 28.4),
       radius = 30.0,
       type = "police"  -- For blip and marker colors
   },
   -- Add more locations as needed
}

-- Whether to enable blips on the map for modification zones
Config.ShowBlips = true

-- Whether to show markers on the ground at modification zones
Config.ShowMarkers = true

-- Whether to restrict to emergency vehicles only
Config.EmergencyVehiclesOnly = true

-- Available modification types - enable/disable as needed
Config.EnabledModifications = {
   Liveries = true,            -- Standard vehicle liveries
   CustomLiveries = true,      -- Custom YFT liveries
   Performance = true,         -- Engine, brakes, transmission, etc.
   Appearance = true,          -- Colors, wheels, window tint
   Neon = true,                -- Neon lights and colors
   Extras = true,              -- Vehicle extras toggle
   Doors = true                -- Door controls
}
```
## Handling Custom Liveries
```text
This script applies custom liveries by referencing `.yft` files that you have streamed using a separate resource.

1.  **Stream Your Liveries:** Ensure your custom vehicle `.yft` files (and their corresponding `.ytd` texture dictionaries) are correctly added to a streaming resource in your server.
2.  **Configure Paths:** Add entries to `Config.CustomLiveries` in `config.lua` or use the in-game 'Add New Livery' menu. Provide:
    * A display name for the menu.
    * The path to the `.yft` file *relative to the resource it's streamed in*, or simply the filename if it's in the root `stream` folder of its resource (e.g., `"police_livery_lspd.yft"`).
3.  **Texture Dictionary Naming:** Crucially, the script expects the accompanying texture dictionary (`.ytd`) to follow a specific naming convention for it to be loaded correctly (see next point).

text
[vehiclename]
├──fxmanifest.lua
└── stream
        ├── vehicle_livery1.yft
        ├── vehicle_livery2.yft
        ├── vehicle.yft
        ├── modparts.yft
        └── vehicle_lightbar_standard.yft
```
## Database Tables
```sql
CREATE TABLE IF NOT EXISTS `vehicle_mods` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `vehicle_model` VARCHAR(255) NOT NULL,
    `extras` TEXT DEFAULT NULL, -- Stores all vehicle properties as JSON
    `player_id` VARCHAR(255) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `vehicle_model_unique` (`vehicle_model`)
);
```
The extras column holds a JSON object containing all saved modifications. 

### Adding Custom Liveries
Place your YFT livery files in the appropriate folders within the stream directory:
- For police vehicles: `stream`
- For ambulances: `stream`
- For other vehicles: `stream`

## Coming Soon
- Vehicle-specific configuration profiles
- Framework integration options
- Image preview for liveries
- Comprehensive livery management panel
- Additional SQL logic to save preferences for each vehicle

## Notes
The script currently uses a location-based permission system for simplicity and ease of configuration. This approach relies on server administrators properly securing the physical locations (police and fire stations) in their server setup.
