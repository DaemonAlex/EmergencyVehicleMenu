if not Config then
    print("^1ERROR:^0 Config is not loaded! Check fxmanifest.lua.")
    return
end

local nearModificationZone = false
local lastZoneCheck = 0
local ZONE_CHECK_INTERVAL = 1000 -- Check every second instead of every frame
local TEXTURE_LOAD_TIMEOUT = 300 -- Increased from 100 (3 seconds instead of 1)
local loadedTextures = {} -- Track loaded textures for cleanup

-- Replace the existing custom livery event handler (around line 275) with this improved version:
RegisterNetEvent('vehiclemods:client:setCustomLivery')
AddEventHandler('vehiclemods:client:setCustomLivery', function(netId, vehicleModelName, liveryFile)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    
    if not vehicle or not DoesEntityExist(vehicle) then
        if Config.Debug then
            print("^1ERROR:^0 Vehicle not found for custom livery application")
        end
        return
    end
    
    -- Validate inputs
    if not vehicleModelName or not liveryFile then
        print("^1ERROR:^0 Invalid parameters for custom livery")
        return
    end
    
    -- Extract base name without "liveries/" prefix
    local baseName = string.match(liveryFile, "([^/]+)%.yft$")
    if not baseName then
        baseName = liveryFile:gsub(".yft", "")
    end
    
    local textureDict = vehicleModelName .. "_" .. baseName
    
    -- Check if already loaded
    if not HasStreamedTextureDictLoaded(textureDict) then
        RequestStreamedTextureDict(textureDict)
        local timeout = 0
        while not HasStreamedTextureDictLoaded(textureDict) and timeout < TEXTURE_LOAD_TIMEOUT do
            Wait(10)
            timeout = timeout + 1
        end
        
        if not HasStreamedTextureDictLoaded(textureDict) then
            print("^1ERROR:^0 Failed to load texture dictionary: " .. textureDict .. " (timeout)")
            return
        end
    end
    
    if HasStreamedTextureDictLoaded(textureDict) then
        local vehicleEntityId = VehToNet(vehicle)
        if not ActiveCustomLiveries then ActiveCustomLiveries = {} end
        
        -- Clean up old texture if exists
        if ActiveCustomLiveries[vehicleEntityId] and ActiveCustomLiveries[vehicleEntityId].dict then
            local oldDict = ActiveCustomLiveries[vehicleEntityId].dict
            if oldDict ~= textureDict and HasStreamedTextureDictLoaded(oldDict) then
                SetStreamedTextureDictAsNoLongerNeeded(oldDict)
                loadedTextures[oldDict] = nil
            end
        end
        
        ActiveCustomLiveries[vehicleEntityId] = {
            file = liveryFile,
            dict = textureDict,
            model = vehicleModelName
        }
        
        -- Track loaded texture
        loadedTextures[textureDict] = GetGameTimer()
        
        -- Apply livery
        local liveryModCount = GetNumVehicleMods(vehicle, 48)
        if liveryModCount > 0 then
            SetVehicleMod(vehicle, 48, 0, false)
        else
            local liveryCount = GetVehicleLiveryCount(vehicle)
            if liveryCount > 0 then
                SetVehicleLivery(vehicle, 1) -- Use first livery as base
            end
        end
        
        -- Update entity routing to refresh appearance
        local currentBucket = GetEntityRoutingBucket(vehicle)
        SetEntityRoutingBucket(vehicle, 100 + currentBucket)
        Wait(50)
        SetEntityRoutingBucket(vehicle, currentBucket)
        
        print("^2INFO:^0 Applied custom livery " .. liveryFile .. " to vehicle")
    else
        print("^1ERROR:^0 Failed to load texture dictionary for livery: " .. textureDict)
    end
end)

-- Improved zone checking with performance optimization
CreateThread(function()
    while true do
        local currentTime = GetGameTimer()
        
        if currentTime - lastZoneCheck >= ZONE_CHECK_INTERVAL then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local foundZone = false
            
            for _, zone in ipairs(Config.ModificationZones) do
                if zone and zone.coords and zone.radius then
                    local distance = #(playerCoords - zone.coords)
                    if distance < 50.0 then -- Only check zones within 50 units
                        foundZone = true
                        break
                    end
                end
            end
            
            nearModificationZone = foundZone
            lastZoneCheck = currentTime
        end
        
        -- Dynamic wait based on proximity
        Wait(nearModificationZone and 100 or 2000)
    end
end)

-- Optimized marker drawing thread
CreateThread(function()
    while Config.ShowMarkers do
        if nearModificationZone then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            for _, zone in ipairs(Config.ModificationZones) do
                if zone and zone.coords and zone.radius then
                    local distance = #(playerCoords - zone.coords)
                    
                    if distance < 50.0 then
                        -- Draw marker
                        local markerColor = (zone.type == "police") and {0, 0, 255, 100} or {255, 0, 0, 100}
                        DrawMarker(1, -- Marker type
                            zone.coords.x, zone.coords.y, zone.coords.z - 1.0, -- Coordinates
                            0.0, 0.0, 0.0, -- Direction
                            0.0, 0.0, 0.0, -- Rotation
                            zone.radius * 2.0, zone.radius * 2.0, 1.0, -- Scale
                            markerColor[1], markerColor[2], markerColor[3], markerColor[4], -- RGBA color
                            false, true, 2, false, nil, nil, false -- Options
                        )
                        
                        -- Draw hint when in a vehicle within the zone
                        if distance < zone.radius and IsPedInAnyVehicle(playerPed, false) and 
                           GetPedInVehicleSeat(GetVehiclePedIsIn(playerPed, false), -1) == playerPed then
                            
                            -- Check if it's an emergency vehicle when restriction is on
                            local veh = GetVehiclePedIsIn(playerPed, false)
                            if not Config.EmergencyVehiclesOnly or Config.IsEmergencyVehicle(veh) then
                                DisplayHelpTextThisFrame("Press ~INPUT_CONTEXT~ to modify this vehicle", false)
                                if IsControlJustReleased(0, 51) then -- E key
                                    TriggerEvent('vehiclemods:client:openVehicleModMenu')
                                end
                            end
                        end
                    end
                end
            end
            Wait(0)
        else
            Wait(1000) -- Wait longer when not near any zone
        end
    end
end)

-- Texture cleanup thread
CreateThread(function()
    while true do
        Wait(30000) -- Check every 30 seconds
        
        local currentTime = GetGameTimer()
        for textureDict, loadTime in pairs(loadedTextures) do
            -- Clean up textures that haven't been used for 5 minutes
            if currentTime - loadTime > 300000 and HasStreamedTextureDictLoaded(textureDict) then
                -- Check if texture is still in use
                local inUse = false
                for _, liveryInfo in pairs(ActiveCustomLiveries or {}) do
                    if liveryInfo.dict == textureDict then
                        inUse = true
                        break
                    end
                end
                
                if not inUse then
                    SetStreamedTextureDictAsNoLongerNeeded(textureDict)
                    loadedTextures[textureDict] = nil
                    if Config.Debug then
                        print("^3INFO:^0 Cleaned up unused texture dictionary: " .. textureDict)
                    end
                end
            end
        end
    end
end)

-- Add cleanup when player leaves vehicle
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkPlayerLeftVehicle' then
        if args[1] == PlayerId() then
            local vehicle = args[2]
            if DoesEntityExist(vehicle) then
                local vehicleEntityId = VehToNet(vehicle)
                if ActiveCustomLiveries and ActiveCustomLiveries[vehicleEntityId] then
                    -- Don't immediately clean up, just mark the time
                    local liveryInfo = ActiveCustomLiveries[vehicleEntityId]
                    if liveryInfo.dict and loadedTextures[liveryInfo.dict] then
                        loadedTextures[liveryInfo.dict] = GetGameTimer() - 240000 -- Age it by 4 minutes
                    end
                end
            end
        end
    end
end)

