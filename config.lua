Config = {}

-- Select the framework you're using: 'qb-core', 'qbx-core', 'esx', or 'standalone'
Config.Framework = 'standalone'  -- Change this value based on your server

-- Access permissions for jobs
Config.JobAccess = {
    ['police'] = true,  -- Can be modified to add other jobs
    ['ambulance'] = true
}

-- Custom YFT liveries configuration
-- Format: [vehicle_model_name] = { {name = "Livery Name", file = "livery_file_name.yft"}, ... }
Config.CustomLiveries = {
    -- Police vehicles
    ['police'] = {
        {name = "LSPD Standard", file = "police_liv1.yft"},
        {name = "LSPD Stealth", file = "police_liv2.yft"}
    },
    ['police2'] = {
        {name = "LSPD Standard", file = "police2_liv1.yft"},
        {name = "Sheriff", file = "police2_liv2.yft"}
    },
    ['police3'] = {
        {name = "LSPD Standard", file = "police3_liv1.yft"},
        {name = "NOOSE", file = "police3_liv2.yft"}
    },
    -- Ambulance
    ['ambulance'] = {
        {name = "LS Medical", file = "ambulance_liv1.yft"},
        {name = "Paleto Medical", file = "ambulance_liv2.yft"}
    },
    -- Custom Bison
    ['bison'] = {
        {name = "Police Bison", file = "polbisonhf_liv1.yft"}
    },
    -- Add more vehicles as needed
}

-- Option to restrict livery application to certain locations (e.g., garages, etc.)
Config.RestrictLocations = false -- Set to true to restrict livery application to specific locations

-- Locations where vehicle mods can be applied (only used if RestrictLocations is true)
Config.AllowedLocations = {
    {
        name = "LSPD Garage",
        coords = vector3(454.6, -1017.4, 28.4),
        radius = 10.0,
        job = "police"
    },
    {
        name = "Pillbox Garage",
        coords = vector3(292.1, -610.3, 43.0),
        radius = 10.0,
        job = "ambulance"
    },
    {
        name = "Sandy Shores Sheriff",
        coords = vector3(1856.91, 3679.53, 33.76),
        radius = 15.0,
        job = "police"
    }
}

-- Debug mode (enables additional console logging)
Config.Debug = false
