--v0476-6-21-2020_01-31-AM

--Most of this code is written by:
--Carl Frank Otto III (aka Distortions864)
--carlotto81@gmail.com

local handler = require("event_handler")
handler.add_lib(require("freeplay"))
handler.add_lib(require("silo-script"))

local function dump(o)
    if type(o) == "table" then
        local s = "{ "
        for k, v in pairs(o) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end
            s = s .. "[" .. k .. "] = " .. dump(v) .. ","
        end
        return s .. "} "
    else
        return tostring(o)
    end
end

--safe console print--
local function console_print(message)
    print("~" .. message)
end

--smart console print--
local function smart_print(player, message)
    if player then
        player.print(message)
    else
        rcon.print("~" .. message)
    end
end

--Global messages--
local function message_all(message)
    for _, player in pairs(game.connected_players) do
        player.print(message)
    end
    print("[MSG] " .. message)
end

--Global messages (players only)--
local function message_allp(message)
    for _, player in pairs(game.connected_players) do
        player.print(message)
    end
end

--Global messages-- (discord only)
local function message_alld(message)
    print("[MSG] " .. message)
end

--Sort players--
local function sorttime(a, b)
    if (not a or not b) then
        return false
    end

    if (not a.time or not b.time) then
        return false
    end

    if (a.time < b.time) then
        return true
    elseif (a.time > b.time) then
        return false
    else
        return nil
    end
end

local function getKeepList(surface, playerForceNames, overlap, pavers)
    local count_entities = surface.count_entities_filtered
    local count_tiles = surface.count_tiles_filtered
    local count_total_chunks = 0
    local count_uncharted = 0
    local count_with_entities = 0
    local count_with_paving = 0
    local keepcords = {}
    local chunks = surface.get_chunks()
    for chunk in (chunks) do
        local chunk_occupied = false
        local chunk_charted = false
        local chunk_paved = false
        local chunkArea = {
            {chunk.x * 32 - overlap, chunk.y * 32 - overlap},
            {chunk.x * 32 + 32 + overlap, chunk.y * 32 + 32 + overlap}
        }
        for _, forceName in pairs(playerForceNames) do
            if game.forces[forceName].is_chunk_charted(surface, chunk) then
                chunk_charted = true
                break
            end
        end
        if chunk_charted then
            for _, forceName in pairs(playerForceNames) do
                if count_entities {area = chunkArea, force = forceName, limit = 1} ~= 0 then
                    chunk_occupied = true
                    break
                end
            end
            if not chunk_occupied and #pavers > 0 then
                local pavedArea = {{chunk.x * 32, chunk.y * 32}, {chunk.x * 32 + 32, chunk.y * 32 + 32}}
                if count_tiles {area = pavedArea, name = pavers, limit = 1} ~= 0 then
                    chunk_paved = true
                end
            end
            if chunk_occupied or chunk_paved then
                if keepcords[chunk.x] == nil then
                    keepcords[chunk.x] = {}
                end
                keepcords[chunk.x][chunk.y] = 1
                if chunk_occupied then
                    count_with_entities = count_with_entities + 1
                elseif chunk_paved then
                    count_with_paving = count_with_paving + 1
                end
            end
        else
            count_uncharted = count_uncharted + 1
        end
        count_total_chunks = count_total_chunks + 1
    end
    -- Compatibility with Mining Drones, Mining_Drones_0.3.2/script/mining_drone.lua:24
    -- Of course it just has to be right on a chunk boundry.
    if game.active_mods["Mining_Drones"] and surface.name == "nauvis" then
        local x = 1000000 / 32
        local y = 1000000 / 32
        if keepcords[x - 1] == nil then
            keepcords[x - 1] = {}
        end
        keepcords[x - 1][y - 1] = 1
        keepcords[x - 1][y] = 1
        if keepcords[x] == nil then
            keepcords[x] = {}
        end
        keepcords[x][y - 1] = 1
        keepcords[x][y] = 1
    end
    return {
        total = count_total_chunks,
        occupied = count_with_entities,
        paved = count_with_paving,
        coordinates = keepcords,
        uncharted = count_uncharted
    }
end

