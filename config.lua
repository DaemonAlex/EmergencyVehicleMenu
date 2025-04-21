Config = {}

-- Framework set to standalone
Config.Framework = 'standalone'

-- Access permissions for jobs (can be modified as needed)
Config.JobAccess = {
    ['police'] = true,
    ['ambulance'] = true,
    -- You can add more jobs here if needed
    ['standalone'] = true  -- This ensures anyone can use the menu in standalone mode
}

-- Menu command
Config.Command = 'modveh'  -- The command to open the vehicle modification menu
