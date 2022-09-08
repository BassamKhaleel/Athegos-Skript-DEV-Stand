util.keep_running()
--require("natives-1640181023")
--require("natives-1606100775")
--util.require_natives(1627063482)
util.require_natives("natives-1660775568-uno")
util.toast("Athego's Script erfolgreich geladen! DEV Version 1.4")
ocoded_for = 1.61

local response = false
local localVer = 1.5
async_http.init("raw.githubusercontent.com", "/BassamKhaleel/Athegos-Skript-DEV-Stand/main/AthegosSkriptVersion", function(output)
    currentVer = tonumber(output)
    response = true
    if localVer ~= currentVer then
        util.toast("Eine neue Version von Athego‘s Skript ist verfügbar, bitte Update das Skript")
        menu.action(menu.my_root(), "Update Lua", {}, "", function()
            async_http.init('raw.githubusercontent.com','/BassamKhaleel/Athegos-Skript-DEV-Stand/main/Athegos_Script_DEV.lua',function(a)
                local err = select(2,load(a))
                if err then
                    util.toast("Fehler beim Updaten des Skript‘s. Probiere es später erneut. Sollte der Fehler weiterhin auftreten Update das Skript Manuell über GitHub.")
                return end
                local f = io.open(filesystem.scripts_dir()..SCRIPT_RELPATH, "wb")
                f:write(a)
                f:close()
                util.toast("Athego‘s Skript wurde erfolgreich Aktualisiert. Bitte starte das Skript neu :)")
                util.stop_script()
            end)
            async_http.dispatch()
        end)
    end
end, function() response = true end)
async_http.dispatch()
repeat 
    util.yield()
until response

local function player_toggle_loop(root, pid, menu_name, command_names, help_text, callback)
    return menu.toggle_loop(root, menu_name, command_names, help_text, function()
        if not players.exists(pid) then util.stop_thread() end
        callback()
    end)
end

all_players = {}

local createPed = PED.CREATE_PED
local getEntityCoords = ENTITY.GET_ENTITY_COORDS
local getPlayerPed = PLAYER.GET_PLAYER_PED
local requestModel = STREAMING.REQUEST_MODEL
local hasModelLoaded = STREAMING.HAS_MODEL_LOADED
local noNeedModel = STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED
local setPedCombatAttr = PED.SET_PED_COMBAT_ATTRIBUTES
local giveWeaponToPed = WEAPON.GIVE_WEAPON_TO_PED

local function BlockSyncs(pid, callback)
    for _, i in ipairs(players.list(false, true, true)) do
        if i ~= pid then
            local outSync = menu.ref_by_rel_path(menu.player_root(i), "Outgoing Syncs>Block")
            menu.trigger_command(outSync, "on")
        end
    end
    util.yield(10)
    callback()
    for _, i in ipairs(players.list(false, true, true)) do
        if i ~= pid then
            local outSync = menu.ref_by_rel_path(menu.player_root(i), "Outgoing Syncs>Block")
            menu.trigger_command(outSync, "off")
        end
    end
end


local function get_blip_coords(blipId)
    local blip = HUD.GET_FIRST_BLIP_INFO_ID(blipId)
    if blip ~= 0 then return HUD.GET_BLIP_COORDS(blip) end
    return v3(0, 0, 0)
end

local All_business_properties = {
    -- Clubhouses
    "1334 Roy Lowenstein Blvd",
    "7 Del Perro Beach",
    "75 Elgin Avenue",
    "101 Route 68",
    "1 Paleto Blvd",
    "47 Algonquin Blvd",
    "137 Capital Blvd",
    "2214 Clinton Avenue",
    "1778 Hawick Avenue",
    "2111 East Joshua Road",
    "68 Paleto Blvd",
    "4 Goma Street",
    -- Facilities
    "Grand Senora Desert",
    "Route 68",
    "Sandy Shores",
    "Mount Gordo",
    "Paleto Bay",
    "Lago Zancudo",
    "Zancudo River",
    "Ron Alternates Wind Farm",
    "Land Act Reservoir",
    -- Arcades
    "Pixel Pete's - Paleto Bay",
    "Wonderama - Grapeseed",
    "Warehouse - Davis",
    "Eight-Bit - Vinewood",
    "Insert Coin - Rockford Hills",
    "Videogeddon - La Mesa",
}

local small_warehouses = {
    [1] = "Pacific Bait Storage", 
    [2] = "White Widow Garage", 
    [3] = "Celltowa Unit", 
    [4] = "Convenience Store Lockup", 
    [5] = "Foreclosed Garage", 
    [9] = "Pier 400 Utility Building", 
}

local medium_warehouses = {
    [7] = "Derriere Lingerie Backlot", 
    [10] = "GEE Warehouse", 
    [11] = "LS Marine Building 3", 
    [12] = "Railyard Warehouse", 
    [13] = "Fridgit Annexe",
    [14] = "Disused Factory Outlet", 
    [15] = "Discount Retail Unit", 
    [21] = "Old Power Station", 
}

local large_warehouses = {
    [6] = "Xero Gas Factory",  
    [8] = "Bilgeco Warehouse", 
    [16] = "Logistics Depot", 
    [17] = "Darnell Bros Warehouse", 
    [18] = "Wholesale Furniture", 
    [19] = "Cypress Warehouses", 
    [20] = "West Vinewood Backlot", 
    [22] = "Walker & Sons Warehouse"
}


