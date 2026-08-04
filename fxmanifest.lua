fx_version 'cerulean'
game 'gta5'

author 'EnyoScripts'
description 'Enyo RTS - Map Builder Tool'
version '1.0.0'

client_scripts {
    'client/camera.lua',
    'shared/catalog.lua',
    'client/main.lua',
    'client/editor.lua',
    'client/cinematic.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/builder.js',
}

dependencies {
    'rts-admin',

}

lua54 'yes'