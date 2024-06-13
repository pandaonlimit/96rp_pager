fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name '96RP Pager'
version '0.9.0'
description 'upgraded pager script from tugamars by panda'
author 'pandaonlimit'

shared_script {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    "config.lua"
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    "server.lua",
}

client_scripts {
    "client.lua",
    "script.js"
} 

ui_page 'nui/index.html'

files({
    'nui/index.html',
    'nui/**/*.png',
    'nui/**/*.mp3',
    'nui/**/*.ttf',
    'nui/**/*.css',
    'nui/**/*.js',
    'nui/**/*.json',
})