Config = {}

-- Select the framework you're using: 'qb-core', 'qbc-core', 'esx', or 'standalone'
Config.Framework = 'qb-core'  -- Change this value based on your server

-- Access permissions for jobs
Config.JobAccess = {
    ['police'] = true,  -- Can be modified to add other jobs
    ['ambulance'] = true
}
