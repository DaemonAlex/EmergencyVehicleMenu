Config = {}

-- Framework is set to standalone only
Config.Framework = 'standalone'

-- Debug mode for additional console information
Config.Debug = true

-- Jobs allowed to access the vehicle modification menu
Config.JobAccess = {
    ['standalone'] = true,  -- Always accessible in standalone mode
    
    -- You can still restrict access if needed by commenting out the line above
    -- and uncommenting specific jobs below:
    -- ['police'] = true,
    -- ['ambulance'] = true,
    -- ['mechanic'] = true,
    -- ['sheriff'] = true,
    -- ['fire'] = true,
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

-- Emergency vehicle models that will be recognized
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
    -- Add any additional emergency vehicles here
}

-- Helper function to check if job is allowed to access the menu
function Config.IsJobAllowed(job)
    return Config.JobAccess[job] or false
end
