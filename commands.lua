-- Carl Frank Otto III
-- carlotto81@gmail.com
-- GitHub: https://github.com/M45-Science/SoftMod
-- License: MPL 2.0

-- Load command groups
require "commands_banish"
require "commands_stash"

local SM_VERSION = require("version")

function CMD_AddCommand(name, help, handler)
    commands.remove_command(name)
    commands.add_command(name, help, handler)
end

function CMD_GetPlayer(param)
    if param and param.player_index then
        return game.players[param.player_index]
    end
    return nil
end

function CMD_GetActorName(player)
    if player and player.valid then
        return player.name
    end
    return "Console"
end

function CMD_RejectConsole(message)
    UTIL_SmartPrint(nil, message or "This command can only be used in-game.")
end

-- Resolve a named surface, coordinate pair, or Factorio GPS tag.
local function mapLocation(target, default_surface)
    target = target:match("^%s*(.-)%s*$")
    local surface = game.surfaces[target]
    if surface then return surface, { x = 0, y = 0 } end

    local gps = target:match("^%[gps=(.+)%]$")
    local coordinates, surface_name
    if gps then coordinates, surface_name = gps:match("^([^,]+,[^,]+),(.+)$") end
    local x, y = (coordinates or gps or target):match("^([-%d%.]+),([-%d%.]+)$")
    x, y = tonumber(x), tonumber(y)
    if not x or not y or math.abs(x) == math.huge or math.abs(y) == math.huge then
        return nil, nil, "Invalid location: " .. target
    end
    if surface_name then
        surface = game.surfaces[surface_name]
        if not surface then return nil, nil, "Invalid surface: " .. surface_name end
    end
    return surface or default_surface, { x = x, y = y }
end

local function teleportToLocation(player, target)
    local surface, position, err = mapLocation(target, player.surface)
    if not surface then return nil, nil, err end

    local destination = surface.find_non_colliding_position("character", position, 1024, 1, false) or position
    UTIL_ExitRemoteView(player)
    if not player.teleport(destination, surface) then
        return nil, nil, "Unable to teleport to the requested location."
    end
    return surface, destination
end

local function cleanSurface(psurface, pforce, delayTick, victim)
    -- Phase 1: Unchart all
    pforce.clear_chart(psurface)

    if not storage.SM_Store.purge_tasks then
        storage.SM_Store.purge_tasks = {}
    end

    -- Add to task queue
    table.insert(storage.SM_Store.purge_tasks, {
        surface = psurface,
        force = pforce,
        delay = game.tick + delayTick,
        victim = victim,
    })
end

function CMD_NoBanished(player)
    if player and UTIL_Is_Banished(player) then
        UTIL_SmartPrint(player, "No. You are banished.")
        return true
    end
    return false
end

function CMD_ModsOnly(param)
    if param and param.player_index then
        local player = game.players[param.player_index]
        if CMD_NoBanished(player) then
            return true
        end
        if player then
            if not player.admin then
                UTIL_SmartPrint(player, "That command is for moderators only.")
                return true
            else
                local args = ""
                if param.parameter then
                    args = param.parameter
                end
                local cmd_name = param.name or "unknown"
                UTIL_ConsolePrint(string.format("[AUDIT] %s ran /%s %s", player.name, cmd_name, args))
            end
        end
    end
    return false
end

function CMD_SysOnly(param)
    if param and param.player_index then
        local player = game.players[param.player_index]
        UTIL_SmartPrint(player, "That command is for system use only.")
        return true
    end
    return false
end

function CMD_NoSys(param)
    if param and param.player_index then
        local player = game.players[param.player_index]
        if CMD_NoBanished(player) then
            return true
        end
        if not player.character then
            UTIL_SmartPrint(player, "This command can only be used in-game (requires a character body).")
            return true
        end
    end
    return false
end

