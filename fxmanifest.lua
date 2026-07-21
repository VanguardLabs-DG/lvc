------------------------------

fx_version 'cerulean'
games { 'gta5' }

author 'TrevorBarns w/ credits see GitHub'
description 'A siren / emergency lights controller for FiveM.'

version '3.2.9'			-- Readonly version of currently installed version.
compatible '3.2.2'		-- Readonly save reverse compatiability.

------------------------------

beta_checking 'true'	-- Notifications for beta revisions and new betas.
experimental 'false'	-- Mute unstable version warning in server console.
debug_mode 'false' 		-- More verbose printing on client console.

------------------------------

ui_page 'UI/html/index.html'
	
dependencies {
    'ox_lib'
}

files({
    'UI/html/index.html',
	'UI/sounds/*.ogg',
	'UI/sounds/**/*.ogg',
})


shared_script {
	'@ox_lib/init.lua',
	'UTIL/semver.lua',
	'UI/cl_locale.lua',
	'UI/locale/pt-br.lua',	-- Set locale / language file here.
	'SETTINGS.lua',
}

client_scripts {
	'SIRENS.lua',
	'UTIL/cl_*.lua',
	'UI/cl_*.lua',
	'PLUGINS/cl_plugins.lua',
}

server_script {
	'UTIL/sv_lvc.lua',
}
------------------------------