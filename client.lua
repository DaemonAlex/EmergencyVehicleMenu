RegisterCommand('modveh', function()
    local job = ''
    local QBCore = exports['qb-core']:GetCoreObject()
        
    if Config.Framework == 'qb-core' or Config.Framework == 'qbx-core' then
        if QBCore and QBCore.Functions then
            local playerData = QBCore.Functions.GetPlayerData()
            job = playerData and playerData.job and playerData.job.name or 'unknown'
        else
            print("^1ERROR:^0 QBCore is not defined, please make sure the qb-core resource is started.")
            job = 'unknown'
        end
    elseif Config.Framework == 'esx' then
        local playerData = ESX.GetPlayerData()
        job = playerData and playerData.job and playerData.job.name or 'unknown'
    elseif Config.Framework == 'standalone' then
        job = 'standalone'
    end

if Config.Framework == 'qb-core' or Config.Framework == 'qbx-core' then
    print("^1ERROR:^0 Access denied for job: " .. job)

    if Config.Framework == 'qb-core' or Config.Framework == 'qbx-core' then
        TriggerEvent('ox_lib:notify', {title = 'Access Denied', description = 'You must be an authorized department to use this.', type = 'error'})
    elseif Config.Framework == 'esx' then
        ESX.ShowNotification('You must be an authorized department to use this.')
    end

    return
end

    print("^2SUCCESS:^0 Access granted. Opening menu...")
    TriggerEvent('vehiclemods:client:openVehicleModMenu')
end, false)

-- Add a keybind to quickly open the menu without typing the command
RegisterKeyMapping('modveh', 'Open Vehicle Modification Menu', 'keyboard', 'F7')

-- Initialize variables
ActiveCustomLiveries = {}
AvailableLiveryFiles = {}

RegisterNetEvent('vehiclemods:client:openVehicleModMenu')
AddEventHandler('vehiclemods:client:openVehicleModMenu', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local vehicleTitle = "Emergency Vehicle Menu"
    local vehicleInfo = nil
    
    if vehicle ~= 0 then
        local vehicleModel = GetEntityModel(vehicle)
        local vehicleModelName = GetDisplayNameFromVehicleModel(vehicleModel)
        local vehicleMake = GetMakeNameFromVehicleModel(vehicleModel)
        
        vehicleTitle = vehicleModelName .. " Modifications"
        vehicleInfo = {
            {label = 'Make', value = vehicleMake ~= "" and vehicleMake or "Unknown"},
            {label = 'Model', value = vehicleModelName},
            {label = 'Class', value = GetVehicleClassNameFromVehicleClass(GetVehicleClass(vehicle))}
        }
    end
    
    local options = {
        {
            title = 'Liveries',
            description = 'Select a vehicle livery.',
            onSelect = function()
                OpenLiveryMenu()
            end
        },
        {
            title = 'Custom Liveries',
            description = 'Apply custom YFT liveries.',
            onSelect = function()
                OpenCustomLiveriesMenu()
            end
        },
        {
            title = 'Vehicle Appearance',
            description = 'Customize vehicle appearance.',
            onSelect = function()
                OpenAppearanceMenu()
            end
        },
        {
            title = 'Performance Mods',
            description = 'Install performance upgrades.',
            onSelect = function()
                OpenPerformanceMenu()
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
            description = 'Open or close individual doors.',
            onSelect = function()
                OpenDoorsMenu()
            end
        },
        {
            title = 'Save Configuration',
            description = 'Save current vehicle setup.',
            onSelect = function()
                SaveVehicleConfig()
            end
        },
        {
            title = 'Close Menu',
            description = 'Exit the vehicle modification menu',
            onSelect = function()
                lib.hideContext()
            end
        }
    }

    lib.registerContext({
        id = 'EmergencyVehicleMenu',
        title = vehicleTitle,
        metadata = vehicleInfo,
        options = options,
        close = false
    })
    lib.showContext('EmergencyVehicleMenu')
end)

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
    }
    
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
        menu = 'EmergencyVehicleMenu',
        close = false
    })
    lib.showContext('LiveryMenu')
end


