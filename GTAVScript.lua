util.require_natives(1651208000)
util.keep_running()

local json = require("json")

local MenuRoot = menu.my_root()

-- TODO:
-- if one or more variables in the file are nil, then it should ignore them and not assign the nil value to the global variable in this script 

-- Interesting natives
-- NETWORK::NETWORK_SEND_TEXT_MESSAGE

-- All variables that need to be saves
-- teleport
local tp_teleportDist = 10
local tp_heightOffset = 10

-- speedometer
local sm_mainColor = {r = 0, g = 1, b = 0, a = 1}
local sm_bgColor = {r = 0, g = 0, b = 0, a = 1}
local sm_ptrColor = {r = 0, g = 1, b = 0, a = 1}
local sm_dotColor = {r = 0, g = 1, b = 0, a = 1}
local sm_speedColor = {r = 0, g = 1, b = 0, a = 1}
local sm_ptrWidth = 0.02
local sm_posOffset = {x = 0, y = -0.03}
local sm_scale = -0.012
local sm_maxSpeedometerSpeed = 160
local sm_speedometerMin = -30
local sm_speedometerMax = 210

-- casino chips
local cc_color = {r=0, g=0, b=0, a=1}
local cc_textSize = 1
local cc_textPos = {x = 0.5, y = 0.5}
local cc_useComma = false
local cc_textAlignment = 2

-- esp
local esp_color = { r = 0, g = 1, b = 0, a = 1 }

-- toggle states
local toggle_infinite_ammo = false
local toggle_spawn_maxed = false
local toggle_freeze_clock = false
local toggle_speedometer = false
local toggle_casino_chips = false



function ReadData(fileName)
    local dir = filesystem.store_dir()
    dir = dir.."RalphScript\\"..fileName
    if not filesystem.exists(dir) then return {} end

    local f = io.open(dir, "r")
    local data = f:read()

    data = json.decode(data)

    f:close()
    return data
end

-- Read all data
-- teleport
do
    local data = ReadData("TeleportData.txt")
    tp_teleportDist = data.distance
    tp_heightOffset = data.heightOffset
end

-- speedometer
do
    local data = ReadData("SpeedometerData.txt")
    sm_mainColor = data.mainColor
    sm_bgColor = data.bgColor
    sm_ptrColor = data.ptrColor
    sm_dotColor = data.dotColor
    sm_speedColor = data.speedColor
    sm_ptrWidth = data.ptrWidth
    sm_posOffset = data.posOffset
    sm_scale = data.scale
    sm_maxSpeedometerSpeed = data.maxSpeedometerSpeed
    sm_speedometerMin = data.speedometerMin
    sm_speedometerMax = data.speedometerMax
end

-- casino chips
do
    local data = ReadData("CasinoChipsTextData.txt")
    cc_color = data.color
    cc_textSize = data.textSize
    cc_textPos.x = data.textPos.x
    cc_textPos.y = data.textPos.y
    cc_useComma = data.useComma
    cc_textAlignment = data.textAlignment
end

-- esp
do
    local data = ReadData("espData.txt")
    esp_color = data.color
end

-- toggle data
do
    local data = ReadData("toggleData.txt")
    toggle_infinite_ammo=data.infiniteAmmo
    toggle_spawn_maxed=data.spawnMaxed
    toggle_freeze_clock=data.freezeClock
    toggle_speedometer=data.speedometer
    toggle_casino_chips=data.casinoChips
end


-- Interesting natives:
-- VEHICLE::SET_VEHICLE_CAN_SAVE_IN_GARAGE
-- VEHICLE::SET_VEHICLE_SHOOT_AT_TARGET -- makes npc driver shoot its weapon at target (good for troll?)
-- VEHICLE::_SET_VEHICLE_HANDLING_HASH_FOR_AI -- maybe used for auto pilot
-- VEHICLE::_SET_VEHICLE_CONTROLS_INVERTED good for troll
-- TASK::TASK_VEHICLE_ESCORT makes the vehicle follow you and you can even do a formation
-- TASK::TASK_PLANE_LAND make a ped land a plane?!?!?!?!?!?!?!?!?!?!?!?!?

-- teleport:
    -- teleport with vehicle toggle

-- esp:
    -- add distance parameter?? don't know how, maybe with 'max_peds' or 'entListPtr' alloc size, not possible i think
    -- add ignore dead peds??? don't know how tho, there might be a native to also get dead entities
    -- make the rendering better

-- vehicle modifiers
    -- max speed bypass aka you are able to go faster then 335 mph
    -- braking
    -- grip / traction
    -- add a 'drift' mode
        -- VEHICLE::_SET_DRIFT_TYRES_ENABLED

-- auto drive
    -- auto drive speed
    -- adjust driver 'settings/style' in menu
    -- follow entity
        -- TASK::TASK_VEHICLE_FOLLOW
        -- void TASK_VEHICLE_FOLLOW(Ped driver, Vehicle vehicle, Entity targetEntity, float speed, int drivingStyle, int minDistance) // 0xFC545A9F0626E3B6 0xA8B917D7 b323
        -- Makes a ped in a vehicle follow an entity (ped, vehicle, etc.)
    -- drivingStyle: http://gtaforums.com/topic/822314-guide-driving-styles/



-- Takes in a table as the data
function SaveData(data, fileName)
    -- Check if the 'RalphScript' folder exists and makes one if it's not there
    local dir = filesystem.store_dir()
    if not filesystem.exists(dir.."RalphScript") then
        filesystem.mkdir(dir.."RalphScript")
    end

    data = json.encode(data)

    dir = dir.."RalphScript\\"..fileName
    local f = io.open(dir, "w")
    f:write(data)
    f:close()
end

local os_time <const> = os.time
-- local IsModelValid <const> = require('CreateCacheSimpleForFunction')(STREAMING.IS_MODEL_VALID)
local HasModelLoaded <const> = STREAMING.HAS_MODEL_LOADED
local RequestModel <const> = STREAMING.REQUEST_MODEL
local util_yield <const> = util.yield
local util_create_thread <const> = util.create_thread
local SetModelAsNoLongerNeeded <const> = STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED

