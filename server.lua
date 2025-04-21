-- Emergency Vehicle Modifications Menu - Standalone Version
-- Server-side script

if not Config then
    print("^1ERROR:^0 Config is not loaded! Check fxmanifest.lua.")
    return
end

-- Initialize oxmysql export
local ox_mysql = exports['oxmysql']

-- Create the required database table if it doesn't exist
CreateThread(function()
    Wait(1000) -- Wait for oxmysql to initialize

    -- Check if oxmysql is available
    if ox_mysql then
        -- Create the vehicle mods table
        ox_mysql:execute([[
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
        ]], {}, function(result)
            if result then
                print("^2INFO:^0 Database tables for vehicle mods script initialized successfully.")
            else
                print("^1ERROR:^0 Failed to initialize database tables for vehicle mods script.")
            end
        end)
    else
        print("^1ERROR:^0 oxmysql export not found. Database functionality will not work.")
    end
end)

-- Event handler to save vehicle modifications
RegisterNetEvent('vehiclemods:server:saveModifications')
AddEventHandler('vehiclemods:server:saveModifications', function(vehicleModel, skin, extras)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0) -- Get player's identifier for tracking

    -- Save modifications to database
    ox_mysql:execute(
        "INSERT INTO emergency_vehicle_mods (vehicle_model, skin, extras, player_id) VALUES (?, ?, ?, ?) " ..
        "ON DUPLICATE KEY UPDATE skin = VALUES(skin), extras = VALUES(extras), player_id = VALUES(player_id)",
        {tostring(vehicleModel), skin, extras, identifier},
        function(result)
            if result and result.affectedRows > 0 then
                print("^2INFO:^0 Player " .. src .. " saved modifications for vehicle model " .. vehicleModel)
            else
                print("^1ERROR:^0 Failed to save vehicle modifications for player " .. src)
            end
        end
    )
end)

-- Event handler to retrieve vehicle modifications
RegisterNetEvent('vehiclemods:server:getModifications')
AddEventHandler('vehiclemods:server:getModifications', function(vehicleModel)
    local src = source
    
    -- Query the database for saved modifications
    ox_mysql:execute(
        "SELECT skin, extras FROM emergency_vehicle_mods WHERE vehicle_model = ?",
        {tostring(vehicleModel)},
        function(result)
            if result and #result > 0 then
                TriggerClientEvent('vehiclemods:client:returnModifications', src, result[1])
            else
                -- No saved modifications found
                TriggerClientEvent('vehiclemods:client:returnModifications', src, nil)
            end
        end
    )
end)

-- Optional: Event handler for server startup to check if any vehicle models have modifications
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print("^2INFO:^0 Vehicle Modifications System (Standalone) started successfully.")
    
    -- You could add additional startup checks here
    ox_mysql:execute("SELECT COUNT(*) as count FROM emergency_vehicle_mods", {}, function(result)
        if result and result[1] then
            print("^2INFO:^0 Found " .. result[1].count .. " saved vehicle configurations in database.")
        end
    end)
end)
