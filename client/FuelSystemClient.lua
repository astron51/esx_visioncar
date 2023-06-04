--==================================================================================================
-- VisionCar Fuel System : Coded by Meowdy - campus9914
-- Redistribution is not allowed by any means, even after server closure!
-- Do not touch anything beside the config.lua
--==================================================================================================
--------------------------------- Client side Fuel System Control ----------------------------------
--This is the client side Fuel System control, basically did nothing to interact with the database,
--only send and receive data from ServerSide script to ensure no exploit can be done plus some 
--hidden counter measure if a player attempted to fuck with the system.
----------------------------------------------------------------------------------------------------

-- ESX 

ESX = nil
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
	ESX.PlayerData = ESX.GetPlayerData()
end)

-- Variables

local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
  }
local Vehicles 				  = {}
local bIsThisCarBeingFuel = false
local bIsPumpingPetrol = false
local bIsNearPump = false
local bIsFueling = false
local bExtendedPump = false
local currentMoney = 100
local currentFuel = 1.0
local currentCost = 0.0
local PlayerData = nil
local currentWeapon = nil
local PromptSleep = 0

-- Initialization

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
	ESX.TriggerServerCallback('VisionCar:GetServerFuelMaster', function(FuelList)
		Vehicles = FuelList
	end)
end)

-- Detect if Player near any Gas Pump

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local pumpObject, pumpDistance, planePump = FindNearestFuelPump()
		PlayerData = ESX.GetPlayerData().accounts
		if pumpDistance < 4.2 then
			bIsNearPump = pumpObject
			bExtendedPump = planePump
			for k,v in ipairs(PlayerData) do
				if v.name == 'money' then
					currentMoney = PlayerData[k].money
					break
				end
			end
		else
			bIsNearPump = false
			bExtendedPump = false
			Citizen.Wait(math.ceil(pumpDistance * 7))
		end
	end
end)

-- Prompt Player to Refill or Purchase Jerry Can

Citizen.CreateThread(function()
	while true do
		-- Currently not pumping and Pump is in good shape and not destroyed.
		if not bIsPumpingPetrol and ((bIsNearPump and GetEntityHealth(bIsNearPump) > 0) or (GetSelectedPedWeapon(PlayerPedId()) == 883325847 and not bIsNearPump)) then
			if IsPedInAnyVehicle(PlayerPedId()) then
				local pumpCoords = GetEntityCoords(bIsNearPump)
				if GetIsVehicleEngineRunning(GetVehiclePedIsIn(PlayerPedId(), false)) then
					-- Engine Running and Inside Car
					if GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId()), -1) == PlayerPedId() and not bExtendedPump then
						DrawText3Ds(pumpCoords.x, pumpCoords.y, pumpCoords.z + 1.2, 'Please turn off your ~r~engine~w~ by pressing ~r~F6~w~.')
						DrawText3Ds(pumpCoords.x, pumpCoords.y, pumpCoords.z + 1.0, 'Or You can just exit from your vehicle.')
						if IsControlJustReleased(0, Keys['F6']) then
							if DoesEntityExist(GetVehiclePedIsIn(PlayerPedId(), false)) then
								SetVehicleEngineOn(GetVehiclePedIsIn(PlayerPedId(), false), false, false, true)
							end
						end
					end
				else
					if GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId()), -1) == PlayerPedId() and not bExtendedPump then
						DrawText3Ds(pumpCoords.x, pumpCoords.y, pumpCoords.z + 1.2, 'Press ~r~F6~w~ to turn on your engine.')
						local pumpCoords = GetEntityCoords(bIsNearPump)
						DrawText3Ds(pumpCoords.x, pumpCoords.y, pumpCoords.z + 1.0, 'Exit the Vehicle to refill.')
						if IsControlJustReleased(0, Keys['F6']) then
							if DoesEntityExist(GetVehiclePedIsIn(PlayerPedId(), false)) then
								SetVehicleEngineOn(GetVehiclePedIsIn(PlayerPedId(), false), true, false, false)
							end
						end
					end
				end
			else
				local LastVehicle = GetPlayersLastVehicle()
				local VehicleCoords = GetEntityCoords(LastVehicle)
				if DoesEntityExist(LastVehicle) then
					PromptSleep = 0
					if (GetVehicleClass(LastVehicle) == 16 or GetVehicleClass(LastVehicle) == 15) and bExtendedPump then
						if bExtendedPump and GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), VehicleCoords) < Config.ExtendPumpRange then
							if not bIsPumpingPetrol then
								MainPromp(LastVehicle, VehicleCoords)
							end
						end
					elseif (GetVehicleClass(LastVehicle) ~= 16 or GetVehicleClass(LastVehicle) ~= 15) and not bExtendedPump then
						if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), VehicleCoords) < 2.0 then
							if not bIsPumpingPetrol then
								MainPromp(LastVehicle, VehicleCoords)
							end
						elseif bIsNearPump then
							Optional(LastVehicle, VehicleCoords)
						end
					elseif (GetVehicleClass(LastVehicle) == 16 or GetVehicleClass(LastVehicle) == 15) and not bExtendedPump then
						if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), VehicleCoords) < 15.0 then
							if not bIsPumpingPetrol then
								MainPromp(LastVehicle, VehicleCoords)
							end
						elseif bIsNearPump then
							Optional(LastVehicle, VehicleCoords)
						end
					end					
				end
			end
		end
		Citizen.Wait(PromptSleep)
	end