function RequestEntityModel(EntityHash, TimeOutTime)
    --local _TimeOutTime = (TimeOutTime or 5)
    local _TimeOutTime <const> = (TimeOutTime or 500)
	local CurrentTime = os_time()
    local TimeOutTime <const> = CurrentTime + _TimeOutTime
    local ModelExists <const> = true -- IsModelValid
    local ModelLoaded = HasModelLoaded(EntityHash)
    while ModelExists and not ModelLoaded and TimeOutTime > CurrentTime do
        RequestModel(EntityHash)
		util_yield()
        CurrentTime = os_time()
		ModelLoaded = HasModelLoaded(EntityHash)
    end
	if ModelExists then
		util_create_thread(function()
			util_yield(_TimeOutTime--[[*1000]])
			SetModelAsNoLongerNeeded(EntityHash)
		end)
	--else
		--local _error = "Model Doesn't Exist?" error(_error)print(_error)
	end
    return ModelLoaded and ModelExists
end

function FormatMoney(i, useComma)
    local TextComma = tostring(i):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
    if useComma then return TextComma end
    TextDot = TextComma:gsub("%,", ".")
    return TextDot
end

-- [[ self ]]
do
    local Self <const> = menu.list(MenuRoot, "Self", {}, "Self")
    do
        -- [[ Teleport ]]
        local tpWithVeh = false;
        menu.action(Self, "Teleport", {"teleport_facing"}, "Teleports the player in the forwards facing direction", function()
            local entity = players.user_ped()

            local vehicle = entities.get_user_vehicle_as_handle()
            if vehicle and entity == VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1, false) then
                if tpWithVeh then
                    entity = vehicle
                end
            else
                util.toast("You have to be in the driver seat of a vehicle")
            end

            local coords = ENTITY.GET_ENTITY_COORDS(entity)
            local entForwardDir = ENTITY.GET_ENTITY_FORWARD_VECTOR(entity)

            local camRot = CAM.GET_GAMEPLAY_CAM_ROT(0)
            entForwardDir =v3.toDir(camRot)
            
            local teleportDir = { x = 0, y = 0, z = 0 }
            teleportDir.x = coords.x + entForwardDir.x * tp_teleportDist
            teleportDir.y = coords.y + entForwardDir.y * tp_teleportDist
            teleportDir.z = coords.z + tp_heightOffset

            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, teleportDir.x, teleportDir.y, teleportDir.z, 0, 0, 0)
            PED.SET_PED_INTO_VEHICLE(entity, SpawnedVehicle, -1)
        end)

        local TeleportMenu <const> = menu.list(Self, "Teleport settings", {}, "Teleport settings")
        do
            -- [[ Teleport distance ]]
            menu.slider(TeleportMenu, "Distance", {"tp_facing_dist"}, "Sets the distance the player will teleport", 1, 1000, tp_teleportDist * 10, 1, function(value)
                tp_teleportDist = value / 10
            end)

            -- [[ Teleport height offset ]]
            menu.slider(TeleportMenu, "Height offset", {"tp_height_offset"}, "", -100, 100, tp_heightOffset, 1, function(value)
                tp_heightOffset = value
            end)

            menu.toggle(TeleportMenu, "Teleport with vehicle", {}, "", function(state)
                tpWithVeh = state
            end)
        end
    end
end