local function getPavingTiles()
    local paving = {}
    local ground = {}
    -- Ignored tileset for "Base mod" as of 0.17.66
    -- Paving: {"concrete", "hazard-concrete-left", "hazard-concrete-right", "refined-concrete", "refined-hazard-concrete-left", "refined-hazard-concrete-right", "stone-path"}
    local Base_tiles = {
        "deepwater",
        "deepwater-green",
        "dirt-1",
        "dirt-2",
        "dirt-3",
        "dirt-4",
        "dirt-5",
        "dirt-6",
        "dirt-7",
        "dry-dirt",
        "grass-1",
        "grass-2",
        "grass-3",
        "grass-4",
        "lab-dark-1",
        "lab-dark-2",
        "lab-white",
        "out-of-map",
        "red-desert-0",
        "red-desert-1",
        "red-desert-2",
        "red-desert-3",
        "sand-1",
        "sand-2",
        "sand-3",
        "tutorial-grid",
        "water",
        "water-green",
        "landfill",
        "water-mud",
        "water-shallow"
    }
    for _, v in ipairs(Base_tiles) do
        table.insert(ground, v)
    end

    -- Ignored tileset for "Alien Biome" exported from 0.4.15
    -- Paving: none
    local AlienBiomes_tiles = {
        "frozen-snow-0",
        "frozen-snow-1",
        "frozen-snow-2",
        "frozen-snow-3",
        "frozen-snow-4",
        "frozen-snow-5",
        "frozen-snow-6",
        "frozen-snow-7",
        "frozen-snow-8",
        "frozen-snow-9",
        "mineral-aubergine-dirt-1",
        "mineral-aubergine-dirt-2",
        "mineral-aubergine-dirt-3",
        "mineral-aubergine-dirt-4",
        "mineral-aubergine-dirt-5",
        "mineral-aubergine-dirt-6",
        "mineral-aubergine-sand-1",
        "mineral-aubergine-sand-2",
        "mineral-aubergine-sand-3",
        "mineral-beige-dirt-1",
        "mineral-beige-dirt-2",
        "mineral-beige-dirt-3",
        "mineral-beige-dirt-4",
        "mineral-beige-dirt-5",
        "mineral-beige-dirt-6",
        "mineral-beige-sand-1",
        "mineral-beige-sand-2",
        "mineral-beige-sand-3",
        "mineral-black-dirt-1",
        "mineral-black-dirt-2",
        "mineral-black-dirt-3",
        "mineral-black-dirt-4",
        "mineral-black-dirt-5",
        "mineral-black-dirt-6",
        "mineral-black-sand-1",
        "mineral-black-sand-2",
        "mineral-black-sand-3",
        "mineral-brown-dirt-1",
        "mineral-brown-dirt-2",
        "mineral-brown-dirt-3",
        "mineral-brown-dirt-4",
        "mineral-brown-dirt-5",
        "mineral-brown-dirt-6",
        "mineral-brown-sand-1",
        "mineral-brown-sand-2",
        "mineral-brown-sand-3",
        "mineral-cream-dirt-1",
        "mineral-cream-dirt-2",
        "mineral-cream-dirt-3",
        "mineral-cream-dirt-4",
        "mineral-cream-dirt-5",
        "mineral-cream-dirt-6",
        "mineral-cream-sand-1",
        "mineral-cream-sand-2",
        "mineral-cream-sand-3",
        "mineral-dustyrose-dirt-1",
        "mineral-dustyrose-dirt-2",
        "mineral-dustyrose-dirt-3",
        "mineral-dustyrose-dirt-4",
        "mineral-dustyrose-dirt-5",
        "mineral-dustyrose-dirt-6",
        "mineral-dustyrose-sand-1",
        "mineral-dustyrose-sand-2",
        "mineral-dustyrose-sand-3",
        "mineral-grey-dirt-1",
        "mineral-grey-dirt-2",
        "mineral-grey-dirt-3",
        "mineral-grey-dirt-4",
        "mineral-grey-dirt-5",
        "mineral-grey-dirt-6",
        "mineral-grey-sand-1",
        "mineral-grey-sand-2",
        "mineral-grey-sand-3",
        "mineral-purple-dirt-1",
        "mineral-purple-dirt-2",
        "mineral-purple-dirt-3",
        "mineral-purple-dirt-4",
        "mineral-purple-dirt-5",
        "mineral-purple-dirt-6",
        "mineral-purple-sand-1",
        "mineral-purple-sand-2",
        "mineral-purple-sand-3",
        "mineral-red-dirt-1",
        "mineral-red-dirt-2",
        "mineral-red-dirt-3",
        "mineral-red-dirt-4",
        "mineral-red-dirt-5",
        "mineral-red-dirt-6",
        "mineral-red-sand-1",
        "mineral-red-sand-2",
        "mineral-red-sand-3",
        "mineral-tan-dirt-1",
        "mineral-tan-dirt-2",
        "mineral-tan-dirt-3",
        "mineral-tan-dirt-4",
        "mineral-tan-dirt-5",
        "mineral-tan-dirt-6",
        "mineral-tan-sand-1",
        "mineral-tan-sand-2",
        "mineral-tan-sand-3",
        "mineral-violet-dirt-1",
        "mineral-violet-dirt-2",
        "mineral-violet-dirt-3",
        "mineral-violet-dirt-4",
        "mineral-violet-dirt-5",
        "mineral-violet-dirt-6",
        "mineral-violet-sand-1",
        "mineral-violet-sand-2",
        "mineral-violet-sand-3",
        "mineral-white-dirt-1",
        "mineral-white-dirt-2",
        "mineral-white-dirt-3",
        "mineral-white-dirt-4",
        "mineral-white-dirt-5",
        "mineral-white-dirt-6",
        "mineral-white-sand-1",
        "mineral-white-sand-2",
        "mineral-white-sand-3",
        "vegetation-blue-grass-1",
        "vegetation-blue-grass-2",
        "vegetation-green-grass-1",
        "vegetation-green-grass-2",
        "vegetation-green-grass-3",
        "vegetation-green-grass-4",
        "vegetation-mauve-grass-1",
        "vegetation-mauve-grass-2",
        "vegetation-olive-grass-1",
        "vegetation-olive-grass-2",
        "vegetation-orange-grass-1",
        "vegetation-orange-grass-2",
        "vegetation-purple-grass-1",
        "vegetation-purple-grass-2",
        "vegetation-red-grass-1",
        "vegetation-red-grass-2",
        "vegetation-turquoise-grass-1",
        "vegetation-turquoise-grass-2",
        "vegetation-violet-grass-1",
        "vegetation-violet-grass-2",
        "vegetation-yellow-grass-1",
        "vegetation-yellow-grass-2",
        "volcanic-blue-heat-1",
        "volcanic-blue-heat-2",
        "volcanic-blue-heat-3",
        "volcanic-blue-heat-4",
        "volcanic-green-heat-1",
        "volcanic-green-heat-2",
        "volcanic-green-heat-3",
        "volcanic-green-heat-4",
        "volcanic-orange-heat-1",
        "volcanic-orange-heat-2",
        "volcanic-orange-heat-3",
        "volcanic-orange-heat-4",
        "volcanic-purple-heat-1",
        "volcanic-purple-heat-2",
        "volcanic-purple-heat-3",
        "volcanic-purple-heat-4"
    }
    if game.active_mods["alien-biomes"] then
        for _, v in ipairs(AlienBiomes_tiles) do
            table.insert(ground, v)
        end
    end

    -- Ignored tileset for "Space Exploration" exported from 0.1.137
    -- Paving:  {"se-space-platform-plating", "se-space-platform-scaffold", "se-spaceship-floor"}
    local SpaceExploration_tiles = {"se-asteroid", "se-regolith", "se-space"}
    if game.active_mods["space-exploration"] then
        for _, v in ipairs(SpaceExploration_tiles) do
            table.insert(ground, v)
        end
    end

    for _, t in pairs(game.tile_prototypes) do
        local found = false
        for _, s in pairs(ground) do
            if t.name == s then
                found = true
                break
            end
        end
        if not found then
            table.insert(paving, t.name)
        end
    end
    return paving
end

local function deleteChunks(surface, coordinates, radius)
    local count_adjacent = 0
    local count_keep = 0
    local count_deleted = 0
    local chunks = surface.get_chunks()
    for chunk in (chunks) do
        local mustClean = true
        if coordinates[chunk.x] ~= nil and coordinates[chunk.x][chunk.y] ~= nil then
            mustClean = false
        elseif radius > 0 then
            for i, x in pairs(coordinates) do
                if chunk.x <= i + radius and chunk.x >= i - radius then
                    for j, y in pairs(x) do
                        if chunk.y <= j + radius and chunk.y >= j - radius then
                            mustClean = false
                            count_adjacent = count_adjacent + 1
                            break
                        end
                    end
                    if not mustClean then
                        break
                    end
                end
            end
        end
        if mustClean then
            surface.delete_chunk({chunk.x, chunk.y})
            count_deleted = count_deleted + 1
        else
            count_keep = count_keep + 1
        end
    end
    if count_keep == 0 then
        surface.clear(true)
    end

    return {adjacent = count_adjacent, deleted = count_deleted, kept = count_keep}
end