end)

function MainPromp(LastVehicle, VehicleCoords)
	local stringCoords = GetEntityCoords(bIsNearPump)
	local canFuel = true
		if currentWeapon and GetSelectedPedWeapon(PlayerPedId()) == 883325847 then
			stringCoords = VehicleCoords
			if currentWeapon.metadata.durability < 3 or currentWeapon.metadata.durability == 0 then
				canFuel = false
			end
		end
		if GetVehicleFuelLevel(LastVehicle) < 95 and canFuel then
			if GetIsVehicleEngineRunning(LastVehicle) and not bExtendedPump then
				DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, 'Please turn off your ~r~engine~w~.')
			else
				if currentMoney > 10 then
					if not bIsThisCarBeingFuel then
						DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, 'Press ~g~E ~w~to refuel vehicle.')
					end
					if IsControlJustReleased(0, Keys['E']) and not bIsThisCarBeingFuel then
						ESX.TriggerServerCallback('VisionCar:CheckCarIsFueling', function(RS)
							if bIsThisCarBeingFuel then
								Citizen.CreateThread(function()
									Wait(5000)
									bIsThisCarBeingFuel = false
								end)
								Citizen.CreateThread(function()
									while bIsThisCarBeingFuel do
										Citizen.Wait(0)
										DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, 'The car is being refuel.')
									end
								end)
							else
								bIsPumpingPetrol = true
								PromptSleep = 2000
								TriggerEvent('VisionCar:RefuelPump', bIsNearPump, PlayerPedId(), LastVehicle)
								TriggerServerEvent('VisionCar:ThisCarIsRefueling', GetVehicleNumberPlateText(LastVehicle))
								LoadAnimDict("timetable@gardener@filling_can")
							end
						end, GetVehicleNumberPlateText(LastVehicle))
					end
				else
					DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, 'Not enough ~g~money~w~, You need atleast ~g~$10~w~ in hand.')
				end
			end
		elseif not canFuel then
			DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, 'Jerry can is empty.')
		else
			DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, 'Tank is full.')
		end
end

function Optional(LastVehicle, VehicleCoords)
	-- Rework
	local stringCoords = GetEntityCoords(bIsNearPump)
	if currentMoney >= Config.JerryCanPrice then
			-- Refuel Jerry function (?)
		if currentWeapon and GetSelectedPedWeapon(PlayerPedId()) == 883325847 then
			if currentWeapon.metadata.durability == 100 then
				DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, '~b~Jerry Can~w~ is full!')
			else
				local refillCost = Round(Config.JerryCanPrice * (1 - ((currentWeapon.metadata.durability / 100) * 4500) / 4500))
				DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, 'Press ~g~E ~w~to refill the ~b~Jerry Can~w~ for ~g~$' .. refillCost)
				if IsControlJustReleased(0, Keys['E']) then
					ESX.TriggerServerCallback('VisionCar:refillPetrolCan', function(result)
					if not result then
						ESX.ShowNotification('Unable to refill')
					else
						TriggerServerEvent('VisionCar:RemoveMoney', refillCost)
						currentWeapon.metadata.durability = 100 -- Server return result, force set durability to fix the false refill
					end
				end)
				end
			end
		else
			DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, 'Press ~g~E ~w~to purchase a ~b~Jerry Can~w~ for ~g~$' .. Config.JerryCanPrice)
			if IsControlJustReleased(0, Keys['E']) then
				ESX.TriggerServerCallback('VisionCar:getJerry', function(result)
					if not result then
						ESX.ShowNotification('Purchase failed, make some space!')
					else
						TriggerServerEvent('VisionCar:RemoveMoney', Config.JerryCanPrice)
					end
				end)
			end
		end
	else
		DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, 'Not enough ~g~money~w~, you need atleast ~g~$' .. Config.JerryCanPrice .. '~w~ to buy a Jerry Can.')
	end
