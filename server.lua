-- Emergency Vehicle Modifications Menu
-- Server-side script

if not Config then
    print("^1ERROR:^0 Config is not loaded! Check fxmanifest.lua.")
    return
end

local QBCore, ESX
local ox_mysql = exports['oxmysql']

if Config.Framework == 'qb-core' or Config.Framework == 'qbc-core' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end

function DoesFileExist(path)
    local f = LoadResourceFile(GetCurrentResourceName(), path)
    return f ~= nil
end

-- Function to scan directories for YFT files (simulate directory scanning)
function ScanForYFTFiles(resourceDir, vehicleModel)
    local liveriesPath = resourceDir .. "/" .. vehicleModel .. "/liveries"
    local modelsPath = resourceDir .. "/" .. vehicleModel .. "/model"
    local modpartsPath = resourceDir .. "/" .. vehicleModel .. "/modparts"
    
    local liveryFiles = {}
    local modelFiles = {}
    local modpartFiles = {}
    
    -- In a real implementation, you would scan the directory
    -- For now, we'll just print debug info
    if Config.Debug then
        print("^3DEBUG:^0 Would scan for YFT files in:")
        print("  Liveries: " .. liveriesPath)
        print("  Models: " .. modelsPath)
        print("  ModParts: " .. modpartsPath)
    end
    
    return {
        liveries = liveryFiles,
        models = modelFiles,
        modparts = modpartFiles
    }
end

-- Enhanced initialization function for resource start
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

    -- Create emergency_vehicle_mods table if it doesn't exist
    ox_mysql:execute([[
        CREATE TABLE IF NOT EXISTS emergency_vehicle_mods (
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
            print("^2INFO:^0 emergency_vehicle_mods table created or already exists.")
        else
            print("^1ERROR:^0 Failed to create emergency_vehicle_mods table.")
        end
    end)

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

    print("^2INFO:^0 Validating vehicle resource directories...")
    for _, vehicleModel in ipairs(Config.EmergencyVehicleModels) do
        local resourceDir = Config.GetVehicleResourceDir(vehicleModel)
        
        if Config.Debug then
            Config.DebugPaths(vehicleModel)
            
            local files = ScanForYFTFiles(resourceDir, vehicleModel)
        end
    end
    
    print("^2INFO:^0 Emergency Vehicle Modifications initialized successfully.")
end)

RegisterNetEvent('vehiclemods:server:verifyJob')
AddEventHandler('vehiclemods:server:verifyJob', function()
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
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Access Denied', 
                description = 'You must be an authorized department to use this.', 
                type = 'error'
            })
        end
    end
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

RegisterNetEvent('vehiclemods:server:clearCustomLivery')
AddEventHandler('vehiclemods:server:clearCustomLivery', function(netId)
    -- Broadcast to all clients to clear the custom livery
    TriggerClientEvent('vehiclemods:client:clearCustomLivery', -1, netId)
    
    if Config.Debug then
        print("^2DEBUG:^0 Cleared custom livery from vehicle with netId " .. netId)
    end
end)

-- Event handler to save vehicle modifications
RegisterNetEvent('vehiclemods:server:saveModifications')
AddEventHandler('vehiclemods:server:saveModifications', function(vehicleModel, vehicleProps)
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

-- Event handler to retrieve vehicle modifications
RegisterNetEvent('vehiclemods:server:getModifications')
AddEventHandler('vehiclemods:server:getModifications', function(vehicleModel)
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

-- Send all custom liveries to a client
RegisterNetEvent('vehiclemods:server:requestCustomLiveries')
AddEventHandler('vehiclemods:server:requestCustomLiveries', function()
    local src = source
    
    -- Load custom liveries from database and send to client
    ox_mysql:execute("SELECT vehicle_model, livery_name, livery_file FROM custom_liveries", {}, function(result)
        local customLiveries = {}
        
        if result and #result > 0 then
            for _, livery in ipairs(result) do
                if not customLiveries[livery.vehicle_model] then
                    customLiveries[livery.vehicle_model] = {}
                end
                
                table.insert(customLiveries[livery.vehicle_model], {
                    name = livery.livery_name,
                    file = livery.livery_file
                })
            end
            
            if Config.Debug then
                print("^2DEBUG:^0 Sending " .. #result .. " custom liveries to client " .. src)
            end
        end
        
        TriggerClientEvent('vehiclemods:client:updateCustomLiveries', src, customLiveries)
    end)
end)

-- Add a new livery
RegisterNetEvent('vehiclemods:server:addCustomLivery')
AddEventHandler('vehiclemods:server:addCustomLivery', function(vehicleModel, liveryName, liveryFile)
    local src = source
    
    -- Check if player has permission (admin or authorized job)
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
    
    -- Validate that the livery file path points to the liveries folder
    if not string.match(liveryFile, "^liveries/") then
        -- If file doesn't start with liveries/, prefix it
        liveryFile = "liveries/" .. liveryFile
    end
    
    -- Ensure the file has .yft extension
    if not string.match(liveryFile, "%.yft$") then
        liveryFile = liveryFile .. ".yft"
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

-- Remove a custom livery
RegisterNetEvent('vehiclemods:server:removeCustomLivery')
AddEventHandler('vehiclemods:server:removeCustomLivery', function(vehicleModel, liveryName)
    local src = source
    
    -- Check if player has permission
    local Player
    local hasPermission = false
    
    if Config.Framework == 'qb-core' or Config.Framework == 'qbc-core' then
        Player = QBCore.Functions.GetPlayer(src)
        hasPermission = Player.PlayerData.permission == "admin" or Player.PlayerData.permission == "god"
    elseif Config.Framework == 'esx' then
        Player = ESX.GetPlayerFromId(src)
        hasPermission = Player.getGroup() == "admin" or Player.getGroup() == "superadmin"
    elseif Config.Framework == 'standalone' then
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

-- Get available livery files
RegisterNetEvent('vehiclemods:server:getAvailableLiveries')
AddEventHandler('vehiclemods:server:getAvailableLiveries', function(vehicleModel)
    local src = source
    local liveryFiles = {}
    
    -- Simulated list for now - in production, this would scan files
    local simulatedFiles = {
        ["police"] = {
            "liveries/police_livery1.yft",
            "liveries/police_livery2.yft",
            "liveries/police_bcso.yft"
        },
        ["sheriff"] = {
            "liveries/sheriff_livery1.yft",
            "liveries/sheriff_livery2.yft"
        },
        ["ambulance"] = {
            "liveries/ambulance_livery1.yft",
            "liveries/ambulance_livery2.yft"
        }
    }
    
    -- Return the simulated files for the requested vehicle model
    if simulatedFiles[vehicleModel] then
        liveryFiles = simulatedFiles[vehicleModel]
    end
    
    TriggerClientEvent('vehiclemods:client:receiveAvailableLiveries', src, vehicleModel, liveryFiles)
end)

-- Create database tables during resource start
CreateThread(function()
    Wait(1000) -- Wait for oxmysql to initialize

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
    ]], {}, function(result)
        if result then
            print("^2INFO:^0 custom_liveries table created or already exists.")
        else
            print("^1ERROR:^0 Failed to create custom_liveries table.")
        end
    end)

    -- Create emergency_vehicle_mods table if it doesn't exist
    ox_mysql:execute([[
        CREATE TABLE IF NOT EXISTS emergency_vehicle_mods (
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
            print("^2INFO:^0 emergency_vehicle_mods table created or already exists.")
        else
            print("^1ERROR:^0 Failed to create emergency_vehicle_mods table.")
        end
    end)

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
