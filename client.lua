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

-- Main menu
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
            description = 'Open or close doors and trunk.',
            onSelect = function()
                OpenDoorsMenu()
            end
        },
        {
            title = 'Engine Upgrades',
            description = 'Upgrade your vehicle\'s engine performance.',
            onSelect = function()
                UpgradeEngine()
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

-- Livery menu
function OpenLiveryMenu()
    local options = {}

    for i = 0, 3 do -- 4 livery options
        table.insert(options, {
            title = 'Livery ' .. i,
            onSelect = function()
                ApplyLivery(i)
            end
        })
    end

    lib.registerContext({
        id = 'liveryMenu',
        title = 'Select Livery',
        options = options,
        menu = 'vehicleModMenu'
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

    for i = 1, 15 do -- 15 extras
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
        menu = 'vehicleModMenu'
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

-- Doors menu
function OpenDoorsMenu()
    local options = {
        { title = 'Open All Doors', onSelect = function() SetDoorsState('open') end },
        { title = 'Close All Doors', onSelect = function() SetDoorsState('close') end },
        { title = 'Open Trunk', onSelect = function() SetDoorState(5, 'open') end },
        { title = 'Close Trunk', onSelect = function() SetDoorState(5, 'close') end }
    }

    lib.registerContext({
        id = 'doorsMenu',
        title = 'Doors Control',
        options = options,
        menu = 'vehicleModMenu'
    })

    lib.showContext('doorsMenu')
end

function SetDoorsState(state)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    for i = 0, 5 do
        if state == 'open' then
            SetVehicleDoorOpen(vehicle, i, false, false)
        else
            SetVehicleDoorShut(vehicle, i, false)
        end
    end
    lib.notify({
        title = 'Success',
        description = 'Doors are now ' .. state .. '.',
        type = 'success',
        duration = 5000
    })
end

function SetDoorState(door, state)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if state == 'open' then
        SetVehicleDoorOpen(vehicle, door, false, false)
    else
        SetVehicleDoorShut(vehicle, door, false)
    end
    lib.notify({
        title = 'Success',
        description = 'Door ' .. (door == 5 and 'Trunk' or door) .. ' is now ' .. state .. '.',
        type = 'success',
        duration = 5000
    })
end

-- Engine upgrades (without changing tires)
function UpgradeEngine()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    SetVehicleModKit(vehicle, 0)
    for i = 0, 49 do
        if i ~= 23 and i ~= 24 then -- Skip tires (wheels)
            SetVehicleMod(vehicle, i, GetNumVehicleMods(vehicle, i) - 1, false)
        end
    end
    lib.notify({
        title = 'Success',
        description = 'Engine upgraded successfully!',
        type = 'success',
        duration = 5000
    })
end
