fx_version 'cerulean'
game 'gta5'

author 'DELLIECODE'
description 'DC Harvest System - Système de récolte configurable'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sql.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
    'client/target.lua'
}

lua54 'yes'