QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('vehiclemods:server:verifyPoliceJob')
AddEventHandler('vehiclemods:server:verifyPoliceJob', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player and Player.PlayerData.job.name == 'police' then
        TriggerClientEvent('vehiclemods:client:openVehicleModMenu', src)
    else
        TriggerClientEvent('QBCore:Notify', src, 'This menu is only for Emergency vehicles.', 'error')
    end
end)
