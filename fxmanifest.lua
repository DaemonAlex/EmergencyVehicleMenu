fx_version 'cerulean'
games { 'gta5' }

author 'Deamonalex'
description 'Emergency Vehicle Modification System'
version '1.0.0'

lua54 'yes'

client_script 'client.lua'
server_script 'server.lua'


dependencies {
    'qb-core',
    'ox_lib' 
}

shared_scripts {
    '@ox_lib/init.lua',
}
