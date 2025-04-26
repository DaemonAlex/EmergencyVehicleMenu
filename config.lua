Config = Config or {}

-- Framework options: 'qb-core', 'qbx-core', 'esx', 'standalone'
Config.Framework = 'standalone'

Config.Debug = true -- Set to true to get more debug information

Config.JobAccess = {
    -- Original jobs
    ['police'] = true,
    ['ambulance'] = true,
    ['mechanic'] = true,
    ['sheriff'] = true,
    ['highway'] = true,
    ['fire'] = true,
    ['standalone'] = true,
    
    -- Additional jobs
    ['bcso'] = true,    -- Blaine County Sheriff's Office
    ['sast'] = true,    -- San Andreas State Troopers
    ['lscso'] = true,   -- Los Santos County Sheriff's Office
    ['pbpd'] = true,    -- Paleto Bay Police Department
    ['sspd'] = true,    -- Sandy Shores Police Department
    ['gspd'] = true,    -- Grapeseed Police Department
    ['papd'] = true,    -- Port Authority Police Department
    ['sagw'] = true,    -- San Andreas Game Warden
    ['fire'] = true     -- Fire Department (already included but listed again for clarity)
}

Config.CustomLiveries = Config.CustomLiveries or {}

-- Vehicle resource directories configuration
Config.VehicleResourceDirs = {
    ["police"] = "resources/[vehicles]/[police]",
    ["police2"] = "resources/[vehicles]/[police]",
    ["police3"] = "resources/[vehicles]/[police]",
    ["police4"] = "resources/[vehicles]/[police]",
    ["policeb"] = "resources/[vehicles]/[police]",
    ["sheriff"] = "resources/[vehicles]/[police]",
    ["sheriff2"] = "resources/[vehicles]/[police]",
    ["fbi"] = "resources/[vehicles]/[police]",
    ["fbi2"] = "resources/[vehicles]/[police]",
    ["pranger"] = "resources/[vehicles]/[police]",
    
    ["ambulance"] = "resources/[vehicles]/[FireEMS]",
    ["firetruk"] = "resources/[vehicles]/[FireEMS]"
    -- Add more mappings as needed
}

-- Default directory to use if a vehicle isn't in the mapping
Config.DefaultVehicleResourceDir = "resources/[vehicles]/[police]"

-- Examples with the correct folder structure
-- Format: Config.CustomLiveries[vehicle_model] = { {name = "Livery Name", file = "liveries/filename.yft"}, ... }
Config.CustomLiveries["police"] = {
    {name = "LSPD Standard", file = "liveries/police_livery1.yft"},
    {name = "LSPD Slicktop", file = "liveries/police_livery2.yft"},
    {name = "BCSO Standard", file = "liveries/police_livery3.yft"}
}

-- Vehicle parts configuration using the folder structure
Config.VehicleParts = {
    ["police"] = {
        parts = {
            {name = "Lightbar - Standard", file = "modparts/police_lightbar_standard.yft"},
            {name = "Lightbar - Slicktop", file = "modparts/police_lightbar_slicktop.yft"},
            {name = "Push Bar", file = "modparts/police_pushbar.yft"}
        }
    },
    ["ambulance"] = {
        parts = {
            {name = "Emergency Lights", file = "modparts/ambulance_lights.yft"},
            {name = "Stretcher Mount", file = "modparts/ambulance_stretcher.yft"}
        }
    }
}

-- Vehicle model configuration using the folder structure
Config.VehicleModels = {
    ["police"] = {
        baseModel = "model/police.yft",
        variants = {
            {name = "LSPD Interceptor", file = "model/police_interceptor.yft"},
            {name = "LSPD SUV", file = "model/police_suv.yft"}
        }
    },
    ["ambulance"] = {
        baseModel = "model/ambulance.yft",
        variants = {
            {name = "Fire Department", file = "model/ambulance_fire.yft"}
        }
    }
}

