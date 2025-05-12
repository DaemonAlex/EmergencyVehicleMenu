-- Vehicle Modification System - Standalone Edition
-- Server-side script

if not Config then
    print("^1ERROR:^0 Config is not loaded! Check fxmanifest.lua.")
    return
end

-- Initialize database
local ox_mysql = exports['oxmysql']

CreateThread(function()
    Wait(1000) -- Wait for oxmysql to initialize

    -- Create database tables if they don't exist
    ox_mysql:execute([[
        CREATE TABLE IF NOT EXISTS custom_liveries (
            id INT NOT NULL AUTO_INCREMENT,
            vehicle_model VARCHAR(255) NOT NULL,
            livery_name VARCHAR(255) NOT NULL,
            livery_file VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id)
        )
    ]], {}, function(result)
        if result then
            print("^2INFO:^0 custom_liveries table created or already exists.")
        else
            print("^1ERROR:^0 Failed to create custom_liveries table.")
        end
    end)

    -- Create vehicle_mods table if it doesn't exist
    ox_mysql:execute([[
        CREATE TABLE IF NOT EXISTS vehicle_mods (
            id INT NOT NULL AUTO_INCREMENT,
            vehicle_model VARCHAR(255) NOT NULL,
            extras TEXT,
            player_id VARCHAR(255),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY vehicle_model_unique (vehicle_model)
        )
    ]], {}, function(result)
        if result then
            print("^2INFO:^0 vehicle_mods table created or already exists.")
        else
            print("^1ERROR:^0 Failed to create vehicle_mods table.")
        end
    end)

    -- Load custom liveries from database
    ox_mysql:execute("SELECT vehicle_model, livery_name, livery_file FROM custom_liveries", {}, function(result)
        if result and #result > 0 then
            for _, livery in ipairs(result) do
                if not Config.CustomLiveries[livery.vehicle_model] then
                    Config.CustomLiveries[livery.vehicle_model] = {}
                end
                
                table.insert(Config.CustomLiveries[livery.vehicle_model], {
                    name = livery.livery_name,
                    file = livery.livery_file
                })
            end
            
            print("^2INFO:^0 Loaded " .. #result .. " custom liveries from database.")
        else
            print("^3INFO:^0 No custom liveries found in database.")
        end
    end)
    
    print("^2INFO:^0 Vehicle Modification System initialized successfully.")
end)

-- Apply a custom livery to a vehicle
RegisterNetEvent('vehiclemods:server:applyCustomLivery')
AddEventHandler('vehiclemods:server:applyCustomLivery', function(netId, vehicleModelName, liveryFile)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    
    if not vehicle or not DoesEntityExist(vehicle) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Vehicle not found.',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    TriggerClientEvent('vehiclemods:client:setCustomLivery', -1, netId, vehicleModelName, liveryFile)
    
    if Config.Debug then
        print("^2DEBUG:^0 Applied custom livery " .. vehicleModelName .. "/" .. liveryFile .. " to vehicle with netId " .. netId)
    end
end)

-- Clear custom livery from a vehicle
RegisterNetEvent('vehiclemods:server:clearCustomLivery')
AddEventHandler('vehiclemods:server:clearCustomLivery', function(netId)
    -- Broadcast to all clients to clear the custom livery
    TriggerClientEvent('vehiclemods:client:clearCustomLivery', -1, netId)
    
    if Config.Debug then
        print("^2DEBUG:^0 Cleared custom livery from vehicle with netId " .. netId)
    end
end)

-- Save vehicle modifications
RegisterNetEvent('vehiclemods:server:saveModifications')
AddEventHandler('vehiclemods:server:saveModifications', function(vehicleModel, vehicleProps)
    local src = source
    local playerId = tostring(src) -- In standalone mode, use the player's server ID
    
    if Config.Debug then
        print("^2DEBUG:^0 Saving modifications for vehicle: " .. vehicleModel)
    end
    
    ox_mysql:execute("INSERT INTO vehicle_mods (vehicle_model, extras, player_id) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE extras = VALUES(extras)",
        {vehicleModel, vehicleProps, playerId})
        
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Vehicle Saved',
        description = 'Your vehicle configuration has been saved.',
        type = 'success',
        duration = 5000
    })
end)

