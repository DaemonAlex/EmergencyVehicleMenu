local ox_lib = require('ox_lib')
local ox_mysql = require('ox_mysql')

-- Register NetEvent handlers for vehicle modifications
AddEventHandler('vehiclemods:server:verifyPoliceJob', function(source)
    -- Verify if the player is a police officer
    local playerId = GetPlayerIdentifierFromId(source)
    local player = Player(playerId)
    if player then
        local job = GetPlayerOccupation(player) -- Assuming 1 represents a police job
        if job == 1 then -- Assuming 1 represents a police job
            TriggerClientEvent('vehiclemods:client:openVehicleModMenu', source)
        else
            Print("[PoliceVehicleMenu] Player not found or invalid occupation.")
        end
    else
        Print("[PoliceVehicleMenu] Player not found.")
    end
end)

AddEventHandler('vehiclemods:server:saveModifications', function(source, vehicleModel, performanceLevel, skin, extras)
    -- Ensure source and parameters are valid
    local playerId = GetPlayerIdentifierFromId(source)
    if playerId and IsValidPlayerSource(playerId) then
        try
            local values = {string(vehicleModel), tonumber(performanceLevel or  string(skin), string(extras)}
            local success, result = ox_mysql.query({
                sql = "INSERT INTO `emergency_vehicle_mods` (`vehicle_model`, `performance_level`, `skin`, `extras`) VALUES (?, ?, ?, ?)",
                values = values
            })
            if not success then
                error(result)
            end
        catch
            local exception = Get(GetLastError())
            Print("[PoliceVehicleMenu] Error saving vehicle modifications: " .. tostring(exception))
        end
    else
        Print("[PoliceVehicleMenu] Invalid source ID.")
    end
end)

AddEventHandler('vehiclemods:server:getModifications', function(source, vehicleModel)
    -- Ensure valid source and parameters
    local playerId = GetPlayerIdentifierFromId(source)
    if playerId and IsValidPlayerSource(playerId) then
        try
            local result = {}
            local querySuccess, queryResult = ox_mysql.query({
                sql = "SELECT performance_level, skin, extras FROM emergency WHERE vehicle_model = ?",
                values = {vehicleModel}
            })
            if not querySuccess then
                error(queryResult)
            else
                for _, row in ipairs(queryResult) do
                    table.insert(result, {performanceLevel = tonumber(row['performance_level']), skin = tostring(row['skin']), extras = tostring(row['extras'])})
                end
            end
            TriggerClientEvent('vehiclemods:client:returnModifications', source, result)
        catch
            local exception = Get(GetLastError())
            Print("[PoliceVehicleMenu] Error fetching vehicle modifications: " .. tostring(exception))
        end
    else
        Print("[PoliceVehicleMenu] Invalid source ID.")
    end
end)