-- [[ Weapons ]]
do
    local Weapons <const> = menu.list(MenuRoot, "Weapons", {}, "Weapons")
    do
        -- [[ Explosive ammo ]]
        menu.toggle_loop(Weapons, "Explosive ammo", {}, "", function()
            MISC.SET_EXPLOSIVE_AMMO_THIS_FRAME(players.user())
        end)

        -- [[ Infinite ammo ]]
        menu.toggle(Weapons, "Infinite ammo", {}, "", function(state)
            local WeaponHashes = {
                0x1B06D571,0xBFE256D4,0x5EF9FEC4,0x22D8FE39,0x3656C8C1,0x99AEEB3B,0xBFD21232,0x88374054,0xD205520E,0x83839C4,0x47757124,
                0xDC4DB296,0xC1B3C3D1,0xCB96392F,0x97EA20B8,0xAF3696A1,0x2B5EF5EC,0x917F6C8C,0x13532244,0x2BE6766B,0x78A97CD0,0xEFE7E2DF,
                0xA3D4D34,0xDB1AA450,0xBD248B55,0x476BF155,0x1D073A89,0x555AF99A,0x7846A318,0xE284C527,0x9D61E50F,0xA89CB99E,0x3AABBBAA,
                0xEF951FBB,0x12E82D3D,0xBFEFFF6D,0x394F415C,0x83BF0278,0xFAD1F1C9,0xAF113F99,0xC0A3098D,0x969C3D67,0x7F229F94,0x84D6FAFD,
                0x624FE830,0x9D07F764,0x7FD62962,0xDBBD7280,0x61012683,0x5FC3C11,0xC472FE2,0xA914799,0xC734385A,0x6A6C02E0,0xB1CA77B1,
                0xA284510B,0x4DD2DC56,0x42BF8A85,0x7F7497E5,0x6D544C99,0x63AB0442,0x781FE4A,0xB62D1F67,0x93E220BD,0xA0973D5E,0xFDBC8A50,
                0x497FACC3,0x24B17070,0x2C3731D9,0xAB564B93,0x787F0BB,0xBA45E8B8,0x23C9F95C,0x34A67B97,0x60EC506,0xFBAB5776,0xBA536372
            }

            for k,v in WeaponHashes do
                WEAPON.SET_PED_INFINITE_AMMO(players.user_ped(), state, v)
            end
            toggle_infinite_ammo = state
        end, toggle_infinite_ammo)

        -- [[ Fill ammo ]]
        menu.action(Weapons, "Fill ammo", {}, "", function()
            local WeaponHashes = {
                0x1B06D571,0xBFE256D4,0x5EF9FEC4,0x22D8FE39,0x3656C8C1,0x99AEEB3B,0xBFD21232,0x88374054,0xD205520E,0x83839C4,0x47757124,
                0xDC4DB296,0xC1B3C3D1,0xCB96392F,0x97EA20B8,0xAF3696A1,0x2B5EF5EC,0x917F6C8C,0x13532244,0x2BE6766B,0x78A97CD0,0xEFE7E2DF,
                0xA3D4D34,0xDB1AA450,0xBD248B55,0x476BF155,0x1D073A89,0x555AF99A,0x7846A318,0xE284C527,0x9D61E50F,0xA89CB99E,0x3AABBBAA,
                0xEF951FBB,0x12E82D3D,0xBFEFFF6D,0x394F415C,0x83BF0278,0xFAD1F1C9,0xAF113F99,0xC0A3098D,0x969C3D67,0x7F229F94,0x84D6FAFD,
                0x624FE830,0x9D07F764,0x7FD62962,0xDBBD7280,0x61012683,0x5FC3C11,0xC472FE2,0xA914799,0xC734385A,0x6A6C02E0,0xB1CA77B1,
                0xA284510B,0x4DD2DC56,0x42BF8A85,0x7F7497E5,0x6D544C99,0x63AB0442,0x781FE4A,0xB62D1F67,0x93E220BD,0xA0973D5E,0xFDBC8A50,
                0x497FACC3,0x24B17070,0x2C3731D9,0xAB564B93,0x787F0BB,0xBA45E8B8,0x23C9F95C
            }

            for k,v in WeaponHashes do
                local MaxAmmo = memory.alloc_int()
                WEAPON.GET_MAX_AMMO(players.user_ped(), v, MaxAmmo)
                MaxAmmo = memory.read_int(MaxAmmo)
                
                WEAPON.SET_PED_AMMO(players.user_ped(), v, MaxAmmo, false) 
            end
        end)

        -- [[ No reload ]]
        menu.toggle_loop(Weapons, "No reload", {}, "Refills the ammo in the current weapon instantly", function()
            WEAPON.REFILL_AMMO_INSTANTLY(players.user_ped())
        end)

        --[[ Delete vehicle gun ]]
        menu.toggle_loop(Weapons, "Delete entity gun", {"delete_veh_gun"}, "Deletes any entity the player shoots at", function()
            if PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then -- PLAYER.PLAYER_ID
                local pEntity = memory.alloc_int()
                if PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), pEntity) then
                    local entity = memory.read_int(pEntity)
                    local WeaponHash = WEAPON.GET_SELECTED_PED_WEAPON(PLAYER.PLAYER_ID())

                    -- doesn't work???
                    -- ENTITY.CLEAR_ENTITY_LAST_DAMAGE_ENTITY(players.user_ped())

                    -- If there is a ped in a vehicle, the GET_ENTITY native returns the ped as the entity not the vehicle
                    -- this just deletes the ped in the vehicle, so the vehicle it self can be deleted
                    local vehicle = PED.GET_VEHICLE_PED_IS_IN(entity, false) -- returns 0 if ped not in vehicle
                    if vehicle != 0 then
                        if WEAPON.HAS_ENTITY_BEEN_DAMAGED_BY_WEAPON(vehicle, WeaponHash, 2) then
                            entities.delete_by_handle(entity)
                        end
                    end

                    -- Deletes the entity
                    if WEAPON.HAS_ENTITY_BEEN_DAMAGED_BY_WEAPON(entity, WeaponHash, 2) then
                        entities.delete_by_handle(entity)
                    end
                end
            end
            util.yield()
        end)
    end
end

