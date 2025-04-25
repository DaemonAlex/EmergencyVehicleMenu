if not Config then
    print("^1ERROR:^0 Config is not loaded! Check fxmanifest.lua.")
end

local QBCore, ESX
local ox_mysql = exports['oxmysql']

if Config.Framework == 'qb-core' or Config.Framework == 'qbc-core' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end

RegisterNetEvent('vehiclemods:server:verifyJob', function()
    local src = source
    local Player

    if Config.Framework == 'qb-core' or Config.Framework == 'qbc-core' then
        Player = QBCore.Functions.GetPlayer(src)
    elseif Config.Framework == 'esx' then
        Player = ESX.GetPlayerFromId(src)
    elseif Config.Framework == 'standalone' then
        Player = { job = { name = 'standalone' } }
    end

    if Player then
        local job = Player.job.name
        if Config.JobAccess[job] then
            TriggerClientEvent('vehiclemods:client:openVehicleModMenu', src)
        else
            TriggerClientEvent('ox_lib:notify', src, {title = 'Access Denied', description = 'You must be a first responder to use this.', type = 'error'})
        end
    end
end)

RegisterNetEvent('vehiclemods:server:saveModifications', function(vehicleModel, vehicleProps)
    local src = source
    local Player
    
    if Config.Debug then
        print("^2DEBUG:^0 Saving modifications for vehicle: " .. vehicleModel)
    end

    if Config.Framework == 'qb-core' or Config.Framework == 'qbc-core' then
        Player = QBCore.Functions.GetPlayer(src)
    elseif Config.Framework == 'esx' then
        Player = ESX.GetPlayerFromId(src)
    elseif Config.Framework == 'standalone' then
        Player = { job = { name = 'standalone' }, identifier = tostring(src) }
    end

    if Player then
        local playerId = nil
        
        if Config.Framework == 'qb-core' or Config.Framework == 'qbc-core' then
            playerId = Player.PlayerData.citizenid
        elseif Config.Framework == 'esx' then
            playerId = Player.identifier
        elseif Config.Framework == 'standalone' then
            playerId = Player.identifier
        end
        
        if playerId then
            ox_mysql:execute("INSERT INTO emergency_vehicle_mods (vehicle_model, extras, player_id) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE extras = VALUES(extras)",
                {vehicleModel, vehicleProps, playerId})
                
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Vehicle Saved',
                description = 'Your vehicle configuration has been saved.',
                type = 'success',
                duration = 5000
            })
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Error',
                description = 'Could not identify player.',
                type = 'error',
                duration = 5000
            })
        end
    end
end)

RegisterNetEvent('vehiclemods:server:getModifications', function(vehicleModel)
    local src = source
    
    if Config.Debug then
        print("^2DEBUG:^0 Retrieving modifications for vehicle: " .. vehicleModel)
    end
    
    ox_mysql:execute("SELECT extras FROM emergency_vehicle_mods WHERE vehicle_model = ?", {vehicleModel}, function(result)
        if result and #result > 0 then
            TriggerClientEvent('vehiclemods:client:returnModifications', src, result[1])
        else
            TriggerClientEvent('vehiclemods:client:returnModifications', src, nil)
        end
    end)
end)

-- Add a custom livery to a vehicle
RegisterNetEvent('vehiclemods:server:addCustomLivery', function(vehicleModel, liveryName, liveryFile)
    local src = source
    
    -- Check if player has permission to add liveries (admin only)
    local Player
    local hasPermission = false
    
    if Config.Framework == 'qb-core' or Config.Framework == 'qbc-core' then
        Player = QBCore.Functions.GetPlayer(src)
        hasPermission = Player.PlayerData.permission == "admin" or Player.PlayerData.permission == "god"
    elseif Config.Framework == 'esx' then
        Player = ESX.GetPlayerFromId(src)
        hasPermission = Player.getGroup() == "admin" or Player.getGroup() == "superadmin"
    elseif Config.Framework == 'standalone' then
        -- In standalone mode, check if they're in the Config.JobAccess list
        hasPermission = true
    end
    
    if not hasPermission then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Permission Denied',
            description = 'You do not have permission to add custom liveries.',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- First, check if the vehicle model exists in the custom liveries config
    if not Config.CustomLiveries[vehicleModel:lower()] then
        Config.CustomLiveries[vehicleModel:lower()] = {}
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

-- Remove a custom livery from a vehicle
RegisterNetEvent('vehiclemods:server:removeCustomLivery', function(vehicleModel, liveryName)
    local src = source
    
    -- Check if player has permission to remove liveries (admin only)
    local Player
    local hasPermission = false
    
    if Config.Framework == 'qb-core' or Config.Framework == 'qbc-core' then
        Player = QBCore.Functions.GetPlayer(src)
        hasPermission = Player.PlayerData.permission == "admin" or Player.PlayerData.permission == "god"
    elseif Config.Framework == 'esx' then
        Player = ESX.GetPlayerFromId(src)
        hasPermission = Player.getGroup() == "admin" or Player.getGroup() == "superadmin"
    elseif Config.Framework == 'standalone' then
        -- In standalone mode, check if they're in the Config.JobAccess list
        hasPermission = true
    end
    
    if not hasPermission then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Permission Denied',
            description = 'You do not have permission to remove custom liveries.',
            type = 'error',
            duration = 5000
        })
        return
    end
    
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

-- Load all custom liveries from the database on resource start
CreateThread(function()
    Wait(1000) -- Wait for database to be ready
    
    -- Create custom_liveries table if it doesn't exist
    ox_mysql:execute([[
        CREATE TABLE IF NOT EXISTS custom_liveries (
            id INT NOT NULL AUTO_INCREMENT,
            vehicle_model VARCHAR(255) NOT NULL,
            livery_name VARCHAR(255) NOT NULL,
            livery_file VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id)
        )
    ]])
    
    -- Load all custom liveries
    ox_mysql:execute("SELECT * FROM custom_liveries", {}, function(result)
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
