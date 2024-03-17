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
...