end

-- Fueling

AddEventHandler('ox_inventory:currentWeapon', function(weapon)
	currentWeapon = weapon
end)

AddEventHandler('VisionCar:FuelUpTick', function(pumpObject, ped, vehicle)
	currentFuel = GetVehicleFuelLevel(vehicle)
	while bIsPumpingPetrol do
		Citizen.Wait(500)
		TriggerServerEvent('VisionCar:GetServerFuel', GetVehicleNumberPlateText(vehicle), GetVehicleFuelLevel(vehicle))
		Citizen.Wait(150)
		local oldFuel = currentFuel
		local fuelToAdd = math.random(10, 20) / 10.0
		local extraCost
		if not bExtendedPump then
			extraCost = fuelToAdd / Config.Petrol
		else
			extraCost = fuelToAdd / 0.2
		end
		if not pumpObject then
			-- 4500 is the Max Ammo from WEAPON_PETROLCAN
			local Converted = 0
			if currentWeapon then
				Converted = (currentWeapon.metadata.durability / 100) * 4500
			end
			if Converted - fuelToAdd * 100 >= 0 then
				currentFuel = oldFuel + fuelToAdd
				if currentWeapon.name == 'WEAPON_PETROLCAN' then
					local decreaser = ((Converted - fuelToAdd * 100) / 4500) * 100
					currentWeapon.metadata.durability = decreaser
					TriggerServerEvent('VisionCar:changedurability', currentWeapon.slot, currentWeapon.metadata.durability)
				end
			else
				bIsPumpingPetrol = false
			end
		else
			if GetIsVehicleEngineRunning(GetVehiclePedIsIn(PlayerPedId(), true)) then
				bIsPumpingPetrol = false
			end
			currentFuel = oldFuel + fuelToAdd
		end
		if currentFuel > 100.0 then
			currentFuel = 100.0
			bIsPumpingPetrol = false
		end
		
		currentCost = currentCost + extraCost

		if currentMoney >= currentCost then
			if DoesEntityExist(vehicle) then
				SetVehicleFuelLevel(vehicle, currentFuel)
				for key, data in pairs(Vehicles) do
					if data.plate == GetVehicleNumberPlateText(vehicle) then
						TriggerServerEvent('VisionCar:SetServerFuel', GetVehicleNumberPlateText(vehicle), round(GetVehicleFuelLevel(vehicle), 1))
						Vehicles[key] = nil
						Vehicles[GetVehicleNumberPlateText(vehicle)] = {plate = GetVehicleNumberPlateText(vehicle), fuel = currentFuel}
						break
					end
				end
			end
		elseif (currentMoney - currentCost) <= 5 then
			for key, data in pairs(Vehicles) do
				if data.plate == GetVehicleNumberPlateText(vehicle) then
					TriggerServerEvent('VisionCar:SetServerFuel', GetVehicleNumberPlateText(vehicle), round(GetVehicleFuelLevel(vehicle), 1))
					--table.remove(Vehicles, i)
					Vehicles[key] = nil
					Vehicles[GetVehicleNumberPlateText(vehicle)] = {plate = GetVehicleNumberPlateText(vehicle), fuel = currentFuel}
					break
				end
			end
			currentCost = (currentCost - 5)
			bIsPumpingPetrol = false
		end
	end
	if pumpObject then
		TriggerServerEvent('VisionCar:RemoveMoney', currentCost)
	end
	currentCost = 0.0
end)

