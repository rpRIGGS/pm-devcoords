fx_version 'cerulean'
game 'gta5'
author 'LuckyyFishyy / PowerMoves RP'
description 'PowerMoves RP developer coordinate capture and administration utilities'
version '1.2.0'
dependencies { 'qb-core', 'ox_lib', 'oxmysql' }
ui_page 'html/index.html'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
client_scripts { 'client/main.lua', 'client/devadmin.lua', 'client/entity_view.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua', 'server/devadmin.lua' }
files { 'html/index.html', 'html/style.css', 'html/script.js' }
