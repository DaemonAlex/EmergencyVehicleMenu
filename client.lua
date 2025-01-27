local QBCore = exports['qb-core']:GetCoreObject()

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
            exports.ox_lib:notify({
                title = 'Error',
                description = 'This menu is only for approved police vehicles.',
                type = 'error',
                duration = 5000
            })
        end
    else
        exports.ox_lib:notify({
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
            description = 'Upgrade your vehicle\'s performance.',
            event = 'vehiclemods:client:upgradePerformance',
            args = {}
        },
        {
            title = 'Change Skin',
            description = 'Change your vehicle\'s appearance.',
            event = 'vehiclemods:client:changeSkin',
            args = {}
        },
        {
            title = 'Toggle Extras',
            description = 'Enable or disable vehicle extras.',
            event = 'vehiclemods:client:toggleExtras',
            args = {}
        }
    }

    exports.ox_lib:showContext('vehicleModMenu', {
        id = 'vehicleModMenu',
        title = 'Vehicle Modification Menu',
        options = options
    })
end

RegisterNetEvent('vehiclemods:client:upgradePerformance')
AddEventHandler('vehiclemods:client:upgradePerformance', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    SetVehicleModKit(vehicle, 0)
    for i = 0, 49 do
        SetVehicleMod(vehicle, i, GetNumVehicleMods(vehicle, i) - 1, false)
    end
    exports.ox_lib:notify({
        title = 'Success',
        description = 'Vehicle performance upgraded to level 4.',
        type = 'success',
        duration = 5000
    })
end)
