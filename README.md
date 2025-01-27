Police Vehicle Modification System for QBCore/QBX
This FiveM resource enables a comprehensive vehicle modification system specifically tailored for emergency vehicles. Designed for servers running the QBCore framework, it allows players with the police job to enhance their vehicle's performance and customize appearances through an intuitive menu.

Requirements
QBCore Framework

ox_lib

MySQL Database (MariaDB or MySQL)

Features
Performance Upgrades: Upgrade emergency vehicles to level 4 performance.

Custom Skins: Change vehicle appearances with customizable skins.

Toggle Extras: Enable or disable vehicle extras.

Database Integration: Save and retrieve modifications for persistence.

Installation
Download the Resource:

Clone or download this repository into your resources folder.

Set Up the Database:

Run the following SQL query in your database to create the emergency_vehicle_mods table:

sql
Copy
CREATE TABLE IF NOT EXISTS `emergency_vehicle_mods` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `vehicle_model` VARCHAR(255) NOT NULL,
  `performance_level` INT NOT NULL DEFAULT 4,
  `skin` INT DEFAULT NULL,
  `extras` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
Configure the Resource:

Edit the config.lua file to specify available police vehicles, skin ranges, and extra options.

Add to server.cfg:

Add the following line to your server.cfg:

plaintext
Copy
ensure PoliceVehicleMenu
Dependencies:

Ensure ox_lib is installed and running on your server.

Configuration
config.lua
Edit the config.lua file to customize the resource:

Config.PoliceVehicles: Add or remove vehicle models allowed for modifications.

Config.SkinsRange: Define the range of available skins.

Config.ExtrasRange: Define the range of available extras.

Example:

lua
Copy
Config.PoliceVehicles = {
    '11caprice',
    'tahoe',
    '18charger'
}

Config.SkinsRange = {min = 1, max = 10}
Config.ExtrasRange = {min = 1, max = 20}
Usage
In-Game Command:

Use the /modvehicle command while inside an approved police vehicle to open the modification menu.

Menu Options:

Performance Upgrades: Upgrade your vehicle's performance to level 4.

Change Skin: Apply a random skin to your vehicle.

Toggle Extras: Enable or disable a random extra.

Troubleshooting
Menu Not Opening:

Ensure ox_lib is installed and running.

Verify the player has the police job.

Modifications Not Saving:

Check the database connection and ensure the emergency_vehicle_mods table exists.

Errors in Console:

Check the server console for any errors and ensure all dependencies are up to date.

License
This resource is distributed under the MIT License. See the LICENSE file for more information.