local weapon_stuff = {
    {"Firework", "weapon_firework"}, 
    {"Up N Atomizer", "weapon_raypistol"},
    {"Unholy Hellbringer", "weapon_raycarbine"},
    {"Rail Gun", "weapon_railgun"},
    {"Red Laser", "vehicle_weapon_enemy_laser"},
    {"Green Laser", "vehicle_weapon_player_laser"},
    {"P-996 Lazer", "vehicle_weapon_player_lazer"},
    {"RPG", "weapon_rpg"},
    {"Homing Launcher", "weapon_hominglauncher"},
    {"EMP Launcher", "weapon_emplauncher"},
    {"Flare Gun", "weapon_flaregun"},
    {"Shotgun", "weapon_bullpupshotgun"},
    {"Stungun", "weapon_stungun"},
    {"Smoke Gun", "weapon_smokegrenade"},
}

local proofs = {
    bullet = {name="Bullets",on=false},
    fire = {name="Fire",on=false},
    explosion = {name="Explosions",on=false},
    collision = {name="Collision",on=false},
    melee = {name="Melee",on=false},
    steam = {name="Steam",on=false},
    drown = {name="Drowning",on=false},
}

local effect_stuff = {
    {"Normal Drugged", "DrugsDrivingIn"}, 
    {"Drugged Trevor", "DrugsTrevorClownsFight"},
    {"Drugged Michael", "DrugsMichaelAliensFight"},
    {"Chop", "ChopVision"},
    {"Black & White", "DeathFailOut"},
    {"Boosted Black & White", "HeistCelebPassBW"},
    {"Rampage", "Rampage"},
    {"Where Are My Glasses?", "MenuMGSelectionIn"},
    {"Acid", "DMT_flight_intro"},
}


local visual_stuff = {
    {"Better Illumination", "AmbientPush"},
    {"Oversaturated", "rply_saturation"},
    {"Boost Everything", "LostTimeFlash"},
    {"Foggy Night", "casino_main_floor_heist"},
    {"Better Night Time", "dlc_island_vault"},
    {"Normal Fog", "Forest"},
    {"Heavy Fog", "nervousRON_fog"},
    {"Firewatch", "MP_Arena_theme_evening"},
    {"Warm", "mp_bkr_int01_garage"},
    {"Deepfried", "MP_deathfail_night"},
    {"Stoned", "stoned"},
    {"Underwater", "underwater"},
}

local drugged_effects = {
    "DRUG_2_drive",
    "drug_drive_blend01",
    "drug_flying_base",
    "DRUG_gas_huffin",
    "drug_wobbly",
    "NG_filmic02",
    "PPFilter",
    "spectator5",
}

local unreleased_vehicles = {
    "Kanjosj",
    "Postlude",
    "Rhinehart",
    "Tenf",
    "Tenf2",
    "Sentinel4",
    "Weevil2",
}

local modded_vehicles = {
    "dune2",
    "tractor",
    "dilettante2",
    "asea2",
    "cutter",
    "mesa2",
    "jet",
    "skylift",
    "policeold1",
    "policeold2",
    "armytrailer2",
    "towtruck",
    "towtruck2",
    "cargoplane",
}

local modded_weapons = {
    "weapon_railgun",
    "weapon_stungun",
    "weapon_digiscanner",
}

local interiors = {
    {"Safe Space [AFK Room]", {x=-158.71494, y=-982.75885, z=149.13135}},
    {"Torture Room", {x=147.170, y=-2201.804, z=4.688}},
    {"Mining Tunnels", {x=-595.48505, y=2086.4502, z=131.38136}},
    {"Omegas Garage", {x=2330.2573, y=2572.3005, z=46.679367}},
    {"Server Farm", {x=2155.077, y=2920.9417, z=-81.075455}},
    {"Character Creation", {x=402.91586, y=-998.5701, z=-99.004074}},
    {"Life Invader Building", {x=-1082.8595, y=-254.774, z=37.763317}},
    {"Mission End Garage", {x=405.9228, y=-954.1149, z=-99.6627}},
    {"Destroyed Hospital", {x=304.03894, y=-590.3037, z=43.291893}},
    {"Stadium", {x=-256.92334, y=-2024.9717, z=30.145584}},
    {"Comedy Club", {x=-430.00974, y=261.3437, z=83.00648}},
    {"Bahama Mamas Nightclub", {x=-1394.8816, y=-599.7526, z=30.319544}},
    {"Janitors House", {x=-110.20285, y=-8.6156025, z=70.51957}},
    {"Therapists House", {x=-1913.8342, y=-574.5799, z=11.435149}},
    {"Martin Madrazos House", {x=1395.2512, y=1141.6833, z=114.63437}},
    {"Floyds Apartment", {x=-1156.5099, y=-1519.0894, z=10.632717}},
    {"Michaels House", {x=-813.8814, y=179.07889, z=72.15914}},
    {"Franklins House (Old)", {x=-14.239959, y=-1439.6913, z=31.101551}},
    {"Franklins House (New)", {x=7.3125067, y=537.3615, z=176.02803}},
    {"Trevors House", {x=1974.1617, y=3819.032, z=33.436287}},
    {"Lesters House", {x=1273.898, y=-1719.304, z=54.771}},
    {"Lesters Warehouse", {x=713.5684, y=-963.64795, z=30.39534}},
    {"Lesters Office", {x=707.2138, y=-965.5549, z=30.412853}},
    {"Meth Lab", {x=1391.773, y=3608.716, z=38.942}},
    {"Humane Labs", {x=3625.743, y=3743.653, z=28.69009}},
    {"Motel Room", {x=152.2605, y=-1004.471, z=-99.024}},
    {"Police Station", {x=443.4068, y=-983.256, z=30.689589}},
    {"Bank Vault", {x=263.39627, y=214.39891, z=101.68336}},
    {"Blaine County Bank", {x=-109.77874, y=6464.8945, z=31.626724}}, -- credit to fluidware for telling me about this one
    {"Tequi-La-La Bar", {x=-564.4645, y=275.5777, z=83.074585}},
    {"Scrapyard Body Shop", {x=485.46396, y=-1315.0614, z=29.2141}},
    {"The Lost MC Clubhouse", {x=980.8098, y=-101.96038, z=74.84504}},
    {"Vangelico Jewlery Store", {x=-629.9367, y=-236.41296, z=38.057056}},
    {"Airport Lounge", {x=-913.8656, y=-2527.106, z=36.331566}},
    {"Morgue", {x=240.94368, y=-1379.0645, z=33.74177}},
    {"Union Depository", {x=1.298771, y=-700.96967, z=16.131021}},
    {"Fort Zancudo Tower", {x=-2357.9187, y=3249.689, z=101.45073}},
    {"Agency Interior", {x=-1118.0181, y=-77.93254, z=-98.99977}},
    {"Avenger Interior", {x=518.6444, y=4750.4644, z=-69.3235}},
    {"Terrobyte Interior", {x=-1421.015, y=-3012.587, z=-80.000}},
    {"Bunker Interior", {x=899.5518,y=-3246.038, z=-98.04907}},
    {"IAA Office", {x=128.20, y=-617.39, z=206.04}},
    {"FIB Top Floor", {x=135.94359, y=-749.4102, z=258.152}},
    {"FIB Floor 47", {x=134.5835, y=-766.486, z=234.152}},
    {"FIB Floor 49", {x=134.635, y=-765.831, z=242.152}},
    {"Big Fat White Cock", {x=-31.007448, y=6317.047, z=40.04039}},
    {"Marijuana Shop", {x=-1170.3048, y=-1570.8246, z=4.663622}},
    {"Strip Club DJ Booth", {x=121.398254, y=-1281.0024, z=29.480522}},
}

