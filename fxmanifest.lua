fx_version 'cerulean'
game 'gta5'

name 'Emergency Vehicle Menu - Auto-Configuration Edition'
description 'Next-generation emergency vehicle modification system with complete auto-configuration, advanced job-based access control, and multi-framework support (ESX, QBCore, QBox, Standalone). Zero manual setup required!'
author 'DaemonAlex'
version '2.0.1'

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

lua54 'yes'