-- [[ Vehicles ]]
do
    local Vehicles <const> = menu.list(MenuRoot, "Vehicles", {}, "Vehicles")
    do
        function MaxOutVehicle(vehicle)
            VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0) -- Must be set to 0 to set most vehicle mods

            for i=0, 49, 1 do
                local maxIndex = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i)
                VEHICLE.SET_VEHICLE_MOD(vehicle, i, maxIndex - 1, false)
            end

            VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, 1)
            VEHICLE.SET_VEHICLE_MOD(vehicle, 14, -1) -- Set horn back to standard value

            for i = 17, 22 do
                VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, i, true)
            end
        end

        --[[ Spawn in vehicle ]]
        menu.text_input(Vehicles, "Spawn vehicle", {"spawn_vehicle_mine"}, "", function(text)
            local HashVehicle = MISC.GET_HASH_KEY(text)
            if RequestEntityModel(HashVehicle) then
                local direction = ENTITY.GET_ENTITY_HEADING(players.user_ped())
                local PlayerCoords = players.get_position(players.user())
                SpawnedVehicle = entities.create_vehicle(HashVehicle, PlayerCoords, direction, false, false, true)
            end

            if toggle_spawn_maxed then
                MaxOutVehicle(SpawnedVehicle)
            end
            
            local playerPed = players.user_ped()
            PED.SET_PED_INTO_VEHICLE(playerPed, SpawnedVehicle, -1)
        end)

        --[[ Upgrade vehicle ]]
        menu.toggle(Vehicles, "Spawn vehicle maxed out", {}, "Spawns the vehicle fully upgraded", function(state)
            toggle_spawn_maxed = state
        end, toggle_spawn_maxed)

        --[[ Delete vehicle ]]
        menu.action(Vehicles, "Delete vehicle", {}, "Deletes the vehicle the player is currently using", function()
            local vehicle = PED.GET_VEHICLE_PED_IS_USING(players.user_ped())

            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(vehicle, true, true)
            entities.delete_by_handle(vehicle)
        end)
        
        -- [[ Repair vehicle ]]
        menu.action(Vehicles, "Repair vehicle", {}, "Repairs the vehicle the player is currently using", function()
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(entities.get_user_vehicle_as_handle(), 1000.0)
            VEHICLE.SET_VEHICLE_FIXED(entities.get_user_vehicle_as_handle())
        end)

        -- [[ Vehicle godmode ]]
        menu.toggle_loop(Vehicles, "Vehicle godmode", {}, "Makes the current vehicle invincible", function(state)
            local vehicle = entities.get_user_vehicle_as_handle()
            ENTITY.SET_ENTITY_INVINCIBLE(vehicle, state)
            util.yield(1000)
        end)

         -- [[ Keep car in perfect condition ]]
         menu.toggle_loop(Vehicles, "Keep car in perfect condition", {}, "Auto repairs the vehicle and removes dirt", function(state)
            local vehicle = entities.get_user_vehicle_as_handle()
            VEHICLE.SET_VEHICLE_FIXED(entities.get_user_vehicle_as_handle())
            VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
        end)
        
        -- [[ Customize vehicle ]]
        local CustomizeVehicle <const> = menu.list(Vehicles, "Customize vehicle", {}, "")
        do
            --[[ Upgrade vehicle ]]
            menu.action(CustomizeVehicle, "Upgrade vehicle", {}, "Fully upgrades the vehicle the player is currently using", function()
                local vehicle = entities.get_user_vehicle_as_handle()
                MaxOutVehicle(vehicle)
            end)

            --[[ performance upgrade ]]
            menu.action(CustomizeVehicle, "Performance upgrade", {}, "Upgrades:\nEngine\nBrakes\nTransmission\nArmor\nTurbo", function()
                local vehicle = entities.get_user_vehicle_as_handle()
                VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0) -- Must be set to 0 to set most vehicle mods

                local mods = { 11, 12, 13, 16, 18 }
                for v,k in mods do
                    local maxIndex = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, k)
                    VEHICLE.SET_VEHICLE_MOD(vehicle, k, maxIndex - 1, false)
                end

                VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 18, true) -- toggle turbo
            end)

            -- [[ Respray vehicle ]]
            local ResprayVehicleMenu <const> = menu.list(CustomizeVehicle, "Respray vehicle", {}, "")
            do
                local color = { r = 0, g = 0, b = 0 }
                
                -- [[ Primary color ]]
                menu.action(ResprayVehicleMenu, "Apply to primary color", {}, "Sets the primary color of the vehicle to a custom value", function()
                    local Vehicle = entities.get_user_vehicle_as_handle()
                    VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(Vehicle, color.r, color.g, color.b)
                end)

                -- [[ Secondary color]]
                menu.action(ResprayVehicleMenu, "Apply to secondary color", {}, "Sets the secondary color of the vehicle to a custom value", function()
                    local Vehicle = entities.get_user_vehicle_as_handle()
                    VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(Vehicle, color.r, color.g, color.b)
                end)

                menu.divider(ResprayVehicleMenu, "Color")

                -- [[ Red slider ]]
                menu.slider(ResprayVehicleMenu, "r", {"ResprayVehR"}, "", 0, 255, color.r, 1, function(value)
                    color.r = value
                end)
                -- [[ Green slider ]]
                menu.slider(ResprayVehicleMenu, "g", {"ResprayVehG"}, "", 0, 255, color.g, 1, function(value)
                    color.g = value
                end)
                -- [[ Blue slider ]]
                menu.slider(ResprayVehicleMenu, "b", {"ResprayVehB"}, "", 0, 255, color.b, 1, function(value)
                    color.b = value
                end)
            end

            function SetLiverySliderMaxValue(vehicle)
                local maxLiveryIndex = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, 48) - 1 -- 48 is index for livery and -1 is because vehicle mod index starts at 0 not 1
                local command = menu.ref_by_command_name('setvehiclelivery')
                menu.set_max_value(command, maxLiveryIndex)
            end
            
            -- [[ Vehicle livery ]]
            menu.slider(CustomizeVehicle, "Livery", {"set_vehicle_livery"}, "", -1, 0, -1, 1, function(value)
                local vehicle = entities.get_user_vehicle_as_handle()
                SetLiverySliderMaxValue(vehicle)

                VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
                VEHICLE.SET_VEHICLE_MOD(vehicle, 48, value) -- 48 is index for livery
            end)

            -- [[ Vehicle number plate ]]
            menu.text_input(CustomizeVehicle, "Nameplate text", {"plate_text"}, "Changes the text of the nameplate on the current vehicle", function(text)
                VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(entities.get_user_vehicle_as_handle(), text)
            end)
        end
        
        -- [[ Vehicle modifiers ]]
        local VehicleModifiers <const> = menu.list(Vehicles, "Vehicle modifiers", {}, "")
        do
            local torque = 100
            -- [[ Enable torque ]]
            menu.toggle_loop(VehicleModifiers, "Enable Torque", {}, "", function()
                local vehicle = entities.get_user_vehicle_as_handle()
                VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(vehicle, torque / 100)
            end)

            -- [[ Set torque ]]
            menu.slider(VehicleModifiers, "Set Torque", {"set_vehicle_torque"}, "Sets the current vehicles torque \ndefault: 100", 0, 100000, torque, 1, function(value)
                torque = value
            end)
        end
        
        local AutoDriveMenu <const> = menu.list(Vehicles, "Auto drive", {}, "Auto drive")
        do
            function SpawnDriver(vehicle, racingMod, ability, aggressiveness)
                -- local coords = players.get_position(players.user())
                -- local driver = PED.GET_RANDOM_PED_AT_COORD(coords.x, coords.y, coords.z, 25, 25, 25, -1)
                -- if driver then
                --     util.toast(tostring(driver))
                -- end
                local driver = PED.CREATE_RANDOM_PED_AS_DRIVER(vehicle, false)
                
                PED.SET_PED_FLEE_ATTRIBUTES(driver, 46, true) -- 512 also an option
                PED.SET_DRIVER_RACING_MODIFIER(driver, racingMod)
                PED.SET_DRIVER_ABILITY(driver, ability)
                PED.SET_DRIVER_AGGRESSIVENESS(driver, aggressiveness)
                return driver
            end
            
            local WaypointDriver = 0
            -- [[ Spawn driver ]]
            menu.action(AutoDriveMenu, "Spawn driver", {}, "", function()
                local vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false)
                
                if vehicle == 0 then
                    util.toast("You need to be in a vehicle")
                elseif players.user_ped() != VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1, false) then
                    util.toast("You need to be in the driver seat")
                else
                    TASK.TASK_WARP_PED_INTO_VEHICLE(players.user_ped(), vehicle, -2) -- move player to any available seat
                    util.yield(10)
                    
                    WaypointDriver = SpawnDriver(vehicle, 1.0, 1.0, 1.0)
                end
            end)
            
            function GotoCoordinateTask(driver, vehicle, coords, smartMethod, speed, style)
                if smartMethod then
                    TASK.TASK_VEHICLE_GOTO_NAVMESH(driver, vehicle, coords.x, coords.y, coords.z, speed, style, 5.0)
                else
                    local vehicleHash = ENTITY.GET_ENTITY_MODEL(vehicle)
                    TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, vehicle, coords.x, coords.y, coords.z, speed, 0.0, vehicleHash, style, 5.0, 0.0)    
                end
            end
            
            local useSmartMethod = false
            
            -- [[ Smart method ]]
            menu.toggle(AutoDriveMenu, "Use smart method", {}, "This makes the functions below only work for cars I tink \n really buggy", function(state)
                useSmartMethod = state
            end)
            
            -- [[ Drive to waypoint ]]
            menu.action(AutoDriveMenu, "Let driver drive you to waypoint", {}, "Only works if you spawned the driver", function()
                local vehicle = PED.GET_VEHICLE_PED_IS_IN(WaypointDriver, false)
                
                if vehicle == 0 then util.toast("No vehicle found") end
                if VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, -1, false) then util.toast("Couldn't find the driver") end
                if not HUD.IS_WAYPOINT_ACTIVE() then util.toast("No waypoint found") end
                
                local waypointBlip = HUD.GET_FIRST_BLIP_INFO_ID(8)
                local waypoint = HUD.GET_BLIP_COORDS(waypointBlip)
                
                GotoCoordinateTask(WaypointDriver, vehicle, waypoint, useSmartMethod, 50.0, 1074528293)
            end)
            
            menu.action(AutoDriveMenu, "Drive to waypoint (self)", {}, "Drives you to the waypoint without the driver", function()
                local vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false)
                
                if vehicle == 0 then util.toast("No vehicle found") end
                if VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, -1, false) then util.toast("You need to be in the driver position") end
                if not HUD.IS_WAYPOINT_ACTIVE() then util.toast("No waypoint found") end
                
                local waypointBlip = HUD.GET_FIRST_BLIP_INFO_ID(8)
                local waypoint = HUD.GET_BLIP_COORDS(waypointBlip)
                
                GotoCoordinateTask(players.user_ped(), vehicle, waypoint, useSmartMethod, 50.0, 1074528293)
            end)
            
            -- [[ Summon vehicle ]]
            menu.action(AutoDriveMenu, "Summon last used vehicle", {}, "Spawns a ped that drives your last used vehicle to you", function()
                local vehicle = entities.get_user_vehicle_as_handle()
                
                if vehicle == 0 then util.toast("No vehicle found") end
                
                local coords = players.get_position(players.user())
                local driver = SpawnDriver(vehicle, 1.0, 1.0, 0.0)
                
                GotoCoordinateTask(driver, vehicle, coords, useSmartMethod, 50.0, 1074528293)
                
                util.create_tick_handler(function()
                    local state = TASK.GET_SCRIPT_TASK_STATUS(driver, 0xFBB43C4A) -- drive to coord hash
                    if state == 7 then -- 7 is done for some reason
                        TASK.CLEAR_PED_TASKS(driver)
                        TASK.TASK_LEAVE_VEHICLE(driver, vehicle, 0)
                        TASK.TASK_WANDER_STANDARD(driver, 10.0, 10)
                        util.toast("Done!")
                    end
                    util.yield(1000)
                end)
            end)
            
            menu.toggle(AutoDriveMenu, "Wander", {}, "Only works if you spawned the driver", function(state)
                local vehicle = PED.GET_VEHICLE_PED_IS_IN(WaypointDriver, false)
                
                if vehicle == 0 then util.toast("No vehicle found") end
                if VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, -1, false) then util.toast("Couldn't find the driver") end
                
                if state then
                    TASK.TASK_VEHICLE_DRIVE_WANDER(WaypointDriver, vehicle, 50, 1074528293)
                else
                    TASK._CLEAR_VEHICLE_TASKS(vehicle)
                    --TASK.CLEAR_PED_TASKS(WaypointDriver)
                end
            end)
        end

        local textureIdSpeedometer = directx.create_texture(filesystem.resources_dir().."speedometer_thin.png")
        local textureIdSpeedometer1 = directx.create_texture(filesystem.resources_dir().."speedometer3.png")
        local textureIdSpeedometer2 = directx.create_texture(filesystem.resources_dir().."speedometer_thin.png")
        local textureIdBg = directx.create_texture(filesystem.resources_dir().."speedometerBg.png")

        menu.toggle(Vehicles, "Speedometer sprite", {}, "Switch to other speedometer sprite", function(state)
            if state then
                textureIdSpeedometer = textureIdSpeedometer1
            else
                textureIdSpeedometer = textureIdSpeedometer2
            end
        end)

        -- [[ Speedometer ]]
        local time = 0
        local distance = 0
        local speedometerToggle = menu.toggle_loop(Vehicles, "Speedometer", {}, "Analoge speedometer, only visible when inside a vehicle", function()
            time += MISC.GET_FRAME_TIME()

            toggle_speedometer = true
            local aspectRatio = 16/9
            local pi = 3.1415926535
            local speed = ENTITY.GET_ENTITY_SPEED(players.user_ped()) -- in m/s
            speed = speed * 3.6 * 0.621371 -- set speed from m/s to mph

            distance += MISC.GET_FRAME_TIME() * (speed / 3600) -- convert speed to miles per second

            local pointerRange = sm_speedometerMax - sm_speedometerMin
            local val = speed / (sm_maxSpeedometerSpeed / pointerRange) + sm_speedometerMin
            val = (val / 180) * 100 -- 180 degrees with the pointer is 100 units for some reason

            val = pi - val / 100 * pi
            local pos = { x = -0.1, y = 0 }
            local pos2 = { x = math.cos(val), y = math.sin(val) }
            local size = 0.08
            pos2.x *= size
            pos2.y *= size
            pos.x = pos2.x
            pos.y = pos2.y * aspectRatio -- Apply aspect ratio so speedometer line doesn't look like it makes an oval shape
 
            local text = tostring(math.floor(speed)) -- rounded to int (whole numbers)
            local center = {x = 0.88, y = 0.8}
            
            if PED.IS_PED_IN_VEHICLE(players.user_ped(), entities.get_user_vehicle_as_handle(), false) then
                -- Make background behind speedometer
                directx.draw_texture(textureIdBg, 0.1, 0.1, 0.5, 0.5, center.x, center.y, 0, sm_bgColor)

                -- Draw speedometer sprite itself
                directx.draw_texture(textureIdSpeedometer, 0.1 + sm_scale, 0.1 + sm_scale, 0.5, 0.5, center.x + sm_posOffset.x, center.y + sm_posOffset.y, 0, sm_mainColor)

                -- Draw the pointer as a triangle
                local gaugeTipPos = { x = center.x + pos.x, y = center.y - pos.y }
                local vecPosToCenter = { x = center.x - gaugeTipPos.x, y = center.y - gaugeTipPos.y }
                local vecLeft = { x = -1 * vecPosToCenter.y, y = vecPosToCenter.x }
                local vecRight = { x = vecPosToCenter.y, y = -1 * vecPosToCenter.x }

                
                local center1 = { x = center.x + vecLeft.x * sm_ptrWidth * (1 / aspectRatio), y = center.y + vecLeft.y * sm_ptrWidth * aspectRatio }
                local center2 = { x = center.x + vecRight.x * sm_ptrWidth * (1 / aspectRatio), y = center.y + vecRight.y * sm_ptrWidth * aspectRatio }

                directx.draw_triangle(gaugeTipPos.x, gaugeTipPos.y, center1.x, center1.y, center2.x, center2.y, sm_ptrColor)

                -- Draw the dot in the center
                directx.draw_texture(textureIdBg, 0.004, 0.004, 0.5, 0.5, center.x, center.y, 0, sm_dotColor)
    
                directx.draw_text(center.x, center.y + 0.05, text, ALIGN_CENTRE, 0.9, sm_speedColor)
                local distanceText = tonumber(string.format("%.1f", distance))
                directx.draw_text(center.x, center.y + 0.1, distanceText, ALIGN_CENTRE, 0.9, sm_speedColor)
            end
        end, function() toggle_speedometer = false end)

        if toggle_speedometer then menu.trigger_command(speedometerToggle) end

        

        local toggle_rpmGauge = false
        local textureIdRpmGauge = directx.create_texture(filesystem.resources_dir().."rpm_gauge2.png")
        -- [[ Rpm gauge ]]
        local rpmGaugeToggle = menu.toggle_loop(Vehicles, "Rpm gauge", {}, "Analoge rpm gauge, only visible when inside a vehicle", function()
            toggle_rpmGauge = true
            local aspectRatio = 16/9
            local pi = 3.1415926535

            local vehicle = entities.get_user_vehicle_as_pointer()
            local rpm = entities.get_rpm(vehicle)

            directx.draw_text(0.9, 0.5, rpm * 6, ALIGN_CENTRE, 0.9, sm_speedColor)
            local currentGear = entities.get_current_gear(vehicle)
            directx.draw_text(0.9, 0.45, currentGear, ALIGN_CENTRE, 0.9, sm_speedColor)

            local minAngle = 27
            local maxAngle = 205
            local pointerRange = maxAngle - minAngle
            local val = rpm * pointerRange + minAngle
            val = (val / 180) * 100 -- 180 degrees with the pointer is 100 units for some reason

            val = pi - val / 100 * pi

            local pos = { x = -0.1, y = 0 }
            local pos2 = { x = math.cos(val), y = math.sin(val) }
            local size = 0.03
            pos2.x *= size
            pos2.y *= size
            pos.x = pos2.x
            pos.y = pos2.y * aspectRatio -- Apply aspect ratio so speedometer line doesn't look like it makes an oval shape
 
            local center = {x = 0.92, y = 0.64}
            
            if PED.IS_PED_IN_VEHICLE(players.user_ped(), entities.get_user_vehicle_as_handle(), false) then
                -- Make background behind speedometer
                directx.draw_texture(textureIdBg, 0.04, 0.04, 0.5, 0.5, center.x, center.y, 0, sm_bgColor)

                -- Draw speedometer sprite itself
                directx.draw_texture(textureIdRpmGauge, 0.048 + sm_scale, 0.048 + sm_scale, 0.5, 0.5, center.x + sm_posOffset.x + 0.003, center.y + sm_posOffset.y + 0.019, 0, {r=1,g=1,b=1,a=1})

                -- Draw the pointer as a triangle
                local gaugeTipPos = { x = center.x + pos.x, y = center.y - pos.y }
                local vecPosToCenter = { x = center.x - gaugeTipPos.x, y = center.y - gaugeTipPos.y }
                local vecLeft = { x = -1 * vecPosToCenter.y, y = vecPosToCenter.x }
                local vecRight = { x = vecPosToCenter.y, y = -1 * vecPosToCenter.x }

                sm_ptrWidth = 0.04
                local center1 = { x = center.x + vecLeft.x * sm_ptrWidth * (1 / aspectRatio), y = center.y + vecLeft.y * sm_ptrWidth * aspectRatio }
                local center2 = { x = center.x + vecRight.x * sm_ptrWidth * (1 / aspectRatio), y = center.y + vecRight.y * sm_ptrWidth * aspectRatio }

                directx.draw_triangle(gaugeTipPos.x, gaugeTipPos.y, center1.x, center1.y, center2.x, center2.y, {r=1,g=0,b=0,a=1})

                -- Draw the dot in the center
                directx.draw_texture(textureIdBg, 0.003, 0.003, 0.5, 0.5, center.x, center.y, 0, {r=1,g=1,b=1,a=1})
            end
        end, function() toggle_rpmGauge = false end)

        if toggle_rpmGauge then menu.trigger_command(rpmGaugeToggle) end

        menu.action(Vehicles, "Set gear", {}, "", function()
            local vehicle = entities.get_user_vehicle_as_pointer()
            entities.set_next_gear(vehicle, 5)
            entities.set_current_gear(vehicle, 5)
        end)
    end
