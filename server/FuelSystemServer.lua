--==================================================================================================
-- VisionCar Fuel System : Coded by Meowdy - campus9914
-- Do not touch anything beside the config.lua
--==================================================================================================
--------------------------------- Server side Fuel System Control ----------------------------------
--This is the server side Fuel System control, this is the core of fuel system within this script,
--it is responsible to handling Send and receive money data and fuel data within the SQL.
----------------------------------------------------------------------------------------------------

ESX = exports["es_extended"]:getSharedObject()

local bReady = false

-- Stored Vars

local CarBeingFuel = {
 	['VISIONRP'] = true
}

local CarFuelLevel = {
	["VISIONRP"] = { plate = 'VISIONRP', fuel = 50, notOwned = true } -- Default 
}

-- Scripting 

AddEventHandler('onResourceStart', function(resourceName)
	if resourceName == GetCurrentResourceName() then
	  	MySQL.ready(function()
			print("Fuel System Ready")
		end)
		-- MySQL.Async.fetchAll('SELECT plate, fuel FROM owned_vehicles', {}, function(data)
			-- for _,v in pairs(data) do
				-- CarFuelLevel[v.plate] = {plate = v.plate, fuel = v.fuel, notOwned = true}
			-- end
			-- bReady = true
		-- end)
	end	
end)

AddEventHandler('onResourceStop', function(resourceName)
	if resourceName == GetCurrentResourceName() then
	  	for key, v in pairs(CarFuelLevel) do
			Citizen.Wait(1)
			if not v.notOwned then
				MySQL.Async.execute('UPDATE owned_vehicles SET `fuel` = @fuel WHERE plate = @plate', {
						['@fuel'] = v.fuel,
						['@plate'] = v.plate
				}, function(rowsChanged)
					--	Do Nothing
				end)
			end
		end
	end	
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(60000)
		for key, v in pairs(CarFuelLevel) do
			Citizen.Wait(1)
			if not v.notOwned then
				MySQL.Async.execute('UPDATE owned_vehicles SET `fuel` = @fuel WHERE plate = @plate', {
						['@fuel'] = v.fuel,
						['@plate'] = v.plate
				}, function(rowsChanged)
					--	Do Nothing
				end)
			end
		end
	end
end)

-- Events



RegisterServerEvent('VisionCar:RemoveMoney')
AddEventHandler('VisionCar:RemoveMoney', function(price)
	local xPlayer = ESX.GetPlayerFromId(source)
	local amount = ESX.Math.Round(price)
	if price > 0 then
		xPlayer.removeMoney(amount)
	end
end)

RegisterServerEvent('VisionCar:changedurability')
AddEventHandler('VisionCar:changedurability', function(slot, val)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	exports.ox_inventory:SetDurability(src, slot, val)
end)

ESX.RegisterServerCallback('VisionCar:refillPetrolCan', function(source, cb)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local weapon = exports.ox_inventory:GetCurrentWeapon(src)
	if weapon then
		exports.ox_inventory:SetDurability(src, weapon.slot, 100)
	end
	cb(true)
end)

ESX.RegisterServerCallback('VisionCar:getJerry', function(source, cb)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	-- Checks if the player calling the event can carry 3 water items
	if exports.ox_inventory:CanCarryItem(src, 'WEAPON_PETROLCAN', 1) then
		exports.ox_inventory:AddItem(src, 'WEAPON_PETROLCAN', 1, {ammo = 100})
		cb(true)
	else
		cb(false)
	end
end)

ESX.RegisterServerCallback('VisionCar:CheckCarIsFueling', function(source, cb, plate)
	if not CarBeingFuel[plate] then
		cb(false) -- Return False if car is not fueling
	else
		cb(true) -- vice versa
	end
end)

RegisterNetEvent('VisionCar:ThisCarIsRefueling')
AddEventHandler('VisionCar:ThisCarIsRefueling', function(plate)
	if not CarBeingFuel[plate] then
		CarBeingFuel[plate] = true
	end
end)

