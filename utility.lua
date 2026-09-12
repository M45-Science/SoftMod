-- Carl Frank Otto III
-- carlotto81@gmail.com
-- GitHub: https://github.com/M45-Science/SoftMod
-- License: MPL 2.0
-- Safe console print

local function UTIL_HasValidItemPrototype(name, quality)
    if not game or type(name) ~= "string" then
        return false
    end

    if not prototypes or not prototypes.item or not prototypes.item[name] then
        return false
    end

    if quality ~= nil then
        if type(quality) ~= "string" then
            return false
        end
        return prototypes.quality and prototypes.quality[quality] ~= nil
    end

    return true
end

local function UTIL_InsertContentsIntoCorpse(inv_corpse, contents, player)
    if not inv_corpse or not contents then
        return
    end

    local player_name = player and player.name or "<unknown>"

    -- Factorio 2.0: get_contents() returns array entries of {name, quality, count}.
    for _, entry in ipairs(contents) do
        if entry and entry.name and entry.count and entry.count > 0 then
            if UTIL_HasValidItemPrototype(entry.name, entry.quality) then
                if entry.quality ~= nil then
                    inv_corpse.insert { name = entry.name, quality = entry.quality, count = entry.count }
                else
                    inv_corpse.insert { name = entry.name, count = entry.count }
                end
            else
                UTIL_ConsolePrint("UTIL_DumpInv: skipping invalid item '" .. tostring(entry.name) .. ":" ..
                    tostring(entry.quality) .. "' from " .. player_name)
            end
        else
            -- ignore invalid entries
        end
    end
end

function UTIL_CheckAbandoned()
    local player_indices = {}
    for player_index, _ in pairs(game.players) do
        table.insert(player_indices, player_index)
    end
    table.sort(player_indices)
    for _, player_index in ipairs(player_indices) do
        local player = game.players[player_index]
        if not player.connected and UTIL_Is_New(player) then
            local pdata = storage and storage.PData and storage.PData[player.index]
            if pdata and pdata.lastOnline and (game.tick - pdata.lastOnline > 1 * 60 * 60 * 60) then
                if UTIL_DumpInv(player, false) then
                    UTIL_MsgAllSys("New player '" .. player.name ..
                        "' was not active long enough to become a member, and have been offline for some time. Their items are now considered abandoned, and have been placed at spawn.")
                end
            end
        end
    end
end

