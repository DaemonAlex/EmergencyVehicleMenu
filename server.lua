local ox_lib = require('ox_lib')
local ox_mysql = require('ox_mysql')

-- Register NetEvent handlers for vehicle modifications
AddEventHandler('vehiclemods:server:verifyPoliceJob', function(source)
    -- Verify if the player is a police officer
    local player = GetPlayer(src)
    if player and GetPlayerOccupation(player) ==  -- Assuming 1 represents a police job
        TriggerClientEvent(source, 'vehiclemods:client:openVehicleModMenu')
    else
        Print("[PoliceVehicleMenu] Player not found or invalid occupation.")
        return
    end
end)

AddEventHandler('vehiclemods:server:saveModifications', function(source, vehicleModel, performanceLevel, skin, extras)
    -- Ensure source and parameters are valid
    if not source or not IsValidPlayerSource(source) then
        Print("[PoliceVehicleMenu] Invalid source ID:", source)
        return false
    end

    try
        local success, result = ox_mysql.query({
            sql = "INSERT INTO `emergency_vehicle_mods` (`vehicle_model`, `performance_level`, `skin`, `extras`) VALUES (?, ?,)",
            values = {
                string: vehicleModel,
                int: performanceLevel or 4, -- Default to 4 if not provided
                string: skin,
                string: extras
            }
        })
        if not success and result then
            Print("[PoliceVehicleMenu] Error saving vehicle modifications:", result)
            return false
        end

        Print("[PoliceVehicleMenu] Successfully saved vehicle data for", vehicleModel, "with performance level", performanceLevel or 4, "and skin", skin)
        return true
    catch
        local exception = GetExceptionInformation(GetLastError())
        Print("[PoliceVehicleMenu] Error during database operation:", exception)
        return false
    end
end)

AddEventHandler('vehiclemods:server:getModifications', function(source, vehicleModel)
    -- Ensure source is valid
    if not IsValidPlayerSource(source) then
        Print("[PoliceVehicleMenu] Invalid source ID:", source)
        return nil
    end

    try
        local result = ox_mysql.query({
            sql = "SELECT * FROM `emergency_vehicle_mods` WHERE `vehicle_model` = (?) ORDER BY `timestamp` DESC LIMIT 1",
            values = {
                string: vehicleModel
            }
        })

        if not result then
            Print("[PoliceVehicleMenu] No modification found for", vehicleModel)
            return nil
        end

        -- Extract relevant data from the result set
        local data = {}
        data.timestamp = result[0]['timestamp']
        data.performance_level = result[0]['performance_level'] or 4
        data.skin = result[0]['skin']
        data.extras = result[0]['extras']

        Print("[PoliceVehicleMenu] Retrieved vehicle modification for", vehicleModel, "with performance level", data.performance_level)
        return data

    catch
        local exception = GetExceptionInformation(GetLastError())
        Print("[PoliceVehicleMenu] Error during database query:", exception)
        return nil
    end
end)

-- Ensure event handlers are properly registered and cleaned up
AddEventHandler('onPlayerDisconnect', function(playerID)
    -- Cleanup resources if the player disconnects while using the menu
    if IsEventValid then
        CancelEvent("vehicleclient:openVehicleModMenu")
        -- Any other cleanup operations can be added here
    end
end)
