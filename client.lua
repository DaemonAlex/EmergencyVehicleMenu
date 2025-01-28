local QBCore = exports['qb-core']:GetCoreObject()

-- Command to open the vehicle modification menu
RegisterCommand('modvehicle', function()
    local ped = PlayerPedId()
    if IsPedSittingInAnyVehicle(ped) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        local vehicleModel = GetEntityModel(vehicle)
        local vehicleName = GetDisplayNameFromVehicleModel(vehicleModel):lower()

        if IsVehicleInConfig(vehicleName) then
            TriggerServerEvent('vehiclemods:server:verifyPoliceJob')
        else
            lib.notify({
                title = 'Error',
                description = 'This menu is only for approved police vehicles.',
                type = 'error',
                duration = 5000
            })
        end
    else
        lib.notify({
            title = 'Error',
            description = 'You must be inside a vehicle to use this command.',
            type = 'error',
            duration = 5000
        })
    end
end)

function IsVehicleInConfig(vehicleName)
    for _, v in pairs(Config.PoliceVehicles) do
        if v == vehicleName then
            return true
        end
    end
    return false
end

RegisterNetEvent('vehiclemods:client:openVehicleModMenu')
AddEventHandler('vehiclemods:client:openVehicleModMenu', function()
    OpenVehicleModMenu()
end)

function OpenVehicleModMenu()
    local options = {
        {
            title = 'Livery',
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
                OpenDoorsSubmenu()
            end
        },
        {
            title = 'Engine Upgrades',
            description = 'Upgrade individual engine components.',
            onSelect = function()
                OpenEngineSubmenu()
            end
        }
    }

    lib.registerContext({
        id = 'vehicleModMenu',
        title = 'Vehicle Modification Menu',
        options = options,
        close = false -- Keep the menu open
    })

    lib.showContext('vehicleModMenu')
end

-- Livery menu
function OpenLiveryMenu()
    local options = {}

    for i = 0, 3 do
        table.insert(options, {
            title = 'Livery ' .. i,
            onSelect = function()
                ApplyLivery(i)
                OpenLiveryMenu()
            end
        })
    end

    lib.registerContext({
        id = 'liveryMenu',
        title = 'Select Livery',
        options = options,
        menu = 'vehicleModMenu',
        close = false
    })

    lib.showContext('liveryMenu')
end

function ApplyLivery(livery)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    SetVehicleLivery(vehicle, livery)
    lib.notify({
        title = 'Success',
        description = 'Applied Livery ' .. livery .. '.',
        type = 'success',
        duration = 5000
    })
end

-- Extras menu
function OpenExtrasMenu()
    local options = {}

    for i = 1, 15 do
        table.insert(options, {
            title = 'Toggle Extra ' .. i,
            onSelect = function()
                ToggleExtra(i)
                OpenExtrasMenu()
            end
        })
    end

    lib.registerContext({
        id = 'extrasMenu',
        title = 'Toggle Extras',
        options = options,
        menu = 'vehicleModMenu',
        close = false
    })

    lib.showContext('extrasMenu')
end

function ToggleExtra(extra)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local state = IsVehicleExtraTurnedOn(vehicle, extra)
    SetVehicleExtra(vehicle, extra, state and 1 or 0)
    lib.notify({
        title = 'Success',
        description = 'Toggled Extra ' .. extra .. '.',
        type = 'success',
        duration = 5000
    })
end

-- Doors submenu
function OpenDoorsSubmenu()
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
                ToggleDoor(door.index)
                OpenDoorsSubmenu()
            end
        })
    end

    lib.registerContext({
        id = 'doorsMenu',
        title = 'Doors Control',
        options = options,
        menu = 'vehicleModMenu',
        close = false
    })

    lib.showContext('doorsMenu')
end

function ToggleDoor(door)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if GetVehicleDoorAngleRatio(vehicle, door) > 0 then
        SetVehicleDoorShut(vehicle, door, false)
        lib.notify({
            title = 'Success',
            description = 'Closed ' .. (door == 5 and 'Trunk' or 'Door ' .. door) .. '.',
            type = 'success',
            duration = 5000
        })
    else
        SetVehicleDoorOpen(vehicle, door, false, false)
        lib.notify({
            title = 'Success',
            description = 'Opened ' .. (door == 5 and 'Trunk' or 'Door ' .. door) .. '.',
            type = 'success',
            duration = 5000
        })
    end
end

-- Engine submenu with submenus for individual components
function OpenEngineSubmenu()
    local options = {
        {
            title = 'Engine Levels',
            description = 'Upgrade engine levels 1-4.',
            onSelect = function()
                OpenComponentSubmenu(11, 'Engine Level')
            end
        },
        {
            title = 'Brakes Levels',
            description = 'Upgrade brakes levels 1-4.',
            onSelect = function()
                OpenComponentSubmenu(12, 'Brakes Level')
            end
        },
        {
            title = 'Transmission Levels',
            description = 'Upgrade transmission levels 1-4.',
            onSelect = function()
                OpenComponentSubmenu(13, 'Transmission Level')
            end
        },
        {
            title = 'Suspension Levels',
            description = 'Upgrade suspension levels 1-4.',
            onSelect = function()
                OpenComponentSubmenu(15, 'Suspension Level')
            end
        },
        {
            title = 'Turbo',
            description = 'Enable or disable turbo.',
            onSelect = function()
                ToggleTurbo()
            end
        }
    }

    lib.registerContext({
        id = 'engineMenu',
        title = 'Engine Upgrades',
        options = options,
        menu = 'vehicleModMenu',
        close = false
    })

    lib.showContext('engineMenu')
end

-- Submenu for upgrading specific component levels (1-4)
function OpenComponentSubmenu(modType, componentName)
    local options = {}

    for level = 1, 4 do
        table.insert(options, {
            title = componentName .. ' ' .. level,
            onSelect = function()
                ApplyComponentUpgrade(modType, level - 1) -- Levels start from 0 internally
                OpenComponentSubmenu(modType, componentName)
            end
        })
    end

    lib.registerContext({
        id = 'componentSubmenu_' .. modType,
        title = componentName .. ' Levels',
        options = options,
        menu = 'engineMenu',
        close = false
    })

    lib.showContext('componentSubmenu_' .. modType)
end

-- Function to apply the component upgrade
function ApplyComponentUpgrade(modType, level)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    SetVehicleModKit(vehicle, 0)
    SetVehicleMod(vehicle, modType, level, false)

    lib.notify({
        title = 'Success',
        description = 'Upgraded to ' .. level + 1 .. '.',
        type = 'success',
        duration = 5000
    })
end

-- Turbo toggle
function ToggleTurbo()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local turboEnabled = IsToggleModOn(vehicle, 18)

    ToggleVehicleMod(vehicle, 18, not turboEnabled)

    lib.notify({
        title = 'Turbo',
        description = turboEnabled and 'Turbo disabled.' or 'Turbo enabled!',
        type = turboEnabled and 'error' or 'success',
        duration = 5000
    })
end