local values = {
    [0] = 0,
    [1] = 50,
    [2] = 88,
    [3] = 160,
    [4] = 208,
}

-- entity-pool gathering handling
vehicle_uses = 0
ped_uses = 0
pickup_uses = 0
player_uses = 0
object_uses = 0
robustmode = false
reap = false
function mod_uses(type, incr)
    -- this func is a patch. every time the script loads, all the toggles load and set their state. in some cases this makes the _uses optimization negative and breaks things. this prevents that.
    if incr < 0 and is_loading then
        -- ignore if script is still loading
        return
    end
    if type == "vehicle" then
        if vehicle_uses <= 0 and incr < 0 then
            return
        end
        vehicle_uses = vehicle_uses + incr
    elseif type == "pickup" then
        if pickup_uses <= 0 and incr < 0 then
            return
        end
        pickup_uses = pickup_uses + incr
    elseif type == "ped" then
        if ped_uses <= 0 and incr < 0 then
            return
        end
        ped_uses = ped_uses + incr
    elseif type == "player" then
        if player_uses <= 0 and incr < 0 then
            return
        end
        player_uses = player_uses + incr
    elseif type == "object" then
        if object_uses <= 0 and incr < 0 then
            return
        end
        object_uses = object_uses + incr
    end
end

-- check online version
online_v = tonumber(NETWORK._GET_ONLINE_VERSION())
if online_v > ocoded_for then
    util.toast("Dieses Skript ist nicht für die aktuelle GTA:O Version (" .. online_v .. "gemacht, Entwickelt für: " .. ocoded_for .. "). Einige Optionen funktionieren vielleicht nicht, aber die meisten sollten es.")
end

--Menü Divider
menu.divider(menu.my_root(), "Athego's Script [DEV]")
local self <const> = menu.list(menu.my_root(), "Self", {}, "")
    menu.divider(self, "Athego's Script [DEV] - Self")
local customloadoutOpt <const> = menu.list(menu.my_root(), "Custom Loadout", {}, "") --Erstellt die Liste
	menu.divider(customloadoutOpt, "Athego's Script [DEV] - Custom Loadout") --Name der Liste
local vehicle <const> = menu.list(menu.my_root(), "Vehicle", {}, "")
    menu.divider(vehicle, "Athego's Script [DEV] - Vehicle")
local detections <const> = menu.list(menu.my_root(), "Modder Detections", {}, "")
    menu.divider(detections, "Athego's Script [DEV] - Detections")

---------------------
---------------------
-- PLAYER Features
---------------------
---------------------

