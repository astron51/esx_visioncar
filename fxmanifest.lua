fx_version 'cerulean'

game 'gta5'

description 'VisionCar : Fuel System'

dependencies {
    'es_extended'
}

client_scripts {
	'@es_extended/imports.lua',
	'@es_extended/locale.lua',
	'config.lua',
	'client/FuelSystemClient.lua'
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'@es_extended/locale.lua',
	'config.lua',
	'server/FuelSystemServer.lua'
}

export {
	'GetFuel','SetFuel'
}