function ApplyCustomLivery(vehicle, liveryFile)
    if not vehicle or vehicle == 0 then
        lib.notify({
            title = 'Error',
            description = 'No vehicle found to apply livery',
            type = 'error',
            duration = 5000
        })
        return false
    end
    
    local vehicleModel = GetEntityModel(vehicle)
    local vehicleModelName = GetDisplayNameFromVehicleModel(vehicleModel):lower()
    
    TriggerServerEvent('vehiclemods:server:applyCustomLivery', NetworkGetNetworkIdFromEntity(vehicle), vehicleModelName, liveryFile)
    
    return true
end

-- Event to set a custom livery on a specific vehicle
RegisterNetEvent('vehiclemods:client:setCustomLivery')
AddEventHandler('vehiclemods:client:setCustomLivery', function(netId, vehicleModelName, liveryFile)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    
    if not vehicle or not DoesEntityExist(vehicle) then
        return
    end
    
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
        
        local success = ApplyVehicleTexture(vehicle, textureDict, vehicleModelName)
        
        if success then
            print("^2INFO:^0 Applied custom livery " .. liveryFile .. " to vehicle")
        else
            print("^1ERROR:^0 Failed to apply custom livery " .. liveryFile)
        end
    else
        print("^1ERROR:^0 Failed to load texture dictionary for livery: " .. textureDict)
    end
end)

function ApplyVehicleTexture(vehicle, textureDict, vehicleModelName)

    local liveryModCount = GetNumVehicleMods(vehicle, 48)
    if liveryModCount > 0 then
        SetVehicleMod(vehicle, 48, 0, false)
    else
        local liveryCount = GetVehicleLiveryCount(vehicle)
        if liveryCount > 0 then
            SetVehicleLivery(vehicle, 1) -- Use first livery as base
        end
    end
    
    SetEntityRoutingBucket(vehicle, 100 + GetEntityRoutingBucket(vehicle)) -- Mark as modified
    Wait(50)
    SetEntityRoutingBucket(vehicle, GetEntityRoutingBucket(vehicle) - 100) -- Restore
    
    return true
end

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

function OpenCustomLiveriesMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local job = ''
    if Config.Framework == 'qb-core' or Config.Framework == 'qbx-core' then
        local QBCore = exports['qb-core']:GetCoreObject()
        if QBCore and QBCore.Functions then
            local playerData = QBCore.Functions.GetPlayerData()
            job = playerData and playerData.job and playerData.job.name or 'unknown'
        end
    elseif Config.Framework == 'esx' then
        local playerData = ESX.GetPlayerData()
        job = playerData and playerData.job and playerData.job.name or 'unknown'
    elseif Config.Framework == 'standalone' then
        job = 'standalone'
    end
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
                    if ApplyCustomLivery(vehicle, livery.file) then
                        lib.notify({
                            title = 'Livery Applied',
                            description = 'Applied ' .. livery.name .. ' livery',
                            type = 'success',
                            duration = 5000
                        })
                        OpenCustomLiveriesMenu()
                    end
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
    
    if Config.JobAccess[job] then
        table.insert(options, {
            title = 'Add New Livery',
            description = 'Add a new custom livery for this vehicle',
            onSelect = function()
                OpenAddCustomLiveryMenu(vehicleModelName)
            end
        })
    end

    lib.registerContext({
        id = 'CustomLiveriesMenu',
        title = 'Custom Liveries',
        options = options,
        menu = 'EmergencyVehicleMenu',
        close = false
    })
    lib.showContext('CustomLiveriesMenu')
end