function UTIL_DumpInv(player, force)
    if not player then
        return false
    end

    if not prototypes or not prototypes.item or not prototypes.quality then
        UTIL_ConsolePrint("[ERROR] UTIL_DumpInv: global 'prototypes' is unavailable; aborting inventory dump to avoid item loss.")
        return false
    end

    if not force and storage and storage.PData and storage.PData[player.index] and storage.PData[player.index].cleaned then
        return false
    end

    local inv_main = player.get_inventory(defines.inventory.character_main)
    local inv_trash = player.get_inventory(defines.inventory.character_trash)

    local inv_main_contents
    if inv_main and inv_main.valid then
        inv_main_contents = inv_main.get_contents()
    end

    local inv_trash_contents
    if inv_trash and inv_trash.valid then
        inv_trash_contents = inv_trash.get_contents()
    end

    local inv_corpse_size = 0
    if inv_main_contents then
        inv_corpse_size = inv_corpse_size + (#inv_main - inv_main.count_empty_stacks())
    end

    if inv_trash_contents then
        inv_corpse_size = inv_corpse_size + (#inv_trash - inv_trash.count_empty_stacks())
    end

    if inv_corpse_size <= 0 then
        return false
    end

    local drop_position = game.surfaces[1].find_non_colliding_position("character", UTIL_GetDefaultSpawn(), 1024, 1, false)
    if not drop_position then
        return false
    end
    local corpse = game.surfaces[1].create_entity {
        name = "character-corpse",
        position = drop_position,
        inventory_size = inv_corpse_size,
        player_index = player.index
    }
    if not corpse then
        return false
    end

    -- corpse.active = true
    -- Commented out: character corpses are already active by default (so their
    -- time_to_live decay still runs), and as of Factorio 2.1.8 LuaEntity.active
    -- is read-only. Assigning to it raises "LuaEntity::active is read only" and
    -- crashes the scenario.

    local inv_corpse = corpse.get_inventory(defines.inventory.character_corpse)

    if not inv_corpse then
        return false
    end

    if inv_main_contents then
        UTIL_InsertContentsIntoCorpse(inv_corpse, inv_main_contents, player)
        inv_main.clear()
    end
    if inv_trash_contents then
        UTIL_InsertContentsIntoCorpse(inv_corpse, inv_trash_contents, player)
        inv_trash.clear()
    end


    if storage and storage.PData then
        storage.PData[player.index] = storage.PData[player.index] or {}
        storage.PData[player.index].cleaned = true
    end

    return true
end

function UTIL_MapPin()
    -- Migrate old map pin
    if (storage.servertag and storage.servertag.valid) then
        storage.servertag.destroy()
        storage.servertag = nil
    end

    -- Server tag
    if (storage.SM_Store.mapPin and not storage.SM_Store.mapPin.valid) then
        storage.SM_Store.mapPin = nil
    end
    if (storage.SM_Store.mapPin and storage.SM_Store.mapPin.valid) then
        storage.SM_Store.mapPin.destroy()
        storage.SM_Store.mapPin = nil
    end
    if (not storage.SM_Store.mapPin) then
        local label = "https://discord.gg/rQANzBheVh"

        local chartTag = {
            position = UTIL_GetDefaultSpawn(),
            icon = {
                type = "item",
                name = "programmable-speaker"
            },
            text = label
        }
        local pforce = game.forces["player"]
        local psurface = game.surfaces[1]

        if pforce and psurface then
            storage.SM_Store.mapPin = pforce.add_chart_tag(psurface, chartTag)
        end
    end
end

function UTIL_WarnOkay(player_index)
    local pdata = storage and storage.PData and storage.PData[player_index]
    if not pdata then
        return false
    end

    pdata.lastWarned = pdata.lastWarned or 0
    if game.tick ~= pdata.lastWarned then
        pdata.lastWarned = game.tick
        return true
    end
    return false
end

function UTIL_GPSPos(pos)
    if pos and pos.x and pos.y then
        return "[gps=" .. math.floor(pos.x) .. ","
            .. math.floor(pos.y) .. "] "
    else
        return "[Invalid position]"
    end
end

function UTIL_GPSXY(surface, x, y)
    if x and y then
        if surface then
        return "[gps=" .. math.floor(x) .. ","
            .. math.floor(y) .. ",".. surface.name .."] "
        else
             return "[gps=" .. math.floor(x) .. ","
            .. math.floor(y) .. "] "
        end
    else
        return "[Invalid xy]"
    end
end

function UTIL_Area(surface, size, area)
    if size and area and area.left_top and area.right_bottom then
        return UTIL_GPSXY(surface, area.left_top.x, area.left_top.y) ..
            " " .. math.floor(size) .. "m²"
    else
        return "[Invalid area]"
    end
end

function UTIL_GPSObj(item)
    if item and item.position then
        local sName = ""
        if item and item.surface then
            sName = item.surface.name
        end

        if sName then
            return "[gps=" .. math.floor(item.position.x) .. ","
                .. math.floor(item.position.y) .. "," .. sName .. "]"
        else
            return "[gps=" .. math.floor(item.position.x) .. ","
                .. math.floor(item.position.y) .. "] "
        end
    end
    return "[Invalid Object]"
end

function UTIL_ConsolePrint(message)
    if message then
        local tag, text = string.match(message, "^%[([A-Z0-9]+)%]%s*(.*)$")
        local events = {
            ACT = "activity",
            AUDIT = "audit",
            CMD = "audit",
            ERROR = "error",
            REPORT = "report",
            TODO = "todo",
        }
        if CW_EmitText then
            CW_EmitText((tag and events[tag]) or "log", (tag and events[tag]) and text or message)
        else
            print(message)
        end
    end
end

-- Determine if an entity is part of the natural world rather than
-- something placed by a player. Natural entities generally belong to
-- the neutral force or have no force at all.
function UTIL_IsNatural(entity)
    if entity and entity.valid then
        if not entity.force or (entity.force and entity.force.name == "neutral") then
            return true
        end
    end
    return false
end

-- Smart/safe Print
function UTIL_SmartPrint(player, message)
    if message then
        if player then
            player.print(message)
        else
            rcon.print(message)
        end
    end
end

-- Global messages (game/discord)
function UTIL_MsgAll(message)
    if message then
        game.print(message)
        CW_EmitText("message", message)
    end
end

-- System messages (game/discord)
function UTIL_MsgAllSys(message)
    if message then
        game.print("[color=orange](SYSTEM)[/color] [color=red]" .. message .. "[/color]")
        CW_EmitText("message", message)
    end
end

-- Global messages (game only)
function UTIL_MsgPlayers(message)
    if message then
        game.print(message)
    end
end

-- Global messages (discord only)
function UTIL_MsgDiscord(message)
    if message then
        CW_EmitText("message", message)
    end
end

-- Calculate distance between two points
function UTIL_Distance(pos_a, pos_b)
    if pos_a and pos_b and pos_a.x and pos_a.y and pos_b.x and pos_b.y then
        local axbx = pos_a.x - pos_b.x
        local ayby = pos_a.y - pos_b.y
        return (axbx * axbx + ayby * ayby) ^ 0.5
    else
        return 10000000
    end
end

-- Show players online to a player
function UTIL_SendPlayers(victim)
    local buf = ""
    local count = 0

    -- For console use
    if not victim then
        local snapshot = helpers.table_to_json(CW_OnlineSnapshot())
        if storage.SM_Store.onlineCache ~= snapshot then
            storage.SM_Store.onlineCache = snapshot
            CW_EmitOnline()
        end
        return
    end

    if storage.SM_Store.playerList then
        for _, target in ipairs(storage.SM_Store.playerList) do
            if target and target.victim and target.victim.connected then
                buf = buf ..
                    string.format("~%16s: - Score: %4d - Online: %4dm - (%s)%s\n", target.victim.name,
                        math.floor(target.score / 60 / 60), math.floor(target.time / 60 / 60), target.type, target.afk)
            end
        end
    end

    -- No one is online
    if not storage.SM_Store.pcount or storage.SM_Store.pcount == 0 then
        UTIL_SmartPrint(victim, "No players online.")
    else
        UTIL_SmartPrint(victim, "Players Online: " .. storage.SM_Store.pcount .. "\n" .. buf)
    end
end

-- Split strings
function UTIL_SplitStr(inputstr, sep)
    if inputstr and sep and inputstr ~= "" then
        local t = {}
        local x = 0

        -- Handle nil/empty strings
        if not sep or not inputstr then
            return t
        end
        if sep == "" or inputstr == "" then
            return t
        end

        for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
            x = x + 1
            if x > 100 then -- Max 100 args
                break
            end

            table.insert(t, str)
        end
        return t
    end
    return { "" }
end

-- Quickly turn tables into strings
function UTIL_Dump(o)
    if type(o) == "table" then
        local s = "{ "
        for k, v in pairs(o) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end
            s = s .. "[" .. k .. "] = " .. UTIL_Dump(v) .. ","
        end
        return s .. "} "
    else
        return tostring(o)
    end
end

-- Cut off extra precision
function UTIL_Quantize(number, precision)
    local fmtStr = string.format("%%0.%sf", precision)
    number = string.format(fmtStr, number)
    return number
end

-- Check if player is flagged patreon
function UTIL_Is_Supporter(victim)
    if victim and storage and storage.PData and storage.PData[victim.index] and storage.PData[victim.index].patreon then
        return storage.PData[victim.index].patreon
    else
        return false
    end
end

-- Check if player is flagged nitro
function UTIL_Is_Nitro(victim)
    if victim and storage and storage.PData and storage.PData[victim.index] and storage.PData[victim.index].nitro then
        return storage.PData[victim.index].nitro
    else
        return false
    end
end

-- permissions system
-- Check if player should be considered a veteran
function UTIL_Is_Veteran(victim)
    if victim and not victim.admin then
        -- If in group
        if victim.permission_group and storage.SM_Store.vetGroup then
            if victim.permission_group.name == storage.SM_Store.vetGroup.name then
                return true
            end
        end
    end

    --Workaround for mods that screw with permissions groups
    if not UTIL_Is_Banished(victim) then
        if storage and storage.PData and storage.PData[victim.index] then
            local level = storage.PData[victim.index].level
            if level == 3 then
                return true
            end
        end
    end

    return false
end

-- permissions system
-- Check if player should be considered a regular
function UTIL_Is_Regular(victim)
    if victim and not victim.admin then
        -- If in group
        if victim.permission_group and storage.SM_Store.regGroup then
            if victim.permission_group.name == storage.SM_Store.regGroup.name then
                return true
            end
        end
    end

    --Workaround for mods that screw with permissions groups
    if not UTIL_Is_Banished(victim) then
        if storage and storage.PData and storage.PData[victim.index] then
            local level = storage.PData[victim.index].level
            if level == 2 then
                return true
            end
        end
    end

    return false
end

-- Check if player should be considered a member
function UTIL_Is_Member(victim)
    if victim and not victim.admin then
        -- If in group
        if victim.permission_group and storage.SM_Store.memGroup then
            if victim.permission_group.name == storage.SM_Store.memGroup.name then
                return true
            end
        end
    end

    --Workaround for mods that screw with permissions groups
    if not UTIL_Is_Banished(victim) then
        if storage and storage.PData and storage.PData[victim.index] then
            local level = storage.PData[victim.index].level
            if level == 1 then
                return true
            end
        end
    end

    return false
end

-- Check if player should be considered new
function UTIL_Is_New(victim)
    if victim and not victim.admin then
        if not UTIL_Is_Member(victim) and not UTIL_Is_Regular(victim) and not UTIL_Is_Veteran(victim) then
            return true
        end
    end

    return false
end

function UTIL_SmartPrintColor(victim, message)
    UTIL_SmartPrint(victim, {"", "[color=red]", message, "[/color]"})
    UTIL_SmartPrint(victim, {"", "[color=cyan]", message, "[/color]"})
    UTIL_SmartPrint(victim, {"", "[color=black]", message, "[/color]"})
end

-- Check if player should be considered banished
function UTIL_Is_Banished(victim)
    --Not Invalid
    if not victim then
        return false
    end

    --Not admin
    if victim.admin then
        return false
    end

    --Physically in jail
    if victim.physical_surface and victim.physical_surface.name == "jail" then
        return true
    end

    --In jailed group
    if victim.permission_group and storage.SM_Store.jailGroup then
        if victim.permission_group.name == storage.SM_Store.jailGroup.name then
            return true
        end
    end


    if storage and storage.PData and storage.PData[victim.index] then
        local pointsNeeded = 1
        local level = storage.PData[victim.index].level

        if level == 2 then
            pointsNeeded = 2
        end
        if level == 3 then
            pointsNeeded = 4
        end

        --Has enough votes against them
        if storage.PData and storage.PData[victim.index] and storage.PData[victim.index].banished and storage.PData[victim.index].banished >= pointsNeeded then
            return true
        else
            return false
        end
    end

    return false
end

-- As of Factorio 2.1.7, LuaPlayer.teleport() no longer implicitly exits remote
-- view. When SoftMod forcibly relocates a player (banish, send-to-spawn) we want
-- the old behavior: after the move the player should be looking at their body,
-- not still spectating the old location. exit_remote_view() is a safe no-op when
-- the player is not in remote view; we additionally gate on controller_type so we
-- only ever touch players that are actually spectating.
function UTIL_ExitRemoteView(victim)
    if victim and victim.valid and victim.controller_type == defines.controllers.remote then
        victim.exit_remote_view()
    end
end

function UTIL_SendToDefaultSpawn(victim)
    if victim and victim.character then
        local nsurf = game.surfaces[1] -- Find default surface

        if nsurf then
            local pforce = victim.force
            local spawnpos = { 0, 0 }
            if pforce then
                spawnpos = pforce.get_spawn_position(nsurf)
            else
                UTIL_ConsolePrint("[ERROR] send_to_default_spawn: victim does not have a valid force.")
            end
            local newpos = nsurf.find_non_colliding_position("character", spawnpos, 1024, 1, false)
            UTIL_ExitRemoteView(victim)
            if newpos then
                victim.teleport(newpos, nsurf)
            else
                victim.teleport({ 0, 0 }, nsurf)
            end
        else
            UTIL_ConsolePrint("[ERROR] send_to_default_spawn: The surface 1 does not exist, could not teleport victim.")
        end
    else
        UTIL_ConsolePrint("[ERROR] send_to_default_spawn: victim invalid or dead")
    end
end

function UTIL_SendToSpawn(victim)
    if victim and victim.character then
        local nsurf = victim.physical_surface
        if nsurf then
            local pforce = victim.force
            local spawnpos = { 0, 0 }
            if pforce then
                spawnpos = pforce.get_spawn_position(nsurf)
            else
                UTIL_ConsolePrint("[ERROR] send_to_surface_spawn: victim force invalid")
            end
            local newpos = nsurf.find_non_colliding_position("character", spawnpos, 1024, 1, false)
            UTIL_ExitRemoteView(victim)
            if newpos then
                victim.teleport(newpos, nsurf)
            else
                victim.teleport({ 0, 0 }, nsurf)
            end
        else
            UTIL_ConsolePrint("[ERROR] send_to_surface_spawn: The surface does not exist, could not teleport victim.")
        end
    else
        UTIL_ConsolePrint("[ERROR] send_to_surface_spawn: victim invalid or dead")
    end
end

function UTIL_GetDefaultSpawn()
    local nsurf = game.surfaces[1]
    if nsurf then
        local pforce = game.forces["player"]
        if pforce then
            local spawnpos = pforce.get_spawn_position(nsurf)
            return spawnpos
        else
            UTIL_ConsolePrint("[ERROR] get_default_spawn: Couldn't find force 'player'")
            return { 0, 0 }
        end
    else
        UTIL_ConsolePrint("[ERROR] get_default_spawn: Couldn't find default surface 1.")
        return { 0, 0 }
    end
end

function UTIL_DrawMapClock(target)
    if storage.SM_Store and storage.SM_Store.resetDuration then
        if target.valid and target.gui and target.gui.top and target.gui.top.reset_clock then

            if storage.SM_Store.resetDuration ~= "" then
                target.gui.top.reset_clock.visible = true
            else 
                target.gui.top.reset_clock.visible = false
            end

            if storage.PData and storage.PData[target.index] and storage.PData[target.index].hideClock then
                target.gui.top.reset_clock.caption = ">"
                target.gui.top.reset_clock.style      = "mini_tool_button_red"
            else
                target.gui.top.reset_clock.caption = "MAP RESET: " .. storage.SM_Store.resetDuration
                target.gui.top.reset_clock.style      = "red_button"
            end
        end
    end
end