function PlayerlistFeatures(pid)
    menu.divider(menu.player_root(pid), "Athego's Script [DEV]")
    local playerr = menu.list(menu.player_root(pid), "Athego's Script [DEV]", {}, "")

    ---------------------
	---------------------
	-- FREUDNLICH
	---------------------
	---------------------

    local friendly = menu.list(playerr, "Friendly", {}, "")
    menu.divider(friendly, "Athego's Script [DEV] - Friendly")

	---------------------
	---------------------
	-- TROLLING
	---------------------
	---------------------

    local trollingOpt <const> = menu.list(playerr, "Trolling", {}, "") --Erstellt die Liste
	menu.divider(trollingOpt, "Athego's Script [DEV] - Trolling") --Name der Liste

    menu.toggle_loop(trollingOpt, "Water Loop", {}, "", function()
        local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local coords = ENTITY.GET_ENTITY_COORDS(target_ped)
		FIRE.ADD_EXPLOSION(coords['x'], coords['y'], coords['z'], 13, 1.0, true, false, 0.0)
	end)

	menu.toggle_loop(trollingOpt, "Water Loop invisible", {}, "", function()
        local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local coords = ENTITY.GET_ENTITY_COORDS(target_ped)
		FIRE.ADD_EXPLOSION(coords['x'], coords['y'], coords['z'], 13, 1.0, true, true, 0.0)
	end)

    menu.toggle_loop(trollingOpt, "Random explosion loop", {"randomexplosions"}, "", function(on)
        local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local coords = ENTITY.GET_ENTITY_COORDS(target_ped)
        FIRE.ADD_EXPLOSION(coords['x'], coords['y'], coords['z'], math.random(0, 82), 1.0, true, false, 0.0)
    end)

    ---------------------
	---------------------
	-- TROLLING/GLITCH PLAYER
	---------------------
	---------------------

    local glitch_player_list = menu.list(trollingOpt, "Glitch Player", {}, "")
    local object_stuff = {
        names = {
            "Ferris Wheel",
            "UFO",
            "Cement Mixer",
            "Scaffolding",
            "Garage Door",
            "Big Bowling Ball",
            "Big Soccer Ball",
            "Big Orange Ball",
            "Stunt Ramp",

        },
        objects = {
            "prop_ld_ferris_wheel",
            "p_spinning_anus_s",
            "prop_staticmixer_01",
            "prop_towercrane_02a",
            "des_scaffolding_root",
            "prop_sm1_11_garaged",
            "stt_prop_stunt_bowling_ball",
            "stt_prop_stunt_soccer_ball",
            "prop_juicestand",
            "stt_prop_stunt_jump_l",
        }
    }

    local object_hash = util.joaat("prop_ld_ferris_wheel")
    menu.list_select(glitch_player_list, "Objekt", {"glitchplayer"}, "Wähle das Objekt welches genutzt werden soll.", object_stuff.names, 1, function(index)
        object_hash = util.joaat(object_stuff.objects[index])
    end)

    menu.slider(glitch_player_list, "Spawn Delay", {"spawndelay"}, "", 0, 3000, 50, 10, function(amount)
        delay = amount
    end)

    local glitchPlayer = false
    local glitchPlayer_toggle
    glitchPlayer_toggle = menu.toggle(glitch_player_list, "Glitch Player", {}, "", function(toggled)
        glitchPlayer = toggled

        while glitchPlayer do
            if not players.exists(pid) then 
                util.toast("Spieler existiert nicht!")
                menu.set_value(glitchPlayer_toggle, false);
            break end
            local glitch_hash = object_hash
            local poopy_butt = util.joaat("rallytruck")
            request_model(glitch_hash)
            request_model(poopy_butt)
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
            local playerpos = ENTITY.GET_ENTITY_COORDS(ped, false)
            local stupid_object = entities.create_object(glitch_hash, playerpos)
            local glitch_vehicle = entities.create_vehicle(poopy_butt, playerpos, 0)
            ENTITY.SET_ENTITY_VISIBLE(stupid_object, false)
            ENTITY.SET_ENTITY_VISIBLE(glitch_vehicle, false)
            ENTITY.SET_ENTITY_INVINCIBLE(stupid_object, true)
            ENTITY.SET_ENTITY_COLLISION(stupid_object, true, true)
            ENTITY.APPLY_FORCE_TO_ENTITY(glitch_vehicle, 1, 0.0, 10, 10, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
            util.yield(delay)
            entities.delete_by_handle(stupid_object)
            entities.delete_by_handle(glitch_vehicle)
            util.yield(delay)    
        end
    end)

    local player_removals = menu.list(playerr, "Player Removals", {}, "")
    local kicks = menu.list(player_removals, "Kicks", {}, "")
    local crashes = menu.list(player_removals, "Crashes", {}, "")

    menu.action(crashes, "Perle der Natur", {"nature"}, "", function()
        local user = players.user()
        local user_ped = players.user_ped()
        local pos = players.get_position(user)
        BlockSyncs(pid, function() -- blocking outgoing syncs to prevent the lobby from crashing :5head:
            util.yield(100)
            menu.trigger_commands("invisibility on")
            for i = 0, 110 do
                PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(user, 0xFBF7D21F)
                PED.SET_PED_COMPONENT_VARIATION(user_ped, 5, i, 0, 0)
                util.yield(50)
                PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(user)
            end
            util.yield(250)
            for i = 1, 5 do
                util.spoof_script("freemode", SYSTEM.WAIT) -- preventing wasted screen
            end
            ENTITY.SET_ENTITY_HEALTH(user_ped, 0) -- killing ped because it will still crash others until you die (clearing tasks doesnt seem to do much)
            NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(pos, 0, false, false, 0)
            PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(user)
            menu.trigger_commands("invisibility off")
        end)
    end)
    
    menu.action(crashes, "Hiroshima", {"hiroshima"}, "", function()
        local user = players.user()
        local user_ped = players.user_ped()
        local pos = players.get_position(user)
        BlockSyncs(pid, function() 
            util.yield(100)
            PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user(), 0xFBF7D21F)
            WEAPON.GIVE_DELAYED_WEAPON_TO_PED(user_ped, 0xFBAB5776, 100, false)
            TASK.TASK_PARACHUTE_TO_TARGET(user_ped, pos.x, pos.y, pos.z)
            util.yield(200)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(user_ped)
            util.yield(500)
            WEAPON.GIVE_DELAYED_WEAPON_TO_PED(user_ped, 0xFBAB5776, 100, false)
            PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(user)
            util.yield(1000)
            for i = 1, 5 do
                util.spoof_script("freemode", SYSTEM.WAIT)
            end
            ENTITY.SET_ENTITY_HEALTH(user_ped, 0)
            NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(pos, 0, false, false, 0)
        end)
    end)

    menu.action(crashes, "Kinder Schutz Service", {""}, "", function()
        local mdl = util.joaat('a_c_poodle')
        BlockSyncs(pid, function()
            if request_model(mdl, 2) then
                local pos = players.get_position(pid)
                util.yield(100)
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                ped1 = entities.create_ped(26, mdl, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.GET_PLAYER_PED(pid), 0, 3, 0), 0) 
                local coords = ENTITY.GET_ENTITY_COORDS(ped1, true)
                WEAPON.GIVE_WEAPON_TO_PED(ped1, util.joaat('WEAPON_HOMINGLAUNCHER'), 9999, true, true)
                local obj
                repeat
                    obj = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(ped1, 0)
                until obj ~= 0 or util.yield()
                ENTITY.DETACH_ENTITY(obj, true, true) 
                util.yield(1500)
                FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 0, 1.0, false, true, 0.0, false)
                entities.delete_by_handle(ped1)
                util.yield(1000)
            else
                util.toast("Fehler beim Laden des Models.")
            end
        end)
    end)

    menu.action(crashes, "Linus Crash Tips", {}, "", function()
        local int_min = -2147483647
        local int_max = 2147483647
        for i = 1, 150 do
            util.trigger_script_event(1 << pid, {2765370640, pid, 3747643341, math.random(int_min, int_max), math.random(int_min, int_max), 
            math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
            math.random(int_min, int_max), pid, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
        end
    end)

end

for pid = 0,30 do
    if players.exists(pid) then
        PlayerlistFeatures(pid)
    end
end
players.on_join(PlayerlistFeatures)

---------------------
---------------------
-- MENÜ Features
---------------------
---------------------

menu.toggle_loop(detections, "Gemoddetes Fahrzeug", {}, "Erkennt ob jemand ein Gemoddetes Fahrzeug benutzt", function()
    for _, pid in ipairs(players.list(false, true, true)) do
        local modelHash = players.get_vehicle_model(pid)
        for i , name in ipairs(modded_vehicles) do
            if modelHash == util.joaat(name) then
                util.toast(players.get_name(pid) .. " fährt ein gemoddetes Fahrzeug")
                break
            end
        end
    end
end)

menu.toggle_loop(detections, "Nicht veröffentliches Fahrzeug", {}, "Erkennt ob jemand ein Fahrzeug benutzt welches noch nicht veröffentlicht wurde.", function()
    for _, pid in ipairs(players.list(false, true, true)) do
        local modelHash = players.get_vehicle_model(pid)
        for i, name in ipairs(unreleased_vehicles) do
            if modelHash == util.joaat(name) then
                util.draw_debug_text(players.get_name(pid) .. " fährt ein unveröffentliches Fahrzeug")
            end
        end
    end
end)

menu.toggle_loop(detections, "Gemoddete Waffe", {}, "Erkennt ob jemand eine Waffe benutzt die man Online nicht haben kann.", function()
    for _, pid in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        for i, hash in ipairs(modded_weapons) do
            local weapon_hash = util.joaat(hash)
            if WEAPON.HAS_PED_GOT_WEAPON(ped, weapon_hash, false) and (WEAPON.IS_PED_ARMED(ped, 7) or TASK.GET_IS_TASK_ACTIVE(ped, 8) or TASK.GET_IS_TASK_ACTIVE(ped, 9)) then
                util.toast(players.get_name(pid) .. " benutzt eine Gemoddete Waffe")
                break
            end
        end
    end
end)

menu.toggle_loop(detections, "Super Drive", {}, "Erkennt ob jemand Super Drive benutzt.", function()
    for _, pid in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)
        local veh_speed = (ENTITY.GET_ENTITY_SPEED(vehicle)* 2.236936)
        local class = VEHICLE.GET_VEHICLE_CLASS(vehicle)
        if class ~= 15 and class ~= 16 and veh_speed >= 180 and VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1) and players.get_vehicle_model(pid) ~= util.joaat("oppressor") then -- not checking opressor mk1 cus its stinky
            util.toast(players.get_name(pid) .. " benutzt Super Drive")
            break
        end
    end
end)