function OpenAddCustomLiveryMenu(vehicleModelName)
    lib.showTextInput({
        title = 'Add Custom Livery',
        description = 'Enter the name and YFT file for the new livery:',
        fields = {
            { label = 'Livery Name', name = 'name', type = 'text', required = true, placeholder = 'e.g. Police Livery 1' },
            { label = 'YFT File Path', name = 'file', type = 'text', required = true, placeholder = 'liveries/' .. vehicleModelName .. '_livery1.yft' }
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

function OpenCosmeticModsMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    local modTypes = {
        { name = "Spoiler", id = 0 },
        { name = "Front Bumper", id = 1 },
        { name = "Rear Bumper", id = 2 },
        { name = "Side Skirt", id = 3 },
        { name = "Exhaust", id = 4 },
        { name = "Frame", id = 5 },
        { name = "Grille", id = 6 },
        { name = "Hood", id = 7 },
        { name = "Fender", id = 8 },
        { name = "Right Fender", id = 9 },
        { name = "Roof", id = 10 },
        { name = "Xenon Headlights", id = 22 },
        { name = "Front Wheels", id = 23 },
        { name = "License Plate Frames", id = 25 },
        { name = "Plate Holder", id = 26 },
        { name = "Interior Trim", id = 27 },
        { name = "Dashboard", id = 29 },
        { name = "Dial", id = 30 },
        { name = "Door Speaker", id = 31 },
        { name = "Seats", id = 32 },
        { name = "Steering Wheel", id = 33 },
        { name = "Shifter Leavers", id = 34 },
        { name = "Plaques", id = 35 },
        { name = "Speakers", id = 36 },
        { name = "Trunk", id = 37 },
        { name = "Hydraulics", id = 38 },
        { name = "Engine Block", id = 39 },
        { name = "Air Filter", id = 40 },
        { name = "Struts", id = 41 },
        { name = "Arch Cover", id = 42 },
        { name = "Aerials", id = 43 },
        { name = "Trim", id = 44 },
        { name = "Tank", id = 45 },
        { name = "Windows", id = 46 },
        { name = "Custom Livery", id = 48 }
    }
    
    local options = {}
    
    -- Add option for each mod type
    for _, modType in pairs(modTypes) do
        local numMods = GetNumVehicleMods(vehicle, modType.id)
        if numMods > 0 then
            table.insert(options, {
                title = modType.name,
                description = 'Available upgrades: ' .. numMods,
                onSelect = function()
                    OpenModSelectionMenu(modType.id, modType.name)
                end
            })
        end
    end
    
    if #options == 0 then
        table.insert(options, {
            title = 'No mods available',
            description = 'This vehicle has no cosmetic mods available',
            onSelect = function() end
        })
    end

    lib.registerContext({
        id = 'CosmeticModsMenu',
        title = 'Cosmetic Mods',
        options = options,
        menu = 'AppearanceMenu',
        close = false
    })
    lib.showContext('CosmeticModsMenu')
end

function OpenModSelectionMenu(modType, modTypeName)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local options = {}
    local numMods = GetNumVehicleMods(vehicle, modType)
    local currentMod = GetVehicleMod(vehicle, modType)
    
    table.insert(options, {
        title = 'Stock ' .. modTypeName,
        description = 'Remove ' .. modTypeName .. ' modifications',
        metadata = {
            {label = 'Status', value = (currentMod == -1) and 'Active' or 'Inactive'}
        },
        onSelect = function()
            SetVehicleMod(vehicle, modType, -1, false)
            lib.notify({
                title = 'Mod Removed',
                description = modTypeName .. ' set to stock',
                type = 'success',
                duration = 5000
            })
            OpenModSelectionMenu(modType, modTypeName)
        end
    })
    
    for i = 0, numMods - 1 do
        local modName = GetLabelText(GetModTextLabel(vehicle, modType, i))
        if modName == "NULL" then
            modName = modTypeName .. " #" .. (i + 1)
        end
        
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
                    title = 'Mod Applied',
                    description = 'Applied ' .. modName,
                    type = 'success',
                    duration = 5000
                })
                OpenModSelectionMenu(modType, modTypeName)
            end
        })
    end

    lib.registerContext({
        id = 'ModSelectionMenu',
        title = modTypeName .. ' Options',
        options = options,
        menu = 'CosmeticModsMenu',
        close = false
    })
    lib.showContext('ModSelectionMenu')
end

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
        menu = 'EmergencyVehicleMenu',
        close = false
    })
    lib.showContext('PerformanceMenu')
end

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
        menu = 'EmergencyVehicleMenu',
        close = false
    })
    lib.showContext('ExtrasMenu')