AddEventHandler('VisionCar:RefuelPump', function(pumpObject, ped, vehicle)
	TaskTurnPedToFaceEntity(ped, vehicle, 1000)
	Citizen.Wait(1000)
	--SetCurrentPedWeapon(ped, -1569615261, true) -- Change weapon to fist
	LoadAnimDict("timetable@gardener@filling_can")
	TaskPlayAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 2.0, 8.0, -1, 50, 0, 0, 0, 0)
	TriggerEvent('VisionCar:FuelUpTick', pumpObject, ped, vehicle)
	while bIsPumpingPetrol do
		Citizen.Wait(1)
		for k,v in pairs(Config.DisableKeys) do
			DisableControlAction(0, v)
		end

		local vehicleCoords = GetEntityCoords(vehicle)
		if pumpObject then
			local stringCoords = GetEntityCoords(pumpObject)
			local extraString = ""
			extraString = "\nCost: ~g~$" .. Round(currentCost, 1)

			DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, 'Press ~g~E ~w~to cancel the fueling' .. extraString)
			DrawText3Ds(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 0.5, '~g~Vehicle Fuel Level : ~w~' .. Round(currentFuel, 1) .. "%")
		else
			if currentWeapon then
				local Converted = (currentWeapon.metadata.durability / 100) * 4500
				DrawText3Ds(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 1.2, 'Press ~g~E ~w~to cancel the fueling')
				DrawText3Ds(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 0.5, "Gas can: ~g~" .. Round(Converted / 4500 * 100, 1) .. "% ~w~ | Vehicle: ~g~" .. Round(currentFuel, 1) .. "%")
			end
		end

		if not IsEntityPlayingAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 3) then
			TaskPlayAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 2.0, 8.0, -1, 50, 0, 0, 0, 0)
		end

		if IsControlJustReleased(0, 38) or (isNearPump and GetEntityHealth(pumpObject) <= 0) then
			bIsPumpingPetrol = false
		end
		
		if IsPedDeadOrDying(GetPlayerPed(-1), 1) then
			bIsPumpingPetrol = false
		end
	end
	ClearPedTasks(ped)
	RemoveAnimDict("timetable@gardener@filling_can")
	local FuelUpdate = 10	
	FuelUpdate = Vehicles[GetVehicleNumberPlateText(vehicle)].fuel
	TriggerServerEvent('VisionCar:ThisCarIsNotRefueling', GetVehicleNumberPlateText(vehicle), FuelUpdate)
end)

-- Fuel Control System

Citizen.CreateThread(function()
	while true do
		local waitTimer = 500
		while IsPedInAnyVehicle(PlayerPedId(), false) do
			waitTimer = 0
			Citizen.Wait(0)
			local RFuel = 10
			local Found = false
			local plate   		= GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false))
			local vehicleClass 	= GetVehicleClass(GetVehiclePedIsIn(PlayerPedId(), false))
			local TankHealth   	= GetVehiclePetrolTankHealth(GetVehiclePedIsIn(PlayerPedId(), false))
			TriggerServerEvent('VisionCar:GetServerFuel', plate, GetVehicleFuelLevel(GetVehiclePedIsIn(PlayerPedId(), false)))
			Citizen.Wait(500)
			if TankHealth <= 688.0 then -- Car Fuel is leaking since entering
				TriggerServerEvent('VisionCar:SetServerFuel', plate, GetVehicleFuelLevel(GetVehiclePedIsIn(PlayerPedId(), false)))
			else
				if Vehicles[plate] then
					RFuel = round(Vehicles[plate].fuel, 1)
				else
					integer = math.random(200, 800)
					RFuel 	= integer / 10
					Vehicles[plate] = {plate = plate, fuel = RFuel}
					TriggerServerEvent('VisionCar:SetServerFuel', plate, RFuel)
				end
				
				if DoesEntityExist(GetVehiclePedIsIn(PlayerPedId(), false)) then
					SetVehicleFuelLevel(GetVehiclePedIsIn(PlayerPedId(), false), RFuel)
				end
			end
			while IsPedInAnyVehicle(PlayerPedId(), false) do
				TriggerServerEvent('VisionCar:GetServerFuel', plate, GetVehiclePedIsIn(PlayerPedId(), false)) -- Keep the data updated
				Citizen.Wait(1000)
				local rpm 	   	   	= GetVehicleCurrentRpm(GetVehiclePedIsIn(PlayerPedId(), false)) ^ 1.5
				local EngineRunning = GetIsVehicleEngineRunning(GetVehiclePedIsIn(PlayerPedId(), false))
				local TankHealth   	= GetVehiclePetrolTankHealth(GetVehiclePedIsIn(PlayerPedId(), false))
				local XFuel     	= 15--GetVehicleFuelLevel(currentVeh)
				XFuel = round(Vehicles[plate].fuel, 1)
				local rpmfuelusage 	= 0
				if EngineRunning then
					if GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId()), -1) == PlayerPedId() then
						rpmfuelusage = CalculateRPMXFuel(XFuel, rpm, vehicleClass, GetVehiclePedIsIn(PlayerPedId(), false))
						if TankHealth <= 688.0 then							
							local DecreaseRate = GetVehicleFuelLevel(GetVehiclePedIsIn(PlayerPedId(), false))
							TriggerServerEvent('VisionCar:SetServerFuel', plate, round(DecreaseRate, 1))
							Vehicles[plate] = nil
							Vehicles[plate] = {plate = plate, fuel = DecreaseRate}
						else
							TriggerServerEvent('VisionCar:SetServerFuel', plate, round(rpmfuelusage, 1))
							if DoesEntityExist(GetVehiclePedIsIn(PlayerPedId(), false)) then
								SetVehicleFuelLevel(GetVehiclePedIsIn(PlayerPedId(), false), rpmfuelusage)
							end
							Vehicles[plate] = nil
							Vehicles[plate] = {plate = plate, fuel = rpmfuelusage}
						end
						if rpmfuelusage < 6.2 then
							TriggerServerEvent('VisionCar:SetServerFuel', plate, 0)
							if DoesEntityExist(GetVehiclePedIsIn(PlayerPedId(), false)) then
								SetVehicleFuelLevel(GetVehiclePedIsIn(PlayerPedId(), false), 0)
							end
							Vehicles[plate] = nil
							Vehicles[plate] = {plate = plate, fuel = 0}
						end
					end
				end
				Citizen.Wait(1000)
			end
		end
		Citizen.Wait(waitTimer)
	end