menu.toggle_loop(detections, "Noclip", {}, "Erkennt ob Spieler Noclip benutzten bzw Levitation", function()
    for _, pid in ipairs(players.list(true, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local ped_ptr = entities.handle_to_pointer(ped)
        local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)
        local oldpos = players.get_position(pid)
        util.yield()
        local currentpos = players.get_position(pid)
        local vel = ENTITY.GET_ENTITY_VELOCITY(ped)
        if not util.is_session_transition_active() and players.exists(pid)
        and get_interior_player_is_in(pid) == 0 and get_transition_state(pid) ~= 0
        and not PED.IS_PED_IN_ANY_VEHICLE(ped, false) -- too many false positives occured when players where driving. so fuck them. lol.
        and not NETWORK.NETWORK_IS_PLAYER_FADING(pid) and ENTITY.IS_ENTITY_VISIBLE(ped) and not PED.IS_PED_DEAD_OR_DYING(ped)
        and not PED.IS_PED_CLIMBING(ped) and not PED.IS_PED_VAULTING(ped) and not PED.IS_PED_USING_SCENARIO(ped)
        and not TASK.GET_IS_TASK_ACTIVE(ped, 160) and not TASK.GET_IS_TASK_ACTIVE(ped, 2)
        and v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), players.get_position(pid)) <= 395.0 -- 400 was causing false positives
        and ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(ped) > 5.0 and not ENTITY.IS_ENTITY_IN_AIR(ped) and entities.player_info_get_game_state(ped_ptr) == 0
        and oldpos.x ~= currentpos.x and oldpos.y ~= currentpos.y and oldpos.z ~= currentpos.z 
        and vel.x == 0.0 and vel.y == 0.0 and vel.z == 0.0 then
            util.toast(players.get_name(pid) .. " benutzt Noclip!")
            break
        end
    end