local function clean_surfaces(radius)
    --message_all("Cleaning map...")

    local keep_paving = true

    -- Get list of possible paving
    local paving = {}
    local paving_base = {
        "concrete",
        "hazard-concrete-left",
        "hazard-concrete-right",
        "refined-concrete",
        "refined-hazard-concrete-left",
        "refined-hazard-concrete-right",
        "stone-path"
    }
    if keep_paving then
        paving = getPavingTiles()
    end

    -- Get list of all player positions and forces
    local playerForceNames = {}
    local playerPositions = {}
    for _, player in pairs(game.players) do
        table.insert(playerForceNames, player.force.name)
        table.insert(playerPositions, {x = math.floor(player.position.x / 32), y = math.floor(player.position.y / 32)})
    end

    -- Verify surface exists
    for _, candidate in pairs(game.surfaces) do
        local surface = candidate

        -- Let the players know what is happening
        if surface == nil then
            --log({'DeleteEmptyChunks_text_mod_nosurface', target_surface, table_to_csv(surface_list)})
        else
            -- Perform chunk deletion on specified surface
            if surface ~= nil then
                -- First Pass
                local list = getKeepList(surface, playerForceNames, radius == 0 and 1 or 0, paving)
                -- Save players from the void
                for _, position in pairs(playerPositions) do
                    if list.coordinates[position.x] == nil then
                        list.coordinates[position.x] = {}
                    end
                    list.coordinates[position.x][position.y] = 1
                end
                -- Second Pass

                local result = deleteChunks(surface, list.coordinates, radius)
                -- Report results to all players
                --log({"DeleteEmptyChunks_text_starting", list.total, surface.name, list.total - list.uncharted})
                if result.kept > 0 then
                    if list.occupied > 0 then
                        if list.paved > 0 then
                            if result.adjacent > 0 then
                                --log({"DeleteEmptyChunks_text_keep_epa", result.kept, list.occupied, list.paved, result.adjacent})
                            else
                                --log({"DeleteEmptyChunks_text_keep_ep", result.kept, list.occupied, list.paved})
                            end
                        else
                            if result.adjacent > 0 then
                                --log({"DeleteEmptyChunks_text_keep_ea", result.kept, list.occupied, result.adjacent})
                            else
                                --log({"DeleteEmptyChunks_text_keep_e", result.kept, list.occupied})
                            end
                        end
                    elseif list.paved > 0 then
                        if result.adjacent > 0 then
                            --log({"DeleteEmptyChunks_text_keep_pa", result.kept, list.paved, result.adjacent})
                        else
                            --log({"DeleteEmptyChunks_text_keep_p", result.kept, list.paved})
                        end
                    end
                end
                --log({"DeleteEmptyChunks_text_delete", result.deleted})
                if game.active_mods["rso-mod"] then
                    remote.call("RSO", "disableStartingArea")
                    remote.call("RSO", "resetGeneration", surface)
                end
            end
        end
    end

    message_all("Map cleaned.")
end

--Create user groups if they don't exsist, and create global links to them
local function create_groups()
    global.defaultgroup = game.permissions.get_group("Default")
    global.membersgroup = game.permissions.get_group("Members")
    global.regularsgroup = game.permissions.get_group("Regulars")
    global.adminsgroup = game.permissions.get_group("Admins")

    if (not global.defaultgroup) then
        game.permissions.create_group("Default")
    end

    if (not global.membersgroup) then
        game.permissions.create_group("Members")
    end

    if (not global.regularsgroup) then
        game.permissions.create_group("Regulars")
    end

    if (not global.adminsgroup) then
        game.permissions.create_group("Admins")
    end

    global.defaultgroup = game.permissions.get_group("Default")
    global.membersgroup = game.permissions.get_group("Members")
    global.regularsgroup = game.permissions.get_group("Regulars")
    global.adminsgroup = game.permissions.get_group("Admins")
end

--Disable some permissions for new users
local function set_perms()
    --Auto set default group permissions

    if global.defaultgroup then
        global.defaultgroup.set_allows_action(defines.input_action.wire_dragging, false)
        global.defaultgroup.set_allows_action(defines.input_action.activate_cut, false)
        global.defaultgroup.set_allows_action(defines.input_action.add_train_station, false)
        global.defaultgroup.set_allows_action(defines.input_action.build_terrain, false)
        global.defaultgroup.set_allows_action(defines.input_action.change_arithmetic_combinator_parameters, false)
        global.defaultgroup.set_allows_action(defines.input_action.change_decider_combinator_parameters, false)
        global.defaultgroup.set_allows_action(defines.input_action.switch_constant_combinator_state, false)
        global.defaultgroup.set_allows_action(defines.input_action.change_programmable_speaker_alert_parameters, false)
        global.defaultgroup.set_allows_action(
            defines.input_action.change_programmable_speaker_circuit_parameters,
            false
        )
        global.defaultgroup.set_allows_action(defines.input_action.change_programmable_speaker_parameters, false)
        global.defaultgroup.set_allows_action(defines.input_action.change_train_stop_station, false)
        global.defaultgroup.set_allows_action(defines.input_action.change_train_wait_condition, false)
        global.defaultgroup.set_allows_action(defines.input_action.change_train_wait_condition_data, false)
        global.defaultgroup.set_allows_action(defines.input_action.connect_rolling_stock, false)
        global.defaultgroup.set_allows_action(defines.input_action.deconstruct, false)
        global.defaultgroup.set_allows_action(defines.input_action.delete_blueprint_library, false)
        global.defaultgroup.set_allows_action(defines.input_action.disconnect_rolling_stock, false)
        global.defaultgroup.set_allows_action(defines.input_action.drag_train_schedule, false)
        global.defaultgroup.set_allows_action(defines.input_action.drag_train_wait_condition, false)
        global.defaultgroup.set_allows_action(defines.input_action.launch_rocket, false)
        global.defaultgroup.set_allows_action(defines.input_action.remove_cables, false)
        global.defaultgroup.set_allows_action(defines.input_action.remove_train_station, false)
        global.defaultgroup.set_allows_action(defines.input_action.set_auto_launch_rocket, false)
        global.defaultgroup.set_allows_action(defines.input_action.set_circuit_condition, false)
        global.defaultgroup.set_allows_action(defines.input_action.set_circuit_mode_of_operation, false)
        global.defaultgroup.set_allows_action(defines.input_action.set_logistic_filter_item, false)
        global.defaultgroup.set_allows_action(defines.input_action.set_logistic_filter_signal, false)
        global.defaultgroup.set_allows_action(defines.input_action.set_logistic_trash_filter_item, false)
        global.defaultgroup.set_allows_action(defines.input_action.set_request_from_buffers, false)
        global.defaultgroup.set_allows_action(defines.input_action.set_signal, false)
        global.defaultgroup.set_allows_action(defines.input_action.set_train_stopped, false)
    end
end

local function create_myglobals()
    if not global.playeractive then
        global.playeractive = {}
    end
    if not global.active_playtime then
        global.active_playtime = {}
    end
    if not global.last_speaker_warning then
        global.last_speaker_warning = 0
    end
    if not global.last_decon_warning then
        global.last_decon_warning = 0
    end
    if (not global.corpselist) then
        global.corpselist = {tag = {}, tick = {}}
    end
end

local function create_player_globals(player)
    if global.playeractive and player and player.index then
        if not global.playeractive[player.index] then
            global.playeractive[player.index] = 0
        end

        if not global.active_playtime[player.index] then
            global.active_playtime[player.index] = 0
        end
    end
