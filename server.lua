QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('vehiclemods:server:verifyPoliceJob')
AddEventHandler('vehiclemods:server:verifyPoliceJob', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        if Player.PlayerData.job and Player.PlayerData.job.name == 'police' then
            TriggerClientEvent('vehiclemods:client:openVehicleModMenu', src)
            print("Vehicle mod menu opened for player ID: " .. src)
        else
            TriggerClientEvent('QBCore:Notify', src, 'This menu is only for Emergency vehicles.', 'error')
            print("Unauthorized vehicle mod menu access attempt by player ID: " .. src)
        end
    else
        print("Failed to retrieve player object for source ID: " .. src)
    end
end)