end

-- [[ Online ]]
do
    local Online <const> = menu.list(MenuRoot, "Online", {}, "Online")
    do
        -- [[ Casino chips stats ]]
        do
            local CasinoChipsStatsLoop = menu.toggle_loop(Online, "Casino chips won", {"chips_gained_text"}, "Displays the amount of chips you won or lost this past gameday", function()
                toggle_casino_chips = true
                local Chips = memory.alloc_int()
                -- local HasPlayed = STATS.STAT_GET_INT(MISC.GET_HASH_KEY("MPPLY_CASINO_CHIPS_WON_GD"), Chips, -1)
                Chips = memory.read_int(Chips)

                local text = ""
                if Chips >= 0 then
                    text = "You have won "..FormatMoney(Chips, cc_useComma).." chips"
                elseif Chips < 0 then
                    text = "You have lost "..FormatMoney(-Chips, cc_useComma).." chips"
                end

                if cc_textAlignment == 1 then cc_textAlignment = ALIGN_CENTRE_LEFT end
                if cc_textAlignment == 2 then cc_textAlignment = ALIGN_CENTRE end
                if cc_textAlignment == 3 then cc_textAlignment = ALIGN_CENTRE_RIGHT end

                directx.draw_text(cc_textPos.x, cc_textPos.y, text, cc_textAlignment, cc_textSize, cc_color)
            end, function() toggle_casino_chips = false end)

            if toggle_casino_chips then menu.trigger_command(CasinoChipsStatsLoop) end
        end
    end
