fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'sovara_docs'
author 'Sovara Roleplay'
description 'Arbeitsvertrag & Gewerbeschein (ESX Legacy, Standard-Inventar)'

dependencies { 'es_extended', 'oxmysql' }

shared_script 'config.lua'
client_script 'client.lua'
server_scripts { '@oxmysql/lib/MySQL.lua', 'server.lua' }

ui_page 'html/index.html'
files { 'html/index.html' }
