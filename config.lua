Config = {}

-- Auto-Configuration Settings
Config.Debug = true
Config.AutoConfigure = true -- Automatically configure everything
Config.AutoDetectFramework = true -- Automatically detect framework if available
Config.AutoDetectZones = true -- Automatically detect modification zones
Config.AutoDetectVehicles = true -- Automatically detect emergency vehicles

-- Manual Override Settings (set to false to disable auto-config for that feature)
Config.ManualFramework = false -- Set to true to use manual framework setting below
Config.ManualZones = false -- Set to true to use manual zones below
Config.ManualVehicleDetection = false -- Set to true to use manual vehicle list below
Config.ManualJobSystem = false -- Set to true to disable auto job detection

-- Advanced Job-Based Access Control
Config.EnableJobRestrictions = false -- Enable job-based location restrictions (DISABLED for admin use)
Config.EnableGradeRestrictions = false -- Enable grade/level restrictions (DISABLED for admin use)
Config.DisableZoneRestrictions = true -- Bypass zone location checks entirely (ENABLED for admin use anywhere)
Config.AutoDetectJobTables = true -- Auto-detect framework job database tables
Config.CacheJobInfo = true -- Cache job information for performance
Config.JobCacheTimeout = 300000 -- 5 minutes in milliseconds

-- Framework Detection and Compatibility (auto-configured unless ManualFramework = true)
Config.Framework = 'standalone' -- Only used if ManualFramework = true

-- Auto-configured framework-specific settings
Config.FrameworkSettings = {}

-- Auto-configuration function for framework settings
function Config.AutoConfigureFramework()
    local detectedFramework = Config.DetectFramework()
    
    -- Default settings template
    local defaultSettings = {
        esx = {
            jobRestriction = true,
            allowedJobs = {'police', 'ambulance', 'fire'},
            useJobGrades = true,
            minGrade = 0,
            resourceName = 'es_extended'
        },
        qbcore = {
            jobRestriction = true,
            allowedJobs = {'police', 'ambulance', 'fire'},
            useJobGrades = true,
            minGrade = 0,
            resourceName = GetResourceState('qb-core') == 'started' and 'qb-core' or 'qbx_core'
        },
        qbox = {
            jobRestriction = true,
            allowedJobs = {'police', 'ambulance', 'fire'},
            useJobGrades = true,
            minGrade = 0,
            resourceName = 'qbox-core'
        },
        standalone = {
            jobRestriction = false,
            locationOnly = true
        }
    }
    
    -- Auto-configure based on detected framework (unless manual override)
    if not Config.ManualFramework then
        Config.FrameworkSettings = defaultSettings
        Config.Framework = detectedFramework
        if Config.Debug then
            print("^2[AUTO-CONFIG]:^0 Framework auto-configured as: " .. detectedFramework)
        end
    else
        Config.FrameworkSettings = defaultSettings
        if Config.Debug then
            print("^2[AUTO-CONFIG]:^0 Using manual framework configuration: " .. Config.Framework)
        end
    end
    
    -- Auto-configure job system
    if Config.EnableJobRestrictions and not Config.ManualJobSystem then
        Config.AutoConfigureJobSystem()
    end
end

-- Auto-configure job system based on framework
function Config.AutoConfigureJobSystem()
    local framework = Config.Framework
    
    -- Framework-specific database table detection
    Config.JobTables = {
        esx = {
            jobs = "jobs",
            job_grades = "job_grades",
            users = "users",
            userJobField = "job",
            userGradeField = "job_grade",
            identifierField = "identifier"
        },
        qbcore = {
            jobs = "jobs",
            players = "players", 
            userJobField = "job",
            userGradeField = "grade",
            identifierField = "citizenid",
            jobDataColumn = "job" -- JSON column in qbcore
        },
        qbox = {
            jobs = "jobs",
            players = "players",
            userJobField = "job", 
            userGradeField = "grade",
            identifierField = "citizenid"
        }
    }
    
    -- Auto-detect job names based on framework
    Config.JobMappings = {
        police = {"police", "lspd", "bcso", "sahp", "sheriff"},
        fire = {"fire", "lsfd", "firefighter"},
        ambulance = {"ambulance", "ems", "medical"}
    }
    
    if Config.Debug then
        print("^2[AUTO-CONFIG]:^0 Job system configured for " .. framework)
    end
end

-- Auto-configured modification zones
Config.ModificationZones = {}

