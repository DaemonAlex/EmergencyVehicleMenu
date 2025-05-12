Config = {}

Config.Debug = true
-- Location-based authorization for vehicle modifications. Please edit to your liking. Only "emergency" vehicles can be modded at the specified locations. 
-- I DID THIS TO SIMPLIFIY THE SCRIPT. I was having issues trying to write the code to make it job based for multiple frameworks. I retry this in the future when I have more time.
-- Feel free to make a pull request if you want that part to work.  
-- Locations should be in a locked location restricted to PD, Fire or other specified job types. 
Config.ModificationZones = {
    -- Police Department Locations (add additional locations useing the same format)
    {
        name = "Mission Row Police Department Garage",
        coords = vector3(454.6, -1017.4, 28.4),
        radius = 30.0,
        type = "police"  -- Just for blip and marker colors
    },
    {
        name = "Sandy Shores Sheriff's Office Garage",
        coords = vector3(1853.7, 3675.9, 33.7),
        radius = 25.0,
        type = "police"
    },
    {
        name = "Paleto Bay Sheriff's Office Garage",
        coords = vector3(-448.5, 6012.6, 31.7),
        radius = 25.0,
        type = "police"
    },
    
    -- Fire Department Locations (add additional locations useing the same format)
    {
        name = "Los Santos Fire Station Garage",
        coords = vector3(1204.3, -1473.2, 34.9),
        radius = 25.0,
        type = "fire"
    },
    {
        name = "Davis Fire Station Garage",
        coords = vector3(208.3, -1660.1, 29.8),
        radius = 25.0,
        type = "fire"
    },
    {
        name = "Paleto Bay Fire Station Garage",
        coords = vector3(-379.5, 6118.6, 31.5),
        radius = 25.0,
        type = "fire"
    }
}

-- Whether to enable blips on the map for modification zones
Config.ShowBlips = true

-- Whether to show markers on the ground at modification zones
Config.ShowMarkers = true

-- Whether to restrict to emergency vehicles only
Config.EmergencyVehiclesOnly = true

-- Available modification types - all enabled by default
Config.EnabledModifications = {
    Liveries = true,            -- Standard vehicle liveries
    CustomLiveries = true,      -- Custom YFT liveries
    Performance = true,         -- Engine, brakes, transmission, etc.
    Appearance = true,          -- Colors, wheels, window tint
    Neon = true,                -- Neon lights and colors
    Extras = true,              -- Vehicle extras toggle
    Doors = true                -- Door controls
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

-- Check if player is in a modification zone
function Config.IsInModificationZone(playerCoords)
    for _, zone in ipairs(Config.ModificationZones) do
        local distance = #(playerCoords - zone.coords)
        if distance <= zone.radius then
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

-- Check if vehicle is an emergency vehicle
function Config.IsEmergencyVehicle(vehicle)
    return IsVehicleEmergency(vehicle)
end

-- This helper ensures we catch all emergency vehicles, including custom ones
function IsVehicleEmergency(vehicle)
    -- Traditional emergency flag check
    if IsVehicleEmergencyVehicle(vehicle) then
        return true
    end
    
    -- Check emergency vehicle class (18)
    if GetVehicleClass(vehicle) == 18 then
        return true
    end
    
    -- Check for emergency livery or sirens
    if DoesVehicleHaveSiren(vehicle) then
        return true
    end
    
    -- Check specific models that might not have flags but are emergency vehicles
    local models = {
        "ambulance", "firetruk", "police", "police2", "police3", "police4", 
        "policeb", "policet", "sheriff", "sheriff2"
    }
    
    for _, model in ipairs(models) do
        if IsVehicleModel(vehicle, GetHashKey(model)) then
            return true
        end
    end
    
    return false
end