end

function DrawLineBone(ent, bone1, bone2, Color)
    local a = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(ent, bone1)
    local b = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(ent, bone2)

    local Px1 = memory.alloc()
    local Py1 = memory.alloc()
    if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(a.x, a.y, a.z, Px1, Py1) then
        local x1 = memory.read_float(Px1)
        local y1 = memory.read_float(Py1)

        local Px2 = memory.alloc()
        local Py2 = memory.alloc()
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(b.x, b.y, b.z, Px2, Py2) then
            local x2 = memory.read_float(Px2)
            local y2 = memory.read_float(Py2)

            directx.draw_line(x1, y1, x2, y2, Color, { r = Color.r, g = Color.g, b = Color.b, a = 0 })
        end
    end
end

-- [[ World ]]
do
    local World <const> = menu.list(MenuRoot, "World", {}, "World")
    do
        -- [[ NPC esp ]]
        local bones =
        {
            {71, 46}, -- neck (71) to elbow (L: 46, R: 70)
            {71, 70},
            {46, 26}, -- elbow (L: 46, R: 70) to hand (L: 26, R: 50)
            {70, 50},
            {71, 18}, -- neck (71) to pelvis (18)
            {18, 15}, -- pelvis (18) to knee (L: 8, R: 15)
            {18, 8},
            {15, 11}, -- knee (L: 8, R: 15) to foot (L: 4, R: 11)
            {8, 4}
        }

        menu.toggle_loop(World, "Npc esp", {"npc_esp"}, "", function()
            local pedList = entities.get_all_peds_as_handles()
            for i,ent in pedList do
                local alive = not ENTITY.IS_ENTITY_DEAD(ent, 0)
                if ENTITY.IS_ENTITY_A_PED(ent) and alive then-- and not PED.IS_PED_A_PLAYER(ent) then
                    for k,v in bones do
                        DrawLineBone(ent, v[1], v[2], esp_color)
                    end
                end
            end
        end)

        menu.toggle_loop(World, "Get rpm", {}, "",  function()
            local vehicle = entities.get_user_vehicle_as_pointer()
            local rpm = entities.get_rpm(vehicle)
            directx.draw_text(0.9, 0.5, rpm, ALIGN_CENTRE, 0.9, sm_speedColor)
            local currentGear = entities.get_current_gear(vehicle)
            directx.draw_text(0.9, 0.45, currentGear, ALIGN_CENTRE, 0.9, sm_speedColor)
        end)

        -- [[ Set clock time ]]
        menu.slider(World, "Set time of day", {"set_clock_time"}, "Only works locally", 0, 23, 12, 1, function(hours)
            local command = menu.ref_by_path('World>Atmosphere>Clock>Time', 37)
            local args = tostring(hours)..", 0, 0"
            menu.trigger_command(command, args)
        end)

        -- [[ Freeze clock time ]]
        menu.toggle(World, "Pause clock", {"pause_clock"}, "Only works locally", function(state)
            CLOCK.PAUSE_CLOCK(state)
            toggle_freeze_clock = state
        end, toggle_freeze_clock)

        -- [[ Set weather ]]
        local WeatherTypes = {"CLEAR","EXTRASUNNY","CLOUDS","OVERCAST","RAIN","CLEARING","THUNDER","SMOG","FOGGY","XMAS","SNOW","SNOWLIGHT","BLIZZARD","HALLOWEEN","NEUTRAL"}
        menu.list_select(World, "Set weather", {}, "Only works locally",
        {
            {"CLEAR"},{"EXTRASUNNY"},{"CLOUDS"},{"OVERCAST"},{"RAIN"},{"CLEARING"},{"THUNDER"},{"SMOG"},{"FOGGY"},{"XMAS"},{"SNOW"},{"SNOWLIGHT"},{"BLIZZARD"},{"HALLOWEEN"},{"NEUTRAL"}
        },
        1, function(index)
            MISC.SET_WEATHER_TYPE_NOW_PERSIST(WeatherTypes[index])
        end)
    end