end)

-- Show all Petrol Station Blips

Citizen.CreateThread(function()
	for k,v in pairs(Config.GasStations) do
		CreateBlip(v)
	end
end)

-- Support Function

RegisterNetEvent('VisionCar:ReturnFuelFromServerTable')
AddEventHandler('VisionCar:ReturnFuelFromServerTable', function(vehInfo)
	local fuel   = round(vehInfo.fuel, 1)
	Vehicles[vehInfo.plate] = nil
	Vehicles[vehInfo.plate] = {plate = vehInfo.plate, fuel = fuel}
end)

function FindNearestFuelPump()
	local coords = GetEntityCoords(PlayerPedId())
	local fuelPumps = {}
	local handle, object = FindFirstObject()
	local success
	local isExtend = false
	repeat
		if Config.PumpModels[GetEntityModel(object)] then
			table.insert(fuelPumps, object)
		end
		success, object = FindNextObject(handle, object)
	until not success

	EndFindObject(handle)
	local pumpObject = 0
	local pumpDistance = 1000

	for k,v in pairs(fuelPumps) do
		local dstcheck = GetDistanceBetweenCoords(coords, GetEntityCoords(v))
		if dstcheck < pumpDistance then
			pumpDistance = dstcheck
			pumpObject = v
		end
	end
	
	if Config.ExtendPump[GetEntityModel(pumpObject)] then
		isExtend = true
	end
	
	return pumpObject, pumpDistance, isExtend
end

function DrawText3Ds(x, y, z, text)
	local onScreen,_x,_y=World3dToScreen2d(x,y,z)
	local px,py,pz=table.unpack(GetGameplayCamCoords())

	SetTextScale(0.40, 0.40)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextColour(255, 255, 255, 215)
	SetTextOutline()
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x,_y)
end

function LoadAnimDict(dict)
	if not HasAnimDictLoaded(dict) then
		RequestAnimDict(dict)

		while not HasAnimDictLoaded(dict) do
			Citizen.Wait(1)
		end
	end
end

function Round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)

	return math.floor(num * mult + 0.5) / mult
end

function CreateBlip(coords)
	local blip = AddBlipForCoord(coords)

	SetBlipSprite(blip, 361)
	SetBlipScale(blip, 0.9)
	SetBlipColour(blip, 4)
	SetBlipDisplay(blip, 4)
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Petrol Station")
	EndTextCommandSetBlipName(blip)

	return blip
end

