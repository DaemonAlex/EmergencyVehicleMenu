local QBCore = exports['qb-core']:GetCoreObject()

RegisterCommand('modvehicle', function()
    local ped = PlayerPedId()
    if IsPedSittingInAnyVehicle(ped) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        if GetVehicleClass(vehicle) == 18 then
            TriggerServerEvent('vehiclemods:server:verifyPoliceJob')
        else
            if exports['ox_lib'] then
                exports['ox_lib']:textUI('This menu is only for Emergency vehicles.', { duration = 5000, position = 'top-center', type = 'error' })
            else
                print("ox_lib is not available.")
            end
        end
    else
        if exports['ox_lib'] then
            exports['ox_lib']:textUI('You must be in a vehicle to use this command.', { duration = 5000, position = 'top-center', type = 'error' })
        else
            print("ox_lib is not available.")
        end
    end
end, false)
