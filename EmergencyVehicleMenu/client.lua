local QBCore = exports['qb-core']:GetCoreObject()

-- Command to open the emergency vehicle modification menu
RegisterCommand('modveh', function()
    local player = PlayerId()
    local ped = PlayerPedId()
    if IsPedSittingInAnyVehicle(ped) then
        QBCore.Functions.GetPlayerData(function(PlayerData)
            if PlayerData.job.name == "police" or PlayerData.job.name == "ems" then
                TriggerEvent('EmergencyVehicleMenu:client:openMenu')
            else
                lib.notify({
                    title = 'Access Denied',
                    description = 'You must be a police officer or EMS to use this menu.',
                    type = 'error',
                    duration = 5000
                })
            end
        end)
    else
        lib.notify({
            title = 'Error',
            description = 'You must be inside an emergency vehicle to use this command.',
            type = 'error',
            duration = 5000
        })
    end
end)

-- Main Menu
RegisterNetEvent('EmergencyVehicleMenu:client:openMenu')
AddEventHandler('EmergencyVehicleMenu:client:openMenu', function()
    local options = {
        {
            title = 'Liveries',
            description = 'Select a vehicle livery.',
            onSelect = function()
                OpenLiveryMenu()
            end
        },
        {
            title = 'Extras',
            description = 'Enable or disable vehicle extras.',
            onSelect = function()
                OpenExtrasMenu()
            end
        },
        {
            title = 'Doors',
            description = 'Open or close individual doors.',
            onSelect = function()
                OpenDoorsMenu()
            end
        }
    }

    lib.registerContext({
        id = 'EmergencyVehicleMenu',
        title = 'Emergency Vehicle Menu',
        options = options,
        close = false
    })
    lib.showContext('EmergencyVehicleMenu')
end)

-- Livery Menu
function OpenLiveryMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local options = {}
    local numLiveries = GetVehicleLiveryCount(vehicle)
    
    for i = 0, numLiveries - 1 do
        table.insert(options, {
            title = 'Livery ' .. i,
            onSelect = function()
                SetVehicleLivery(vehicle, i)
                lib.notify({
                    title = 'Livery Applied',
                    description = 'Applied Livery ' .. i .. '.',
                    type = 'success',
                    duration = 5000
                })
                OpenLiveryMenu()
            end
        })
    end

    lib.registerContext({
        id = 'LiveryMenu',
        title = 'Select Livery',
        options = options,
        menu = 'EmergencyVehicleMenu',
        close = false
    })
    lib.showContext('LiveryMenu')
end

-- Extras Menu
function OpenExtrasMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local options = {}
    
    for i = 1, 20 do
        if DoesExtraExist(vehicle, i) then
            table.insert(options, {
                title = 'Toggle Extra ' .. i,
                onSelect = function()
                    local state = IsVehicleExtraTurnedOn(vehicle, i)
                    SetVehicleExtra(vehicle, i, state and 1 or 0)
                    lib.notify({
                        title = 'Success',
                        description = 'Toggled Extra ' .. i .. '.',
                        type = 'success',
                        duration = 5000
                    })
                    OpenExtrasMenu()
                end
            })
        end
    end

    lib.registerContext({
        id = 'ExtrasMenu',
        title = 'Toggle Extras',
        options = options,
        menu = 'EmergencyVehicleMenu',
        close = false
    })
    lib.showContext('ExtrasMenu')
end

-- Doors Menu
function OpenDoorsMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local doors = {
        { title = 'Driver Door', index = 0 },
        { title = 'Passenger Door', index = 1 },
        { title = 'Rear Driver Door', index = 2 },
        { title = 'Rear Passenger Door', index = 3 },
        { title = 'Hood', index = 4 },
        { title = 'Trunk', index = 5 }
    }

    local options = {}
    for _, door in pairs(doors) do
        table.insert(options, {
            title = 'Toggle ' .. door.title,
            onSelect = function()
                if GetVehicleDoorAngleRatio(vehicle, door.index) > 0 then
                    SetVehicleDoorShut(vehicle, door.index, false)
                else
                    SetVehicleDoorOpen(vehicle, door.index, false, false)
                end
                OpenDoorsMenu()
            end
        })
    end

    lib.registerContext({
        id = 'DoorsMenu',
        title = 'Doors Control',
        options = options,
        menu = 'EmergencyVehicleMenu',
        close = false
    })
    lib.showContext('DoorsMenu')
end