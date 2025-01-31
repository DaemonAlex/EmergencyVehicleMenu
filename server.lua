local QBCore = exports['qb-core']:GetCoreObject()
local ox_mysql = exports['oxmysql']

RegisterNetEvent('vehiclemods:server:verifyJob', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local job = Player.PlayerData.job.name
        if job == 'police' or job == 'ambulance' then
            TriggerClientEvent('vehiclemods:client:openVehicleModMenu', src)
        else
            TriggerClientEvent('ox_lib:notify', src, {title = 'Access Denied', description = 'You must be a first responder to use this.', type = 'error'})
        end
    end
end)

RegisterNetEvent('vehiclemods:server:saveModifications', function(vehicleModel, skin, extras)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        ox_mysql:execute("INSERT INTO emergency_vehicle_mods (vehicle_model, skin, extras) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE skin = VALUES(skin), extras = VALUES(extras)",
            {vehicleModel, skin, extras})
    end
end)

RegisterNetEvent('vehiclemods:server:getModifications', function(vehicleModel)
    local src = source
    ox_mysql:execute("SELECT skin, extras FROM emergency_vehicle_mods WHERE vehicle_model = ?", {vehicleModel}, function(result)
        if result and #result > 0 then
            TriggerClientEvent('vehiclemods:client:returnModifications', src, result[1])
        else
            TriggerClientEvent('vehiclemods:client:returnModifications', src, nil)
        end
    end)
end)
