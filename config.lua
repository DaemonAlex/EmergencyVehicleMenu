-- Emergency Vehicle Modifications Config
Config = Config or {}

-- Framework options: 'qb-core', 'qbc-core', 'esx', 'standalone'
Config.Framework = 'standalone'

-- Debug mode
Config.Debug = false

-- Job access configuration - who can access the menu
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

-- Initialize the custom liveries table if not already defined
Config.CustomLiveries = Config.CustomLiveries or {}

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

-- Vehicle mod slot limitations
Config.MaxModSlots = 40  -- Maximum number of mod slots supported
Config.MaxLiverySlots = 20  -- Maximum number of livery slots supported

-- Folder structure configuration 
Config.FolderStructure = {
    BasePath = "stream",
    Liveries = "liveries",
    Models = "model",
    ModParts = "modparts"
}

-- Function to get full path for a livery file
function Config.GetLiveryPath(vehicleModel, liveryFile)
    -- If the path already includes the liveries folder, use as is
    if string.match(liveryFile, "^" .. Config.FolderStructure.Liveries .. "/") then
        return Config.FolderStructure.BasePath .. "/" .. vehicleModel .. "/" .. liveryFile
    end
    
    -- Otherwise, construct the full path
    return Config.FolderStructure.BasePath .. "/" .. vehicleModel .. "/" .. Config.FolderStructure.Liveries .. "/" .. liveryFile
end

-- Function to get full path for a model file
function Config.GetModelPath(vehicleModel, modelFile)
    -- If the path already includes the model folder, use as is
    if string.match(modelFile, "^" .. Config.FolderStructure.Models .. "/") then
        return Config.FolderStructure.BasePath .. "/" .. vehicleModel .. "/" .. modelFile
    end
    
    -- Otherwise, construct the full path
    return Config.FolderStructure.BasePath .. "/" .. vehicleModel .. "/" .. Config.FolderStructure.Models .. "/" .. modelFile
end

-- Function to get full path for a mod part file
function Config.GetModPartPath(vehicleModel, partFile)
    -- If the path already includes the modparts folder, use as is
    if string.match(partFile, "^" .. Config.FolderStructure.ModParts .. "/") then
        return Config.FolderStructure.BasePath .. "/" .. vehicleModel .. "/" .. partFile
    end
    
    -- Otherwise, construct the full path
    return Config.FolderStructure.BasePath .. "/" .. vehicleModel .. "/" .. Config.FolderStructure.ModParts .. "/" .. partFile
end

-- Sample emergency vehicle models
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

-- Function to check if a job is allowed to use the menu
function Config.IsJobAllowed(job)
    return Config.JobAccess[job] or false
end
