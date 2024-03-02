# Police Vehicle Modification System for QBCore/QBX

This FiveM resource enables a comprehensive vehicle modification system specifically tailored for emergency vehicles. Designed for servers running the QBCore framework, it allows players with the 'police' job to enhance their vehicle's performance and customize appearances through an intuitive menu.

## Requirements

- QBCore Framework
- OX MySQL

## Features

- Performance enhancements up to level 4 for emergency vehicles.
- Customizable skins and extras for vehicle appearance.

## Installation

1. Ensure QBCore and OX MySQL are properly installed and configured on your server.
2. Clone this repository into your server's resources folder.
3. Add `ensure PoliceVehicleMenu` to your server.cfg.
4. Import the following SQL to your Database
  
```
-- Check if the 'emergency_vehicle_mods' table exists, and create it if not
CREATE TABLE IF NOT EXISTS `emergency_vehicle_mods` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `vehicle_model` VARCHAR(255) NOT NULL,
  `performance_level` INT NOT NULL DEFAULT 4,
  `skin` INT DEFAULT NULL,
  `extras` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert example data (adjust or remove according to your needs)
INSERT INTO `emergency_vehicle_mods` (`vehicle_model`, `performance_level`, `skin`, `extras`) VALUES
('11caprice', 4, 1, '1,2,3'),
('tahoe', 4, 2, '4,5,6'),
('18charger', 4, 3, '7,8,9');
```
-- Note: The above table and data insertion are examples.
-- Modify the structure and data according to your server specific requirements.

## Configuration

Edit the `config.lua` file to specify available police vehicles, skin ranges, and extra options. This allows for extensive customization to fit server themes.

## Usage

In-game, players with the 'police' job can access the modification menu by using the `/modvehicle` command near their assigned emergency vehicles.

## Troubleshooting

For common issues, such as missing vehicles or menu access problems, verify your server's configuration and ensure all dependencies are up to date.

## Contributing

Contributions are welcome! Please submit pull requests or issues on GitHub for any features or fixes.

## License

Distributed under the MIT License. See `LICENSE` for more information.






