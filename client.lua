RegisterCommand(Config.Command, function()
    -- In standalone mode, we don't need to check for job permissions
    -- This will directly open the menu for any player
    print("^2SUCCESS:^0 Opening vehicle modification menu...")
    OpenVehicleModMenu()
end, false)

-- Main menu function
function OpenVehicleModMenu()
    -- Check if player is in a vehicle
    local playerPed = PlayerPedId()
    if not IsPedInAnyVehicle(playerPed, false) then
        lib.notify({
            title = 'Error',
            description = 'You must be in a vehicle to use this menu.',
            type = 'error',
            duration = 5000
        })
        return
    end

    local options = {
        {
            title = 'Liveries',
            description = 'Select a vehicle livery.',
            icon = 'paint-roller',
            onSelect = function()
                OpenLiveryMenu()
            end
        },
        {
            title = 'Extras',
            description = 'Enable or disable vehicle extras.',
            icon = 'puzzle-piece',
            onSelect = function()
                OpenExtrasMenu()
            end
        },
        {
            title = 'Doors',
            description = 'Open or close individual doors.',
            icon = 'door-open',
            onSelect = function()
                OpenDoorsMenu()
            end
        },
        {
            title = 'Save Configuration',
            description = 'Save the current vehicle configuration.',
            icon = 'save',
            onSelect = function()
                SaveVehicleConfiguration()
            end
        }
    }

    lib.registerContext({
        id = 'VehicleModMenu',
        title = 'Vehicle Modification Menu',
        options = options,
        close = true
    })
    lib.showContext('VehicleModMenu')
end

-- Livery menu function
function OpenLiveryMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local options = {}
    local numLiveries = GetVehicleLiveryCount(vehicle)
    
    if numLiveries <= 0 then
        lib.notify({
            title = 'No Liveries',
            description = 'This vehicle has no liveries available.',
            type = 'inform',
            duration = 5000
        })
        return OpenVehicleModMenu()
    end
    
    -- Add "Default" option at the top
    table.insert(options, {
        title = 'Default Livery',
        icon = 'ban',
        onSelect = function()
            SetVehicleLivery(vehicle, 0)
            lib.notify({
                title = 'Livery Applied',
                description = 'Applied Default Livery.',
                type = 'success',
                duration = 3000
            })
        end
    })
    
    for i = 0, numLiveries - 1 do
        table.insert(options, {
            title = 'Livery ' .. i,
            icon = 'palette',
            onSelect = function()
                SetVehicleLivery(vehicle, i)
                lib.notify({
                    title = 'Livery Applied',
                    description = 'Applied Livery ' .. i .. '.',
                    type = 'success',
                    duration = 3000
                })
            end
        })
    end

    lib.registerContext({
        id = 'LiveryMenu',
        title = 'Select Vehicle Livery',
        options = options,
        menu = 'VehicleModMenu',
        close = true
    })
    lib.showContext('LiveryMenu')
end

-- Extras menu function
function OpenExtrasMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local options = {}
    local hasExtras = false
    
    for i = 0, 20 do
        if DoesExtraExist(vehicle, i) then
            hasExtras = true
            local state = IsVehicleExtraTurnedOn(vehicle, i)
            table.insert(options, {
                title = 'Extra ' .. i,
                icon = state and 'toggle-on' or 'toggle-off',
                description = state and 'Currently: Enabled' or 'Currently: Disabled',
                onSelect = function()
                    local newState = not IsVehicleExtraTurnedOn(vehicle, i)
                    SetVehicleExtra(vehicle, i, not newState)
                    lib.notify({
                        title = 'Extra Toggled',
                        description = (newState and 'Enabled' or 'Disabled') .. ' Extra ' .. i .. '.',
                        type = 'success',
                        duration = 3000
                    })
                    OpenExtrasMenu() -- Refresh the menu to update toggle states
                end
            })
        end
    end
    
    if not hasExtras then
        lib.notify({
            title = 'No Extras',
            description = 'This vehicle has no extras available.',
            type = 'inform',
            duration = 5000
        })
        return OpenVehicleModMenu()
    end
    
    lib.registerContext({
        id = 'ExtrasMenu',
        title = 'Vehicle Extras',
        options = options,
        menu = 'VehicleModMenu',
        close = true
    })
    lib.showContext('ExtrasMenu')
end