end

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
        menu = 'EmergencyVehicleMenu',
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
        },
        {
            title = 'Cosmetic Mods',
            description = 'Apply various cosmetic mods.',
            onSelect = function()
                OpenCosmeticModsMenu()
            end
        }
    }

    lib.registerContext({
        id = 'AppearanceMenu',
        title = 'Vehicle Appearance',
        options = options,
        menu = 'EmergencyVehicleMenu',
        close = false
    })
    lib.showContext('AppearanceMenu')
end

function OpenColorsMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local primaryColor, secondaryColor = GetVehicleColours(vehicle)
    
    local colorOptions = {
        { name = "Black", color = 0 },
        { name = "Carbon Black", color = 147 },
        { name = "Graphite", color = 1 },
        { name = "Anhracite Black", color = 11 },
        { name = "Black Steel", color = 2 },
        { name = "Dark Steel", color = 3 },
        { name = "Silver", color = 4 },
        { name = "Bluish Silver", color = 5 },
        { name = "Rolled Steel", color = 6 },
        { name = "Shadow Silver", color = 7 },
        { name = "Stone Silver", color = 8 },
        { name = "Midnight Silver", color = 9 },
        { name = "Cast Iron Silver", color = 10 },
        { name = "Red", color = 27 },
        { name = "Torino Red", color = 28 },
        { name = "Formula Red", color = 29 },
        { name = "Lava Red", color = 150 },
        { name = "Blaze Red", color = 30 },
        { name = "Grace Red", color = 31 },
        { name = "Garnet Red", color = 32 },
        { name = "Sunset Red", color = 33 },
        { name = "Cabernet Red", color = 34 },
        { name = "Wine Red", color = 143 },
        { name = "Candy Red", color = 35 },
        { name = "Hot Pink", color = 135 },
        { name = "Pfsiter Pink", color = 137 },
        { name = "Salmon Pink", color = 136 },
        { name = "Sunrise Orange", color = 36 },
        { name = "Orange", color = 38 },
        { name = "Bright Orange", color = 138 },
        { name = "Gold", color = 99 },
        { name = "Bronze", color = 90 },
        { name = "Yellow", color = 88 },
        { name = "Race Yellow", color = 89 },
        { name = "Dew Yellow", color = 91 },
        { name = "Dark Green", color = 49 },
        { name = "Racing Green", color = 50 },
        { name = "Sea Green", color = 51 },
        { name = "Olive Green", color = 52 },
        { name = "Bright Green", color = 53 },
        { name = "Gasoline Green", color = 54 },
        { name = "Blue", color = 64 },
        { name = "Midnight Blue", color = 141 },
        { name = "Dark Blue", color = 62 },
        { name = "Saxon Blue", color = 63 },
        { name = "Navy Blue", color = 65 },
        { name = "Harbor Blue", color = 66 },
        { name = "Diamond Blue", color = 67 },
        { name = "Surf Blue", color = 68 },
        { name = "Ultra Blue", color = 70 },
        { name = "Light Blue", color = 74 },
        { name = "Police Blue", color = 127 },
        { name = "White", color = 111 },
        { name = "Frost White", color = 112 },
    }

    local primaryOptions = {}
    local secondaryOptions = {}

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

function OpenPearlescentMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    
    local pearlescentOptions = {
        { name = "Black", color = 0 },
        { name = "Carbon Black", color = 147 },
        { name = "Graphite", color = 1 },
        { name = "Anhracite Black", color = 11 },
        { name = "Black Steel", color = 2 },
        { name = "Dark Steel", color = 3 },
        { name = "Silver", color = 4 },
        { name = "Bluish Silver", color = 5 },
        { name = "Rolled Steel", color = 6 },
        { name = "Shadow Silver", color = 7 },
        { name = "Stone Silver", color = 8 },
        { name = "Midnight Silver", color = 9 },
        { name = "Cast Iron Silver", color = 10 },
        { name = "Red", color = 27 },
        { name = "Torino Red", color = 28 },
        { name = "Formula Red", color = 29 },
        { name = "Lava Red", color = 150 },
        { name = "Blaze Red", color = 30 },
        { name = "Grace Red", color = 31 },
        { name = "Garnet Red", color = 32 },
        { name = "Sunset Red", color = 33 },
        { name = "Cabernet Red", color = 34 },
        { name = "Wine Red", color = 143 },
        { name = "Candy Red", color = 35 },
        { name = "Hot Pink", color = 135 },
        { name = "Pfsiter Pink", color = 137 },
        { name = "Salmon Pink", color = 136 },
        { name = "Sunrise Orange", color = 36 },
        { name = "Orange", color = 38 },
        { name = "Bright Orange", color = 138 },
        { name = "Gold", color = 99 },
        { name = "Bronze", color = 90 },
        { name = "Yellow", color = 88 },
        { name = "Race Yellow", color = 89 },
        { name = "Dew Yellow", color = 91 },
        { name = "Dark Green", color = 49 },
        { name = "Racing Green", color = 50 },
        { name = "Sea Green", color = 51 },
        { name = "Olive Green", color = 52 },
        { name = "Bright Green", color = 53 },
        { name = "Gasoline Green", color = 54 },
        { name = "Blue", color = 64 },
        { name = "Midnight Blue", color = 141 },
        { name = "Dark Blue", color = 62 },
        { name = "Saxon Blue", color = 63 },
        { name = "Navy Blue", color = 65 },
        { name = "Harbor Blue", color = 66 },
        { name = "Diamond Blue", color = 67 },
        { name = "Surf Blue", color = 68 },
        { name = "Ultra Blue", color = 70 },
        { name = "Light Blue", color = 74 },
        { name = "Police Blue", color = 127 },
        { name = "White", color = 111 },
        { name = "Frost White", color = 112 },
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

    local currentWheelType = "Unknown"
    for _, wheel in pairs(wheelTypeOptions) do
        if wheel.type == wheelType then
            currentWheelType = wheel.name
            break
        end
    end

    table.insert(options, {
        title = 'Select ' .. currentWheelType .. ' Wheel',
        description = 'Choose a wheel style for current type: ' .. currentWheelType,
        onSelect = function()
            OpenWheelSelectionMenu(wheelType)
        end
    })

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
                -- Also apply to rear wheels (in case of different back wheels)
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

function OpenWheelColorMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local pearlescent, wheelColor = GetVehicleExtraColours(vehicle)
    
    local colorOptions = {
        { name = "Black", color = 0 },
        { name = "Carbon Black", color = 147 },
        { name = "Graphite", color = 1 },
        { name = "Anhracite Black", color = 11 },
        { name = "Black Steel", color = 2 },
        { name = "Dark Steel", color = 3 },
        { name = "Silver", color = 4 },
        { name = "Bluish Silver", color = 5 },
        { name = "Rolled Steel", color = 6 },
        { name = "Shadow Silver", color = 7 },
        { name = "Stone Silver", color = 8 },
        { name = "Midnight Silver", color = 9 },
        { name = "Cast Iron Silver", color = 10 },
        { name = "Red", color = 27 },
        { name = "Torino Red", color = 28 },
        { name = "Formula Red", color = 29 },
        { name = "Lava Red", color = 150 },
        { name = "Blaze Red", color = 30 },
        { name = "Grace Red", color = 31 },
        { name = "Garnet Red", color = 32 },
        { name = "Sunset Red", color = 33 },
        { name = "Cabernet Red", color = 34 },
        { name = "Wine Red", color = 143 },
        { name = "Candy Red", color = 35 },
        { name = "Hot Pink", color = 135 },
        { name = "Pfsiter Pink", color = 137 },
        { name = "Salmon Pink", color = 136 },
        { name = "Sunrise Orange", color = 36 },
        { name = "Orange", color = 38 },
        { name = "Bright Orange", color = 138 },
        { name = "Gold", color = 99 },
        { name = "Bronze", color = 90 },
        { name = "Yellow", color = 88 },
        { name = "Race Yellow", color = 89 },
        { name = "Dew Yellow", color = 91 },
        { name = "Dark Green", color = 49 },
        { name = "Racing Green", color = 50 },
        { name = "Sea Green", color = 51 },
        { name = "Olive Green", color = 52 },
        { name = "Bright Green", color = 53 },
        { name = "Gasoline Green", color = 54 },
        { name = "Blue", color = 64 },
        { name = "Midnight Blue", color = 141 },
        { name = "Dark Blue", color = 62 },
        { name = "Saxon Blue", color = 63 },
        { name = "Navy Blue", color = 65 },
        { name = "Harbor Blue", color = 66 },
        { name = "Diamond Blue", color = 67 },
        { name = "Surf Blue", color = 68 },
        { name = "Ultra Blue", color = 70 },
        { name = "Light Blue", color = 74 },
        { name = "White", color = 111 },
        { name = "Frost White", color = 112 },
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

-- Function to save vehicle config
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

-- Custom function to get all vehicle properties
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
        
        -- Get mods
        local mods = {}
        for modType = 0, 49 do
            mods[modType] = GetVehicleMod(vehicle, modType)
        end
        
        -- Get extras
        local extras = {}
        for extraId = 0, 20 do
            if DoesExtraExist(vehicle, extraId) then
                extras[extraId] = IsVehicleExtraTurnedOn(vehicle, extraId)
            end
        end
        
        -- Handle tyres and windows
        local tyreSmokeColor = {GetVehicleTyreSmokeColor(vehicle)}
        
        -- Check if the vehicle has custom livery
        local livery = GetVehicleLivery(vehicle)
        
        -- Check for mod slot 48 livery (used by newer DLC vehicles and custom liveries)
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
            tyreSmokeColor = tyreSmokeColor,
            modSpoilers = mods[0],
            modFrontBumper = mods[1],
            modRearBumper = mods[2],
            modSideSkirt = mods[3],
            modExhaust = mods[4],
            modFrame = mods[5],
            modGrille = mods[6],
            modHood = mods[7],
            modFender = mods[8],
            modRightFender = mods[9],
            modRoof = mods[10],
            modEngine = mods[11],
            modBrakes = mods[12],
            modTransmission = mods[13],
            modHorns = mods[14],
            modSuspension = mods[15],
            modArmor = mods[16],
            modTurbo = IsToggleModOn(vehicle, 18),
            modSmokeEnabled = IsToggleModOn(vehicle, 20),
            modXenon = IsToggleModOn(vehicle, 22),
            modFrontWheels = mods[23],
            modBackWheels = mods[24],
            modPlateHolder = mods[25],
            modVanityPlate = mods[26],
            modTrimA = mods[27],
            modOrnaments = mods[28],
            modDashboard = mods[29],
            modDial = mods[30],
            modDoorSpeaker = mods[31],
            modSeats = mods[32],
            modSteeringWheel = mods[33],
            modShifterLeavers = mods[34],
            modAPlate = mods[35],
            modSpeakers = mods[36],
            modTrunk = mods[37],
            modHydrolic = mods[38],
            modEngineBlock = mods[39],
            modAirFilter = mods[40],
            modStruts = mods[41],
            modArchCover = mods[42],
            modAerials = mods[43],
            modTrimB = mods[44],
            modTank = mods[45],
            modWindows = mods[46],
            modLivery = modLivery,
            livery = livery,
            extras = extras
        }
    else
        return nil
    end
end

-- Event to receive custom liveries from server
RegisterNetEvent('vehiclemods:client:updateCustomLiveries')
AddEventHandler('vehiclemods:client:updateCustomLiveries', function(customLiveries)
    Config.CustomLiveries = customLiveries
    
    if Config.Debug then
        print("^2INFO:^0 Custom liveries updated from server")
    end
end)

-- Event to receive livery files for a specific vehicle model
RegisterNetEvent('vehiclemods:client:receiveAvailableLiveries')
AddEventHandler('vehiclemods:client:receiveAvailableLiveries', function(vehicleModel, liveryFiles)
    -- Store the list for use in menus
    if not AvailableLiveryFiles then
        AvailableLiveryFiles = {}
    end
    
    AvailableLiveryFiles[vehicleModel] = liveryFiles
    
    -- Notify that files were found
    lib.notify({
        title = 'Livery Files',
        description = 'Found ' .. #liveryFiles .. ' livery files for ' .. vehicleModel,
        type = 'success',
        duration = 5000
    })
end)

-- Request custom liveries from server on resource start
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Initialize variables
    ActiveCustomLiveries = {}
    AvailableLiveryFiles = {}
    
    -- Request custom liveries from server
    Citizen.SetTimeout(1000, function()
        TriggerServerEvent('vehiclemods:server:requestCustomLiveries')
    end)
end)

