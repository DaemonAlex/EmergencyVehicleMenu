fx_version 'cerulean'
games { 'gta5' }

author 'Deamonalex'
description 'Emergency Vehicle Menu'
version '1.0.0'

lua54 'yes'

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    -- Uncomment the framework you are using. Leave all uncommented if you are STANDALONE
    -- 'qb-core',
    -- 'qbx_core',
    -- 'es_extended',
    'ox_lib'
}

shared_scripts {
    '@ox_lib/init.lua',
}