end)

---------------------
---------------------
-- SELF/UNLOCKS
---------------------
---------------------

local unlocks = menu.list(self, "Unlocks", {}, "")

menu.action(unlocks, "Unlock M16", {""}, "", function()
    memory.write_int(memory.script_global(262145 + 32775), 1)
end)

local collectibles = menu.list(unlocks, "Collectibles", {}, "")
menu.click_slider(collectibles, "Movie Props", {""}, "", 0, 9, 0, 1, function(i)
    util.trigger_script_event(1 << players.user(), {0xB9BA4D30, 0, 0x0, i, 1, 1, 1})
end)

menu.click_slider(collectibles, "Hidden Caches", {""}, "", 0, 9, 0, 1, function(i)
    util.trigger_script_event(1 << players.user(), {0xB9BA4D30, 0, 0x1, i, 1, 1, 1})
end)

menu.click_slider(collectibles, "Treasure Chests", {""}, "", 0, 1, 0, 1, function(i)
    util.trigger_script_event(1 << players.user(), {0xB9BA4D30, 0, 0x2, i, 1, 1, 1})
end)

menu.click_slider(collectibles, "Radio Antennas", {""}, "", 0, 9, 0, 1, function(i)
    util.trigger_script_event(1 << players.user(), {0xB9BA4D30, 0, 0x3, i, 1, 1, 1})
end)

menu.click_slider(collectibles, "Media USBs", {""}, "", 0, 19, 0, 1, function(i)
    util.trigger_script_event(1 << players.user(), {0xB9BA4D30, 0, 0x4, i, 1, 1, 1})
end)

menu.action(collectibles, "Shipwreck", {""}, "", function()
    util.trigger_script_event(1 << players.user(), {0xB9BA4D30, 0, 0x5, 0, 1, 1, 1})
end)

menu.click_slider(collectibles, "Buried Stash", {""}, "", 0, 1, 0, 1, function(i)
    util.trigger_script_event(1 << players.user(), {0xB9BA4D30, 0, 0x6, i, 1, 1, 1})
end)

menu.action(collectibles, "Halloween T-Shirt", {""}, "", function()
    util.trigger_script_event(1 << players.user(), {0xB9BA4D30, 0, 0x7, 1, 1, 1, 1})
end)

menu.click_slider(collectibles, "Jack O' Lanterns", {""}, "", 0, 9, 0, 1, function(i)
    util.trigger_script_event(1 << players.user(), {0xB9BA4D30, 0, 0x8, i, 1, 1, 1})
end)

menu.click_slider(collectibles, "Lamar Davis Organics Product", {""}, "", 0, 99, 0, 1, function(i)
    util.trigger_script_event(1 << players.user(), {0xB9BA4D30, 0, 0x9, i, 1, 1, 1})
end)

menu.click_slider(collectibles, "Junk Energy Skydive", {""}, "", 0, 9, 0, 1, function(i)
    util.trigger_script_event(1 << players.user(), {0xB9BA4D30, 0, 0xA, i, 1, 1, 1})
end)

---------------------
---------------------
-- Anti Oppressor
---------------------
---------------------

local antioppOpt <const> = menu.list(menu.my_root(), "Anti Oppressor", {}, "") --Erstellt die Liste
	menu.divider(antioppOpt, "Athego's Script [DEV] - Anti Oppressor") --Name der Liste

antioppressor = false
menu.toggle(antioppOpt, "Anti Oppressor", {""}, "Lässt keine Oppressor mehr in der Lobby zu und löscht diese.", function (on)
    antioppressor = on
    mod_uses("player", if on then 1 else -1)
end)

---------------------
---------------------
-- Custom Loadout
---------------------
---------------------

local STOREDIR = filesystem.store_dir() --- not using this much, consider moving it to the 2 locations it's used in..
local LIBDIR = filesystem.scripts_dir() .. "lib\\"
local do_autoload = false
local attachments_table = {}
local weapons_table = {}
if filesystem.exists(LIBDIR .. "wpcmplabels.lua") and filesystem.exists(LIBDIR .. "Athego_weapons.lua") then
    attachments_table = require("lib.wpcmplabels")
    weapons_table = require("lib.Athego_weapons")
else
    --util.toast("You didn't install the resources properly. Make sure weapons.lua and wpcmplabels.lua are in the lib directory")
    util.stop_script()
end

