## Emergency Vehicle Modification System for QBCore/QBX via OX_LIB UI

## Requirements
- **QBCore/QBX Framework**
- **ox_lib**
- **OxMysql**

---

## Features

- **Change Vehicle Extras**: Add and remove up to 20 Veh Extras
- **Custom Skins**: Change vehicle liveries.
- **Database Integration**: Save and retrieve modifications for user veh preference persistence.

![Screenshot 2025-01-30 190859](https://github.com/user-attachments/assets/5b62ed1c-a2e7-4b71-b89a-47df75792435)
![Screenshot 2025-01-30 190647](https://github.com/user-attachments/assets/86eda620-02b0-4841-9939-d02b35a4e4d5)
![Screenshot 2025-01-30 190611](https://github.com/user-attachments/assets/dea93887-7598-4896-aee2-294e8a4d009d)

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
    `skin` VARCHAR(255) DEFAULT NULL,
    `extras` TEXT DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `vehicle_model_unique` (`vehicle_model`)
);
```
