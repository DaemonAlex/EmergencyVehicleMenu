fx_version 'cerulean'
games { 'gta5' }

author 'Your Name'
description 'Police Vehicle Modification System'
version '1.0.0'

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'qb-core',
    'ox_lib' -- Ensure ox_lib is declared as a dependency
}