-- Custom commands
function CMD_RegisterCommands()
    BANISH_AddBanishCommands()
    STASH_AddStashCommands()

        -- Enable / disable cheat mode
        CMD_AddCommand("onelife", "Moderators Only: One life mode on/off or <playerName> for revive.",
            function(param)
                local player

                if param and param.player_index then
                    player = game.players[param.player_index]
                end
                if CMD_ModsOnly(param) then
                    return
                end

                if param and param.parameter then
                    if param.parameter == "on" and not storage.SM_Store.oneLifeMode then
                        storage.SM_Store.oneLifeMode = true
                        UTIL_SmartPrint(player, "One-life mode enabled.")
                        UTIL_MsgAll("One-life mode enabled.")
                        for _, victim in ipairs(game.connected_players) do
                            ONELIFE_MakeButton(victim)
                        end
                    elseif param.parameter == "off" and storage.SM_Store.oneLifeMode then
                        storage.SM_Store.oneLifeMode = false
                        UTIL_SmartPrint(player, "One-life mode disabled.")
                        UTIL_MsgAll("One-life mode disabled.")
                        for _, victim in ipairs(game.connected_players) do
                            ONELIFE_MakeButton(victim)
                        end
                    elseif storage.SM_Store.oneLifeMode then
                        local victim = UTIL_FindPlayer(param.parameter)

                        if victim then
                            if ONELIFE_IsRevivable(victim) then
                                storage.SM_Store.oneLifeMode = false
                                ONELIFE_MakeButton(victim)
                                storage.SM_Store.oneLifeMode = true
                                ONELIFE_MakeButton(victim)

                                UTIL_MsgAll(victim.name .. " was revived!")
                                UTIL_SmartPrint(player, victim.name .. " was revived!")
                            else
                                UTIL_SmartPrint(player, victim.name .. " is already alive!!!")
                            end
                        else
                            UTIL_SmartPrint(player, "I don't see a player by that name.")
                        end
                    end
                end
            end)

        -- adjust run speed
        CMD_AddCommand("run", "Moderators only: speed: -1 to 100, 0 = normal speed", function(param)
            local player

            if param and param.player_index then
                player = game.players[param.player_index]
            end
            if CMD_ModsOnly(param) then
                return
            end

            if player and player.valid then
                if player.character and player.character.valid then
                    if tonumber(param.parameter) then
                        local speed = tonumber(param.parameter)

                        -- Factorio doesn't like speeds less than -1
                        if speed < -0.99 then
                            speed = -0.99
                        end

                        -- Cap to reasonable amount
                        if speed > 1000 then
                            speed = 1000
                        end

                        player.character.character_running_speed_modifier = speed
                        UTIL_SmartPrint(player, "Walk speed set to " .. speed)
                    else
                        UTIL_SmartPrint(player, "Numbers only.")
                    end
                else
                    UTIL_SmartPrint(player, "Can't set walk speed, because you don't have a body.")
                end
            else
                UTIL_SmartPrint(player, "The console can't walk...")
            end
        end)

        -- turn invincible
        CMD_AddCommand("immortal", "Moderators only: optional: <name> (toggle player immortality, default self)",
            function(param)
                local player
                local victim

                if param and param.player_index then
                    player = game.players[param.player_index]
                end
                if CMD_ModsOnly(param) then
                    return
                end

                local target = player

                if param and param.parameter then
                    victim = UTIL_FindPlayer(param.parameter)
                end

                if victim then
                    target = victim
                end

                if target and target.valid then
                    if target.character and target.character.valid then
                        if target.character.destructible then
                            target.character.destructible = false
                            UTIL_SmartPrint(player, target.name .. " is now immortal.")
                        else
                            target.character.destructible = true
                            UTIL_SmartPrint(player, target.name .. " is now mortal.")
                        end
                    else
                        UTIL_SmartPrint(player, "They don't have a character body right now.")
                    end
                else
                    UTIL_SmartPrint(player, "Couldn't find a player by that name.")
                end
            end)

        -- register command
        CMD_AddCommand("register", "<code> (Requires a registration code from discord)", function(param)
            local player = CMD_GetPlayer(param)
            if CMD_NoSys(param) then
                return
            end

            if not player then
                CMD_RejectConsole("The console can't register this way.")
                return
            end

            -- Only if arguments
            if param.parameter and player and player.valid then
                -- Init player if needed, else add to

                if storage.PData[player.index].regAttempts > 3 then
                    UTIL_SmartPrint(player, "You have exhausted your registration attempts.")
                    return
                end
                storage.PData[player.index].regAttempts = storage.PData[player.index].regAttempts + 1

                local ptype = "Error"

                if player.admin then
                    ptype = "moderator"
                elseif UTIL_Is_Veteran(player) then
                    ptype = "veteran"
                elseif UTIL_Is_Regular(player) then
                    ptype = "regular"
                elseif UTIL_Is_Member(player) then
                    ptype = "member"
                else
                    ptype = "normal"
                end

                -- Send to ChatWire
                CW_EmitEvent("registration", { type = ptype, name = player.name, code = param.parameter })
                UTIL_SmartPrint(player, "Sending registration code...")
                return
            end
            UTIL_SmartPrint(player, "You need to provide a registration code!")
        end)

        -- Reset players's time and status
        CMD_AddCommand("reset", "Moderators only: <player> -- (Set player to NEW)", function(param)
            local player

            if param and param.player_index then
                player = game.players[param.player_index]
            end
            if CMD_ModsOnly(param) then
                return
            end

            -- Argument needed
            if param.parameter then
                local victim = UTIL_FindPlayer(param.parameter)
                PERMS_MakeNew(player, victim)
                return
            end
            UTIL_SmartPrint(player, "Player not found.")
        end)

        -- Trust player
        CMD_AddCommand("member", "Moderators only: <player> -- (Makes the player a member)", function(param)
            local player

            if param and param.player_index then
                player = game.players[param.player_index]
            end
            if CMD_ModsOnly(param) then
                return
            end

            -- Argument required
            if param.parameter then
                local victim = UTIL_FindPlayer(param.parameter)

                if not victim then
                    UTIL_SmartPrint(player, "Player not found.")
                    return
                end
                PERMS_MakeMember(player, victim)
            end
        end)

        -- Change default spawn point
        CMD_AddCommand("cspawn",
            "Moderators only: <x,y> -- (OPTIONAL) (Sets spawn point to <x,y>, or where you stand by default)",
            function(param)
                local victim
                local new_pos_x
                local new_pos_y


                if param and param.player_index then
                    victim = game.players[param.player_index]
                end
                if CMD_ModsOnly(param) then
                    return
                end

                local psurface = game.surfaces[1]
                local pforce = game.forces["player"]

                -- use mods's force and position if available.
                if victim then
                    pforce = victim.force

                    new_pos_x = victim.position.x
                    new_pos_y = victim.position.y
                end

                -- Location supplied
                if param.parameter then
                    local xytable = UTIL_SplitStr(param.parameter, ",")
                    if tonumber(xytable[1]) and tonumber(xytable[2]) then
                        new_pos_x = tonumber(xytable[1])
                        new_pos_y = tonumber(xytable[2])
                    else
                        UTIL_SmartPrint(victim, "Invalid argument. /cspawn x,y. No argument uses your current location.")
                        return
                    end
                end

                -- Set new spawn spot
                if pforce and psurface and new_pos_x and new_pos_y then
                    pforce.set_spawn_position({ new_pos_x, new_pos_y }, psurface)

                    local newPos = UTIL_GetDefaultSpawn()
                    UTIL_SmartPrint(victim, string.format("New spawn point set: %d,%d", math.floor(newPos.x),
                        math.floor(newPos.y)))
                    UTIL_SmartPrint(victim, string.format("Force: %s", pforce.name))
                    LOGO_DrawLogo(false)
                else
                    UTIL_SmartPrint(victim, "Couldn't find force...")
                end
            end)

        -- Reveal map
        CMD_AddCommand("reveal",
            "Moderators only: /reveal [size] [location]. Use x,y, a GPS tag, or a surface name. Size defaults to 1024 tiles (128 to 8192).",
            function(param)
                if CMD_ModsOnly(param) then
                    return
                end

                local victim = param.player_index and game.players[param.player_index] or nil
                local psurface = game.surfaces[1]
                local pforce = game.forces["player"]
                local center = { x = 0, y = 0 }
                local size = 1024

                if victim then
                    psurface = victim.surface
                    pforce = victim.force
                    center = victim.position
                end

                local target = (param.parameter or ""):match("^%s*(.-)%s*$")
                local first, rest = target:match("^(%S+)%s*(.*)$")
                local requested_size = tonumber(first)
                if requested_size then
                    size = math.max(128, math.min(8192, requested_size))
                    target = rest
                end

                if target ~= "" then
                    local err
                    psurface, center, err = mapLocation(target, psurface)
                    if not psurface then
                        UTIL_SmartPrint(victim, err)
                        return
                    end
                end

                if psurface and pforce and center then
                    local area = {
                        left_top = { x = center.x - size / 2, y = center.y - size / 2 },
                        right_bottom = { x = center.x + size / 2, y = center.y + size / 2 }
                    }

                    pforce.chart(psurface, area)
                    UTIL_SmartPrint(victim, "Revealing " .. size .. "x" .. size ..
                        " area centered at (" ..
                        math.floor(center.x) .. "," .. math.floor(center.y) .. ") on surface '" .. psurface.name .. "'.")
                else
                    UTIL_SmartPrint(victim, "Invalid force, surface, or center position.")
                end
            end)


        CMD_AddCommand("rechart",
            "Moderators only: Recharts known chunks. Usage: /rechart [surface] [force]",
            function(param)
                if CMD_ModsOnly(param) then return end

                local victim = param.player_index and game.players[param.player_index] or nil

                local psurface = game.surfaces[1]
                local pforce = game.forces["player"]

                if victim then
                    psurface = victim.surface
                    pforce = victim.force
                end

                if param.parameter then
                    local tokens = {}
                    for token in param.parameter:gmatch("[^%s]+") do
                        table.insert(tokens, token)
                    end

                    if #tokens >= 1 then
                        local surfname = tokens[1]
                        if game.surfaces[surfname] then
                            psurface = game.surfaces[surfname]
                        else
                            UTIL_SmartPrint(victim, "Invalid surface: " .. surfname)
                            return
                        end
                    end

                    if #tokens >= 2 then
                        local forcename = tokens[2]
                        if game.forces[forcename] then
                            pforce = game.forces[forcename]
                        else
                            UTIL_SmartPrint(victim, "Invalid force: " .. forcename)
                            return
                        end
                    end
                end

                if psurface and pforce then
                    pforce.clear_chart(psurface)
                    UTIL_SmartPrint(victim,
                        "Recharting surface '" .. psurface.name .. "' for force '" .. pforce.name .. "'.")
                else
                    UTIL_SmartPrint(victim, "Invalid surface or force.")
                end
            end)

        CMD_AddCommand("clean-surface",
            "Moderators only: Uncharts and later deletes unused chunks. Optional: <surface> or <all>",
            function(param)
                if CMD_ModsOnly(param) then return end

                local victim = param.player_index and game.players[param.player_index] or nil
                local psurface = game.surfaces[1]
                local pforce = game.forces["player"]
                local doAllSurf = false

                if victim then
                    psurface = victim.surface
                    pforce = victim.force
                end

                if param.parameter then
                    local surfname = param.parameter:match("^%s*([%w_]+)%s*$")
                    if surfname and game.surfaces[surfname] then
                        psurface = game.surfaces[surfname]
                    else
                        if param.parameter == "all" then
                            doAllSurf = true
                        else
                            UTIL_SmartPrint(victim, "Invalid surface: " .. param.parameter)
                            return
                        end
                    end
                end

                game.server_save()

                if doAllSurf then
                    local x = 0
                    for _, surface in pairs(game.surfaces) do
                        if string.sub(surface.name, 1, 8) == "platform" or surface.name == "jail" then
                            UTIL_ConsolePrint("Skipped cleaning surface: " .. surface.name)
                        else
                            x = x + 1
                            cleanSurface(surface, pforce, (60 * 10) + (x*30), victim)
                        end
                    end
                    UTIL_MsgAll("Cleaning all surfaces (" .. x .. "), chunk deletion scheduled.")
                    return
                else
                    cleanSurface(psurface, pforce, (60 * 10), victim)
                    UTIL_MsgAll("Unused chunk deletion for " .. psurface.name .. " scheduled for 10s from now.")
                end

            end)


        -- Online
        CMD_AddCommand("online", "See who is online", function(param)
            local victim

            if param and param.player_index then
                victim = game.players[param.player_index]
            end

            -- Sends updated list of players to server
            ONLINE_UpdatePlayerList()

            -- Already sent if console
            if victim then
                UTIL_SendPlayers(victim)
            end
        end)

        -- Game speed, without walk speed mod
        CMD_AddCommand("aspeed", "Moderators only: <x.x> -- Set game UPS, and do not adjust walk speed.",
            function(param)
                local player

                if param and param.player_index then
                    player = game.players[param.player_index]
                end
                if CMD_ModsOnly(param) then
                    return
                end

                -- Need argument
                if (not param.parameter) then
                    UTIL_SmartPrint(player, "But what speed? 1 to 6000")
                    return
                end

                -- Decode arg
                if tonumber(param.parameter) then
                    local value = tonumber(param.parameter)

                    -- Limit speed range
                    if (value >= 1 and value <= 6000) then
                        game.speed = (value / 60.0)
                    else
                        UTIL_SmartPrint(player, "That doesn't seem like a good idea...")
                    end
                else
                    UTIL_SmartPrint(player, "Numbers only.")
                end
            end)

        -- Game speed
        CMD_AddCommand("gspeed",
            "Moderators only: <x.x> -- Changes game speed. Default speed: 1.0 (60 UPS), Min 0.01 (0.6 UPS), Max  10.0 (600 UPS)",
            function(param)
                local player

                if param and param.player_index then
                    player = game.players[param.player_index]
                end
                if CMD_ModsOnly(param) then
                    return
                end

                -- Need argument
                if (not param.parameter) then
                    UTIL_SmartPrint(player, "But what speed? 0.01 to 10")
                    return
                end

                -- Decode arg
                if tonumber(param.parameter) then
                    local value = tonumber(param.parameter)

                    -- Limit speed range
                    if (value >= 0.1 and value <= 100.0) then
                        game.speed = value

                        -- Get default force
                        local pforce = game.forces["player"]

                        -- Use admin's force
                        if player and player.valid then
                            pforce = player.force
                        end

                        -- If force found
                        if pforce then
                            -- Calculate walk speed for UPS
                            pforce.character_running_speed_modifier = ((1.0 / value) - 1.0)
                            UTIL_SmartPrint(player, "Game speed: " .. value .. " Walk speed: " ..
                                pforce.character_running_speed_modifier)

                            -- Don't show message if run via console (ChatWire)
                            if (player) then
                                UTIL_MsgAll("Game speed set to " .. (game.speed * 100.00) .. "%")
                            end
                        else
                            UTIL_SmartPrint(player, "Couldn't find a valid force")
                        end
                    else
                        UTIL_SmartPrint(player, "That doesn't seem like a good idea...")
                    end
                else
                    UTIL_SmartPrint(player, "Numbers only.")
                end
            end)

        -- Teleport to
        CMD_AddCommand("goto", "Moderators only: goto to <player>", function(param)
            local player = CMD_GetPlayer(param)
            if CMD_NoSys(param) or CMD_ModsOnly(param) then
                return
            end
            if not player then
                CMD_RejectConsole("The console can't use /goto. This command requires an in-game player.")
                return
            end

            -- Argument required
            if param.parameter then
                local victim = UTIL_FindPlayer(param.parameter)

                if victim == player then
                    UTIL_SmartPrint(player, "You can't goto yourself, are you having an identity crisis?")
                    return
                end

                if (victim) then
                    local newpos = victim.physical_surface.find_non_colliding_position("character",
                        victim.physical_position, 1024,
                        1, false)
                    if (newpos) then
                        UTIL_ExitRemoteView(player)
                        player.teleport(newpos, victim.physical_surface)
                        if player and victim then
                            UTIL_SmartPrint(player, "You goto " .. victim.name)
                            UTIL_SmartPrint(victim, player.name .. " suddenly appears.")
                        end
                    else
                        UTIL_SmartPrint(player, "Area appears to be full.")
                        UTIL_ConsolePrint("[ERROR] goto: unable to find non_colliding_position.")
                    end
                    return
                else
                    UTIL_SmartPrint(player, "There isn't a player with that name.")
                end
            else
                UTIL_SmartPrint(player, "Goto to who?")
            end
        end)

        CMD_AddCommand("tp", "Moderators only: teleport to <x,y>, <surface>, or [gps=x,y] or [gps=x,y,surface]",
            function(param)
                local player = CMD_GetPlayer(param)
                if CMD_NoSys(param) or CMD_ModsOnly(param) then
                    return
                end
                if not player then
                    CMD_RejectConsole("The console can't use /tp. This command requires an in-game player.")
                    return
                end

                if not param.parameter then
                    UTIL_SmartPrint(player, "Teleport to where?")
                    return
                end

                local surface, position, err = teleportToLocation(player, param.parameter)
                if not surface then
                    UTIL_SmartPrint(player, err)
                    return
                end
                UTIL_SmartPrint(player,
                    "You teleport to (" .. position.x .. "," .. position.y .. ") on surface '" .. surface.name .. "'.")
            end)

        -- Teleport player to me
        CMD_AddCommand("summon", "Moderators only: summon <player> to me", function(param)
            local player = CMD_GetPlayer(param)
            if CMD_NoSys(param) or CMD_ModsOnly(param) then
                return
            end
            if not player then
                CMD_RejectConsole("The console can't use /summon. This command requires an in-game player.")
                return
            end

            -- Argument required
            if param.parameter then
                local victim = UTIL_FindPlayer(param.parameter)
                if UTIL_Is_Banished(victim) then
                    UTIL_SmartPrint(player, "They are in jail, use /unjail <name>")
                    return
                end
                if victim == player then
                    UTIL_SmartPrint(player, "You can't summon yourself, are you having an identity crisis?")
                    return
                end

                if (victim) then
                    local newpos = player.physical_surface.find_non_colliding_position("character",
                        player.physical_position, 1024,
                        1, false)
                    if (newpos) then
                        UTIL_ExitRemoteView(victim)
                        victim.teleport(newpos, player.physical_surface)
                        if player and victim then
                            UTIL_SmartPrint(player, victim.name .. " suddenly appears before you.")
                            UTIL_SmartPrint(victim, player.name .. " has summoned you.")
                        end
                    else
                        UTIL_SmartPrint(player, "Area appears to be full.")
                        UTIL_ConsolePrint("[ERROR] summon: unable to find non_colliding_position.")
                    end
                else
                    UTIL_SmartPrint(player, "There isn't a player with that name.")
                end
            end
        end)

        -- Teleport victim to x,y
        CMD_AddCommand("transport",
            "Moderators only: transport <player> <x,y>, <surface>, or [gps=x,y] or [gps=x,y,surface]", function(param)
                if CMD_ModsOnly(param) then
                    return
                end

                local player = CMD_GetPlayer(param)
                local actor_name = CMD_GetActorName(player)

                if not param.parameter then
                    UTIL_SmartPrint(player, "Transport who to where?")
                    return
                end

                local victim_name, target = param.parameter:match("^%s*(%S+)%s+(.+)$")

                if not victim_name or not target then
                    UTIL_SmartPrint(player, "Usage: /transport <player> <x,y>, <surface>, or [gps=x,y,surface]")
                    return
                end

                local victim = UTIL_FindPlayer(victim_name)
                if not victim then
                    UTIL_SmartPrint(player, "There isn't a player with that name.")
                    return
                elseif UTIL_Is_Banished(victim) then
                    UTIL_SmartPrint(player, "They are in jail, use /unjail <name>")
                    return
                end

                local surface, position, err = teleportToLocation(victim, target)
                if not surface then
                    UTIL_SmartPrint(player, err)
                    return
                end
                UTIL_SmartPrint(player, "You transported " .. victim.name ..
                    " to (" .. position.x .. "," .. position.y .. ") on '" .. surface.name .. "'.")
                UTIL_SmartPrint(victim, actor_name .. " has transported you.")
            end)

        -- List surfaces
        CMD_AddCommand("surfaces", "Moderators only, list game surfaces and players on them.",
            function(param)
                local player

                if CMD_ModsOnly(param) then
                    return
                end

                if param and param.player_index then
                    player = game.players[param.player_index]
                end

                UTIL_SmartPrint(player, "Surfaces and players: ")

                local buf = ""
                for _, surface in pairs(game.surfaces) do
                    if buf ~= "" then
                        buf = buf .. "\n"
                    end

                    buf = buf .. surface.name .. ": "

                    local pbuf = ""
                    for _, victim in pairs(game.players) do
                        if victim.physical_surface == surface then
                            if pbuf ~= "" then
                                pbuf = pbuf .. ", "
                            else
                                pbuf = "Players: "
                            end
                            pbuf = pbuf .. victim.name
                        end
                    end
                    if pbuf == "" then
                        pbuf = "(None)"
                    end
                    buf = buf .. pbuf
                end

                UTIL_SmartPrint(player, buf)
            end)
end

CMD_RegisterCommands()
