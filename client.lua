AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if not Config then
        print("^1CRITICAL ERROR:^0 Config not loaded!")
        return
    end
    
    if not Config.ModificationZones or #Config.ModificationZones == 0 then
        print("^3WARNING:^0 No modification zones configured!")
    end
    
    if not Config.EnabledModifications then
        print("^3WARNING:^0 No modifications enabled in config!")
    end
    
    print("^2SUCCESS:^0 Vehicle Modification System client initialized")
end)

if not Config then
    print("^1ERROR:^0 Config is not loaded! Check fxmanifest.lua.")
    return
end

-- Performance optimization variables
local nearModificationZone = false
local lastZoneCheck = 0
local ZONE_CHECK_INTERVAL = 1000
local TEXTURE_LOAD_TIMEOUT = 300
local loadedTextures = {}

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

-- Display help text function
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

-- Enhanced custom livery event handler with proper timeout and cleanup
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
                if loadedTextures then
                    loadedTextures[oldDict] = nil
                end
            end
        end
        
        ActiveCustomLiveries[vehicleEntityId] = {
            file = liveryFile,
            dict = textureDict,
            model = vehicleModelName
        }
        
        -- Track loaded texture
        if not loadedTextures then loadedTextures = {} end
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

-- Save Vehicle Configuration with enhanced error handling
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

-- Function to get all vehicle properties
function GetVehicleProperties(vehicle)
    if not DoesEntityExist(vehicle) then
        return nil
    end
    
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
end

function LoadVehicleConfig(vehicle)
    local vehicleModel = GetEntityModel(vehicle)
    local vehicleModelName = GetDisplayNameFromVehicleModel(vehicleModel)
    
    if not vehicleModelName or vehicleModelName == "" then
        return
    end
    
    -- Request configuration from server
    TriggerServerEvent('vehiclemods:server:requestVehicleConfig', vehicleModelName)
end

-- Event handler to apply vehicle configuration from server
RegisterNetEvent('vehiclemods:client:applyVehicleConfig')
AddEventHandler('vehiclemods:client:applyVehicleConfig', function(vehicleModel, configJson)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if vehicle == 0 then
        return
    end
    
    local success, vehicleProps = pcall(json.decode, configJson)
    if not success or not vehicleProps then
        if Config.Debug then
            print("^1ERROR:^0 Failed to decode vehicle configuration")
        end
        return
    end
    
    ApplyVehicleProperties(vehicle, vehicleProps)
    
    lib.notify({
        title = 'Configuration Loaded',
        description = 'Vehicle configuration has been applied.',
        type = 'success',
        duration = 5000
    })
end)

-- Function to apply vehicle properties
function ApplyVehicleProperties(vehicle, props)
    if not DoesEntityExist(vehicle) or not props then
        return
    end
    
    -- Apply colors
    if props.color1 and props.color2 then
        SetVehicleColours(vehicle, props.color1, props.color2)
    end
    
    if props.pearlescentColor and props.wheelColor then
        SetVehicleExtraColours(vehicle, props.pearlescentColor, props.wheelColor)
    end
    
    -- Apply window tint
    if props.windowTint then
        SetVehicleWindowTint(vehicle, props.windowTint)
    end
    
    -- Apply wheels
    if props.wheels then
        SetVehicleWheelType(vehicle, props.wheels)
    end
    
    -- Apply mods
    local modTypes = {
        {prop = 'modEngine', id = 11},
        {prop = 'modBrakes', id = 12},
        {prop = 'modTransmission', id = 13},
        {prop = 'modSuspension', id = 15},
        {prop = 'modArmor', id = 16},
        {prop = 'modFrontWheels', id = 23},
        {prop = 'modLivery', id = 48}
    }
    
    for _, mod in pairs(modTypes) do
        if props[mod.prop] and props[mod.prop] ~= -1 then
            SetVehicleMod(vehicle, mod.id, props[mod.prop], false)
        end
    end
    
    -- Apply toggle mods
    if props.modTurbo ~= nil then
        ToggleVehicleMod(vehicle, 18, props.modTurbo)
    end
    
    if props.modXenon ~= nil then
        ToggleVehicleMod(vehicle, 22, props.modXenon)
    end
    
    -- Apply neon
    if props.neonEnabled then
        for i = 0, 3 do
            if props.neonEnabled[i] ~= nil then
                SetVehicleNeonLightEnabled(vehicle, i, props.neonEnabled[i])
            end
        end
    end
    
    if props.neonColor and props.neonColor[1] and props.neonColor[2] and props.neonColor[3] then
        SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
    end
    
    -- Apply extras
    if props.extras then
        for extraId, enabled in pairs(props.extras) do
            if DoesExtraExist(vehicle, tonumber(extraId)) then
                SetVehicleExtra(vehicle, tonumber(extraId), enabled and 0 or 1)
            end
        end
    end
    
    -- Apply livery
    if props.livery and props.livery > -1 then
        SetVehicleLivery(vehicle, props.livery)
    end
end

-- Auto-load configuration when entering a vehicle
CreateThread(function()
    local lastVehicle = 0
    
    while true do
        Wait(1000)
        
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if vehicle ~= 0 and vehicle ~= lastVehicle then
            -- Check if we're in a modification zone and it's an emergency vehicle
            local playerCoords = GetEntityCoords(playerPed)
            local inZone = Config.IsInModificationZone(playerCoords)
            
            if inZone and (not Config.EmergencyVehiclesOnly or Config.IsEmergencyVehicle(vehicle)) then
                LoadVehicleConfig(vehicle)
            end
            
            lastVehicle = vehicle
        elseif vehicle == 0 then
            lastVehicle = 0
        end
    end
end)

RegisterNetEvent('vehiclemods:client:updateCustomLiveries')
AddEventHandler('vehiclemods:client:updateCustomLiveries', function(customLiveries)
    Config.CustomLiveries = customLiveries
    
    if Config.Debug then
        print("^2INFO:^0 Updated custom liveries configuration")
    end
end)

-- Request custom liveries when resource starts
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    TriggerServerEvent('vehiclemods:server:requestCustomLiveries')
end)

CreateThread(function()
    while true do
        Wait(60000) -- Check every minute
        
        if loadedTextures then
            local currentTime = GetGameTimer()
            local toRemove = {}
            
            for textureDict, loadTime in pairs(loadedTextures) do
                -- Remove textures loaded more than 5 minutes ago and not currently in use
                if currentTime - loadTime > 300000 then
                    local inUse = false
                    
                    -- Check if any active custom livery is using this texture
                    if ActiveCustomLiveries then
                        for _, liveryInfo in pairs(ActiveCustomLiveries) do
                            if liveryInfo.dict == textureDict then
                                inUse = true
                                break
                            end
                        end
                    end
                    
                    if not inUse and HasStreamedTextureDictLoaded(textureDict) then
                        SetStreamedTextureDictAsNoLongerNeeded(textureDict)
                        table.insert(toRemove, textureDict)
                        
                        if Config.Debug then
                            print("^3INFO:^0 Cleaned up unused texture: " .. textureDict)
                        end
                    end
                end
            end
            
            -- Remove from tracking
            for _, textureDict in pairs(toRemove) do
                loadedTextures[textureDict] = nil
            end
        end
    end
end)