end

--Flag player as currently active
local function set_player_active(player)
    if
        (player and player.valid and player.connected and player.character and player.character.valid and
            global.playeractive)
     then
        global.playeractive[player.index] = true
    end
end

--Split strings
local function mysplit(inputstr, sep)
    local t = {}
    local x = 0

    --Handle nil/empty strings
    if not sep or not inputstr then
        return t
    end
    if sep == "" or inputstr == "" then
        return t
    end

    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        x = x + 1
        if x > 100 then --Max 100 args
            break
        end

        table.insert(t, str)
    end
    return t
end

--Set our default settings
local function game_settings(player)
    if game then
        player.force.friendly_fire = false --friendly fire
        player.force.research_queue_enabled = true --nice to have
    end
end

--Check if player should be considered a regular
local function is_regular(victim)
    --If in group
    if victim and victim.permission_group and global.regularsgroup then
        if victim.permission_group.name == global.regularsgroup.name then
            return true
        end
    end

    --If they have enough hours
    if
        (global.active_playtime and global.active_playtime[victim.index] and
            global.active_playtime[victim.index] > (4 * 60 * 60 * 60))
     then
        return true
    end

    return false
end

--Check if player should be considered trusted
local function is_trusted(victim)
    --If in group
    if victim and victim.permission_group and global.membersgroup then
        if victim.permission_group.name == global.membersgroup.name then
            return true
        end
    end

    --If they have enough hours
    if
        (global.active_playtime and global.active_playtime[victim.index] and
            global.active_playtime[victim.index] > (30 * 60 * 60))
     then
        return true
    end

    return false
end

--Check if player should be considered new
local function is_new(victim)
    if is_trusted(victim) == false and is_regular(victim) == false and victim.admin == false then
        return true
    end

    return false
end

--Auto permisisons--
local function get_permgroup()
    --Cleaned up 1-2020
    for _, player in pairs(game.connected_players) do
        if (player and player.valid) then
            --Handle nil permissions, for mod compatability
            if (global.defaultgroup and global.membersgroup and global.regularsgroup and global.adminsgroup) then
                if player.permission_group then
                    if (player.admin and player.permission_group.name ~= global.adminsgroup.name) then
                        global.adminsgroup.add_player(player)
                        message_all(player.name .. " moved to Admins group.")
                    elseif
                        (global.active_playtime and global.active_playtime[player.index] and
                            global.active_playtime[player.index] > (4 * 60 * 60 * 60) and
                            not player.admin)
                     then
                        if (player.permission_group.name ~= global.regularsgroup.name) then
                            global.regularsgroup.add_player(player)
                            message_all(player.name .. " is now a regular!")
                            player.print(
                                "[color=0.25,1,1](@ChatWire)[/color] [color=1,0.75,0]You have been active enough, that you have been promoted to the 'Regulars' group![/color]"
                            )
                            player.print(
                                "[color=0.25,1,1](@ChatWire)[/color] [color=1,0.75,0]You now have access to our 'Regulars' Discord role, and can get access to regulars-only Factorio servers, and Discord channels.[/color]"
                            )
                            player.print(
                                "[color=0.25,1,1](@ChatWire)[/color] [color=1,0.75,0]Find out more on our Discord server, the link can be copied from the text in the top-left of your screen.[/color]"
                            )
                            player.print(
                                "[color=0.25,1,1](@ChatWire)[/color] [color=1,0.75,0]Select text with mouse, then press control-c. Or, just visit https://bhmm.net/[/color]"
                            )
                        end
                    elseif
                        (global.active_playtime and global.active_playtime[player.index] and
                            global.active_playtime[player.index] > (30 * 60 * 60) and
                            not player.admin)
                     then
                        if
                            (player.permission_group.name ~= global.membersgroup.name and
                                player.permission_group.name ~= global.regularsgroup.name)
                         then
                            global.membersgroup.add_player(player)
                            message_all(player.name .. " is now a member!")
                            player.print(
                                "[color=0.25,1,1](@ChatWire)[/color] [color=1,0.75,0]You have been active enough, that the restrictions on your character have been lifted.[/color]"
                            )
                            player.print(
                                "[color=0.25,1,1](@ChatWire)[/color] [color=1,0.75,0]You now have access to our 'Members' Discord role![/color]"
                            )
                            player.print(
                                "[color=0.25,1,1](@ChatWire)[/color] [color=1,0.75,0]Find out more on our Discord server, the link can be copied from the text in the top-left of your screen.[/color]"
                            )
                            player.print(
                                "[color=0.25,1,1](@ChatWire)[/color] [color=1,0.75,0]Select text with mouse, then press control-c. Or, just visit https://bhmm.net/[/color]"
                            )
                        end
                    end
                else
                    --Fix nil group (bugged mods)
                    global.defaultgroup.add_player(player)
                    message_alld(player.name .. " has nil permissions.")
                end
            end
        end
    end
end

local function show_players(victim)
    local numpeople = 0

    --Cleaned up 1-2020
    for _, player in pairs(game.connected_players) do
        if (player and player.valid and player.connected) then
            numpeople = (numpeople + 1)
            local utag = "(error)"

            if player.permission_group then
                local gname = player.permission_group.name
                if gname == "Default" then
                    gname = "NEW"
                end

                utag = gname
            else
                utag = "(none)"
            end

            if (global.active_playtime and global.active_playtime[player.index]) then
                smart_print(
                    victim,
                    string.format(
                        "%-3d: %-18s Activity: %-4.3f, Online: %-4.3fh, (%s)",
                        numpeople,
                        player.name,
                        (global.active_playtime[player.index] / 60.0 / 60.0 / 60.0),
                        (player.online_time / 60.0 / 60.0 / 60.0),
                        utag
                    )
                )
            end
        end
    end
    if numpeople == 0 then
        smart_print(victim, "No players online.")
    end
end

