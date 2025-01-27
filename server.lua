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