save_loadout = menu.action(customloadoutOpt, "Loadout speichern", {}, "Speichert alle aktuell ausgerüsteten Waffen und Aufsätze um sie in Zukunft zu laden.",
	function()
		util.toast("[Athego's Script] Loadout wird gespeichert...")
        util.log("[Athego's Script] Loadout wird gespeichert...")
		local charS,charE = "   ","\n"
		local player = PLAYER.GET_PLAYER_PED(players.user())
		file = io.open(STOREDIR .. "Athego_Custom-Loadout.lua", "wb")
		file:write("return {" .. charE)
		for category, weapon in pairs(weapons_table) do
			for n, weapon_hash in pairs(weapon) do
				if WEAPON.HAS_PED_GOT_WEAPON(player, weapon_hash, false) then
					file:write(charS .. "[" .. weapon_hash .. "] = ")
					WEAPON.SET_CURRENT_PED_WEAPON(player, weapon_hash, true)
					util.yield(100)
					local num_attachments = 0
					for attachment_hash, attachment_name in pairs(attachments_table) do
						if (WEAPON.DOES_WEAPON_TAKE_WEAPON_COMPONENT(weapon_hash, attachment_hash)) then
							util.yield(10)
							if WEAPON.HAS_PED_GOT_WEAPON_COMPONENT(player, weapon_hash, attachment_hash) then
								num_attachments = num_attachments + 1
								if num_attachments == 1 then
									file:write("{")
								else
									file:write(",")
								end
								file:write(charE .. charS .. charS .. "[" .. num_attachments .. "] = " .. attachment_hash)
							end
						end
					end
					local cur_tint = WEAPON.GET_PED_WEAPON_TINT_INDEX(player, weapon_hash)
					if num_attachments > 0 then
						file:write("," .. charE .. charS .. charS .. "[\"tint\"] = " .. cur_tint)
						file:write(charE .. charS .. "}," .. charE)
					else
						file:write("{" .. charE .. charS .. charS .. "[\"tint\"] = " .. cur_tint)
						file:write(charE .. charS .. "}," .. charE)
					end
				end
			end
		end
		file:write("}")
		file:close()
		util.toast("[Athego's Script] Speichern erfolgreich!")
        util.log("[Athego's Script] Speichern erfolgreich!")
	end)

load_loadout = menu.action(customloadoutOpt, "Loadout laden", {"loadloadout"}, "Equippt dein Loadout aus der letzten Speicherung",
	function()
		if filesystem.exists(STOREDIR .. "Athego_Custom-Loadout.lua") then
			util.toast("[Athego's Script] Loadout wird geladen...")
            util.log("[Athego's Script] Loadout wird geladen...")
			player = PLAYER.GET_PLAYER_PED(players.user())
			WEAPON.REMOVE_ALL_PED_WEAPONS(player, false)
			WEAPON._SET_CAN_PED_EQUIP_ALL_WEAPONS(player, true)
			local loadout_table = require("store\\" .. "Athego_Custom-Loadout")
			for w_hash, attach in pairs(loadout_table) do
				WEAPON.GIVE_WEAPON_TO_PED(player, w_hash, 10, false, true)
					for n, a_hash in pairs(attach) do
						if n ~= "tint" then
							WEAPON.GIVE_WEAPON_COMPONENT_TO_PED(player, w_hash, a_hash)
							util.yield(10)
						end
					end
				WEAPON.SET_PED_WEAPON_TINT_INDEX(player, w_hash, attach["tint"])
			end
			regen_menu()
			util.toast("[Athego's Script] Loadout erfolgreich geladen!")
            util.log("[Athego's Script] Loadout erfolgreich geladen!")
		else
			util.toast("[Athego's Script] Du hast noch kein Loadout gespeichert.")
            util.log("[Athego's Script] Du hast noch kein Loadout gespeichert.")
		end
		package.loaded["store\\Athego_Custom-Loadout"] = nil --- load_loadout should always get the current state of loadout.lua, therefore always load it again or else the last required table would be taken, as it has already been loaded before..
	end
)

customloadout = false
menu.toggle(customloadoutOpt, "Auto-Load", {}, "Lädt deine Waffen bei jedem Sitzungswechsel neu.", function(on)
	customloadout = on
end)

from_scratch = menu.action(customloadoutOpt, "Fang von Vorne an", {}, "Löscht jede Waffe damit du dein Loadout so einrichten kannst wie du magst.",
        function()
            WEAPON.REMOVE_ALL_PED_WEAPONS(PLAYER.GET_PLAYER_PED(players.user()), false)
            regen_menu()
            util.toast("Deine Waffen wurde gelöscht!")
        end)

menu.divider(customloadoutOpt, "Waffen bearbeiten")

function regen_menu()
    attachments = {}
    weapon_deletes = {}
    tints = {}
    for category, weapon in pairs(weapons_table) do
        category = string.gsub(category, "_", " ")
        for weapon_name, weapon_hash in pairs(weapon) do
            weapon_name = string.gsub(weapon_name, "_", " ")
            menu.delete(weapons[weapon_name])
            if WEAPON.HAS_PED_GOT_WEAPON(PLAYER.GET_PLAYER_PED(players.user()), weapon_hash, false) == true then
                generate_for_new_weapon(category, weapon_name, weapon_hash)
            else
                weapons[weapon_name] = menu.action(categories[category], weapon_name .. "(Nicht ausgerüstet)", {}, "Ausrüsten " .. weapon_name,
                        function()
                            menu.delete(weapons[weapon_name])
                            equip_weapon(category, weapon_name, weapon_hash)
                        end
                )
            end
            WEAPON.ADD_AMMO_TO_PED(PLAYER.GET_PLAYER_PED(players.user()), weapon_hash, 10) --- if a special ammo type has been equipped.. it should get some ammo
        end
    end
end

function equip_comp(category, weapon_name, weapon_hash, attachment_hash)
    WEAPON.GIVE_WEAPON_COMPONENT_TO_PED(PLAYER.GET_PLAYER_PED(players.user()), weapon_hash, attachment_hash)
    generate_attachments(category, weapon_name, weapon_hash)
end

function equip_weapon(category, weapon_name, weapon_hash)
    WEAPON.GIVE_WEAPON_TO_PED(PLAYER.GET_PLAYER_PED(players.user()), weapon_hash, 10, false, true)
    util.yield(10)
    weapon_deletes[weapon_name] = nil
    generate_for_new_weapon(category, weapon_name, weapon_hash)
end