RegisterNetEvent('VisionCar:ThisCarIsNotRefueling')
AddEventHandler('VisionCar:ThisCarIsNotRefueling', function(plate, fuel)
	if CarBeingFuel[plate] then
		CarBeingFuel[plate] = nil
	else
		print('WARNING : Fuel Pump not in sync ' .. plate)
	end
	MySQL.Async.execute('UPDATE owned_vehicles SET `fuel` = @fuel WHERE plate = @plate', {
		['@fuel'] = fuel,
		['@plate'] = plate
	}, function(rowsChanged)
	end)
end)

-- Look up for Vehicle Fuel in Cache
RegisterNetEvent('VisionCar:GetServerFuel')
AddEventHandler('VisionCar:GetServerFuel', function(retplate, retfuel)
	if not CarFuelLevel[retplate] then
		MySQL.Async.fetchScalar('SELECT fuel FROM owned_vehicles WHERE plate = @plate', {['@plate'] = retplate}, function(data)
			if data then
				CarFuelLevel[retplate] = {plate = retplate, fuel = data, notOwned = false}
			else
				local fuelDefault = retfuel
				if fuelDefault <= 20 then
					fuelDefault = 30
				end
				CarFuelLevel[retplate] = {plate = retplate, fuel = fuelDefault, notOwned = true}
			end
		end)
	end
	while not CarFuelLevel[retplate] do
		Citizen.Wait(10)
	end
	TriggerClientEvent('VisionCar:ReturnFuelFromServerTable', -1, {plate = retplate, fuel = CarFuelLevel[retplate].fuel})
end)

ESX.RegisterServerCallback('VisionCar:GetServerFuelMaster', function(source, cb)
	cb(CarFuelLevel)
end)

-- Save Vehicle Fuel to Cache
RegisterNetEvent('VisionCar:SetServerFuel')
AddEventHandler('VisionCar:SetServerFuel', function(retPlate, fuelVal)	
	if not CarFuelLevel[retPlate] then
		CarFuelLevel[retPlate] = {plate = retPlate, fuel = fuelVal, notOwned = true}
	else
		local previousOwned = CarFuelLevel[retPlate].notOwned
		CarFuelLevel[retPlate] = nil
		CarFuelLevel[retPlate] = {plate = retPlate, fuel = fuelVal, notOwned = previousOwned}
	end
end)

RegisterNetEvent('VisionCar:fossilDino')
AddEventHandler('VisionCar:fossilDino', function(retPlate, desFuel)	
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	if isAdmin(xPlayer) then
		TriggerEvent('VisionCar:SetServerFuel', retPlate, desFuel)
	else
		print('Warning : Admin command issued by Normal player')
	end
end)

function isAdmin(xPlayer)
	for k,v in ipairs(Config.StaffGroups) do
		if xPlayer and xPlayer.getGroup() == v then 
			return true 
		end
	end
	return false
end

RegisterCommand("outputfuel", function(source, args, rawCommand)
	for key, v in pairs(CarFuelLevel) do
		print(v.plate .. ' ' .. tostring(v.fuel) .. ' ' .. tostring(v.notOwned))
	end
end, true)

RegisterCommand("savefuelnow", function(source, args, rawCommand)
	for key, v in pairs(CarFuelLevel) do
		if not v.notOwned then
			MySQL.Async.execute('UPDATE owned_vehicles SET `fuel` = @fuel WHERE plate = @plate', {
					['@fuel'] = v.fuel,
					['@plate'] = v.plate
			}, function(rowsChanged)
				--	Do Nothing
			end)
		end
	end
	print('Fuel data saved to database.')
end, true)

function ResetFuelData()
	print('Clearing Vehicle Fuel Cache')
	CarFuelLevel = nil
	CarFuelLevel = {
		["VISIONRP"] = { plate = 'VISIONRP', fuel = 50, notOwned = true } -- Default 
	}
end

TriggerEvent("cron:runAt", 22, 05, ResetFuelData)