--Custom commands
script.on_load(
    function()
        --Only add if no commands yet
        if (not commands.commands.server_interface) then
            --User report command
            commands.add_command(
                "report",
                "send in a report",
                function(param)
                    if param and param.player_index then
                        local player = game.players[param.player_index]
                        if player and param.parameter then
                            print("[REPORT] " .. player.name .. " " .. param.parameter)
                            smart_print(player, "Report sent.")
                        else
                            smart_print(player, "Usage: /report (your message to moderators here)")
                        end
                    else
                        smart_print(nil, "The console doesn't need to send in reports this way.")
                    end
                end
            )

            --Hide discord URL
            commands.add_command(
                "hideurl",
                "toggles the discord url on/off",
                function(param)
                    if param and param.player_index then
                        local player = game.players[param.player_index]
                        if player and player.valid and player.gui and player.gui.top and player.gui.top.discord then
                            if player.gui.top.discord.visible == true then
                                smart_print(
                                    player,
                                    "Discord link is now hidden. Using the command again will turn it back on."
                                )
                                player.gui.top.discord.visible = false
                            else
                                smart_print(
                                    player,
                                    "Discord link now shown. Using the command again will turn it back off."
                                )
                                player.gui.top.discord.visible = true
                            end
                        end
                    else
                        smart_print(nil, "The console can't see the discord url, but okay...")
                    end
                end
            )
            --Clean Surfaces--from Delete Empty Chunks
            commands.add_command(
                "clean",
                "<except radius>",
                function(param)
                    local player

                    if param.player_index then
                        player = game.players[param.player_index]
                        if player and player.admin == false then
                            smart_print(player, "Admins only.")
                            return
                        end
                    end

                    if (param.parameter and tonumber(param.parameter)) then
                        local radi = tonumber(param.parameter)

                        if (radi > 0 and radi < 1024) then
                            clean_surfaces(radi)
                        end
                    end
                end
            )

            --register command
            commands.add_command(
                "register",
                "<code>",
                function(param)
                    local player
                    if param.player_index then
                        local player = game.players[param.player_index]

                        if param.parameter then
                            local ptype = "Error"

                            if player.admin then
                                ptype = "admin"
                            elseif is_regular(player) then
                                ptype = "regular"
                            elseif is_trusted(player) then
                                ptype = "trusted"
                            else
                                ptype = "normal"
                            end

                            print("[ACCESS] " .. ptype .. " " .. player.name .. " " .. param.parameter)
                            smart_print(player, "Sending registration code...")
                            return
                        end
                        smart_print(player, "You need to specify an registration code!")
                        return
                    end
                    smart_print(nil, "I don't think the console needs to use this command...")
                end
            )

            --server chat
            commands.add_command(
                "cchat",
                "<message here>",
                function(param)
                    if param.player_index then
                        local player = game.players[param.player_index]
                        smart_print(player, "This command is for console use only.")
                        return
                    end

                    if param.parameter then
                        message_allp(param.parameter)
                    end
                end
            )

            --server whisper
            commands.add_command(
                "cwhisper",
                "<message here>",
                function(param)
                    if param.player_index then
                        local player = game.players[param.player_index]
                        smart_print(player, "This command is for console use only.")
                        return
                    end

                    if param.parameter then
                        local args = mysplit(param.parameter, " ")
                        if args ~= {} and args[1] and args[2] then
                            for _, player in pairs(game.connected_players) do
                                if player.name == args[1] then
                                    args[1] = ""
                                    player.print(table.concat(args, " "))
                                    break
                                end
                            end
                        end
                    end
                end
            )

            --Set player color
            commands.add_command(
                "pcolor",
                "<player> <color>",
                function(param)
                    local player

                    if param.player_index then
                        player = game.players[param.player_index]
                        if player and player.admin == false then
                            smart_print(player, "Admins only.")
                            return
                        end
                    end

                    if param.parameter then
                        local args = mysplit(param.parameter, " ")

                        if args ~= {} and args[1] and args[2] then
                            local victim = game.players[args[1]]
                            local xytable = mysplit(args[2], ",")
                            if xytable ~= {} and xytable[1] and xytable[2] and xytable[3] then
                                if (victim and victim.valid) then
                                    if xytable then
                                        local argr = xytable[1]
                                        local argg = xytable[2]
                                        local argb = xytable[3]
                                        if tonumber(xytable[1]) and tonumber(xytable[2]) and tonumber(xytable[3]) then
                                            victim.color = {argr, argg, argb, 1.0}
                                            victim.chat_color = {argr, argg, argb, 1.0}
                                            smart_print(player, "Color set.")
                                        else
                                            smart_print(player, "Numbers only.")
                                        end
                                        return
                                    end
                                else
                                    smart_print(player, "Player not found.")
                                    return
                                end
                            end
                        end
                    end
                    smart_print(player, "Invalid argument, systax pcolor <player> <r,g,b>")
                end
            )

            --Reset user
            commands.add_command(
                "reset",
                "<player> -- sets user to 0",
                function(param)
                    local is_admin = true
                    local player

                    if param.player_index then
                        player = game.players[param.player_index]
                        if player and player.admin == false then
                            is_admin = false
                            smart_print(player, "Admins only.")
                            return
                        end
                    end

                    if param.parameter then
                        local victim = game.players[param.parameter]

                        if (victim) then
                            if global.active_playtime and global.active_playtime[victim.index] then
                                global.active_playtime[victim.index] = 0
                                if victim and victim.valid and global.defaultgroup then
                                    global.defaultgroup.add_player(victim)
                                end
                                smart_print(player, "Player set to 0.")
                                return
                            end
                        end
                    end
                    smart_print(player, "Error.")
                end
            )

            --Trust user
            commands.add_command(
                "member",
                "<player> -- sets user to member status",
                function(param)
                    local is_admin = true
                    local player

                    if param.player_index then
                        player = game.players[param.player_index]
                        if player.admin == false then
                            is_admin = false
                            smart_print(player, "Admins only.")
                            return
                        end
                    end

                    if param.parameter then
                        local victim = game.players[param.parameter]

                        if (victim) then
                            if victim and victim.valid and global.membersgroup then
                                smart_print(player, "Player given members status.")
                                global.membersgroup.add_player(victim)
                                return
                            end
                        end
                    end
                    smart_print(player, "Error.")
                end
            )

            --Set user to regular
            commands.add_command(
                "regular",
                "<player> -- sets user to regular status",
                function(param)
                    local is_admin = true
                    local player

                    if param.player_index then
                        player = game.players[param.player_index]
                        if player and player.admin == false then
                            is_admin = false
                            smart_print(player, "Admins only.")
                            return
                        end
                    end

                    if param.parameter then
                        local victim = game.players[param.parameter]

                        if (victim) then
                            if victim and victim.valid and global.regularsgroup then
                                smart_print(player, "Player given regulars status.")
                                global.regularsgroup.add_player(victim)
                                return
                            end
                        end
                    end
                    smart_print(player, "Error.")
                end
            )

            --Change default spawn point
            commands.add_command(
                "cspawn",
                "<x,y> -- Changes default spawn location, if no <x,y> then where you currently stand.",
                function(param)
                    local is_admin = true
                    local victim
                    local new_pos_x = 0.0
                    local new_pos_y = 0.0

                    if param.player_index then
                        victim = game.players[param.player_index]

                        if victim and victim.admin == false then
                            is_admin = false
                        else
                            new_pos_x = victim.position.x
                            new_pos_y = victim.position.y
                        end
                    end

                    if is_admin then
                        local psurface = game.surfaces["nauvis"]
                        local pforce = game.forces["player"]

                        if victim then
                            pforce = victim.force
                            psurface = victim.surface
                        end

                        if param.parameter then
                            local xytable = mysplit(param.parameter, ",")
                            if xytable ~= {} and tonumber(xytable[1]) and tonumber(xytable[2]) then
                                local argx = xytable[1]
                                local argy = xytable[2]
                                new_pos_x = argx
                                new_pos_y = argy
                            else
                                smart_print(victim, "Invalid argument.")
                                return
                            end
                        end

                        if pforce and psurface and new_pos_x and new_pos_y then
                            pforce.set_spawn_position({new_pos_x, new_pos_y}, psurface)
                            smart_print(
                                victim,
                                string.format(
                                    "New spawn point set: %d,%d",
                                    math.floor(new_pos_x),
                                    math.floor(new_pos_y)
                                )
                            )
                            smart_print(victim, string.format("Surface: %s, Force: %s", psurface.name, pforce.name))
                            global.cspawnpos = {new_pos_x, new_pos_y}
                        else
                            smart_print(victim, "Couldn't find force or surface...")
                        end
                    else
                        smart_print(victim, "Admins only.")
                    end
                end
            )

            --Reveal map
            commands.add_command(
                "reveal",
                "<size> -- <x> units of map. Default: 1024, max 4096",
                function(param)
                    local is_admin = true
                    local victim

                    if param.player_index then
                        victim = game.players[param.player_index]
                        if victim and victim.admin == false then
                            is_admin = false
                        end
                    end

                    if (is_admin) then
                        local psurface = game.surfaces["nauvis"]
                        local pforce = game.forces["player"]
                        local size = 1024

                        if param.parameter then
                            if tonumber(param.parameter) then
                                local rsize = tonumber(param.parameter)

                                --limits
                                if rsize > 0 then
                                    if rsize < 128 then
                                        rsize = 128
                                    else
                                        if rsize > 4096 then
                                            rsize = 4096
                                        end
                                        size = rsize
                                    end
                                end
                            else
                                smart_print(victim, "Numbers only.")
                                return
                            end
                        end

                        if psurface and pforce and size then
                            pforce.chart(
                                psurface,
                                {lefttop = {x = -size, y = -size}, rightbottom = {x = size, y = size}}
                            )
                            local sstr = string.format("%-4.0f", size)
                            smart_print(victim, "Revealing " .. sstr .. "x" .. sstr .. " tiles")
                        else
                            smart_print(victim, "Either couldn't find surface nauvis, or couldn't find force player.")
                        end
                    else
                        smart_print(victim, "Admins only.")
                    end
                end
            )

            --Rechart map
            commands.add_command(
                "rechart",
                "resets fog of war",
                function(param)
                    local is_admin = true
                    local victim

                    if param.player_index then
                        victim = game.players[param.player_index]
                        if victim and victim.admin == false then
                            is_admin = false
                        end
                    end

                    if (is_admin) then
                        local pforce = game.forces["player"]

                        if pforce then
                            pforce.clear_chart()
                            smart_print(victim, "Recharting map...")
                        else
                            smart_print(victim, "Couldn't find force: player")
                        end
                    else
                        smart_print(victim, "Admins only.")
                    end
                end
            )

            --Online
            commands.add_command(
                "online",
                "See who is online!",
                function(param)
                    local victim
                    local is_admin = true

                    if param.player_index then
                        victim = game.players[param.player_index]
                        if victim and victim.admin == false then
                            is_admin = false
                        end
                    end

                    if (param.parameter == "active" and is_admin) then
                        local plen = 0
                        local playtime = {}
                        for pos, player in pairs(game.players) do
                            playtime[pos] = {
                                time = global.active_playtime[player.index],
                                name = game.players[player.index].name
                            }
                            plen = plen + 1
                            if plen > 3000 then --Max size
                                break
                            end
                        end

                        table.sort(playtime, sorttime)

                        --Lets limit number of results shown
                        for ipos, time in pairs(playtime) do
                            if (time) then
                                if (time.time) then
                                    if ipos > (plen - 20) then
                                        smart_print(
                                            victim,
                                            string.format(
                                                "%-4d: %-32s Active: %-4.2fm",
                                                ipos,
                                                time.name,
                                                time.time / 60.0 / 60.0
                                            )
                                        )
                                    end
                                end
                            end
                        end
                        return
                    end

                    show_players(victim)
                end
            )

            --Game speed
            commands.add_command(
                "gspeed",
                "<x.x> -- Changes game speed. Default: 1.0, min 0.1, max 10.0",
                function(param)
                    local player
                    local is_admin = true

                    if param.player_index then
                        player = game.players[param.player_index]
                    end

                    if (player) then
                        if (player and player.admin == false) then
                            is_admin = false
                        end
                    end

                    if (is_admin == false) then
                        smart_print(player, "Admins only..")
                        return
                    end

                    if (not param.parameter) then
                        smart_print(player, "But what speed? 0.1 to 10")
                        return
                    end

                    if tonumber(param.parameter) then
                        local value = tonumber(param.parameter)
                        if (value >= 0.1 and value <= 10.0) then
                            game.speed = value

                            local pforce = game.forces["player"]

                            if pforce then
                                game.forces["player"].character_running_speed_modifier = ((1.0 / value) - 1.0)
                                smart_print(
                                    player,
                                    "Game speed: " ..
                                        value ..
                                            " Walk speed: " .. game.forces["player"].character_running_speed_modifier
                                )
                                message_all("Game speed set to %" .. (game.speed * 100.00))
                            else
                                smart_print(player, "Force: Player doesn't seem to exsist.")
                            end
                        else
                            smart_print(player, "That doesn't seem like a good idea...")
                        end
                    else
                        smart_print(player, "Numbers only.")
                    end
                end
            )

            --Teleport to
            commands.add_command(
                "tto",
                "<player> -- teleport to <player>",
                function(param)
                    if not param.player_index then
                        smart_print(nil, "You want me to teleport a remote console somewhere???")
                        return
                    end
                    local player = game.players[param.player_index]

                    if (player and player.valid and player.connected and player.character and player.character.valid) then
                        if (player.admin == false) then
                            player.print("Admins only.")
                            return
                        end

                        if param.parameter then
                            local victim = game.players[param.parameter]

                            if (victim and victim.valid) then
                                local newpos =
                                    victim.surface.find_non_colliding_position(
                                    "character",
                                    victim.position,
                                    15,
                                    0.01,
                                    false
                                )
                                if (newpos) then
                                    player.teleport(newpos, victim.surface)
                                    player.print("Okay.")
                                else
                                    player.print("Area appears to be full.")
                                end
                                return
                            end
                        end
                        player.print("Error...")
                    end
                end
            )

            --Teleport x,y
            commands.add_command(
                "tp",
                "<x,y> -- teleport to <x,y>",
                function(param)
                    if not param.player_index then
                        smart_print(nil, "You want me to teleport a remote console somewhere???")
                        return
                    end
                    local player = game.players[param.player_index]

                    if (player and player.valid and player.connected and player.character and player.character.valid) then
                        if (player.admin == false) then
                            player.print("Admins only.")
                            return
                        end

                        if param.parameter then
                            local str = param.parameter
                            local xpos = "0.0"
                            local ypos = "0.0"

                            xpos, ypos = str:match("([^,]+),([^,]+)")
                            if tonumber(xpos) and tonumber(ypos) then
                                local position = {x = xpos, y = ypos}

                                if position then
                                    if position.x and position.y then
                                        local newpos =
                                            player.surface.find_non_colliding_position(
                                            "character",
                                            position,
                                            15,
                                            0.01,
                                            false
                                        )
                                        if (newpos) then
                                            player.teleport(newpos, player.surface)
                                            player.print("Okay.")
                                        else
                                            player.print("Area appears to be full.")
                                        end
                                    else
                                        player.print("invalid x/y.")
                                    end
                                end
                                return
                            else
                                player.print("Numbers only.")
                            end
                        end
                        player.print("Error...")
                    end
                end
            )

            --Teleport player to me
            commands.add_command(
                "tfrom",
                "<player> -- teleport <player> to me",
                function(param)
                    if not param.player_index then
                        smart_print(nil, "You want me to teleport a remote console somewhere???")
                        return
                    end
                    local player = game.players[param.player_index]

                    if (player and player.valid and player.connected and player.character and player.character.valid) then
                        if (player.admin == false) then
                            player.print("Admins only.")
                            return
                        end

                        if param.parameter then
                            local victim = game.players[param.parameter]

                            if (victim and victim.valid) then
                                local newpos =
                                    player.surface.find_non_colliding_position(
                                    "character",
                                    player.position,
                                    15,
                                    0.01,
                                    false
                                )
                                if (newpos) then
                                    victim.teleport(newpos, player.surface)
                                    player.print("Okay.")
                                else
                                    player.print("Area full.")
                                end
                            end
                        end
                        player.print("Error.")
                    end
                end
            )
        end
    end
)

