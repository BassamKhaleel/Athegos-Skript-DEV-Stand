require("natives-1640181023")
require("natives-1606100775")
util.require_natives(1627063482)
util.toast("Athego's Script erfolgreich geladen! DEV-Version")
ocoded_for = 1.61

store_dir = filesystem.store_dir() .. '\\athego_loadout\\'
if not filesystem.is_dir(store_dir) then
    filesystem.mkdirs(store_dir)
end

local response = false
local localVer = 1.04
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

--Ändert den Menü Pfad
local menuroot = menu.my_root()

-- check online version
online_v = tonumber(NETWORK._GET_ONLINE_VERSION())
if online_v > ocoded_for then
    util.toast("Dieses Skript ist nicht für die aktuelle GTA:O Version (" .. online_v .. "gemacht, Entwickelt für: " .. ocoded_for .. "). Einige Optionen funktionieren vielleicht nicht, aber die meisten sollten es.")
end

--Menü Divider
menu.divider(menu.my_root(), "Athego's Script [DEV]")
local self = menu.list(menu.my_root(), "Self", {}, "")
local vehicle = menu.list(menu.my_root(), "Vehicle", {}, "")
local detections = menu.list(menu.my_root(), "Modder Detections", {}, "")

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

menu.toggle_loop(detections, "Modded Vehicle", {}, "", function()
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

local function exportstring( s )
    return string.format("%q", s)
end

function table.save(  tbl,filename )
   local charS,charE = "   ","\n"
   local file,err = io.open( filename, "wb" )
   if err then return err end
   -- initiate variables for save procedure
   local tables,lookup = { tbl },{ [tbl] = 1 }
   file:write( "return {"..charE )
   for idx,t in ipairs( tables ) do
      file:write( "-- Table: {"..idx.."}"..charE )
      file:write( "{"..charE )
      local thandled = {}
      for i,v in ipairs( t ) do
         thandled[i] = true
         local stype = type( v )
         -- only handle value
         if stype == "table" then
            if not lookup[v] then
               table.insert( tables, v )
               lookup[v] = #tables
            end
            file:write( charS.."{"..lookup[v].."},"..charE )
         elseif stype == "string" then
            file:write(  charS..exportstring( v )..","..charE )
         elseif stype == "number" then
            file:write(  charS..tostring( v )..","..charE )
         end
      end
      for i,v in pairs( t ) do
         -- escape handled values
         if (not thandled[i]) then
            local str = ""
            local stype = type( i )
            -- handle index
            if stype == "table" then
               if not lookup[i] then
                  table.insert( tables,i )
                  lookup[i] = #tables
               end
               str = charS.."[{"..lookup[i].."}]="
            elseif stype == "string" then
               str = charS.."["..exportstring( i ).."]="
            elseif stype == "number" then
               str = charS.."["..tostring( i ).."]="
            end
            if str ~= "" then
               stype = type( v )
               -- handle value
               if stype == "table" then
                  if not lookup[v] then
                     table.insert( tables,v )
                     lookup[v] = #tables
                  end
                  file:write( str.."{"..lookup[v].."},"..charE )
               elseif stype == "string" then
                  file:write( str..exportstring( v )..","..charE )
               elseif stype == "number" then
                  file:write( str..tostring( v )..","..charE )
               end
            end
         end
      end
      file:write( "},"..charE )
   end
   file:write( "}" )
   file:close()
end

function table.load( sfile )
   local ftables,err = loadfile( sfile )
   if err then return _,err end
   local tables = ftables()
   for idx = 1,#tables do
      local tolinki = {}
      for i,v in pairs( tables[idx] ) do
         if type( v ) == "table" then
            tables[idx][i] = tables[v[1]]
         end
         if type( i ) == "table" and tables[i[1]] then
            table.insert( tolinki,{ i,tables[i[1]] } )
         end
      end
      -- link indices
      for _,v in ipairs( tolinki ) do
         tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
      end
   end
   return tables[1]
end
-- END UTILITY FUNCTIONS

--https://gist.github.com/xSetrox/20faaea29d48369ffd814460a8908d44/raw
comp_path = store_dir .. '\\all_components.txt'
liveries_path = store_dir .. '\\all_liveries.txt'
need_install_components = false
need_install_liveries = false
if not filesystem.exists(comp_path) then
    need_install_components = true
    async_http.init('gist.githubusercontent.com', '/xSetrox/0e75d50b366a32503a0f431abd6525c2/raw', function(data)
        local file = io.open(comp_path,'w')
        file:write(data)
        file:close()
        need_install_components = false
    end)
    async_http.dispatch()
end

if not filesystem.exists(liveries_path) then
    need_install_liveries = true
    async_http.init('gist.githubusercontent.com', '/xSetrox/20faaea29d48369ffd814460a8908d44/raw', function(data)
        local file = io.open(liveries_path,'w')
        file:write(data)
        file:close()
        need_install_liveries = false
    end)
    async_http.dispatch()
end

while need_install_components or need_install_liveries do
    util.yield()
end

local all_components = {}
local all_liveries = {}

for line in io.lines(comp_path) do 
    all_components[#all_components+1] = tonumber(line)
end

for line in io.lines(liveries_path) do 
    all_liveries[#all_liveries+1] = tonumber(line)
end

-- credit http://lua-users.org/wiki/StringRecipes
local function ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
 end


local all_loadouts = {}
function update_all_loadouts()
    temp_loadouts = {}
    for i, path in ipairs(filesystem.list_files(store_dir)) do
        local file_str = path:gsub(store_dir, '')
        if ends_with(file_str, '.loadout') then
            temp_loadouts[#temp_loadouts+1] = file_str
        end
    end
    all_loadouts = temp_loadouts
end
update_all_loadouts()

weapons = {}
temp_weapons = util.get_weapons()
-- create a table with just weapon hashes, labels
for a,b in pairs(temp_weapons) do
    weapons[#weapons + 1] = {hash = b['hash'], label_key = b['label_key']}
end

function weapon_name_from_hash(hash)
    for k,v in pairs(weapons) do
        if tostring(v['hash']) == tostring(hash) then
            return util.get_label_text(v['label_key'])
        end
    end
    return nil
end

function format_weapon_name_for_stand(name)
    local name_copy = string.lower(name)
    local forbidden_chars = {'%_', '%.', '%-', ' '}
    for k,char in pairs(forbidden_chars) do 
        name_copy = string.gsub(name_copy, char, '')
    end
    if name_copy == 'stungun' then
        name_copy = 'stungunsp'
    end
    return name_copy
end

function get_weapons_ped_has(ped)
    local p_weapons = {}
    for k,v in pairs(weapons) do
        if WEAPON.HAS_PED_GOT_WEAPON(ped, v.hash, false) then 
            local this_weapon = {
                weapon = v.hash,
                tint = -1,
                components = {},
                liveries = {}
            }
            for k,comp in pairs(all_components) do
                if WEAPON.DOES_WEAPON_TAKE_WEAPON_COMPONENT(v.hash, comp) then
                    if WEAPON.HAS_PED_GOT_WEAPON_COMPONENT(players.user_ped(), v.hash, comp) then
                        this_weapon.components[#this_weapon.components+1] = comp
                    end
                end
            end
            this_weapon.tint = WEAPON.GET_PED_WEAPON_TINT_INDEX(players.user_ped(), v.hash)
            for k,livery in pairs(all_liveries) do
                local livery_color = WEAPON._GET_PED_WEAPON_LIVERY_COLOR(players.user_ped(), v.hash, livery)
                if livery_color ~= -1 then 
                    this_weapon.liveries[#this_weapon.liveries+1] = {livery = livery, color = livery_color}
                end
            end
            p_weapons[#p_weapons+1] = this_weapon
        end
    end
    return p_weapons
end

local load_list_actions
menu.action(customloadoutOpt, "Save loadout", {"saveloadout"}, "Save your character\'s current loadout", function()
    util.toast("Please input the name of this loadout")
    menu.show_command_box("saveloadout ")
end, function(file_name)
    local weps = get_weapons_ped_has(players.user_ped())
    table.save(weps, store_dir .. file_name .. '.loadout')
    util.toast("Loadout saved as " .. file_name .. ".loadout")
    update_all_loadouts()
    menu.set_list_action_options(load_list_actions, all_loadouts)
end)

load_list_actions = menu.list_action(customloadoutOpt, "Load loadout", {"loadloadout"}, "Load a loadout from file", all_loadouts, function(index, value, click_type)
    util.toast("Loading loadout...")
    menu.trigger_commands('noguns')
    local error_ct = 0
    local success_ct = 0
    local wep_tbl = table.load(store_dir .. '/' .. value)
    for k,wep in pairs(wep_tbl) do
        menu.trigger_commands('getguns' .. format_weapon_name_for_stand(weapon_name_from_hash(wep.weapon)))
        WEAPON.SET_PED_WEAPON_TINT_INDEX(players.user_ped(), wep.weapon, wep.tint)
        for k, l in pairs(wep.liveries) do
            WEAPON._SET_PED_WEAPON_LIVERY_COLOR(players.user_ped(), wep.weapon, l.livery, l.color)
        end
        for k, c in pairs(wep.components) do
            WEAPON.GIVE_WEAPON_COMPONENT_TO_PED(players.user_ped(), wep.weapon, c)
        end
    end
    --util.toast("Loadout " .. value .. " loaded. " .. success_ct .. " guns loaded successfully, " .. error_ct .. " errors.")
end)

-- update all loadouts every 5 seconds so if a user drags in a loadout it shows up :)
util.create_thread(function()
    while true do
        update_all_loadouts()
        menu.set_list_action_options(load_list_actions, all_loadouts)
        util.yield(5000)
    end
end)



menu.action(customloadoutOpt, "Clear loadout", {"clearloadout"}, "Clear your current loadout", function()
    menu.trigger_commands('noguns')
end)

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

util.keep_running()