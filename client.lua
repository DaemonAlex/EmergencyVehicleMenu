local QBCore = exports['qb-core']:GetCoreObject()

-- Debug: Check if ox_lib is loaded
print("Checking if ox_lib is loaded...")
if not lib then
    print("^1[ERROR] ox_lib is not loaded. Attempting to initialize it manually...^7")
    lib = exports.ox_lib:init()
    if not lib then
        print("^1[ERROR] Failed to initialize ox_lib. Please ensure ox_lib is installed and started before PoliceVehicleMenu.^7")
        return
    else
        print("^2[SUCCESS] ox_lib initialized manually.^7")
    end
else
    print("^2[SUCCESS] ox_lib is loaded and ready to use.^7")
end

-- Command to open the vehicle modification menu
RegisterCommand('modvehicle', function()
    local ped = PlayerPedId()
    if IsPedSittingInAnyVehicle(ped) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        local vehicleModel = GetEntityModel(vehicle)
        local vehicleName = GetDisplayNameFromVehicleModel(vehicleModel):lower()

        -- Check if the vehicle is in the Config.PoliceVehicles list
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

-- Function to check if the vehicle is in the Config.PoliceVehicles list
function IsVehicleInConfig(vehicleName)
    for _, v in pairs(Config.PoliceVehicles) do
        if v == vehicleName then
            return true
        end
    end
    return false
end

-- Event to open the vehicle modification menu
RegisterNetEvent('vehiclemods:client:openVehicleModMenu')
AddEventHandler('vehiclemods:client:openVehicleModMenu', function()
    OpenVehicleModMenu()
end)

-- Function to open the modification menu using ox_lib
function OpenVehicleModMenu()
    local options = {
        {
            title = 'Performance Upgrades',
            description = 'Select performance modifications.',
            onSelect = function()
                OpenPerformanceMenu()
            end
        },
        {
            title = 'Change Skin',
            description = 'Select vehicle skin.',
            onSelect = function()
                OpenSkinMenu()
            end
        },
        {
            title = 'Toggle Extras',
            description = 'Select vehicle extras.',
            onSelect = function()
                OpenExtrasMenu()
            end
        }
    }

    lib.registerContext({
        id = 'vehicleModMenu',
        title = 'Vehicle Modification Menu',
        options = options
    })

    lib.showContext('vehicleModMenu')
end

-- Submenu for performance upgrades
function OpenPerformanceMenu()
    local options = {}

    for i = 0, 4 do
        table.insert(options, {
            title = 'Performance Level ' .. i,
            onSelect = function()
                UpgradePerformance(i)
            end
        })
    end

    lib.registerContext({
        id = 'performanceMenu',
        title = 'Performance Upgrades',
        options = options,
        menu = 'vehicleModMenu' -- Go back to the main menu
    })

    lib.showContext('performanceMenu')
end

function UpgradePerformance(level)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    SetVehicleModKit(vehicle, 0)
    for i = 0, 49 do
        SetVehicleMod(vehicle, i, level, false)
    end
    lib.notify({
        title = 'Success',
        description = 'Vehicle performance upgraded to level ' .. level .. '.',
        type = 'success',
        duration = 5000
    })

    -- Save modifications to the database
    local vehicleModel = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)):lower()
    TriggerServerEvent('vehiclemods:server:saveModifications', vehicleModel, level, nil, nil)
end

-- Submenu for skin changes
function OpenSkinMenu()
    local options = {}

    for i = Config.SkinsRange.min, Config.SkinsRange.max do
        table.insert(options, {
            title = 'Skin ' .. i,
            onSelect = function()
                ChangeSkin(i)
            end
        })
    end

    lib.registerContext({
        id = 'skinMenu',
        title = 'Change Skin',
        options = options,
        menu = 'vehicleModMenu' -- Go back to the main menu
    })

    lib.showContext('skinMenu')
end

function ChangeSkin(skin)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    SetVehicleLivery(vehicle, skin)
    lib.notify({
        title = 'Success',
        description = 'Vehicle skin changed to ' .. skin .. '.',
        type = 'success',
        duration = 5000
    })

    -- Save modifications to the database
    local vehicleModel = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)):lower()
    TriggerServerEvent('vehiclemods:server:saveModifications', vehicleModel, nil, skin, nil)
end

-- Submenu for toggling extras
function OpenExtrasMenu()
    local options = {}

    for i = Config.ExtrasRange.min, Config.ExtrasRange.max do
        table.insert(options, {
            title = 'Toggle Extra ' .. i,
            onSelect = function()
                ToggleExtra(i)
            end
        })
    end

    lib.registerContext({
        id = 'extrasMenu',
        title = 'Toggle Extras',
        options = options,
        menu = 'vehicleModMenu' -- Go back to the main menu
    })

    lib.showContext('extrasMenu')
end

function ToggleExtra(extra)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local state = IsVehicleExtraTurnedOn(vehicle, extra)
    SetVehicleExtra(vehicle, extra, state and 1 or 0)
    lib.notify({
        title = 'Success',
        description = 'Extra ' .. extra .. ' toggled.',
        type = 'success',
        duration = 5000
    })

    -- Save modifications to the database
    local vehicleModel = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)):lower()
    TriggerServerEvent('vehiclemods:server:saveModifications', vehicleModel, nil, nil, tostring(extra))
end