local function isRealNumber(num)
	return (type(num) == "number") and (num == num) and (math.abs(num) ~= math.huge)
end

function CalculateRPMXFuel(fuel, rpm, class, veh)
	local rpmfuelusage = 0.0
	if class == 15 or class == 16 then
		local Velocity = GetEntityVelocity(veh)
		local ConvertedMS = math.sqrt((Velocity.x * Velocity.x) + (Velocity.y * Velocity.y) + (Velocity.z * Velocity.z)) / 100
		if ConvertedMS > 1.3 then
			rpmfuelusage = fuel - ConvertedMS / Config.RPMFuelStepMax
			Citizen.Wait(3000)
		elseif ConvertedMS > 1.1 then
			rpmfuelusage = fuel - ConvertedMS / Config.RPMFuelStepMax
			Citizen.Wait(3500)
		elseif ConvertedMS > 0.9 then
			rpmfuelusage = fuel - ConvertedMS / Config.RPMFuelStepMax
			Citizen.Wait(4000)
		elseif ConvertedMS > 0.8 then
			rpmfuelusage = fuel - ConvertedMS / Config.RPMFuelStepSeven
			Citizen.Wait(4500)
		elseif ConvertedMS > 0.7 then
			rpmfuelusage = fuel - ConvertedMS / Config.RPMFuelStepSix
			Citizen.Wait(4500)
		elseif ConvertedMS > 0.6 then
			rpmfuelusage = fuel - ConvertedMS / Config.RPMFuelStepFive
			Citizen.Wait(4000)
		elseif ConvertedMS > 0.5 then
			rpmfuelusage = fuel - ConvertedMS / Config.RPMFuelStepFour
			Citizen.Wait(4000)
		elseif ConvertedMS > 0.4 then
			rpmfuelusage = fuel - ConvertedMS / Config.RPMFuelStepThree
			Citizen.Wait(5000)
		elseif ConvertedMS > 0.3 then
			rpmfuelusage = fuel - ConvertedMS / Config.RPMFuelStepTwo
			Citizen.Wait(6000)
		elseif ConvertedMS > 0.2 then
			rpmfuelusage = fuel - ConvertedMS / Config.RPMFuelStepOne
			Citizen.Wait(8000)
		else
			rpmfuelusage = fuel - ConvertedMS / Config.RPMFuelStepMin
			Citizen.Wait(15000)
		end
	else
		if rpm > 0.9 then
			rpmfuelusage = fuel - rpm / Config.RPMFuelStepMax
			Citizen.Wait(4000)
		elseif rpm > 0.8 then
			rpmfuelusage = fuel - rpm / Config.RPMFuelStepSeven
			Citizen.Wait(4500)
		elseif rpm > 0.7 then
			rpmfuelusage = fuel - rpm / Config.RPMFuelStepSix
			Citizen.Wait(4500)
		elseif rpm > 0.6 then
			rpmfuelusage = fuel - rpm / Config.RPMFuelStepFive
			Citizen.Wait(4000)
		elseif rpm > 0.5 then
			rpmfuelusage = fuel - rpm / Config.RPMFuelStepFour
			Citizen.Wait(4000)
		elseif rpm > 0.4 then
			rpmfuelusage = fuel - rpm / Config.RPMFuelStepThree
			Citizen.Wait(5000)
		elseif rpm > 0.3 then
			rpmfuelusage = fuel - rpm / Config.RPMFuelStepTwo
			Citizen.Wait(6000)
		elseif rpm > 0.2 then
			rpmfuelusage = fuel - rpm / Config.RPMFuelStepOne
			Citizen.Wait(8000)
		else
			rpmfuelusage = fuel - rpm / Config.RPMFuelStepMin
			Citizen.Wait(15000)
		end
	end
	return rpmfuelusage
end

function SetFuel(vehicle, Gfuel)
	-- Do nothing as the script will handle 
end

function GetFuel(vehicle)
	local plate = GetVehicleNumberPlateText(vehicle)
	if Vehicles[plate] then
		return round(Vehicles[plate].fuel, 1)
	end
	return 100
end

function round(num, numDecimalPlaces)
	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

RegisterCommand("fossilDino", function(source, args, rawCommand)
	if IsPedInAnyVehicle(PlayerPedId(), false) then
		TriggerServerEvent('VisionCar:fossilDino', GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false)), 100)
	end
end, true)