-- Doors control menu
function OpenDoorsMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local doors = {
        { title = 'Driver Door', index = 0, icon = 'door-open' },
        { title = 'Passenger Door', index = 1, icon = 'door-open' },
        { title = 'Rear Left Door', index = 2, icon = 'door-open' },
        { title = 'Rear Right Door', index = 3, icon = 'door-open' },
        { title = 'Hood', index = 4, icon = 'car' },
        { title = 'Trunk', index = 5, icon = 'box' }
    }

    local options = {}
    for _, door in pairs(doors) do
        local isOpen = GetVehicleDoorAngleRatio(vehicle, door.index) > 0
        table.insert(options, {
            title = door.title,
            icon = door.icon,
            description = isOpen and 'Currently: Open' or 'Currently: Closed',
            onSelect = function()
                if isOpen then
                    SetVehicleDoorShut(vehicle, door.index, false)
                    lib.notify({
                        title = 'Door Control',
                        description = 'Closed ' .. door.title .. '.',
                        type = 'success',
                        duration = 3000
                    })
                else
                    SetVehicleDoorOpen(vehicle, door.index, false, false)
                    lib.notify({
                        title = 'Door Control',
                        description = 'Opened ' .. door.title .. '.',
                        type = 'success',
                        duration = 3000
                    })
                end
                OpenDoorsMenu() -- Refresh the menu to update door states
            end
        })
    end
    
    -- Add "All Doors" options
    table.insert(options, {
        title = 'Open All Doors',
        icon = 'door-open',
        description = 'Open all doors at once.',
        onSelect = function()
            for i = 0, 5 do
                SetVehicleDoorOpen(vehicle, i, false, false)
            end
            lib.notify({
                title = 'Door Control',
                description = 'All doors opened.',
                type = 'success',
                duration = 3000
            })
            OpenDoorsMenu()
        end
    })
    
    table.insert(options, {
        title = 'Close All Doors',
        icon = 'door-closed',
        description = 'Close all doors at once.',
        onSelect = function()
            for i = 0, 5 do
                SetVehicleDoorShut(vehicle, i, false)
            end
            lib.notify({
                title = 'Door Control',
                description = 'All doors closed.',
                type = 'success',
                duration = 3000
            })
            OpenDoorsMenu()
        end
    })

    lib.registerContext({
        id = 'DoorsMenu',
        title = 'Door Controls',
        options = options,
        menu = 'VehicleModMenu',
        close = true
    })
    lib.showContext('DoorsMenu')
end

-- Function to save vehicle configuration
function SaveVehicleConfiguration()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if not vehicle or vehicle == 0 then
        lib.notify({
            title = 'Error',
            description = 'You must be in a vehicle to save configuration.',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    local vehicleModel = GetEntityModel(vehicle)
    local livery = GetVehicleLivery(vehicle)
    
    -- Collect extras configuration
    local extras = {}
    for i = 0, 20 do
        if DoesExtraExist(vehicle, i) then
            extras[i] = IsVehicleExtraTurnedOn(vehicle, i)
        end
    end
    
    -- Convert extras to JSON string
    local extrasJson = json.encode(extras)
    
    -- Request server to save configuration
    TriggerServerEvent('vehiclemods:server:saveModifications', vehicleModel, livery, extrasJson)
    
    lib.notify({
        title = 'Configuration Saved',
        description = 'Your vehicle configuration has been saved.',
        type = 'success',
        duration = 5000
    })
end

-- Event to apply saved modifications
RegisterNetEvent('vehiclemods:client:returnModifications')
AddEventHandler('vehiclemods:client:returnModifications', function(data)
    if not data then return end
    
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if not vehicle or vehicle == 0 then return end
    
    -- Apply saved livery if available
    if data.skin then
        SetVehicleLivery(vehicle, tonumber(data.skin))
    end
    
    -- Apply saved extras if available
    if data.extras then
        local extras = json.decode(data.extras)
        for extraId, enabled in pairs(extras) do
            SetVehicleExtra(vehicle, tonumber(extraId), not enabled)
        end
    end
    
    lib.notify({
        title = 'Configuration Applied',
        description = 'Your saved vehicle configuration has been applied.',
        type = 'success',
        duration = 5000
    })
end)

-- Load saved configuration when entering a vehicle
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkPlayerEnteredVehicle' then
        local playerServerId = args[1]
        local vehicle = args[2]
        
        -- Check if it's the local player
        if GetPlayerServerId(PlayerId()) == playerServerId then
            -- Wait a moment for the vehicle to fully load
            Wait(500)
            
            -- Request saved modifications for this vehicle model
            local vehicleModel = GetEntityModel(vehicle)
            TriggerServerEvent('vehiclemods:server:getModifications', vehicleModel)
        end
    end
end)
