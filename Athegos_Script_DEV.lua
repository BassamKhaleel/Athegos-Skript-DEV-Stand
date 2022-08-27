util.keep_running()
require("natives-1640181023")
require("natives-1606100775")
util.require_natives(1627063482)
util.toast("Athego's Script erfolgreich geladen!")
coded_for_gtao_version = 1.61

local response = false
local localVer = 1.00
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

all_players = {}

local createPed = PED.CREATE_PED
local getEntityCoords = ENTITY.GET_ENTITY_COORDS
local getPlayerPed = PLAYER.GET_PLAYER_PED
local requestModel = STREAMING.REQUEST_MODEL
local hasModelLoaded = STREAMING.HAS_MODEL_LOADED
local noNeedModel = STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED
local setPedCombatAttr = PED.SET_PED_COMBAT_ATTRIBUTES
local giveWeaponToPed = WEAPON.GIVE_WEAPON_TO_PED

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

--Ändert den Menü Pfad
local menuroot = menu.my_root()

-- check online version
online_v = tonumber(NETWORK._GET_ONLINE_VERSION())
if online_v > coded_for_gtao_version then
    util.toast("Dieses Skript ist veraltet für die aktuelle GTA:O Version (" .. online_v .. ", Entwickelt für: " .. ocoded_for .. "). Einige Optionen funktionieren vielleicht nicht, aber die meisten sollten es.")
end

--Menü Divider
menu.divider(menu.my_root(), "Athego's Script [DEV]")

---------------------
---------------------
-- PLAYERS Features
---------------------
---------------------

function PlayerlistFeatures(pid)
    menu.divider(menu.player_root(pid), "Athego's Script [DEV]")

    ---------------------
	---------------------
	-- TROLLING
	---------------------
	---------------------

    local trollingOpt <const> = menu.list(menu.player_root(pid), "Trolling", {}, "") --Erstellt die Liste
	menu.divider(trollingOpt, "Athego's Script [DEV] - Trolling") --Name der Liste

	-------------------------------------
	--Water Loop
	-------------------------------------

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

---------------------
---------------------
-- Anti Oppressor
---------------------
---------------------

local antioppOpt <const> = menu.list(menuroot, "Anti Oppressor", {}, "") --Erstellt die Liste
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

local customloadoutOpt <const> = menu.list(menuroot, "Custom Loadout", {}, "") --Erstellt die Liste
	menu.divider(customloadoutOpt, "Athego's Script [DEV] - Custom Loadout") --Name der Liste

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