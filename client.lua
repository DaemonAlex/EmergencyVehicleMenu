local QBCore = exports['qb-core']:GetCoreObject()

RegisterCommand('modvehicle', function()
    local ped = PlayerPedId()
    if IsPedSittingInAnyVehicle(ped) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        if GetVehicleClass(vehicle) == 18 then
            TriggerServerEvent('vehiclemods:server:verifyPoliceJob')
        else
            exports['ox_lib']:textUI('This menu is only for Emergency vehicles.', { duration = 5000, position = 'top-center', type = 'error' })
        end
    else
        exports['ox_lib']:textUI('You must be in a vehicle to use this command.', { duration = 5000, position = 'top-center', type = 'error' })
    end
end, false)

RegisterNetEvent('vehiclemods:client:openVehicleModMenu')
AddEventHandler('vehiclemods:client:openVehicleModMenu', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    openVehicleModMenu(vehicle)
end)

function openVehicleModMenu(vehicle)
    -- Apply performance mods to level 4 automatically
    local performanceMods = {11, 12, 13, 15, 16} -- Mod types for performance
    for _, modType in ipairs(performanceMods) do
        SetVehicleMod(vehicle, modType, 3, false) -- Mods are 0-indexed
    end
    exports['ox_lib']:textUI('All performance mods upgraded to level 4.', { duration = 5000, position = 'top-center', type = 'success' })

    -- Further implementation for opening the OX Menu for skins and extras
end

-- Placeholder for `openSkinSubMenu` and `openExtrasSubMenu` functions