-- Add proper error handling to vehicle property functions
local function SafeGetVehicleProperties(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        return nil
    end
    
    local success, properties = pcall(GetVehicleProperties, vehicle)
    if success then
        return properties
    else
        print("^1ERROR:^0 Failed to get vehicle properties: " .. tostring(properties))
        return nil
    end
end

-- Replace the existing SaveVehicleConfig function with this safer version:
function SaveVehicleConfig()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if vehicle == 0 then
        lib.notify({
            title = 'Error',
            description = 'You need to be in a vehicle to save configuration',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    local vehicleProps = SafeGetVehicleProperties(vehicle)
    if not vehicleProps then
        lib.notify({
            title = 'Error',
            description = 'Failed to read vehicle properties',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    local vehicleModel = GetEntityModel(vehicle)
    local vehicleModelName = GetDisplayNameFromVehicleModel(vehicleModel)
    
    if not vehicleModelName or vehicleModelName == "" then
        lib.notify({
            title = 'Error',
            description = 'Unable to identify vehicle model',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Save to database via server
    local success, jsonString = pcall(json.encode, vehicleProps)
    if success then
        TriggerServerEvent('vehiclemods:server:saveModifications', vehicleModelName, jsonString)
        
        lib.notify({
            title = 'Configuration Saved',
            description = 'Your vehicle configuration has been saved.',
            type = 'success',
            duration = 5000
        })
    else
        lib.notify({
            title = 'Error',
            description = 'Failed to encode vehicle configuration',
            type = 'error',
            duration = 5000
        })
        print("^1ERROR:^0 JSON encoding failed: " .. tostring(jsonString))
    end
end

-- Command to open the vehicle modification menu
RegisterCommand('modveh', function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local inZone, zoneInfo = Config.IsInModificationZone(playerCoords)
    
    if not inZone then
        lib.notify({
            title = 'Access Denied',
            description = zoneInfo.message,
            type = 'error',
            duration = 5000
        })
        return
    end
    
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if vehicle == 0 then
        lib.notify({
            title = 'Error',
            description = 'You must be in a vehicle to use this menu',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Check if vehicle is an emergency vehicle (if restriction is enabled)
    if Config.EmergencyVehiclesOnly and not Config.IsEmergencyVehicle(vehicle) then
        lib.notify({
            title = 'Vehicle Not Authorized',
            description = 'Only emergency vehicles can be modified here',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    print("^2SUCCESS:^0 " .. zoneInfo.message .. ". Opening menu...")
    TriggerEvent('vehiclemods:client:openVehicleModMenu')
end, false)

-- Display help text function (FIXED VERSION)
function DisplayHelpTextThisFrame(text, beep)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

-- Add a keybind to quickly open the menu without typing the command
RegisterKeyMapping('modveh', 'Open Vehicle Modification Menu', 'keyboard', 'F7')

-- Initialize variables
ActiveCustomLiveries = {}

-- Main menu event
RegisterNetEvent('vehiclemods:client:openVehicleModMenu')
AddEventHandler('vehiclemods:client:openVehicleModMenu', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local vehicleTitle = "Vehicle Menu"
    local vehicleInfo = nil
    
    if vehicle ~= 0 then
        local vehicleModel = GetEntityModel(vehicle)
        local vehicleModelName = GetDisplayNameFromVehicleModel(vehicleModel)
        local vehicleMake = GetVehicleManufacturer(vehicleModel)
        
        vehicleTitle = vehicleModelName .. " Modifications"
        vehicleInfo = {
            {label = 'Make', value = vehicleMake ~= "" and vehicleMake or "Unknown"},
            {label = 'Model', value = vehicleModelName},
            {label = 'Class', value = GetVehicleClassNameFromVehicleClass(GetVehicleClass(vehicle))}
        }
    end
    
    local options = {}
    
    -- Only add options that are enabled in the config
    if Config.EnabledModifications.Liveries then
        table.insert(options, {
            title = 'Liveries',
            description = 'Select a vehicle livery.',
            onSelect = function()
                OpenLiveryMenu()
            end
        })
    end
    
    if Config.EnabledModifications.CustomLiveries then
        table.insert(options, {
            title = 'Custom Liveries',
            description = 'Apply custom YFT liveries.',
            onSelect = function()
                OpenCustomLiveriesMenu()
            end
        })
    end
    
    if Config.EnabledModifications.Appearance then
        table.insert(options, {
            title = 'Vehicle Appearance',
            description = 'Customize vehicle appearance.',
            onSelect = function()
                OpenAppearanceMenu()
            end
        })
    end
    
    if Config.EnabledModifications.Performance then
        table.insert(options, {
            title = 'Performance Mods',
            description = 'Install performance upgrades.',
            onSelect = function()
                OpenPerformanceMenu()
            end
        })
    end
    
    if Config.EnabledModifications.Extras then
        table.insert(options, {
            title = 'Extras',
            description = 'Enable or disable vehicle extras.',
            onSelect = function()
                OpenExtrasMenu()
            end
        })
    end
    
    if Config.EnabledModifications.Doors then
        table.insert(options, {
            title = 'Doors',
            description = 'Open or close individual doors.',
            onSelect = function()
                OpenDoorsMenu()
            end
        })
    end
    
    -- These options should always be available
    table.insert(options, {
        title = 'Save Configuration',
        description = 'Save current vehicle setup.',
        onSelect = function()
            SaveVehicleConfig()
        end
    })
    
    table.insert(options, {
        title = 'Close Menu',
        description = 'Exit the vehicle modification menu',
        onSelect = function()
            lib.hideContext()
        end
    })

    lib.registerContext({
        id = 'VehicleModMenu',
        title = vehicleTitle,
        metadata = vehicleInfo,
        options = options,
        close = false
    })
    lib.showContext('VehicleModMenu')
end)

-- Livery Menu
function OpenLiveryMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if vehicle == 0 then
        lib.notify({
            title = 'Error',
            description = 'You need to be in a vehicle to change liveries',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    local options = {}
    local numLiveries = GetVehicleLiveryCount(vehicle)
    local currentLivery = GetVehicleLivery(vehicle)
    local numMods = GetNumVehicleMods(vehicle, 48)
    
    if (numLiveries > 5 or numMods > 5) then
        table.insert(options, {
            title = 'Search Liveries',
            description = 'Find specific liveries by name or number',
            onSelect = function()
                OpenLiverySearchMenu()
            end
        })
    end
    
    if numLiveries > 0 then
        for i = 0, numLiveries - 1 do
            local isActive = (currentLivery == i)
            table.insert(options, {
                title = 'Livery ' .. i,
                description = 'Apply Livery ' .. i,
                metadata = {
                    {label = 'Status', value = isActive and 'Active' or 'Inactive'}
                },
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
    else
        local currentMod = GetVehicleMod(vehicle, 48)
        
        if numMods > 0 then
            for i = -1, numMods - 1 do
                local modName = i == -1 and "Default" or "Style " .. (i + 1)
                local isActive = (currentMod == i)
                
                table.insert(options, {
                    title = modName,
                    description = 'Apply ' .. modName,
                    metadata = {
                        {label = 'Status', value = isActive and 'Active' or 'Inactive'}
                    },
                    onSelect = function()
                        SetVehicleMod(vehicle, 48, i, false)
                        lib.notify({
                            title = 'Livery Applied',
                            description = 'Applied ' .. modName .. '.',
                            type = 'success',
                            duration = 5000
                        })
                        OpenLiveryMenu()
                    end
                })
            end
        else
            table.insert(options, {
                title = 'No liveries available',
                description = 'This vehicle has no available liveries.',
                onSelect = function() end
            })
        end
    end
    
    -- Add custom liveries option if available for this vehicle
    local vehicleModel = GetEntityModel(vehicle)
    local vehicleModelName = GetDisplayNameFromVehicleModel(vehicleModel):lower()
    
    if Config.CustomLiveries and Config.CustomLiveries[vehicleModelName] then
        table.insert(options, 1, {
            title = 'Custom Liveries (YFT)',
            description = 'Browse custom YFT liveries for this vehicle',
            onSelect = function()
                OpenCustomLiveriesMenu()
            end
        })
    end

    lib.registerContext({
        id = 'LiveryMenu',
        title = 'Select Livery',
        options = options,
        menu = 'VehicleModMenu',
        close = false
    })
    lib.showContext('LiveryMenu')
end

-- Custom Liveries Menu
function OpenCustomLiveriesMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if vehicle == 0 then
        lib.notify({
            title = 'Error',
            description = 'You need to be in a vehicle to change liveries',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    local vehicleModel = GetEntityModel(vehicle)
    local vehicleModelName = GetDisplayNameFromVehicleModel(vehicleModel):lower()
    
    local availableLiveries = {}
    
    if Config.CustomLiveries then
        availableLiveries = Config.CustomLiveries[vehicleModelName] or {}
    else
        Config.CustomLiveries = {}
    end
    
    local options = {}
    
    table.insert(options, {
        title = 'Stock (No Livery)',
        description = 'Remove custom livery',
        onSelect = function()
            SetVehicleLivery(vehicle, 0)
            SetVehicleMod(vehicle, 48, -1, false)
            
            TriggerServerEvent('vehiclemods:server:clearCustomLivery', NetworkGetNetworkIdFromEntity(vehicle))
            
            lib.notify({
                title = 'Livery Removed',
                description = 'Custom livery removed',
                type = 'success',
                duration = 5000
            })
            OpenCustomLiveriesMenu()
        end
    })
    
    if availableLiveries and #availableLiveries > 0 then
        for i, livery in ipairs(availableLiveries) do
            table.insert(options, {
                title = livery.name,
                description = 'Apply ' .. livery.name .. ' livery',
                onSelect = function()
                    TriggerServerEvent('vehiclemods:server:applyCustomLivery', 
                        NetworkGetNetworkIdFromEntity(vehicle), 
                        vehicleModelName, 
                        livery.file
                    )
                    lib.notify({
                        title = 'Livery Applied',
                        description = 'Applied ' .. livery.name .. ' livery',
                        type = 'success',
                        duration = 5000
                    })
                    OpenCustomLiveriesMenu()
                end
            })
        end
    else
        table.insert(options, {
            title = 'No Custom Liveries',
            description = 'This vehicle has no custom YFT liveries configured',
            onSelect = function() end
        })
    end
    
    -- Option to add new livery
    table.insert(options, {
        title = 'Add New Livery',
        description = 'Add a new custom livery for this vehicle',
        onSelect = function()
            OpenAddCustomLiveryMenu(vehicleModelName)
        end
    })

    lib.registerContext({
        id = 'CustomLiveriesMenu',
        title = 'Custom Liveries',
        options = options,
        menu = 'VehicleModMenu',
        close = false
    })
    lib.showContext('CustomLiveriesMenu')
end

-- For receiving custom liveries from server
RegisterNetEvent('vehiclemods:client:setCustomLivery')
AddEventHandler('vehiclemods:client:setCustomLivery', function(netId, vehicleModelName, liveryFile)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    
    if not vehicle or not DoesEntityExist(vehicle) then
        return
    end
    
    -- Extract base name without "liveries/" prefix
    local baseName = string.match(liveryFile, "([^/]+)%.yft$")
    if not baseName then
        baseName = liveryFile:gsub(".yft", "")
    end
    
    local textureDict = vehicleModelName .. "_" .. baseName
    
    if not HasStreamedTextureDictLoaded(textureDict) then
        RequestStreamedTextureDict(textureDict)
        local timeout = 0
        while not HasStreamedTextureDictLoaded(textureDict) and timeout < 100 do
            Wait(10)
            timeout = timeout + 1
        end
    end
    
    if HasStreamedTextureDictLoaded(textureDict) then
        local vehicleEntityId = VehToNet(vehicle)
        if not ActiveCustomLiveries then ActiveCustomLiveries = {} end
        ActiveCustomLiveries[vehicleEntityId] = {
            file = liveryFile,
            dict = textureDict,
            model = vehicleModelName
        }
        
        -- Apply livery
        local liveryModCount = GetNumVehicleMods(vehicle, 48)
        if liveryModCount > 0 then
            SetVehicleMod(vehicle, 48, 0, false)
        else
            local liveryCount = GetVehicleLiveryCount(vehicle)
            if liveryCount > 0 then
                SetVehicleLivery(vehicle, 1) -- Use first livery as base
            end
        end
        
        -- Update entity routing to refresh appearance
        SetEntityRoutingBucket(vehicle, 100 + GetEntityRoutingBucket(vehicle))
        Wait(50)
        SetEntityRoutingBucket(vehicle, GetEntityRoutingBucket(vehicle) - 100)
        
        print("^2INFO:^0 Applied custom livery " .. liveryFile .. " to vehicle")
    else
        print("^1ERROR:^0 Failed to load texture dictionary for livery: " .. textureDict)
    end
end)

-- Removing custom liveries
RegisterNetEvent('vehiclemods:client:clearCustomLivery')
AddEventHandler('vehiclemods:client:clearCustomLivery', function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    
    if not vehicle or not DoesEntityExist(vehicle) then
        return
    end
    
    local vehicleEntityId = VehToNet(vehicle)
    if ActiveCustomLiveries and ActiveCustomLiveries[vehicleEntityId] then
        local liveryInfo = ActiveCustomLiveries[vehicleEntityId]
        
        SetVehicleLivery(vehicle, 0) -- Reset to default livery
        SetVehicleMod(vehicle, 48, -1, false) -- Remove livery mod
        
        if HasStreamedTextureDictLoaded(liveryInfo.dict) then
            SetStreamedTextureDictAsNoLongerNeeded(liveryInfo.dict)
        end
        
        ActiveCustomLiveries[vehicleEntityId] = nil
        
        print("^2INFO:^0 Cleared custom livery from vehicle")
    end
end)

-- Add custom livery menu
function OpenAddCustomLiveryMenu(vehicleModelName)
    lib.showTextInput({
        title = 'Add Custom Livery',
        description = 'Enter the name and YFT file for the new livery:',
        fields = {
            { label = 'Livery Name', name = 'name', type = 'text', required = true, placeholder = 'e.g. Police Livery 1' },
            { label = 'YFT File Path', name = 'file', type = 'text', required = true, placeholder = vehicleModelName .. '_livery1.yft' }
        },
        onSubmit = function(data)
            if data.name and data.file then
                TriggerServerEvent('vehiclemods:server:addCustomLivery', vehicleModelName, data.name, data.file)
                
                Citizen.SetTimeout(500, function()
                    OpenCustomLiveriesMenu()
                end)
            end
        end
    })
end

-- Function to search for liveries
function OpenLiverySearchMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if vehicle == 0 then
        return
    end
    
    lib.showTextInput({
        title = 'Search Liveries',
        description = 'Enter a search term to filter liveries',
        placeholder = 'e.g. LSPD or Sheriff',
        onSubmit = function(data)
            if data and data ~= "" then
                FilteredLiveryMenu(data:lower())
            else
                OpenLiveryMenu()
            end
        end
    })
end

-- Function to filter liveries by search term
function FilteredLiveryMenu(searchTerm)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local options = {}
    local numLiveries = GetVehicleLiveryCount(vehicle)
    local currentLivery = GetVehicleLivery(vehicle)
    local filteredResults = 0
    
    -- For standard liveries
    if numLiveries > 0 then
        for i = 0, numLiveries - 1 do
            local liveryName = 'Livery ' .. i
            
            if string.find(liveryName:lower(), searchTerm) then
                local isActive = (currentLivery == i)
                table.insert(options, {
                    title = liveryName,
                    description = 'Apply ' .. liveryName,
                    metadata = {
                        {label = 'Status', value = isActive and 'Active' or 'Inactive'}
                    },
                    onSelect = function()
                        SetVehicleLivery(vehicle, i)
                        lib.notify({
                            title = 'Livery Applied',
                            description = 'Applied ' .. liveryName .. '.',
                            type = 'success',
                            duration = 5000
                        })
                        FilteredLiveryMenu(searchTerm)
                    end
                })
                filteredResults = filteredResults + 1
            end
        end
    end
    
    -- For mod slot 48 liveries
    local numMods = GetNumVehicleMods(vehicle, 48)
    local currentMod = GetVehicleMod(vehicle, 48)
    
    if numMods > 0 then
        for i = -1, numMods - 1 do
            local modName = i == -1 and "Default" or "Style " .. (i + 1)
            
            if string.find(modName:lower(), searchTerm) then
                local isActive = (currentMod == i)
                
                table.insert(options, {
                    title = modName,
                    description = 'Apply ' .. modName,
                    metadata = {
                        {label = 'Status', value = isActive and 'Active' or 'Inactive'}
                    },
                    onSelect = function()
                        SetVehicleMod(vehicle, 48, i, false)
                        lib.notify({
                            title = 'Livery Applied',
                            description = 'Applied ' .. modName .. '.',
                            type = 'success',
                            duration = 5000
                        })
                        FilteredLiveryMenu(searchTerm)
                    end
                })
                filteredResults = filteredResults + 1
            end
        end
    end
    
    -- Custom YFT liveries search
    local vehicleModel = GetEntityModel(vehicle)
    local vehicleModelName = GetDisplayNameFromVehicleModel(vehicleModel):lower()
    
    if Config.CustomLiveries and Config.CustomLiveries[vehicleModelName] then
        for _, livery in ipairs(Config.CustomLiveries[vehicleModelName]) do
            if string.find(livery.name:lower(), searchTerm) then
                table.insert(options, {
                    title = livery.name,
                    description = 'Apply ' .. livery.name .. ' custom livery',
                    onSelect = function()
                        TriggerServerEvent('vehiclemods:server:applyCustomLivery', 
                            NetworkGetNetworkIdFromEntity(vehicle), 
                            vehicleModelName, 
                            livery.file
                        )
                        lib.notify({
                            title = 'Livery Applied',
                            description = 'Applied ' .. livery.name .. ' livery',
                            type = 'success',
                            duration = 5000
                        })
                        FilteredLiveryMenu(searchTerm)
                    end
                })
                filteredResults = filteredResults + 1
            end
        end
    end
    
    if filteredResults == 0 then
        table.insert(options, {
            title = 'No Results Found',
            description = 'No liveries match your search term: ' .. searchTerm,
            onSelect = function()
                OpenLiverySearchMenu()
            end
        })
    end
    
    table.insert(options, 1, {
        title = 'New Search',
        description = 'Search for a different livery',
        onSelect = function()
            OpenLiverySearchMenu()
        end
    })
    
    table.insert(options, 2, {
        title = 'Show All Liveries',
        description = 'Display all available liveries',
        onSelect = function()
            OpenLiveryMenu()
        end
    })

    lib.registerContext({
        id = 'FilteredLiveryMenu',
        title = 'Search Results: ' .. searchTerm,
        metadata = {
            {label = 'Results', value = filteredResults}
        },
        options = options,
        menu = 'VehicleModMenu',
        close = false
    })
    lib.showContext('FilteredLiveryMenu')
end

-- Performance Menu
function OpenPerformanceMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    local modTypes = {
        { name = "Engine", id = 11 },
        { name = "Brakes", id = 12 },
        { name = "Transmission", id = 13 },
        { name = "Suspension", id = 15 },
        { name = "Armor", id = 16 },
        { name = "Turbo", id = 18 }
    }
    
    local options = {}
    
    for _, modType in pairs(modTypes) do
        local numMods = GetNumVehicleMods(vehicle, modType.id)
        local specialCase = false
        
        -- Special case for Turbo which is a toggle
        if modType.id == 18 then
            numMods = 1
            specialCase = true
        end
        
        if numMods > 0 then
            local status = ""
            if specialCase then
                status = IsToggleModOn(vehicle, modType.id) and "Enabled" or "Disabled"
            else
                local currentLevel = GetVehicleMod(vehicle, modType.id)
                if currentLevel == -1 then
                    status = "Stock"
                else
                    status = "Level " .. (currentLevel + 1)
                end
            end
            
            table.insert(options, {
                title = modType.name,
                description = specialCase and 'Toggle turbo on/off' or 'Available upgrades: ' .. numMods,
                metadata = {
                    {label = 'Current', value = status}
                },
                onSelect = function()
                    if specialCase then
                        ToggleTurbo(vehicle)
                    else
                        OpenPerformanceModMenu(modType.id, modType.name)
                    end
                end
            })
        end
    end

    lib.registerContext({
        id = 'PerformanceMenu',
        title = 'Performance Upgrades',
        options = options,
        menu = 'VehicleModMenu',
        close = false
    })
    lib.showContext('PerformanceMenu')
end

-- Toggle turbo function
function ToggleTurbo(vehicle)
    local hasTurbo = IsToggleModOn(vehicle, 18)
    
    ToggleVehicleMod(vehicle, 18, not hasTurbo)
    
    lib.notify({
        title = 'Turbo',
        description = hasTurbo and 'Turbo disabled' or 'Turbo enabled',
        type = 'success',
        duration = 5000
    })
    
    OpenPerformanceMenu()
end

-- Performance mod selection menu
function OpenPerformanceModMenu(modType, modTypeName)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local options = {}
    local numMods = GetNumVehicleMods(vehicle, modType)
    local currentMod = GetVehicleMod(vehicle, modType)
    
    table.insert(options, {
        title = 'Stock ' .. modTypeName,
        description = 'Remove ' .. modTypeName .. ' upgrades',
        metadata = {
            {label = 'Status', value = (currentMod == -1) and 'Active' or 'Inactive'}
        },
        onSelect = function()
            SetVehicleMod(vehicle, modType, -1, false)
            lib.notify({
                title = 'Upgrade Removed',
                description = modTypeName .. ' set to stock',
                type = 'success',
                duration = 5000
            })
            OpenPerformanceModMenu(modType, modTypeName)
        end
    })
    
    local modNames = {}
    if modType == 11 then  -- Engine
        modNames = {"EMS Upgrade, Level 1", "EMS Upgrade, Level 2", "EMS Upgrade, Level 3", "EMS Upgrade, Level 4"}
    elseif modType == 12 then  -- Brakes
        modNames = {"Street Brakes", "Sport Brakes", "Race Brakes", "Racing Brakes"}
    elseif modType == 13 then  -- Transmission
        modNames = {"Street Transmission", "Sports Transmission", "Race Transmission", "Super Transmission"}
    elseif modType == 15 then  -- Suspension
        modNames = {"Lowered Suspension", "Street Suspension", "Sport Suspension", "Competition Suspension"}
    elseif modType == 16 then  -- Armor
        modNames = {"Armor Upgrade 20%", "Armor Upgrade 40%", "Armor Upgrade 60%", "Armor Upgrade 80%", "Armor Upgrade 100%"}
    end
    
    for i = 0, numMods - 1 do
        local modName = (modNames[i+1] ~= nil) and modNames[i+1] or (modTypeName .. " Level " .. (i + 1))
        local isActive = (currentMod == i)
        
        table.insert(options, {
            title = modName,
            description = 'Apply ' .. modName,
            metadata = {
                {label = 'Status', value = isActive and 'Active' or 'Inactive'}
            },
            onSelect = function()
                SetVehicleMod(vehicle, modType, i, false)
                lib.notify({
                    title = 'Upgrade Applied',
                    description = 'Applied ' .. modName,
                    type = 'success',
                    duration = 5000
                })
                OpenPerformanceModMenu(modType, modTypeName)
            end
        })
    end

    lib.registerContext({
        id = 'PerformanceModMenu',
        title = modTypeName .. ' Upgrades',
        options = options,
        menu = 'PerformanceMenu',
        close = false
    })
    lib.showContext('PerformanceModMenu')
end

-- Extras Menu
function OpenExtrasMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local options = {}
    
    for i = 1, 20 do
        if DoesExtraExist(vehicle, i) then
            local isEnabled = IsVehicleExtraTurnedOn(vehicle, i)
            
            table.insert(options, {
                title = 'Extra ' .. i,
                description = isEnabled and 'Disable Extra ' .. i or 'Enable Extra ' .. i,
                metadata = {
                    {label = 'Status', value = isEnabled and 'Enabled' or 'Disabled'}
                },
                onSelect = function()
                    SetVehicleExtra(vehicle, i, isEnabled and 1 or 0)
                    lib.notify({
                        title = 'Success',
                        description = (isEnabled and 'Disabled' or 'Enabled') .. ' Extra ' .. i .. '.',
                        type = 'success',
                        duration = 5000
                    })
                    OpenExtrasMenu()
                end
            })
        end
    end
    
    if #options == 0 then
        table.insert(options, {
            title = 'No Extras Available',
            description = 'This vehicle has no extras to toggle',
            onSelect = function() end
        })
    end
    
    lib.registerContext({
        id = 'ExtrasMenu',
        title = 'Toggle Extras',
        options = options,
        menu = 'VehicleModMenu',
        close = false
    })
    lib.showContext('ExtrasMenu')
end

-- Door Control Menu
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
        local isDoorOpen = GetVehicleDoorAngleRatio(vehicle, door.index) > 0
        
        table.insert(options, {
            title = door.title,
            description = isDoorOpen and 'Close ' .. door.title or 'Open ' .. door.title,
            metadata = {
                {label = 'Status', value = isDoorOpen and 'Open' or 'Closed'}
            },
            onSelect = function()
                if isDoorOpen then
                    SetVehicleDoorShut(vehicle, door.index, false)
                else
                    SetVehicleDoorOpen(vehicle, door.index, false, false)
                end
                OpenDoorsMenu()
            end
        })
    end

    -- Add all doors options
    table.insert(options, {
        title = 'All Doors',
        description = 'Open or close all doors at once',
        onSelect = function()
            -- Check if any door is open
            local anyDoorOpen = false
            for _, door in pairs(doors) do
                if GetVehicleDoorAngleRatio(vehicle, door.index) > 0 then
                    anyDoorOpen = true
                    break
                end
            end
            
            for _, door in pairs(doors) do
                if anyDoorOpen then
                    SetVehicleDoorShut(vehicle, door.index, false)
                else
                    SetVehicleDoorOpen(vehicle, door.index, false, false)
                end
            end
            
            lib.notify({
                title = 'All Doors',
                description = anyDoorOpen and 'All doors closed' or 'All doors opened',
                type = 'success',
                duration = 5000
            })
            
            OpenDoorsMenu()
        end
    })

    lib.registerContext({
        id = 'DoorsMenu',
        title = 'Doors Control',
        options = options,
        menu = 'VehicleModMenu',
        close = false
    })
    lib.showContext('DoorsMenu')
end

-- Appearance Menu
function OpenAppearanceMenu()
    local options = {
        {
            title = 'Colors',
            description = 'Change vehicle colors.',
            onSelect = function()
                OpenColorsMenu()
            end
        },
        {
            title = 'Wheels',
            description = 'Change vehicle wheels.',
            onSelect = function()
                OpenWheelsMenu()
            end
        },
        {
            title = 'Windows',
            description = 'Apply window tint.',
            onSelect = function()
                OpenWindowTintMenu()
            end
        },
        {
            title = 'Neon Lights',
            description = 'Customize neon lights.',
            onSelect = function()
                OpenNeonMenu()
            end
        }
    }

    lib.registerContext({
        id = 'AppearanceMenu',
        title = 'Vehicle Appearance',
        options = options,
        menu = 'VehicleModMenu',
        close = false
    })
    lib.showContext('AppearanceMenu')
end

-- Window Tint Menu
function OpenWindowTintMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    local tintOptions = {
        { name = "None", tint = 0 },
        { name = "Pure Black", tint = 1 },
        { name = "Dark Smoke", tint = 2 },
        { name = "Light Smoke", tint = 3 },
        { name = "Stock", tint = 4 },
        { name = "Limo", tint = 5 },
        { name = "Green", tint = 6 }
    }
    
    local options = {}
    local currentTint = GetVehicleWindowTint(vehicle)
    
    for _, tintOption in pairs(tintOptions) do
        local isActive = (currentTint == tintOption.tint)
        table.insert(options, {
            title = tintOption.name,
            description = 'Apply ' .. tintOption.name .. ' window tint',
            metadata = {
                {label = 'Status', value = isActive and 'Active' or 'Inactive'}
            },
            onSelect = function()
                SetVehicleWindowTint(vehicle, tintOption.tint)
                lib.notify({
                    title = 'Window Tint Applied',
                    description = 'Applied ' .. tintOption.name .. ' window tint',
                    type = 'success',
                    duration = 5000
                })
                OpenWindowTintMenu()
            end
        })
    end

    lib.registerContext({
        id = 'WindowTintMenu',
        title = 'Window Tint',
        options = options,
        menu = 'AppearanceMenu',
        close = false
    })
    lib.showContext('WindowTintMenu')
end

-- Function to load and apply saved vehicle configurations
function LoadVehicleConfig(vehicle)
    local vehicleModel = GetEntityModel(vehicle)
    local vehicleModelName = GetDisplayNameFromVehicleModel(vehicleModel)
    
    -- Request saved configuration from server
    TriggerServerEvent('vehiclemods:server:requestVehicleConfig', vehicleModelName)
end

-- Event to receive and apply saved vehicle configuration
RegisterNetEvent('vehiclemods:client:applyVehicleConfig')
AddEventHandler('vehiclemods:client:applyVehicleConfig', function(vehicleModelName, vehiclePropsJson)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if vehicle == 0 or GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)):lower() ~= vehicleModelName:lower() then
        -- Not in the right vehicle
        return
    end
    
    -- Parse the JSON string back into a table
    local vehicleProps = json.decode(vehiclePropsJson)
    
    if vehicleProps then
        -- Apply the saved properties to the vehicle
        ApplyVehicleProperties(vehicle, vehicleProps)
        
        lib.notify({
            title = 'Configuration Loaded',
            description = 'Vehicle configuration has been applied.',
            type = 'success',
            duration = 5000
        })
    else
        lib.notify({
            title = 'Error',
            description = 'Failed to load vehicle configuration.',
            type = 'error',
            duration = 5000
        })
    end
end)

-- Function to apply vehicle properties
function ApplyVehicleProperties(vehicle, props)
    if props.color1 then
        SetVehicleColours(vehicle, props.color1, props.color2 or 0)
    end
    
    if props.pearlescentColor then
        SetVehicleExtraColours(vehicle, props.pearlescentColor, props.wheelColor or 0)
    end
    
    if props.wheels then
        SetVehicleWheelType(vehicle, props.wheels)
    end
    
    if props.windowTint then
        SetVehicleWindowTint(vehicle, props.windowTint)
    end
    
    -- Apply neon lights
    if props.neonEnabled then
        for i = 0, 3 do
            SetVehicleNeonLightEnabled(vehicle, i, props.neonEnabled[i])
        end
    end
    
    if props.neonColor then
        SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
    end
    
    -- Apply mods
    for modType = 0, 49 do
        local modValue = props['mod' .. modType]
        if modValue ~= nil then
            SetVehicleMod(vehicle, modType, modValue, false)
        end
    end
    
    -- Apply special mods
    if props.modTurbo ~= nil then
        ToggleVehicleMod(vehicle, 18, props.modTurbo)
    end
    
    if props.modSmokeEnabled ~= nil then
        ToggleVehicleMod(vehicle, 20, props.modSmokeEnabled)
    end
    
    if props.modXenon ~= nil then
        ToggleVehicleMod(vehicle, 22, props.modXenon)
    end
    
    -- Apply extras
    if props.extras then
        for extraId, enabled in pairs(props.extras) do
            local extraIndex = tonumber(extraId)
            if extraIndex and DoesExtraExist(vehicle, extraIndex) then
                SetVehicleExtra(vehicle, extraIndex, enabled and 0 or 1)
            end
        end
    end
    
    -- Apply livery
    if props.livery and props.livery ~= -1 then
        SetVehicleLivery(vehicle, props.livery)
    elseif props.modLivery and props.modLivery ~= -1 then
        SetVehicleMod(vehicle, 48, props.modLivery, false)
    end
end

-- When player enters vehicle, load saved config
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkPlayerEnteredVehicle' then
        -- args[1] is the player ID, args[2] is the vehicle
        if args[1] == PlayerId() then
            local vehicle = args[2]
            if DoesEntityExist(vehicle) then
                Citizen.SetTimeout(500, function() -- Small delay to ensure vehicle is fully loaded
                    LoadVehicleConfig(vehicle)
                end)
            end
        end
    end
end)

-- Neon Menu
function OpenNeonMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    local options = {
        {
            title = 'Toggle Neon',
            description = 'Turn neon lights on/off',
            onSelect = function()
                local hasNeon = false
                for i = 0, 3 do
                    if IsVehicleNeonLightEnabled(vehicle, i) then
                        hasNeon = true
                        break
                    end
                end
                
                for i = 0, 3 do
                    SetVehicleNeonLightEnabled(vehicle, i, not hasNeon)
                end
                
                lib.notify({
                    title = 'Neon Lights',
                    description = hasNeon and 'Neon lights turned off' or 'Neon lights turned on',
                    type = 'success',
                    duration = 5000
                })
                OpenNeonMenu()
            end
        },
        {
            title = 'Neon Layout',
            description = 'Choose which neon lights to enable',
            onSelect = function()
                OpenNeonLayoutMenu()
            end
        },
        {
            title = 'Neon Color',
            description = 'Change the color of neon lights',
            onSelect = function()
                OpenNeonColorMenu()
            end
        }
    }

    lib.registerContext({
        id = 'NeonMenu',
        title = 'Neon Lights',
        options = options,
        menu = 'AppearanceMenu',
        close = false
    })
    lib.showContext('NeonMenu')
end

-- Neon Layout Menu
function OpenNeonLayoutMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    local neonOptions = {
        { name = "Front", index = 2 },
        { name = "Back", index = 3 },
        { name = "Left", index = 0 },
        { name = "Right", index = 1 },
        { name = "All", index = -1 }
    }
    
    local options = {}
    
    for _, neonOption in pairs(neonOptions) do
        local isEnabled = neonOption.index == -1 and false or IsVehicleNeonLightEnabled(vehicle, neonOption.index)
        
        table.insert(options, {
            title = neonOption.name,
            description = isEnabled and 'Turn off ' .. neonOption.name .. ' neon' or 'Turn on ' .. neonOption.name .. ' neon',
            metadata = {
                {label = 'Status', value = isEnabled and 'Enabled' or 'Disabled'}
            },
            onSelect = function()
                if neonOption.index == -1 then
                    local allEnabled = IsVehicleNeonLightEnabled(vehicle, 0)
                    for i = 0, 3 do
                        SetVehicleNeonLightEnabled(vehicle, i, not allEnabled)
                    end
                else
                    SetVehicleNeonLightEnabled(vehicle, neonOption.index, not isEnabled)
                end
                
                lib.notify({
                    title = 'Neon Layout Updated',
                    description = 'Updated ' .. neonOption.name .. ' neon setting',
                    type = 'success',
                    duration = 5000
                })
                OpenNeonLayoutMenu()
            end
        })
    end

    lib.registerContext({
        id = 'NeonLayoutMenu',
        title = 'Neon Layout',
        options = options,
        menu = 'NeonMenu',
        close = false
    })
    lib.showContext('NeonLayoutMenu')
end

-- Neon Color Menu
function OpenNeonColorMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    local colorOptions = {
        { name = "White", r = 255, g = 255, b = 255 },
        { name = "Blue", r = 0, g = 0, b = 255 },
        { name = "Electric Blue", r = 0, g = 150, b = 255 },
        { name = "Mint Green", r = 50, g = 255, b = 155 },
        { name = "Lime Green", r = 0, g = 255, b = 0 },
        { name = "Yellow", r = 255, g = 255, b = 0 },
        { name = "Golden Shower", r = 204, g = 204, b = 0 },
        { name = "Orange", r = 255, g = 128, b = 0 },
        { name = "Red", r = 255, g = 0, b = 0 },
        { name = "Pony Pink", r = 255, g = 0, b = 255 },
        { name = "Hot Pink", r = 255, g = 0, b = 150 },
        { name = "Purple", r = 153, g = 0, b = 153 }
    }
    
    local options = {}
    local currentR, currentG, currentB = GetVehicleNeonLightsColour(vehicle)
    
    for _, colorOption in pairs(colorOptions) do
        local isActive = (currentR == colorOption.r and currentG == colorOption.g and currentB == colorOption.b)
        
        table.insert(options, {
            title = colorOption.name,
            description = 'Apply ' .. colorOption.name .. ' neon color',
            metadata = {
                {label = 'Status', value = isActive and 'Active' or 'Inactive'}
            },
            onSelect = function()
                SetVehicleNeonLightsColour(vehicle, colorOption.r, colorOption.g, colorOption.b)
                lib.notify({
                    title = 'Neon Color Applied',
                    description = 'Applied ' .. colorOption.name .. ' neon color',
                    type = 'success',
                    duration = 5000
                })
                OpenNeonColorMenu()
            end
        })
    end

    lib.registerContext({
        id = 'NeonColorMenu',
        title = 'Neon Colors',
        options = options,
        menu = 'NeonMenu',
        close = false
    })
    lib.showContext('NeonColorMenu')
end

-- Colors Menu
function OpenColorsMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local primaryColor, secondaryColor = GetVehicleColours(vehicle)
    
    local colorOptions = {
        { name = "Black", color = 0 },
        { name = "Carbon Black", color = 147 },
        { name = "Graphite", color = 1 },
        { name = "Black Steel", color = 2 },
        { name = "Dark Steel", color = 3 },
        { name = "Silver", color = 4 },
        { name = "Red", color = 27 },
        { name = "Torino Red", color = 28 },
        { name = "Formula Red", color = 29 },
        { name = "Blue", color = 64 },
        { name = "Dark Blue", color = 62 },
        { name = "White", color = 111 },
        { name = "Frost White", color = 112 }
    }

    local options = {
        {
            title = 'Primary Color',
            description = 'Change the primary color of the vehicle.',
            menu = 'primary_color',
        },
        {
            title = 'Secondary Color',
            description = 'Change the secondary color of the vehicle.',
            menu = 'secondary_color',
        },
        {
            title = 'Pearlescent Color',
            description = 'Apply pearlescent finish.',
            onSelect = function()
                OpenPearlescentMenu()
            end
        }
    }

    lib.registerContext({
        id = 'ColorsMenu',
        title = 'Vehicle Colors',
        options = options,
        menu = 'AppearanceMenu',
        close = false
    })

    -- Generate primary color menu options
    local primaryOptions = {}
    for _, colorOption in pairs(colorOptions) do
        table.insert(primaryOptions, {
            title = colorOption.name,
            description = 'Set primary color to ' .. colorOption.name,
            metadata = {
                {label = 'Status', value = (primaryColor == colorOption.color) and 'Active' or 'Inactive'}
            },
            onSelect = function()
                SetVehicleColours(vehicle, colorOption.color, secondaryColor)
                lib.notify({
                    title = 'Color Applied',
                    description = 'Primary color set to ' .. colorOption.name,
                    type = 'success',
                    duration = 5000
                })
                OpenColorsMenu()
            end
        })
    end

    -- Generate secondary color menu options
    local secondaryOptions = {}
    for _, colorOption in pairs(colorOptions) do
        table.insert(secondaryOptions, {
            title = colorOption.name,
            description = 'Set secondary color to ' .. colorOption.name,
            metadata = {
                {label = 'Status', value = (secondaryColor == colorOption.color) and 'Active' or 'Inactive'}
            },
            onSelect = function()
                SetVehicleColours(vehicle, primaryColor, colorOption.color)
                lib.notify({
                    title = 'Color Applied',
                    description = 'Secondary color set to ' .. colorOption.name,
                    type = 'success',
                    duration = 5000
                })
                OpenColorsMenu()
            end
        })
    end

    lib.registerContext({
        id = 'primary_color',
        title = 'Primary Colors',
        menu = 'ColorsMenu',
        options = primaryOptions,
        close = false
    })

    lib.registerContext({
        id = 'secondary_color',
        title = 'Secondary Colors',
        menu = 'ColorsMenu',
        options = secondaryOptions,
        close = false
    })

    lib.showContext('ColorsMenu')
end

-- Pearlescent Color Menu
function OpenPearlescentMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    
    local pearlescentOptions = {
        { name = "Black", color = 0 },
        { name = "Carbon Black", color = 147 },
        { name = "Graphite", color = 1 },
        { name = "Black Steel", color = 2 },
        { name = "Dark Steel", color = 3 },
        { name = "Silver", color = 4 },
        { name = "Red", color = 27 },
        { name = "Torino Red", color = 28 },
        { name = "Formula Red", color = 29 },
        { name = "Blue", color = 64 },
        { name = "Dark Blue", color = 62 },
        { name = "White", color = 111 },
        { name = "Frost White", color = 112 }
    }

    local options = {}
    
    for _, colorOption in pairs(pearlescentOptions) do
        local isActive = (pearlescentColor == colorOption.color)
        
        table.insert(options, {
            title = colorOption.name,
            description = 'Set pearlescent color to ' .. colorOption.name,
            metadata = {
                {label = 'Status', value = isActive and 'Active' or 'Inactive'}
            },
            onSelect = function()
                SetVehicleExtraColours(vehicle, colorOption.color, wheelColor)
                lib.notify({
                    title = 'Pearlescent Applied',
                    description = 'Pearlescent color set to ' .. colorOption.name,
                    type = 'success',
                    duration = 5000
                })
                OpenPearlescentMenu()
            end
        })
    end

    lib.registerContext({
        id = 'PearlescentMenu',
        title = 'Pearlescent Colors',
        options = options,
        menu = 'ColorsMenu',
        close = false
    })
    lib.showContext('PearlescentMenu')
end

-- Wheels Menu
function OpenWheelsMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local wheelType = GetVehicleWheelType(vehicle)

    local wheelTypeOptions = {
        { name = "Sport", type = 0 },
        { name = "Muscle", type = 1 },
        { name = "Lowrider", type = 2 },
        { name = "SUV", type = 3 },
        { name = "Offroad", type = 4 },
        { name = "Tuner", type = 5 },
        { name = "Bike Wheels", type = 6 },
        { name = "High End", type = 7 }
    }
    
    local options = {}
    
    for _, wheelOption in pairs(wheelTypeOptions) do
        local isActive = (wheelType == wheelOption.type)
        
        table.insert(options, {
            title = wheelOption.name,
            description = 'Switch to ' .. wheelOption.name .. ' wheels',
            metadata = {
                {label = 'Status', value = isActive and 'Active' or 'Inactive'}
            },
            onSelect = function()
                SetVehicleWheelType(vehicle, wheelOption.type)
                lib.notify({
                    title = 'Wheel Type Changed',
                    description = 'Changed to ' .. wheelOption.name .. ' wheels',
                    type = 'success',
                    duration = 5000
                })
                OpenWheelSelectionMenu(wheelOption.type)
            end
        })
    end

    -- Add wheel color option
    table.insert(options, {
        title = 'Wheel Color',
        description = 'Change the color of wheels',
        onSelect = function()
            OpenWheelColorMenu()
        end
    })

    lib.registerContext({
        id = 'WheelsMenu',
        title = 'Vehicle Wheels',
        options = options,
        menu = 'AppearanceMenu',
        close = false
    })
    lib.showContext('WheelsMenu')
end

-- Wheel Style Selection Menu
function OpenWheelSelectionMenu(wheelType)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local options = {}

    -- Get the number of wheel mods available
    local numWheels = GetNumVehicleMods(vehicle, 23) -- 23 = wheels
    local currentWheel = GetVehicleMod(vehicle, 23)
    
    for i = -1, numWheels - 1 do
        local title = i == -1 and "Stock Wheels" or "Wheel " .. (i + 1)
        local isActive = (currentWheel == i)
        
        table.insert(options, {
            title = title,
            metadata = {
                {label = 'Status', value = isActive and 'Active' or 'Inactive'}
            },
            onSelect = function()
                SetVehicleMod(vehicle, 23, i, GetVehicleModVariation(vehicle, 23))
                if GetVehicleClass(vehicle) == 8 then -- Motorcycle
                    SetVehicleMod(vehicle, 24, i, GetVehicleModVariation(vehicle, 24))
                end
                
                lib.notify({
                    title = 'Wheels Changed',
                    description = 'Applied ' .. title,
                    type = 'success',
                    duration = 5000
                })
                
                OpenWheelSelectionMenu(wheelType)
            end
        })
    end

    lib.registerContext({
        id = 'WheelSelectionMenu',
        title = 'Select Wheels',
        options = options,
        menu = 'WheelsMenu',
        close = false
    })
    lib.showContext('WheelSelectionMenu')
end

-- Wheel Color Menu
function OpenWheelColorMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local pearlescent, wheelColor = GetVehicleExtraColours(vehicle)
    
    local colorOptions = {
        { name = "Black", color = 0 },
        { name = "Carbon Black", color = 147 },
        { name = "Graphite", color = 1 },
        { name = "Dark Steel", color = 3 },
        { name = "Silver", color = 4 },
        { name = "Red", color = 27 },
        { name = "Blue", color = 64 },
        { name = "White", color = 111 }
    }

    local options = {}
    
    for _, colorOption in pairs(colorOptions) do
        local isActive = (wheelColor == colorOption.color)
        
        table.insert(options, {
            title = colorOption.name,
            description = 'Set wheel color to ' .. colorOption.name,
            metadata = {
                {label = 'Status', value = isActive and 'Active' or 'Inactive'}
            },
            onSelect = function()
                SetVehicleExtraColours(vehicle, pearlescent, colorOption.color)
                lib.notify({
                    title = 'Wheel Color Applied',
                    description = 'Wheel color set to ' .. colorOption.name,
                    type = 'success',
                    duration = 5000
                })
                OpenWheelColorMenu()
            end
        })
    end

    lib.registerContext({
        id = 'WheelColorMenu',
        title = 'Wheel Colors',
        options = options,
        menu = 'WheelsMenu',
        close = false
    })
    lib.showContext('WheelColorMenu')
end

-- Save Vehicle Configuration
function SaveVehicleConfig()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if vehicle == 0 then
        lib.notify({
            title = 'Error',
            description = 'You need to be in a vehicle to save configuration',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    local vehicleProps = GetVehicleProperties(vehicle)
    local vehicleModel = GetEntityModel(vehicle)
    local vehicleModelName = GetDisplayNameFromVehicleModel(vehicleModel)
    
    -- Save to database via server
    TriggerServerEvent('vehiclemods:server:saveModifications', vehicleModelName, json.encode(vehicleProps))
    
    lib.notify({
        title = 'Configuration Saved',
        description = 'Your vehicle configuration has been saved.',
        type = 'success',
        duration = 5000
    })
end

-- Function to get all vehicle properties
function GetVehicleProperties(vehicle)
    if DoesEntityExist(vehicle) then
        -- Get the colors
        local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
        local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
        
        -- Get neon status and color
        local neonEnabled = {}
        for i = 0, 3 do
            neonEnabled[i] = IsVehicleNeonLightEnabled(vehicle, i)
        end
        local neonColor = {GetVehicleNeonLightsColour(vehicle)}
        
        -- Get extras
        local extras = {}
        for extraId = 0, 20 do
            if DoesExtraExist(vehicle, extraId) then
                extras[extraId] = IsVehicleExtraTurnedOn(vehicle, extraId)
            end
        end
        
        local tyreSmokeColor = {GetVehicleTyreSmokeColor(vehicle)}
        local livery = GetVehicleLivery(vehicle)
        local modLivery = GetVehicleMod(vehicle, 48)
        
        return {
            model = GetEntityModel(vehicle),
            plate = GetVehicleNumberPlateText(vehicle),
            plateIndex = GetVehicleNumberPlateTextIndex(vehicle),
            bodyHealth = GetVehicleBodyHealth(vehicle),
            engineHealth = GetVehicleEngineHealth(vehicle),
            tankHealth = GetVehiclePetrolTankHealth(vehicle),
            fuelLevel = GetVehicleFuelLevel(vehicle),
            dirtLevel = GetVehicleDirtLevel(vehicle),
            color1 = colorPrimary,
            color2 = colorSecondary,
            pearlescentColor = pearlescentColor,
            wheelColor = wheelColor,
            wheels = GetVehicleWheelType(vehicle),
            windowTint = GetVehicleWindowTint(vehicle),
            neonEnabled = neonEnabled,
            neonColor = neonColor,
            extras = extras,
            tyreSmokeColor = tyreSmokeColor,
            modSpoilers = GetVehicleMod(vehicle, 0),
            modFrontBumper = GetVehicleMod(vehicle, 1),
            modRearBumper = GetVehicleMod(vehicle, 2),
            modSideSkirt = GetVehicleMod(vehicle, 3),
            modExhaust = GetVehicleMod(vehicle, 4),
            modFrame = GetVehicleMod(vehicle, 5),
            modGrille = GetVehicleMod(vehicle, 6),
            modHood = GetVehicleMod(vehicle, 7),
            modFender = GetVehicleMod(vehicle, 8),
            modRightFender = GetVehicleMod(vehicle, 9),
            modRoof = GetVehicleMod(vehicle, 10),
            modEngine = GetVehicleMod(vehicle, 11),
            modBrakes = GetVehicleMod(vehicle, 12),
            modTransmission = GetVehicleMod(vehicle, 13),
            modHorns = GetVehicleMod(vehicle, 14),
            modSuspension = GetVehicleMod(vehicle, 15),
            modArmor = GetVehicleMod(vehicle, 16),
            modTurbo = IsToggleModOn(vehicle, 18),
            modSmokeEnabled = IsToggleModOn(vehicle, 20),
            modXenon = IsToggleModOn(vehicle, 22),
            modFrontWheels = GetVehicleMod(vehicle, 23),
            modBackWheels = GetVehicleMod(vehicle, 24),
            modPlateHolder = GetVehicleMod(vehicle, 25),
            modVanityPlate = GetVehicleMod(vehicle, 26),
            modTrimA = GetVehicleMod(vehicle, 27),
            modOrnaments = GetVehicleMod(vehicle, 28),
            modDashboard = GetVehicleMod(vehicle, 29),
            modDial = GetVehicleMod(vehicle, 30),
            modDoorSpeaker = GetVehicleMod(vehicle, 31),
            modSeats = GetVehicleMod(vehicle, 32),
            modSteeringWheel = GetVehicleMod(vehicle, 33),
            modShifterLeavers = GetVehicleMod(vehicle, 34),
            modAPlate = GetVehicleMod(vehicle, 35),
            modSpeakers = GetVehicleMod(vehicle, 36),
            modTrunk = GetVehicleMod(vehicle, 37),
            modHydrolic = GetVehicleMod(vehicle, 38),
            modEngineBlock = GetVehicleMod(vehicle, 39),
            modAirFilter = GetVehicleMod(vehicle, 40),
            modStruts = GetVehicleMod(vehicle, 41),
            modArchCover = GetVehicleMod(vehicle, 42),
            modAerials = GetVehicleMod(vehicle, 43),
            modTrimB = GetVehicleMod(vehicle, 44),
            modTank = GetVehicleMod(vehicle, 45),
            modWindows = GetVehicleMod(vehicle, 46),
            modLivery = modLivery,
            livery = livery
        }
    else
        return nil
    end
end

-- Helper function to get vehicle class name
function GetVehicleClassNameFromVehicleClass(vehicleClass)
    local classNames = {
        [0] = "Compact",
        [1] = "Sedan",
        [2] = "SUV",
        [3] = "Coupe",
        [4] = "Muscle",
        [5] = "Sports Classic",
        [6] = "Sports",
        [7] = "Super",
        [8] = "Motorcycle",
        [9] = "Off-road",
        [10] = "Industrial",
        [11] = "Utility",
        [12] = "Van",
        [13] = "Cycle",
        [14] = "Boat",
        [15] = "Helicopter",
        [16] = "Plane",
        [17] = "Service",
        [18] = "Emergency",
        [19] = "Military",
        [20] = "Commercial",
        [21] = "Train",
        [22] = "Open Wheel"
    }
    
    return classNames[vehicleClass] or "Unknown"
end

-- Get vehicle manufacturer helper function
function GetVehicleManufacturer(modelHash)
    local vehicleMake = "Unknown"
    
    local makeHash = GetMakeNameFromVehicleModel(modelHash)
    local makeName = GetLabelText(makeHash)
    
    if makeName and makeName ~= "" then
        vehicleMake = makeName
    else
        local displayName = GetDisplayNameFromVehicleModel(modelHash)
        if displayName then
            local parts = {}
            for part in string.gmatch(displayName, "%S+") do
                table.insert(parts, part)
            end
            
            if #parts > 0 then
                vehicleMake = parts[1]
            end
        end
    end
    
    return vehicleMake
end

-- Event handlers for custom liveries
RegisterNetEvent('vehiclemods:client:updateCustomLiveries')
AddEventHandler('vehiclemods:client:updateCustomLiveries', function(liveries)
    Config.CustomLiveries = liveries
    if Config.Debug then
        print("^2INFO:^0 Custom liveries updated from server")
    end
end)

-- Initialize client on resource start
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then 
        return 
    end
    
    TriggerServerEvent('vehiclemods:server:requestCustomLiveries')
    print("^2INFO:^0 Vehicle Modification System initialized successfully on client.")
end)

-- Create blips and markers for modification zones
CreateThread(function()
    if Config.ShowBlips then
        for _, zone in ipairs(Config.ModificationZones) do
            -- Create blip
            local blip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
            
            -- Set blip properties based on zone type
            if zone.type == "police" then
                SetBlipSprite(blip, 60)  -- Police station sprite
                SetBlipColour(blip, 38)  -- Blue color
            elseif zone.type == "fire" then
                SetBlipSprite(blip, 61)  -- Fire station sprite
                SetBlipColour(blip, 1)   -- Red color
            else
                SetBlipSprite(blip, 446) -- Default wrench icon
                SetBlipColour(blip, 0)   -- White color
            end
            
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.8)
            SetBlipAsShortRange(blip, true)
            
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(zone.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- Draw markers at modification zones when nearby
CreateThread(function()
    while Config.ShowMarkers do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearZone = false
        
        for _, zone in ipairs(Config.ModificationZones) do
            local distance = #(playerCoords - zone.coords)
            
            if distance < 50.0 then
                nearZone = true
                
                -- Draw marker
                local markerColor = (zone.type == "police") and {0, 0, 255, 100} or {255, 0, 0, 100}
                DrawMarker(1, -- Marker type
                    zone.coords.x, zone.coords.y, zone.coords.z - 1.0, -- Coordinates
                    0.0, 0.0, 0.0, -- Direction
                    0.0, 0.0, 0.0, -- Rotation
                    zone.radius * 2.0, zone.radius * 2.0, 1.0, -- Scale
                    markerColor[1], markerColor[2], markerColor[3], markerColor[4], -- RGBA color
                    false, true, 2, false, nil, nil, false -- Options
                )
                
                -- Draw hint when in a vehicle within the zone
                if distance < zone.radius and IsPedInAnyVehicle(playerPed, false) and 
                   GetPedInVehicleSeat(GetVehiclePedIsIn(playerPed, false), -1) == playerPed then
                    
                    -- Check if it's an emergency vehicle when restriction is on
                    local veh = GetVehiclePedIsIn(playerPed, false)
                    if not Config.EmergencyVehiclesOnly or Config.IsEmergencyVehicle(veh) then
                        DisplayHelpTextThisFrame("Press ~INPUT_CONTEXT~ to modify this vehicle", false)
                        if IsControlJustReleased(0, 51) then -- E key
                            TriggerEvent('vehiclemods:client:openVehicleModMenu')
                        end
                    end
                end
            end
        end
        
        -- Optimization: Check less frequently when far from any zone
        Wait(nearZone and 0 or 1000)
    end
end)

-- Notify players when entering/exiting modification zones
CreateThread(function()
    local inZone = false
    local currentZoneName = nil
    
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local foundZone = false
        local zoneName = nil
        
        for _, zone in ipairs(Config.ModificationZones) do
            local distance = #(playerCoords - zone.coords)
            if distance <= zone.radius then
                foundZone = true
                zoneName = zone.name
                break
            end
        end
        
        -- Notify when entering a new zone
        if foundZone and (not inZone or zoneName ~= currentZoneName) then
            local vehicleRestriction = Config.EmergencyVehiclesOnly and " emergency" or ""
            lib.notify({
                title = 'Vehicle Modification Zone',
                description = 'Entered ' .. zoneName .. '. Press E to modify' .. vehicleRestriction .. ' vehicles.',
                type = 'info',
                duration = 5000
            })
            inZone = true
            currentZoneName = zoneName
        elseif not foundZone and inZone then
            -- Notify when leaving zone
            lib.notify({
                title = 'Leaving Modification Zone',
                description = 'Exited ' .. currentZoneName,
                type = 'info',
                duration = 3000
            })
            inZone = false
            currentZoneName = nil
        end
        
        -- Check every second to avoid performance impact
        Wait(1000)
    end
end)