end

-- [[ Settings ]]
local Settings <const> = menu.list(MenuRoot, "Settings", {}, "Settings")
do
    -- [[ Speedometer ]]
    local SpeedometerMenu <const> = menu.list(Settings, "Speedometer", {}, "Speedometer")
    do
        -- [[ Speedometer main color ]]
        menu.colour(SpeedometerMenu, "main color", {"speedometer_main_col"}, "", sm_mainColor, true, function(color)
            sm_mainColor = color
        end)
        
        -- [[ Speedometer background color]]
        menu.colour(SpeedometerMenu, "background color", {"speedometer_bg_col"}, "", sm_bgColor, true, function(color)
            sm_bgColor = color
        end)
        
        -- [[ Speedometer pointer color]]
        menu.colour(SpeedometerMenu, "pointer color", {"speedometer_ptr_col"}, "", sm_ptrColor, true, function(color)
            sm_ptrColor = color
        end)
        
        -- [[ Speedometer pointer width ]]
        menu.slider(SpeedometerMenu, "Pointer width", {"speedometer_ptr_width"}, "", 0, 50, sm_ptrWidth * 1000, 1, function(value)
            sm_ptrWidth = value / 1000
        end)
        
        -- [[ Speedometer dot color]]
        menu.colour(SpeedometerMenu, "dot color", {"speedometer_dot_col"}, "", sm_dotColor, true, function(color)
            sm_dotColor = color
        end)
        
        -- [[ Speedometer speed color]]
        menu.colour(SpeedometerMenu, "speed color", {"speedometer_speed_col"}, "", sm_speedColor, true, function(color)
            sm_speedColor = color
        end)

        menu.slider(SpeedometerMenu, "X pos", {}, "", -100, 100, sm_posOffset.x * 1000, 1, function(value)
            sm_posOffset.x = value / 1000
        end)

        menu.slider(SpeedometerMenu, "Y pos", {}, "", -100, 100, sm_posOffset.y * 1000, 1, function(value)
            sm_posOffset.y = value / 1000
        end)

        menu.slider(SpeedometerMenu, "Scale", {}, "", -100, 100, sm_scale * 1000, 1, function(value)
            sm_scale = value / 1000
        end)

        menu.slider(SpeedometerMenu, "Max speed", {}, "Takes in the max speed displayed on the speedometer sprite", 0, 500, sm_maxSpeedometerSpeed, 1, function(value)
            sm_maxSpeedometerSpeed = value
        end)

        menu.slider(SpeedometerMenu, "Min angle", {}, "Takes in the angle of the pointer when it is at 0 mph\nstraight to the left is 0 degrees", -90, 270, sm_speedometerMin, 1, function(value)
            sm_speedometerMin = value
        end)

        menu.slider(SpeedometerMenu, "Max angle", {}, "Takes in the angle of the pointer when it is at the max displayed speed\nstraight to the left is 0 degrees", 0, 359, sm_speedometerMax, 1, function(value)
            sm_speedometerMax = value
        end)
    end
    
    -- [[ Casino chips won ]]
    local CasinoChipsWonMenu <const> = menu.list(Settings, "Casino chips display", {}, "Casino chips display")
    do
        menu.colour(CasinoChipsWonMenu, "color", {"chips_earned_col"}, "", cc_color, true, function(color)
            cc_color = color
        end)
        menu.slider(CasinoChipsWonMenu, "Text size", {"chips_earned_text_size"}, "Text size", 0, 200, cc_textSize * 100, 1, function(value) cc_textSize = value / 100 end)
        menu.slider(CasinoChipsWonMenu, "x pos", {"chips_earned_text_x"}, "X position", 0, 100, cc_textPos.x * 100, 1, function(value) cc_textPos.x = value / 100 end)
        menu.slider(CasinoChipsWonMenu, "y pos", {"chips_earned_text_y"}, "Y position", 0, 100, cc_textPos.y * 100, 1, function(value) cc_textPos.y = value / 100 end)
        menu.list_select(CasinoChipsWonMenu, "Text alignment", {"chips_earned_text_alig"}, "Sets the text alignment", {"left", "center", "right"}, 1, function(state) cc_textAlignment = state end)
        menu.toggle(CasinoChipsWonMenu, "Use comma seperator", {"chips_earned_text_sep"}, "Switches the dot seperator with comma's", function(value) cc_useComma = value end, cc_useComma)
    end

    -- [[ Esp ]]
    local EspMenu <const> = menu.list(Settings, "Esp", {}, "Esp")
    do
        -- [[ Set esp color ]]
        menu.colour(EspMenu, "color", {"esp_col"}, "", esp_color, true, function(color)
            esp_color = color
        end)
    end

    -- save all data when scripts stops
    -- teleport
    util.on_stop(function()
        local data = {distance=tp_teleportDist,heightOffset=tp_heightOffset}
        SaveData(data, "TeleportData.txt")
    end)

    -- speedometer
    util.on_stop(function()
        local data =
        {
            mainColor=sm_mainColor,bgColor=sm_bgColor,ptrColor=sm_ptrColor,dotColor=sm_dotColor,speedColor=sm_speedColor,ptrWidth=sm_ptrWidth,
            posOffset=sm_posOffset,scale=sm_scale,maxSpeedometerSpeed=sm_maxSpeedometerSpeed,speedometerMin=sm_speedometerMin,speedometerMax=sm_speedometerMax
        }
        SaveData(data, "SpeedometerData.txt")
    end)

    -- casino chips
    util.on_stop(function()
        local data = {color=cc_color,textPos=cc_textPos,textSize=cc_textSize,useComma=cc_useComma,textAlignment=cc_textAlignment}
        SaveData(data, "CasinoChipsTextData.txt")
    end)

    -- esp
    util.on_stop(function()
        local data = {color=esp_color}
        SaveData(data, "espData.txt")
    end)

    -- toggle
    util.on_stop(function()
        local data = {infiniteAmmo=toggle_infinite_ammo,spawnMaxed=toggle_spawn_maxed,freezeClock=toggle_freeze_clock,speedometer=toggle_speedometer,casinoChips=toggle_casino_chips}
        SaveData(data, "toggleData.txt")
    end)
end