-- Function to list available YFT files from the vehicle model's liveries folder
function ListAvailableLiveryFiles(vehicleModel)
    TriggerServerEvent('vehiclemods:server:getAvailableLiveries', vehicleModel)
end

-- Helper functions for improved menu usability

-- Function to get vehicle class name from vehicle class ID
function GetVehicleClassNameFromVehicleClass(vehicleClass)
    local vehicleClassNames = {
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
        [13] = "Bicycle",
        [14] = "Boat",
        [15] = "Helicopter",
        [16] = "Plane",
        [17] = "Service",
        [18] = "Emergency",
        [19] = "Military",
        [20] = "Commercial",
        [21] = "Train"
    }
    
    return vehicleClassNames[vehicleClass] or "Unknown"
end

-- Search function for liveries when there are many available
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
    
    -- For custom liveries
    local vehicleModel = GetEntityModel(vehicle)
    local vehicleModelName = GetDisplayNameFromVehicleModel(vehicleModel):lower()
    
    if Config.CustomLiveries and Config.CustomLiveries[vehicleModelName] then
        for _, livery in ipairs(Config.CustomLiveries[vehicleModelName]) do
            if string.find(livery.name:lower(), searchTerm) then
                table.insert(options, {
                    title = livery.name,
                    description = 'Apply ' .. livery.name .. ' custom livery',
                    onSelect = function()
                        if ApplyCustomLivery(vehicle, livery.file) then
                            lib.notify({
                                title = 'Livery Applied',
                                description = 'Applied ' .. livery.name .. ' livery',
                                type = 'success',
                                duration = 5000
                            })
                            FilteredLiveryMenu(searchTerm)
                        end
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
    
    -- Add search option at the top
    table.insert(options, 1, {
        title = 'New Search',
        description = 'Search for a different livery',
        onSelect = function()
            OpenLiverySearchMenu()
        end
    })
    
    -- Add option to show all liveries
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
        menu = 'EmergencyVehicleMenu',
        close = false
    })
    lib.showContext('FilteredLiveryMenu')