--EVENTS--
--Command logging
script.on_event(
    defines.events.on_console_command,
    function(event)
        local command = ""
        local args = ""

        if event.command then
            command = event.command
        end

        if event.parameters then
            args = event.parameters
        end

        if event.player_index then
            local player = game.players[event.player_index]
            print(string.format("[CMD] NAME: %s, COMMAND: %s, ARGS: %s", player.name, command, args))
        elseif command ~= "time" and command ~= "p" and command ~= "w" and command ~= "server-save" then --Ignore spammy console commands
            print(string.format("[CMD] NAME: NONE, COMMAND: %s, ARGS: %s", command, args))
        end
    end
)

--Deconstuction planner warning
script.on_event(
    defines.events.on_player_deconstructed_area,
    function(event)
        if event and event.player_index and event.area then
            local player = game.players[event.player_index]
            local area = event.area

            if player and player.valid and area then
                set_player_active(player)
                if (global.last_decon_warning and game.tick - global.last_decon_warning >= 600) then
                    local msg =
                        player.name ..
                        " is using the deconstruction planner from [gps=" ..
                            math.floor(area.left_top.x) ..
                                "," ..
                                    math.floor(area.left_top.y) ..
                                        "] to [gps=" ..
                                            math.floor(area.right_bottom.x) ..
                                                "," .. math.floor(area.right_bottom.y) .. "]"
                    if is_regular(player) == false and player.admin == false then --Dont bother with regulars/admins
                        message_all(msg)
                    end
                    console_print(msg)
                    global.last_decon_warning = game.tick
                end
            end
        end
    end
)