-- Add a new custom livery
RegisterNetEvent('vehiclemods:server:addCustomLivery')
AddEventHandler('vehiclemods:server:addCustomLivery', function(vehicleModel, liveryName, liveryFile)
    local src = source
    
    -- Validate that the livery file path points to the liveries folder
    if not string.match(liveryFile, "^liveries/") then
        -- If file doesn't start with liveries/, prefix it
        liveryFile = "liveries/" .. liveryFile
    end
    
    -- Ensure the file has .yft extension
    if not string.match(liveryFile, "%.yft$") then
        liveryFile = liveryFile .. ".yft"
    end
    
    -- First, check if the vehicle model exists in the custom liveries config
    if not Config.CustomLiveries[vehicleModel:lower()] then
        Config.CustomLiveries[vehicleModel:lower()] = {}
    end
        
    -- Check if we've reached the limit of 20 liveries for this vehicle
    if #Config.CustomLiveries[vehicleModel:lower()] >= 20 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Limit Reached',
            description = 'This vehicle already has the maximum of 20 custom liveries.',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Add the new livery
    table.insert(Config.CustomLiveries[vehicleModel:lower()], {
        name = liveryName,
        file = liveryFile
    })
    
    -- Save to database
    ox_mysql:execute("INSERT INTO custom_liveries (vehicle_model, livery_name, livery_file) VALUES (?, ?, ?)",
        {vehicleModel:lower(), liveryName, liveryFile})
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Livery Added',
        description = 'Custom livery "' .. liveryName .. '" added for ' .. vehicleModel,
        type = 'success',
        duration = 5000
    })
    
    -- Broadcast the updated config to all clients
    TriggerClientEvent('vehiclemods:client:updateCustomLiveries', -1, Config.CustomLiveries)
end)

-- Request vehicle configuration
RegisterNetEvent('vehiclemods:server:requestVehicleConfig')
AddEventHandler('vehiclemods:server:requestVehicleConfig', function(vehicleModel)
    local src = source
    local playerId = tostring(src) -- In standalone mode, use the player's server ID
    
    -- Check if config exists in database
    ox_mysql:execute('SELECT extras FROM vehicle_mods WHERE vehicle_model = ?', {vehicleModel}, 
        function(result)
            if result and result[1] and result[1].extras then
                -- Send the configuration back to the client
                TriggerClientEvent('vehiclemods:client:applyVehicleConfig', src, vehicleModel, result[1].extras)
                
                if Config.Debug then
                    print("^2DEBUG:^0 Sent saved configuration for " .. vehicleModel .. " to player " .. src)
                end
            else
                if Config.Debug then
                    print("^3DEBUG:^0 No saved configuration found for " .. vehicleModel)
                end
            end
        end
    )
end)

-- Remove a custom livery
RegisterNetEvent('vehiclemods:server:removeCustomLivery')
AddEventHandler('vehiclemods:server:removeCustomLivery', function(vehicleModel, liveryName)
    local src = source
    
    -- Check if the vehicle model exists in the custom liveries config
    if not Config.CustomLiveries[vehicleModel:lower()] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'No custom liveries found for this vehicle.',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Find and remove the livery
    local removed = false
    for i, livery in ipairs(Config.CustomLiveries[vehicleModel:lower()]) do
        if livery.name == liveryName then
            table.remove(Config.CustomLiveries[vehicleModel:lower()], i)
            removed = true
            break
        end
    end
    
    if removed then
        -- Remove from database
        ox_mysql:execute("DELETE FROM custom_liveries WHERE vehicle_model = ? AND livery_name = ?",
            {vehicleModel:lower(), liveryName})
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Livery Removed',
            description = 'Custom livery "' .. liveryName .. '" removed from ' .. vehicleModel,
            type = 'success',
            duration = 5000
        })
        
        -- Broadcast the updated config to all clients
        TriggerClientEvent('vehiclemods:client:updateCustomLiveries', -1, Config.CustomLiveries)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Livery "' .. liveryName .. '" not found.',
            type = 'error',
            duration = 5000
        })
    end
end)

-- Send all custom liveries to a client when requested
RegisterNetEvent('vehiclemods:server:requestCustomLiveries')
AddEventHandler('vehiclemods:server:requestCustomLiveries', function()
    local src = source
    TriggerClientEvent('vehiclemods:client:updateCustomLiveries', src, Config.CustomLiveries)
end)

-- Initialize custom liveries when resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Load all custom liveries from database
    ox_mysql:execute("SELECT vehicle_model, livery_name, livery_file FROM custom_liveries", {}, function(result)
        if result and #result > 0 then
            for _, livery in ipairs(result) do
                if not Config.CustomLiveries[livery.vehicle_model] then
                    Config.CustomLiveries[livery.vehicle_model] = {}
                end
                
                table.insert(Config.CustomLiveries[livery.vehicle_model], {
                    name = livery.livery_name,
                    file = livery.livery_file
                })
            end
            
            print("^2INFO:^0 Loaded " .. #result .. " custom liveries from database.")
        else
            print("^3INFO:^0 No custom liveries found in database.")
        end
    end)
end)