end

-- Preview function for liveries before applying
function PreviewLivery(vehicle, liveryIndex)
    -- Store original livery
    local originalLivery = GetVehicleLivery(vehicle)
    
    -- Apply the preview livery
    SetVehicleLivery(vehicle, liveryIndex)
    
    -- Notify user
    lib.notify({
        title = 'Livery Preview',
        description = 'Previewing Livery ' .. liveryIndex .. '. Press ENTER to apply or BACKSPACE to cancel.',
        type = 'info',
        duration = 5000
    })
    
    -- Listen for key presses
    Citizen.CreateThread(function()
        local previewActive = true
        
        while previewActive do
            Citizen.Wait(0)
            
            -- ENTER key to confirm
            if IsControlJustPressed(0, 18) then -- 18 is ENTER key
                previewActive = false
                lib.notify({
                    title = 'Livery Applied',
                    description = 'Applied Livery ' .. liveryIndex .. '.',
                    type = 'success',
                    duration = 5000
                })
            end
            
            -- BACKSPACE key to cancel
            if IsControlJustPressed(0, 177) then -- 177 is BACKSPACE key
                previewActive = false
                -- Restore original livery
                SetVehicleLivery(vehicle, originalLivery)
                lib.notify({
                    title = 'Preview Cancelled',
                    description = 'Restored original livery.',
                    type = 'info',
                    duration = 5000
                })
            end
            
            -- Exit if player leaves vehicle
            if not IsPedInAnyVehicle(PlayerPedId(), false) then
                previewActive = false
                SetVehicleLivery(vehicle, originalLivery)
            end
        end
        
        -- Reopen menu after preview
        OpenLiveryMenu()
    end)
end
