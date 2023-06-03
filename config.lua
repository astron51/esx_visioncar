--====================================================================================
-- VisionCar Fuel System : Coded by Meowdy - campus9914
-- Redistribution is not allowed by any means, even after server closure!
-- Do not touch anything beside here, the config.lua
--====================================================================================


-- Constant , do not touch
Config = {}
Config.DisableKeys = {0, 22, 23, 24, 29, 30, 31, 37, 44, 56, 82, 140, 166, 167, 168, 170, 288, 289, 311, 323}

-- Price Config for Jerry Can
Config.JerryCanPrice = 300
Config.JerryCanRefill = 50

-- Price for Fuel
Config.Petrol = 0.5 -- Lower = More Expensive Fuel . Higher = More Cheap Fuel

-- Pump Model within Game
Config.PumpModels = {
	[-2007231801] = true,
	[1339433404] = true,
	[1694452750] = true,
	[1933174915] = true,
	[-462817101] = true,
	[-469694731] = true,
	[-164877493] = true,
	[-531344027] = true
}

-- What this does is basically tell the script that to extend the range of certain Pump to fuel up something like a plane
Config.ExtendPump = {
	[-531344027] = true
}

-- All Petrol Station within Game
Config.GasStations = {
	vector3(49.4187, 2778.793, 58.043),
	vector3(263.894, 2606.463, 44.983),
	vector3(1039.958, 2671.134, 39.550),
	vector3(1207.260, 2660.175, 37.899),
	vector3(2539.685, 2594.192, 37.944),
	vector3(2679.858, 3263.946, 55.240),
	vector3(2005.055, 3773.887, 32.403),
	vector3(1687.156, 4929.392, 42.078),
	vector3(1701.314, 6416.028, 32.763),
	vector3(179.857, 6602.839, 31.868),
	vector3(-94.4619, 6419.594, 31.489),
	vector3(-2554.996, 2334.40, 33.078),
	vector3(-1800.375, 803.661, 138.651),
	vector3(-1437.622, -276.747, 46.207),
	vector3(-2096.243, -320.286, 13.168),
	vector3(-724.619, -935.1631, 19.213),
	vector3(-526.019, -1211.003, 18.184),
	vector3(-70.2148, -1761.792, 29.534),
	vector3(265.648, -1261.309, 29.292),
	vector3(819.653, -1028.846, 26.403),
	vector3(1208.951, -1402.567,35.224),
	vector3(1181.381, -330.847, 69.316),
	vector3(620.843, 269.100, 103.089),
	vector3(2581.321, 362.039, 108.468),
	vector3(176.631, -1562.025, 29.263),
	vector3(176.631, -1562.025, 29.263),
	vector3(-319.292, -1471.715, 30.549),
	vector3(1784.324, 3330.55, 41.253)
}

-- Blacklisted Car , Model Name or Hash ID
Config.Blacklist = {
	--"Adder",
	--276773164
}

-- Fuel Compensation 
-- StepMin (Idle) <<<>>> StepMax (Max RPM)
-- 2.1 Fastest Fuel Decrease Rate
-- 7.4 Slowest Fuel Decrease Rate
Config.RPMFuelStepNine = 1.5
Config.RPMFuelStepEight = 1.9
Config.RPMFuelStepMax = 2.1
Config.RPMFuelStepSeven = 3.4
Config.RPMFuelStepSix = 3.9
Config.RPMFuelStepFive = 4.7
Config.RPMFuelStepFour = 5.7
Config.RPMFuelStepThree = 6.4
Config.RPMFuelStepTwo = 6.7
Config.RPMFuelStepOne = 6.9
Config.RPMFuelStepMin = 7.0

-- Fuel Check Timing
-- Minimum 5000     (5 Seconds)
-- Maximum 10000    (10 Seconds)
Config.FuelTiming = 5000