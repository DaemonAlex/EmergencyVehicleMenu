Config = require('config')

local QBCore, ESX

if Config.Framework == 'qb-core' or Config.Framework == 'qbc-core' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end

RegisterCommand('modveh', function()
    local job = ''
    if QBCore then
        job = QBCore.Functions.GetPlayerData().job.name
    elseif ESX then
        local playerData = ESX.GetPlayerData()
        job = playerData.job.name
    end

    if job == 'police' or job == 'ambulance' then
        TriggerEvent('vehiclemods:client:openVehicleModMenu')
    else
        if Config.Framework == 'qb-core' or Config.Framework == 'qbc-core' then
            TriggerEvent('ox_lib:notify', {title = 'Access Denied', description = 'You must be a first responder to use this.', type = 'error'})
        elseif ESX then
            ESX.ShowNotification('You must be a first responder to use this.')
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
    end
end)

RegisterNetEvent('vehiclemods:client:saveModifications', function(vehicleModel, skin, extras)
    if QBCore then
        local playerData = QBCore.Functions.GetPlayerData()
        TriggerServerEvent('vehiclemods:server:saveModifications', vehicleModel, skin, extras)
    elseif ESX then
        local playerData = ESX.GetPlayerData()
        TriggerServerEvent('vehiclemods:server:saveModifications', vehicleModel, skin, extras)
    elseif Config.Framework == 'standalone' then
    end
end)

RegisterNetEvent('vehiclemods:client:updateUI', function(modifications)
    if modifications then
    end
end)