--Player connected
script.on_event(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.players[event.player_index]
        create_myglobals()
        create_player_globals(player)
        create_groups()
        game_settings(player)

        --Discord Info--
        if not player.gui.top.discord then
            player.gui.top.add {type = "textfield", name = "discord"}
            player.gui.top.discord.text = "discord.gg/Ps2jnm7"
            player.gui.top.discord.tooltip = "Select with mouse and press control-c to copy!"
        end

        --Send info to bot--
        if (player.admin) then
            message_alld(player.name .. " moved to Admins group.")
        elseif (player.permission_group and player.permission_group.name == global.regularsgroup.name) then
            message_alld(player.name .. " is now a regular!")
        elseif (player.permission_group and player.permission_group.name == global.membersgroup.name) then
            message_alld(player.name .. " is now a member!")
        end

        get_permgroup()
    end
)

--New player created
script.on_event(
    defines.events.on_player_created,
    function(event)
        local player = game.players[event.player_index]
        set_perms()
        show_players(player)
        smart_print(player, "To see online players, chat /online")
        message_all("Welcome " .. player.name .. " to the map!")
    end
)

--ACTIVITY EVENTS
--Build stuff
script.on_event(
    defines.events.on_built_entity,
    function(event)
        local player = game.players[event.player_index]
        local created_entity = event.created_entity
        local stack = event.stack

        --Blueprint safety
        if stack and stack.valid and stack.valid_for_read and stack.is_blueprint then
            local count = stack.get_blueprint_entity_count()

            if player.admin then
                return
            elseif is_new(player) and count > 5000 then
                --message_alld(player.name .. " tried to load a blueprint with " .. count .. " items in it! (DELETED)")
                smart_print(player, "You aren't allowed to use blueprints that large yet.")
                stack.clear_blueprint()
                return
            elseif count > 20000 then
                --message_alld(player.name .. " tried to load a blueprint with " .. count .. " items in it! (DELETED)")
                smart_print(player, "That blueprint is too large.")
                stack.clear_blueprint()
                return
            end
        end

        if (global.last_speaker_warning and game.tick - global.last_speaker_warning >= 300) then
            if player and created_entity then
                if is_regular(player) == false and player.admin == false then --Dont bother with regulars/admins
                    if created_entity.name == "programmable-speaker" then
                        message_all(
                            player.name ..
                                " placed a speaker at [gps=" ..
                                    math.floor(created_entity.position.x) ..
                                        "," .. math.floor(created_entity.position.y) .. "]"
                        )
                        global.last_speaker_warning = game.tick
                    end
                end
            end
        end
    end
)
--Cursor stack
script.on_event(
    defines.events.on_player_cursor_stack_changed,
    function(event)
        local player = game.players[event.player_index]

        if player and player.valid then
            if player.cursor_stack then
                local stack = player.cursor_stack
                if stack and stack.valid and stack.valid_for_read and stack.is_blueprint then
                    local count = stack.get_blueprint_entity_count()

                    if player.admin then
                        return
                    elseif is_new(player) and count > 5000 then
                        --message_alld(player.name .. " tried to load a blueprint with " .. count .. " items in it! (DELETED)")
                        smart_print(player, "You aren't allowed to use blueprints that large yet.")
                        stack.clear_blueprint()
                        return
                    elseif count > 20000 then
                        --message_alld(player.name .. " tried to load a blueprint with " .. count .. " items in it! (DELETED)")
                        smart_print(player, "That blueprint is too large!")
                        stack.clear_blueprint()
                        return
                    end
                end
            end
        end
    end
)