function generate_for_new_weapon(category, weapon_name, weapon_hash)
    weapons[weapon_name] = menu.list(categories[category], weapon_name, {}, "Aufsätze bearbeiten für " .. weapon_name,
            function()
                WEAPON.SET_CURRENT_PED_WEAPON(PLAYER.GET_PLAYER_PED(players.user()), weapon_hash, true)
                generate_attachments(category, weapon_name, weapon_hash)
            end
    )
end

function generate_attachments(category, weapon_name, weapon_hash)
    player = PLAYER.GET_PLAYER_PED(players.user())
    if weapon_deletes[weapon_name] == nil then
        weapon_deletes[weapon_name] = menu.action(weapons[weapon_name], "Lösche " .. weapon_name, {}, "",
                function()
                    WEAPON.REMOVE_WEAPON_FROM_PED(player, weapon_hash)
                    menu.delete(weapons[weapon_name])
                    util.toast(weapon_name .. " wurde gelöscht")
                    weapons[weapon_name] = menu.action(categories[category], weapon_name .. "(Nicht ausgerüstet)", {}, "Ausrüsten " .. weapon_name,
                            function()
                                for a_key, a_action in pairs(attachments) do
                                    if string.find(a_key, weapon_hash) ~= nil then
                                        attachments[a_key] = nil
                                    end
                                end
                                menu.delete(weapons[weapon_name])
                                equip_weapon(category, weapon_name, weapon_hash)
                                weapon_deletes[weapon_name] = nil
                            end
                    )
                end
        )

        local tint_count = WEAPON.GET_WEAPON_TINT_COUNT(weapon_hash)
        local cur_tint = WEAPON.GET_PED_WEAPON_TINT_INDEX(player, weapon_hash)
        tints[weapon_hash] = menu.slider(weapons[weapon_name], "Lackierung", {}, "Wähl die Lackierung für " .. weapon_name, 0, tint_count - 1, cur_tint, 1,
                function(change)
                    WEAPON.SET_PED_WEAPON_TINT_INDEX(player, weapon_hash, change)
                end
        )

        menu.divider(weapons[weapon_name], "Aufsätze")
    end

    for attachment_hash, attachment_name in pairs(attachments_table) do
        if (WEAPON.DOES_WEAPON_TAKE_WEAPON_COMPONENT(weapon_hash, attachment_hash)) then
            if (attachments[weapon_hash .. " " .. attachment_hash] ~= nil) then menu.delete(attachments[weapon_hash .. " " .. attachment_hash]) end
            attachments[weapon_hash .. " " .. attachment_hash] = menu.action(weapons[weapon_name], attachment_name, {}, "Equip " .. attachment_name .. " on your " .. weapon_name,
                    function()
                        equip_comp(category, weapon_name, weapon_hash, attachment_hash)
                        util.yield(1)
                        if string.find(attachment_name, "Rounds") ~= nil and WEAPON.HAS_PED_GOT_WEAPON_COMPONENT(player, weapon_hash, attachment_hash) then
                            --- if the type of rounds is changed, the player needs some bullets of the new type to be able to use them
                            WEAPON.ADD_AMMO_TO_PED(player, weapon_hash, 10)
                            util.toast("Habe " .. weapon_name .. " neue Munition gegeben wegen neuer Munitions-Art.")
                        end
                    end
            )
        end
    end
end

categories = {}
weapons = {}
attachments = {}
weapon_deletes = {}
tints = {}
for category, weapon in pairs(weapons_table) do
    category = string.gsub(category, "_", " ")
    categories[category] = menu.list(customloadoutOpt, category, {}, "Bearbeite Waffen der " .. category .. " Kategorie.")
    for weapon_name, weapon_hash in pairs(weapon) do
        weapon_name = string.gsub(weapon_name, "_", " ")
        if WEAPON.HAS_PED_GOT_WEAPON(PLAYER.GET_PLAYER_PED(players.user()), weapon_hash, false) == true then
            generate_for_new_weapon(category, weapon_name, weapon_hash)
        else
            weapons[weapon_name] = menu.action(categories[category], weapon_name .. "(Nicht ausgerüstet)", {}, "Ausrüsten " .. weapon_name,
                    function()
                        menu.delete(weapons[weapon_name])
                        equip_weapon(category, weapon_name, weapon_hash)
                    end
            )
        end
    end
end

players_thread = util.create_thread(function (thr)
    while true do
        if player_uses > 0 then
            if show_updates then
                util.toast("Player pool is being updated")
            end
            all_players = players.list(false, true, true)
            for k,pid in pairs(all_players) do
                if antioppressor then
                    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                    local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, true)
                    if vehicle ~= 0 then
                      local hash = util.joaat("oppressor")
                      local hash2 = util.joaat("oppressor2")
                      if VEHICLE.IS_VEHICLE_MODEL(vehicle, hash) or VEHICLE.IS_VEHICLE_MODEL(vehicle, hash2) then
                        entities.delete(vehicle)
                        util.toast("[Athego's Script] Oppressor-Nutzer gefunden: " .. PLAYER.GET_PLAYER_NAME(pid) .. "\nLösche sein Oppressor")
                        util.log("[Athego's Script] Oppressor gefunden""\nLösche die Oppressor")
                      end
                    end
                end
            end
        end
        util.yield()
    end
end)

self_thread = util.create_thread(function (thr2)
    while true do
        if customloadout then
            if NETWORK.NETWORK_IS_IN_SESSION() == false then
                while NETWORK.NETWORK_IS_IN_SESSION() == false or util.is_session_transition_active() do
                    util.yield(1000)
                end
                util.yield(12000) --- wait until even the clownish animation on spawn is definitely finished..
                if do_autoload then
                    menu.trigger_commands("loadloadout")
                else
                    regen_menu()
                end
            end
        end
        util.yield()
    end
end)