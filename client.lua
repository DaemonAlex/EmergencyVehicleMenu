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