--Mined item
script.on_event(
    defines.events.on_pre_player_mined_item,
    function(event)
        local player = game.players[event.player_index]
        local obj = event.entity

        --Don't let new players mine other players items... dirty dirty hack.
        if is_new(player) and obj.last_user ~= nil and obj.last_user ~= player then
            if game.surfaces["limbo"] == nil then
                game.create_surface("limbo")
            end
            local oldpos = player.character.position
            local oldsurf = player.character.surface

            player.teleport({0, 0}, game.surfaces["limbo"])
            player.teleport(oldpos, oldsurf)

            player.print("You are a new user, and are not allowed to mine other people's objects yet!")
        else
            console_print(
                player.name .. " mined " .. obj.name .. " at [gps=" .. obj.position.x .. "," .. obj.position.y .. "]"
            )
        end

        set_player_active(player)
    end
)

--Rotated item
script.on_event(
    defines.events.on_player_rotated_entity,
    function(event)
        local player = game.players[event.player_index]
        local obj = event.entity
        local rot = event.previous_direction

        --Don't let new players rotate other players items... dirty dirty hack.
        if is_new(player) and obj.last_user ~= nil and obj.last_user ~= player then
            obj.rotate()
            obj.rotate()
            obj.rotate()

            global.fixme = obj
            global.last = obj.last_user
            player.print("You are a new user, and are not allowed to rotate other people's objects yet!")
        else
            console_print(
                player.name .. " rotated " .. obj.name .. " at [gps=" .. obj.position.x .. "," .. obj.position.y .. "]"
            )
        end
        set_player_active(player)
    end
)

--Player inventory
script.on_event(
    defines.events.on_player_main_inventory_changed,
    function(event)
        local player = game.players[event.player_index]

        set_player_active(player)
    end
)

--Mine tiles
script.on_event(
    defines.events.on_player_mined_tile,
    function(event)
        local player = game.players[event.player_index]

        set_player_active(player)
    end
)

--Repair entity
script.on_event(
    defines.events.on_player_repaired_entity,
    function(event)
        local player = game.players[event.player_index]

        set_player_active(player)
    end
)

--Fast transfer
script.on_event(
    defines.events.on_player_fast_transferred,
    function(event)
        local player = game.players[event.player_index]

        set_player_active(player)
    end
)

--Shooting
script.on_event(
    defines.input_action.change_shooting_state,
    function(event)
        local player = game.players[event.player_index]

        set_player_active(player)
    end
)

--Chatting
script.on_event(
    defines.events.on_console_chat,
    function(event)
        --Can be triggered by console, so check for nil
        if event.player_index then
            local player = game.players[event.player_index]

            set_player_active(player)
        end
    end
)

--End Activity

--Walking/Driving
script.on_event(
    defines.events.on_player_changed_position,
    function(event)
        local player = game.players[event.player_index]

        --Only count if actually walking...
        if player and player.valid and player.walking_state then
            local walking_state = player.walking_state.walking

            if walking_state == true then
                set_player_active(player)
            end
        end
    end
)

--OTHER EVENTS
--Corpse Marker
script.on_event(
    defines.events.on_pre_player_died,
    function(event)
        local player = game.players[event.player_index]
        if player and player.valid and player.character then
            local centerPosition = player.position
            local label =
                "Corpse of: " ..
                player.name .. " " .. math.floor(player.position.x) .. "," .. math.floor(player.position.y .. "")
            local chartTag = {position = centerPosition, icon = nil, text = label}
            local qtag = player.force.add_chart_tag(player.surface, chartTag)

            create_myglobals()
            create_player_globals(player)

            table.insert(global.corpselist, {tag = qtag, tick = game.tick})

            --Log to discord
            message_all(
                player.name ..
                    " died at [gps=" .. math.floor(player.position.x) .. "," .. math.floor(player.position.y) .. "]"
            )
        end
    end
)

--Research Finished
script.on_event(
    defines.events.on_research_finished,
    function(event)
        local tech = event.research
        local wscript = event.by_script

        if tech then
            --Log to discord
            if wscript == false then
                message_alld("Research " .. tech.name .. " completed.")
            end
        end
    end
)

--Looping timer, 15 seconds
script.on_nth_tick(
    900,
    function(event)
        --Check permissions / player time
        get_permgroup()
    end
)

--Looping timer, 2 minutes
script.on_nth_tick(
    7200,
    function(event)
        local toremove

        --Remove old corpse tags
        local max = 0
        if (global.corpselist) then
            for _, corpse in pairs(global.corpselist) do
                max = max + 1
                if max > 100 then
                    break
                end
                if (corpse.tick and (corpse.tick + (15 * 60 * 60)) < game.tick) then
                    if (corpse.tag and corpse.tag.valid) then
                        corpse.tag.destroy()
                    end
                    toremove = corpse
                    break
                end
            end
        else
            create_myglobals()
        end
        if (toremove) then
            toremove.tag = nil
            toremove.tick = nil
            toremove = nil
        end

        --Server tag
        if (global.servertag and not global.servertag.valid) then
            global.servertag = nil
        end
        if (global.servertag and global.servertag.valid) then
            global.servertag.destroy()
            global.servertag = nil
        end
        if (not global.servertag) then
            local label = "Spawn Area"
            local xpos = 0
            local ypos = 0

            if
                global.cspawnpos and global.cspawnpos[1] and global.cspawnpos[2] and tonumber(global.cspawnpos[1]) and
                    tonumber(global.cspawnpos[2])
             then
                xpos = global.cspawnpos[1]
                ypos = global.cspawnpos[2]
            end

            local chartTag = {
                position = {xpos, ypos},
                icon = {type = "item", name = "heavy-armor"},
                text = label
            }
            local pforce = game.forces["player"]
            local psurface = game.surfaces["nauvis"]

            if pforce and psurface then
                global.servertag = pforce.add_chart_tag(psurface, chartTag)
            end
        end

        --Add time to connected players
        if global.active_playtime then
            for _, player in pairs(game.connected_players) do
                if global.playeractive[player.index] then
                    if global.playeractive[player.index] == true then
                        global.playeractive[player.index] = false --Turn back off

                        if global.active_playtime[player.index] then
                            global.active_playtime[player.index] = global.active_playtime[player.index] + 7200 --Same as loop time
                        else
                            --INIT
                            global.active_playtime[player.index] = 0
                        end
                    end
                else
                    --INIT
                    global.playeractive[player.index] = true
                end
            end
        end
    end
)

--Keep to minimum--
script.on_nth_tick(
    300, --about 5 seconds
    function(event)
        --Repair discord info
        if player and player.valid and player.gui and player.gui.top and player.gui.top.discord then
            player.gui.top.discord.text = "discord.gg/Ps2jnm7"
        end
    end
)

--Cheap hack to fix last user
script.on_nth_tick(
    1,
    function(event)

        if global.fixme and global.fixme.valid then
            if global.last then
                global.fixme.last_user = global.last
                global.last = nil
            else
                --just in case
                global.fixme.last_user = game.players[1]
            end

            global.fixme = nil
        end
    end
)