-- Auto-configuration function for modification zones
function Config.AutoConfigureZones()
    -- Default zones with job restrictions (auto-configured based on framework)
    local defaultZones = {
        -- Police Stations (Police job, grade 4+) - Repositioned to parking areas with car-sized zones
        {
            name = "Mission Row Police Department - Parking Garage",
            coords = vector3(454.2, -1025.1, 28.4),
            radius = 4.0,
            type = "police",
            requiredJob = "police",
            minGrade = 4,
            jobLabel = "Police Officer"
        },
        {
            name = "Davis Sheriff Station - Parking Lot",
            coords = vector3(379.9, -1600.5, 29.3),
            radius = 4.0,
            type = "police",
            requiredJob = "police",
            minGrade = 4,
            jobLabel = "Police Officer"
        },
        {
            name = "Sandy Shores Sheriff Office - Garage",
            coords = vector3(1862.1, 3673.8, 33.7),
            radius = 4.0,
            type = "police",
            requiredJob = "police",
            minGrade = 4,
            jobLabel = "Police Officer"
        },
        {
            name = "Paleto Bay Sheriff Office - Parking",
            coords = vector3(-456.3, 6008.4, 31.3),
            radius = 4.0,
            type = "police",
            requiredJob = "police",
            minGrade = 4,
            jobLabel = "Police Officer"
        },
        {
            name = "Vespucci Police Station - Garage",
            coords = vector3(-1088.6, -834.7, 37.7),
            radius = 4.0,
            type = "police",
            requiredJob = "police",
            minGrade = 4,
            jobLabel = "Police Officer"
        },
        -- Fire Stations (Fire job, grade 4+)
        {
            name = "Los Santos Fire Station 1 - Garage",
            coords = vector3(1193.8, -1464.8, 34.9),
            radius = 4.0,
            type = "fire",
            requiredJob = "fire",
            minGrade = 4,
            jobLabel = "Firefighter"
        },
        {
            name = "Davis Fire Station - Garage",
            coords = vector3(213.7, -1644.2, 29.8),
            radius = 4.0,
            type = "fire",
            requiredJob = "fire",
            minGrade = 4,
            jobLabel = "Firefighter"
        },
        {
            name = "Paleto Bay Fire Station - Garage",
            coords = vector3(-367.2, 6123.4, 31.5),
            radius = 4.0,
            type = "fire",
            requiredJob = "fire",
            minGrade = 4,
            jobLabel = "Firefighter"
        },
        {
            name = "Sandy Shores Fire Station - Garage",
            coords = vector3(1691.5, 3581.2, 35.6),
            radius = 4.0,
            type = "fire",
            requiredJob = "fire",
            minGrade = 4,
            jobLabel = "Firefighter"
        },
        -- Hospitals (Ambulance job, grade 4+)
        {
            name = "Pillbox Hill Medical Center - Parking Garage",
            coords = vector3(338.5, -580.3, 28.8),
            radius = 4.0,
            type = "medical",
            requiredJob = "ambulance",
            minGrade = 4,
            jobLabel = "EMS Personnel"
        },
        {
            name = "Sandy Shores Medical Center - Parking",
            coords = vector3(1835.2, 3678.9, 34.3),
            radius = 4.0,
            type = "medical",
            requiredJob = "ambulance",
            minGrade = 4,
            jobLabel = "EMS Personnel"
        }
    }
    
    if Config.AutoDetectZones and not Config.ManualZones then
        Config.ModificationZones = defaultZones
        if Config.Debug then
            print("^2[AUTO-CONFIG]:^0 Configured " .. #defaultZones .. " modification zones")
        end
    elseif Config.ManualZones then
        if Config.Debug then
            print("^2[AUTO-CONFIG]:^0 Using manual zone configuration")
        end
    end
end


-- Available modification types - auto-configured but can be manually overridden
Config.EnabledModifications = {
    Liveries = true,            -- Standard vehicle liveries
    CustomLiveries = true,      -- Custom YFT liveries  
    Performance = true,         -- Engine, brakes, transmission, etc.
    Appearance = true,          -- Colors, wheels, window tint
    Neon = false,               -- Neon lights and colors (disabled by default for performance)
    Extras = true,              -- Vehicle extras toggle
    Doors = true                -- Door controls
}

-- Other auto-configured settings (can be manually overridden)
Config.ShowBlips = false        -- Show modification zone blips on map (disabled for invisible zones)
Config.ShowMarkers = false      -- Show ground markers at zones (disabled for invisible zones)
Config.EmergencyVehiclesOnly = false  -- Allow any vehicle (DISABLED for admin testing)

-----------------------------------------------------------
-- FIELD REPAIR SYSTEM (v2.1.0+)
-- Allows emergency repairs outside of stations with requirements
-----------------------------------------------------------
Config.FieldRepair = {
    enabled = true,                    -- Enable field repair system
    requireItem = true,                -- Require a toolkit item
    itemName = 'repairkit',            -- Item name (or 'advanced_repairkit', 'toolkit')
    alternativeItems = {               -- Alternative items that work
        'repairkit', 'toolkit', 'mechanickit', 'advanced_repairkit'
    },
    allowedJobs = {                    -- Jobs that can use field repair
        'police', 'ambulance', 'fire', 'mechanic', 'lspd', 'bcso', 'sahp', 'ems', 'lsfd'
    },
    minGrade = 0,                      -- Minimum job grade (0 = any grade)
    maxEngineRepair = 350.0,           -- Max engine health from field repair (350/1000)
    cooldown = 300000,                 -- 5 minute cooldown between field repairs
    consumeItem = true,                -- Remove item after use
    repairTime = 15000                 -- Time in ms for field repair
}

-----------------------------------------------------------
-- PRESET/FLEET SYSTEM (v2.1.0+)
-- Save and load vehicle configurations for fleet standardization
-----------------------------------------------------------
Config.Presets = {
    enabled = true,                    -- Enable preset system
    maxPresetsPerPlayer = 10,          -- Max presets per player
    maxPresetsPerJob = 5,              -- Max shared job presets
    allowJobPresets = true,            -- Allow creating job-wide presets
    minGradeForJobPresets = 3,         -- Min grade to create job presets (Sergeant+)
    saveToDatabase = true              -- Persist presets to database
}

-----------------------------------------------------------
-- AUTO-APPLY LIVERY SYSTEM (v2.1.0+)
-- Automatically apply last used livery when spawning vehicles
-----------------------------------------------------------
Config.AutoApplyLivery = {
    enabled = true,                    -- Enable auto-apply
    applyOnSpawn = true,               -- Apply when vehicle spawns
    applyOnEnter = false,              -- Apply when entering vehicle (alternative)
    rememberPerVehicle = true,         -- Remember livery per vehicle model
    rememberExtras = true,             -- Also remember extra toggles
    notifyOnApply = true               -- Show notification when auto-applied
}

-- Custom liveries configuration - add your vehicle liveries here
Config.CustomLiveries = {
    ["police"] = {
        {name = "LSPD Standard", file = "liveries/police_livery1.yft"},
        {name = "LSPD Slicktop", file = "liveries/police_livery2.yft"},
        {name = "BCSO Standard", file = "liveries/police_livery3.yft"}
    },
    ["ambulance"] = {
        {name = "EMS Standard", file = "liveries/ambulance_livery1.yft"},
        {name = "Fire Department", file = "liveries/ambulance_fire.yft"}
    }
    -- Add more vehicles and liveries as needed
}

-- Manual Zone Configuration (only used if ManualZones = true)
Config.ManualModificationZones = {
    -- Add your custom zones here if you want manual control
    -- Example:
    -- {
    --     name = "Custom Police Station",
    --     coords = vector3(0.0, 0.0, 0.0),
    --     radius = 25.0,
    --     type = "police"
    -- }
}

-- Framework Detection
function Config.DetectFramework()
    if Config.AutoDetectFramework and not Config.ManualFramework then
        if GetResourceState('es_extended') == 'started' then
            return 'esx'
        -- Check for QBox FIRST (it uses qbx_core but is different from QBX/QB-Core)
        elseif GetResourceState('qbx_core') == 'started' then
            -- QBox uses qbx_core resource name
            return 'qbox'
        elseif GetResourceState('qb-core') == 'started' then
            -- Legacy QB-Core
            return 'qbcore'
        else
            return 'standalone'
        end
    else
        return Config.Framework -- Use manual setting
    end
end

-- Job information cache using ox_lib cache system
Config.JobCache = {}
Config.LastCacheUpdate = 0

-- Advanced job permission checking with caching and database fallback
function Config.HasJobPermission(playerId, requiredJob, minGrade, framework, frameworkObject)
    if not Config.EnableJobRestrictions then
        return true
    end
    
    local currentFramework = framework or Config.Framework
    
    -- Check cache first (using ox_lib cache if available)
    local cacheKey = playerId .. ":" .. (requiredJob or "any")
    local cachedResult = Config.GetCachedJobInfo(cacheKey)
    
    if cachedResult and cachedResult.timestamp > (GetGameTimer() - Config.JobCacheTimeout) then
        return Config.ValidateJobAccess(cachedResult.jobData, requiredJob, minGrade)
    end
    
    -- Try framework method first
    local jobData = Config.GetJobFromFramework(playerId, currentFramework, frameworkObject)
    
    if not jobData then
        -- Fallback to database polling
        jobData = Config.GetJobFromDatabase(playerId, currentFramework)
    end
    
    if jobData then
        -- Cache the result
        Config.CacheJobInfo(cacheKey, jobData)
        return Config.ValidateJobAccess(jobData, requiredJob, minGrade)
    end
    
    return false
end

-- Get job info from framework objects (real-time)
function Config.GetJobFromFramework(playerId, framework, frameworkObject)
    if framework == 'esx' and frameworkObject then
        local xPlayer = frameworkObject.GetPlayerFromId(playerId)
        if xPlayer then
            local job = xPlayer.getJob()
            return {
                name = job.name,
                grade = job.grade,
                label = job.label
            }
        end
    elseif framework == 'qbcore' and frameworkObject then
        local Player = frameworkObject.Functions.GetPlayer(playerId)
        if Player then
            local job = Player.PlayerData.job
            return {
                name = job.name,
                grade = job.grade and job.grade.level or job.grade,
                label = job.label
            }
        end
    elseif framework == 'qbox' then
        -- QBox uses qbx_core resource with GetPlayer export
        local Player = exports.qbx_core:GetPlayer(playerId)
        if Player then
            local job = Player.PlayerData.job
            return {
                name = job.name,
                grade = job.grade,
                label = job.label
            }
        end
    end
    
    return nil
end

-- Validate job access against requirements
function Config.ValidateJobAccess(jobData, requiredJob, minGrade)
    if not jobData or not requiredJob then
        return false
    end
    
    -- Check if job matches (including mapped job names)
    local jobMatches = false
    if Config.JobMappings[requiredJob] then
        for _, jobName in ipairs(Config.JobMappings[requiredJob]) do
            if jobData.name == jobName then
                jobMatches = true
                break
            end
        end
    else
        jobMatches = jobData.name == requiredJob
    end
    
    if not jobMatches then
        return false
    end
    
    -- Check grade requirement if enabled
    if Config.EnableGradeRestrictions and minGrade then
        return jobData.grade >= minGrade
    end
    
    return true
end

-- Cache management using ox_lib or fallback
function Config.GetCachedJobInfo(key)
    if lib and lib.cache then
        return lib.cache.get('job_' .. key)
    else
        return Config.JobCache[key]
    end
end

function Config.CacheJobInfo(key, jobData)
    local cacheData = {
        jobData = jobData,
        timestamp = GetGameTimer()
    }
    
    if lib and lib.cache then
        lib.cache.set('job_' .. key, cacheData, Config.JobCacheTimeout)
    else
        Config.JobCache[key] = cacheData
    end
end

-- Legacy permission function for backwards compatibility
function Config.HasPermission(playerId, framework, frameworkObject)
    local settings = Config.FrameworkSettings[framework or Config.Framework]
    
    if not settings or not settings.jobRestriction then
        return true
    end
    
    -- Use new job permission system with default job requirements
    for _, allowedJob in ipairs(settings.allowedJobs) do
        if Config.HasJobPermission(playerId, allowedJob, settings.minGrade, framework, frameworkObject) then
            return true
        end
    end
    
    return false
end

-- Enhanced zone checking with job-specific requirements
function Config.IsInModificationZone(playerCoords, playerId, framework, frameworkObject)
    -- Bypass zone restrictions entirely if disabled (admin mode)
    if Config.DisableZoneRestrictions then
        return true, {
            allowed = true,
            message = "Zone restrictions disabled - access granted anywhere",
            zone = { name = "Anywhere", type = "admin" }
        }
    end

    for _, zone in ipairs(Config.ModificationZones) do
        local distance = #(playerCoords - zone.coords)
        if distance <= zone.radius then
            -- Check job-specific permissions for this zone
            if playerId and Config.EnableJobRestrictions then
                if zone.requiredJob then
                    local hasAccess = Config.HasJobPermission(
                        playerId, 
                        zone.requiredJob, 
                        zone.minGrade, 
                        framework, 
                        frameworkObject
                    )
                    
                    if not hasAccess then
                        return false, {
                            allowed = false,
                            message = string.format("Access denied. Requires %s (Grade %d+)", 
                                zone.jobLabel or zone.requiredJob, zone.minGrade or 0),
                            zone = zone,
                            requiredJob = zone.requiredJob,
                            minGrade = zone.minGrade
                        }
                    end
                else
                    -- Fallback to legacy permission system
                    if framework and not Config.HasPermission(playerId, framework, frameworkObject) then
                        return false, {
                            allowed = false,
                            message = "You don't have permission to use vehicle modifications",
                            zone = zone
                        }
                    end
                end
            end

            return true, {
                allowed = true,
                message = "Access granted at " .. zone.name,
                zone = zone
            }
        end
    end

    return false, {
        allowed = false,
        message = "You must be at a designated modification garage",
        zone = nil
    }
end

-- Database polling system for job information (async with ox_lib)
function Config.GetJobFromDatabase(playerId, framework)
    if not Config.AutoDetectJobTables or not Config.JobTables[framework] then
        return nil
    end
    
    local jobTables = Config.JobTables[framework]
    local identifier = Config.GetPlayerIdentifier(playerId)
    
    if not identifier then
        return nil
    end
    
    -- Use oxmysql for async database queries
    local ox_mysql = exports['oxmysql']
    if not ox_mysql then
        if Config.Debug then
            print("^3[AUTO-CONFIG]:^0 Warning: oxmysql not available for database job polling")
        end
        return nil
    end
    
    local jobData = nil
    local completed = false
    
    if framework == 'esx' then
        -- ESX job query
        local query = string.format(
            "SELECT u.job, u.job_grade, j.label FROM %s u JOIN %s j ON u.job = j.name WHERE u.%s = ?",
            jobTables.users, jobTables.jobs, jobTables.identifierField
        )
        
        ox_mysql:execute(query, {identifier}, function(result)
            if result and result[1] then
                jobData = {
                    name = result[1].job,
                    grade = result[1].job_grade,
                    label = result[1].label
                }
            end
            completed = true
        end)
        
    elseif framework == 'qbcore' then
        -- QBCore job query (handles JSON job column)
        local query = string.format(
            "SELECT %s FROM %s WHERE %s = ?",
            jobTables.jobDataColumn, jobTables.players, jobTables.identifierField
        )
        
        ox_mysql:execute(query, {identifier}, function(result)
            if result and result[1] and result[1][jobTables.jobDataColumn] then
                local jobJson = json.decode(result[1][jobTables.jobDataColumn])
                if jobJson then
                    jobData = {
                        name = jobJson.name,
                        grade = jobJson.grade and jobJson.grade.level or jobJson.grade,
                        label = jobJson.label
                    }
                end
            end
            completed = true
        end)
        
    elseif framework == 'qbox' then
        -- QBox job query
        local query = string.format(
            "SELECT %s, %s FROM %s WHERE %s = ?",
            jobTables.userJobField, jobTables.userGradeField, jobTables.players, jobTables.identifierField
        )
        
        ox_mysql:execute(query, {identifier}, function(result)
            if result and result[1] then
                jobData = {
                    name = result[1][jobTables.userJobField],
                    grade = result[1][jobTables.userGradeField],
                    label = result[1][jobTables.userJobField] -- Fallback
                }
            end
            completed = true
        end)
    end
    
    -- Wait for async query to complete (with timeout)
    local timeout = 0
    while not completed and timeout < 50 do -- 500ms max wait
        Citizen.Wait(10)
        timeout = timeout + 1
    end
    
    return jobData
end

-- Get player identifier based on framework
function Config.GetPlayerIdentifier(playerId)
    local framework = Config.Framework
    
    if framework == 'esx' then
        -- ESX uses steam identifier
        for _, id in ipairs(GetPlayerIdentifiers(playerId)) do
            if string.find(id, "steam:") then
                return id
            end
        end
    elseif framework == 'qbcore' or framework == 'qbox' then
        -- QBCore/QBox uses citizenid (license identifier)
        for _, id in ipairs(GetPlayerIdentifiers(playerId)) do
            if string.find(id, "license:") then
                return string.gsub(id, "license:", "")
            end
        end
    end
    
    return nil
end

-- Clean up expired cache entries
function Config.CleanJobCache()
    if not lib or not lib.cache then
        local currentTime = GetGameTimer()
        for key, data in pairs(Config.JobCache) do
            if data.timestamp < (currentTime - Config.JobCacheTimeout) then
                Config.JobCache[key] = nil
            end
        end
    end
end

-- Check if vehicle is an emergency vehicle
function Config.IsEmergencyVehicle(vehicle)
    return IsVehicleEmergency(vehicle)
end

-- Manual Emergency Vehicle List (only used if ManualVehicleDetection = true)
Config.ManualEmergencyVehicles = {
    -- Add your custom emergency vehicles here if you want manual control
    "ambulance", "firetruk", "police", "police2", "police3", "police4",
    "policeb", "policet", "sheriff", "sheriff2", "fbi", "fbi2", "riot",
    "lguard", "pranger", "polmav", "predator", "riot2"
    -- Add custom vehicle models here
}

-- Auto-detect emergency vehicles or use manual list
function IsVehicleEmergency(vehicle)
    if Config.ManualVehicleDetection then
        -- Use manual vehicle list
        for _, model in ipairs(Config.ManualEmergencyVehicles) do
            if IsVehicleModel(vehicle, GetHashKey(model)) then
                return true
            end
        end
        return false
    else
        -- Auto-detection mode
        -- Check emergency vehicle class (18) - most reliable
        if GetVehicleClass(vehicle) == 18 then
            return true
        end
        
        -- Check if vehicle has emergency lights (some servers may have this native)
        -- Commented out as this native may not be available on all servers
        -- if GetVehicleHasKstock and GetVehicleHasKstock(vehicle) then
        --     return true
        -- end
        
        -- Check common emergency vehicle models as fallback
        local commonModels = {
            "ambulance", "firetruk", "police", "police2", "police3", "police4",
            "policeb", "policet", "sheriff", "sheriff2", "fbi", "fbi2", "riot",
            "lguard", "pranger", "polmav", "predator", "riot2"
        }
        
        for _, model in ipairs(commonModels) do
            if IsVehicleModel(vehicle, GetHashKey(model)) then
                return true
            end
        end
        
        return false
    end
end

-- Initialize all auto-configurations
function Config.Initialize()
    if Config.AutoConfigure then
        Config.AutoConfigureFramework()
        Config.AutoConfigureZones()
        
        -- Use manual zones if specified
        if Config.ManualZones and Config.ManualModificationZones and #Config.ManualModificationZones > 0 then
            Config.ModificationZones = Config.ManualModificationZones
        end
        
        -- Validate configuration
        Config.ValidateConfiguration()
        
        if Config.Debug then
            print("^2[AUTO-CONFIG]:^0 Emergency Vehicle Menu auto-configuration completed")
            print("^2[AUTO-CONFIG]:^0 Framework: " .. (Config.Framework or "unknown"))
            print("^2[AUTO-CONFIG]:^0 Zones: " .. #Config.ModificationZones)
            print("^2[AUTO-CONFIG]:^0 Vehicle Detection: " .. (Config.ManualVehicleDetection and "Manual" or "Auto"))
        end
    else
        if Config.Debug then
            print("^3[AUTO-CONFIG]:^0 Auto-configuration disabled, using manual settings")
        end
    end
end

-- Validate configuration and provide fallbacks
function Config.ValidateConfiguration()
    -- Ensure we have modification zones
    if not Config.ModificationZones or #Config.ModificationZones == 0 then
        print("^3[AUTO-CONFIG]:^0 Warning: No modification zones configured! Using default zone.")
        Config.ModificationZones = {{
            name = "Default Emergency Services Garage",
            coords = vector3(454.2, -1025.1, 28.4), -- Mission Row PD Parking Garage
            radius = 4.0,
            type = "police"
        }}
    end
    
    -- Ensure framework settings exist
    if not Config.FrameworkSettings or not Config.FrameworkSettings[Config.Framework] then
        print("^3[AUTO-CONFIG]:^0 Warning: No framework settings for " .. Config.Framework .. ". Using defaults.")
        if not Config.FrameworkSettings then Config.FrameworkSettings = {} end
        Config.FrameworkSettings[Config.Framework] = {
            jobRestriction = false,
            locationOnly = true
        }
    end
    
    -- Ensure enabled modifications are configured
    if not Config.EnabledModifications then
        print("^3[AUTO-CONFIG]:^0 Warning: No modifications enabled! Enabling defaults.")
        Config.EnabledModifications = {
            Liveries = true,
            CustomLiveries = true,
            Performance = true,
            Appearance = true,
            Neon = false,
            Extras = true,
            Doors = true
        }
    end
    
    -- Ensure custom liveries table exists
    if not Config.CustomLiveries then
        Config.CustomLiveries = {}
    end
end