Config.MaxModSlots = 40  -- Maximum number of mod slots supported
Config.MaxLiverySlots = 20  -- Maximum number of livery slots supported

-- Updated folder structure configuration to handle multiple possibilities
Config.FolderStructure = {
    BasePath = "stream",
    Liveries = "liveries",
    Models = "model",
    ModParts = "modparts",
    -- Add possible paths for meta files
    MetaPaths = {
        "",            -- Direct in vehicle folder
        "data",        -- In data subfolder
        "data/%s"      -- In data/vehiclename subfolder (will be formatted with vehicle name)
    }
}

-- Function to get resource directory for a vehicle model
function Config.GetVehicleResourceDir(vehicleModel)
    local modelName = string.lower(vehicleModel)
    return Config.VehicleResourceDirs[modelName] or Config.DefaultVehicleResourceDir
end

-- Updated path finding functions
function Config.GetLiveryPath(vehicleModel, liveryFile)
    local resourceDir = Config.GetVehicleResourceDir(vehicleModel)
    
    if string.match(liveryFile, "^" .. Config.FolderStructure.Liveries .. "/") then
        return resourceDir .. "/" .. vehicleModel .. "/" .. liveryFile
    end
    
    return resourceDir .. "/" .. vehicleModel .. "/" .. Config.FolderStructure.Liveries .. "/" .. liveryFile
end

function Config.GetModelPath(vehicleModel, modelFile)
    local resourceDir = Config.GetVehicleResourceDir(vehicleModel)
    
    if string.match(modelFile, "^" .. Config.FolderStructure.Models .. "/") then
        return resourceDir .. "/" .. vehicleModel .. "/" .. modelFile
    end
    
    return resourceDir .. "/" .. vehicleModel .. "/" .. Config.FolderStructure.Models .. "/" .. modelFile
end

function Config.GetModPartPath(vehicleModel, partFile)
    local resourceDir = Config.GetVehicleResourceDir(vehicleModel)
    
    -- If the path already includes the modparts folder, use as is
    if string.match(partFile, "^" .. Config.FolderStructure.ModParts .. "/") then
        return resourceDir .. "/" .. vehicleModel .. "/" .. partFile
    end
    
    return resourceDir .. "/" .. vehicleModel .. "/" .. Config.FolderStructure.ModParts .. "/" .. partFile
end

-- Function to find meta files in various possible locations
function Config.GetMetaFilePath(vehicleModel)
    local resourceDir = Config.GetVehicleResourceDir(vehicleModel)
    local possiblePaths = {}
    
    for _, pathTemplate in ipairs(Config.FolderStructure.MetaPaths) do
        local path
        if pathTemplate == "" then
            path = resourceDir .. "/" .. vehicleModel
        elseif string.find(pathTemplate, "%%s") then
            path = resourceDir .. "/" .. vehicleModel .. "/" .. string.format(pathTemplate, vehicleModel)
        else
            path = resourceDir .. "/" .. vehicleModel .. "/" .. pathTemplate
        end
        
        table.insert(possiblePaths, path)
    end
    
    return possiblePaths
end

-- add your emergency vehicle models
Config.EmergencyVehicleModels = {
    "police",
    "police2",
    "police3",
    "police4",
    "policeb",
    "sheriff",
    "sheriff2",
    "ambulance",
    "firetruk",
    "fbi",
    "fbi2",
    "pranger"
}

function Config.IsJobAllowed(job)
    return Config.JobAccess[job] or false
end

-- Debug function to print paths for a vehicle model
function Config.DebugPaths(vehicleModel)
    if Config.Debug then
        print("^3DEBUG:^0 Vehicle resource directory for " .. vehicleModel .. ": " .. Config.GetVehicleResourceDir(vehicleModel))
        print("^3DEBUG:^0 Possible meta file paths for " .. vehicleModel .. ":")
        for i, path in ipairs(Config.GetMetaFilePath(vehicleModel)) do
            print("  " .. i .. ": " .. path)
        end
    end
end
