fx_version 'cerulean'
game 'gta5'

name 'Emergency Vehicle Modifications'
description 'A script for emergency vehicle modifications with custom livery support'
author 'Your Name'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'ox_lib',
    'oxmysql'
}

-- Define files to include with the correct folder structure
files {
    -- YFT files in each vehicle model subdirectory
    'stream/*/liveries/*.yft',
    'stream/*/model/*.yft',
    'stream/*/modparts/*.yft',
    
    -- Include any meta files that might be in the stream folder
    'stream/*.meta'
}

-- Add data files to game
data_file 'VEHICLE_LAYOUTS_FILE' 'stream/*.meta'
data_file 'CARCOLS_FILE' 'stream/*.meta'
data_file 'VEHICLE_VARIATION_FILE' 'stream/*.meta'

-- Use Lua 5.4 for better performance
lua54 'yes'
