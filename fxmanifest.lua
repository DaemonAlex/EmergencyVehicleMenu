
fx_version 'cerulean'
games { 'gta5' }

author 'Deamonalex'
description 'Emergency Vehicle Menu - Standalone Version'
version '1.0.1'

lua54 'yes'

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'ox_lib'
}

shared_scripts {
    '@ox_lib/init.lua',
}
