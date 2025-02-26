Config = require('config')

local QBCore, ESX

if Config.Framework == 'qb-core' or Config.Framework == 'qbc-core' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end

RegisterCommand('modveh', function()
    local job = ''
    if Config.Framework == 'qb-core' or Config.Framework == 'qbc-core' then
        job = QBCore.Functions.GetPlayerData().job.name
    elseif Config.Framework == 'esx' then
        local playerData = ESX.GetPlayerData()
        job = playerData.job.name
    elseif Config.Framework == 'standalone' then
        -- Handle standalone job retrieval logic
        job = 'standalone'  -- Example, replace with actual logic
    end

    if Config.JobAccess[job] then
        TriggerEvent('vehiclemods:client:openVehicleModMenu')
    else
        if Config.Framework == 'qb-core' or Config.Framework == 'qbc-core' then
            TriggerEvent('ox_lib:notify', {title = 'Access Denied', description = 'You must be a first responder to use this.', type = 'error'})
        elseif Config.Framework == 'esx' then
            ESX.ShowNotification('You must be a first responder to use this.')
        elseif Config.Framework == 'standalone' then
            -- Handle standalone notification logic
            print('You must be a first responder to use this.')  -- Example, replace with actual logic
        end
    end
end, false)

RegisterNetEvent('vehiclemods:client:openVehicleModMenu', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'open_vehicle_mod_menu'
    })
end)

RegisterNetEvent('vehiclemods:client:returnModifications', function(modifications)
    if modifications then
        local skin = modifications.skin
        local extras = modifications.extras
    else
        -- Handle case where no modifications are found
    end
end)

RegisterNetEvent('vehiclemods:client:saveModifications', function(vehicleModel, skin, extras)
    if Config.Framework == 'qb-core' or Config.Framework == 'qbc-core' then
        TriggerServerEvent('vehiclemods:server:saveModifications', vehicleModel, skin, extras)
    elseif Config.Framework == 'esx' then
        TriggerServerEvent('vehiclemods:server:saveModifications', vehicleModel, skin, extras)
    elseif Config.Framework == 'standalone' then
        -- Handle standalone logic if needed
        TriggerServerEvent('vehiclemods:server:saveModifications', vehicleModel, skin, extras)
    end
end)

RegisterNetEvent('vehiclemods:client:updateUI', function(modifications)
    if modifications then
        -- Update UI with modifications
    end
end)
