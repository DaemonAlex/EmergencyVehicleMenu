local QBCore = exports['qb-core']:GetCoreObject()

-- Event to verify the player's job
RegisterNetEvent('vehiclemods:server:verifyPoliceJob')
AddEventHandler('vehiclemods:server:verifyPoliceJob', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        if Player.PlayerData.job and Player.PlayerData.job.name == 'police' then
            TriggerClientEvent('vehiclemods:client:openVehicleModMenu', src)
            print("[PoliceVehicleMenu] Vehicle mod menu opened for player ID: " .. src)
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Error',
                description = 'You must be a police officer to use this command.',
                type = 'error',
                duration = 5000
            })
            print("[PoliceVehicleMenu] Player is not a police officer. Player ID: " .. src)
        end
    else
        print("[PoliceVehicleMenu] Player not found. Player ID: " .. src)
    end
end)

-- Event to save modifications to the database
RegisterNetEvent('vehiclemods:server:saveModifications')
AddEventHandler('vehiclemods:server:saveModifications', function(vehicleModel, performanceLevel, skin, extras)
    local query = 'INSERT INTO emergency_vehicle_mods (vehicle_model, performance_level, skin, extras) VALUES (?, ?, ?, ?)'
    local params = {vehicleModel, performanceLevel or 4, skin, extras}

    MySQL.Async.execute(query, params, function(rowsChanged)
        if rowsChanged > 0 then
            print("[PoliceVehicleMenu] Modifications saved for vehicle: " .. vehicleModel)
        else
            print("[PoliceVehicleMenu] Failed to save modifications for vehicle: " .. vehicleModel)
        end
    end)
end)

-- Event to retrieve modifications from the database
RegisterNetEvent('vehiclemods:server:getModifications')
AddEventHandler('vehiclemods:server:getModifications', function(vehicleModel)
    local src = source
    local query = 'SELECT * FROM emergency_vehicle_mods WHERE vehicle_model = ? ORDER BY created_at DESC LIMIT 1'
    local params = {vehicleModel}

    MySQL.Async.fetchAll(query, params, function(result)
        if result[1] then
            TriggerClientEvent('vehiclemods:client:applyModifications', src, result[1])
        else
            print("[PoliceVehicleMenu] No modifications found for vehicle: " .. vehicleModel)
        end
    end)
end)
