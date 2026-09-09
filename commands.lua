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

        -- Reset interval message
        CMD_AddCommand("resetdur", "System use only.", function(param)
            if CMD_SysOnly(param) then
                return
            end

            local input = ""
            if param.parameter then
                input = param.parameter
            end


            if storage.SM_Store.resetDuration ~= input then
                storage.SM_Store.resetDuration = input

                -- Refresh open info windows
                for _, victim in pairs(game.connected_players) do
                    if victim and victim.gui and victim.gui.screen and
                        victim.gui.screen.m45_info_window then
                        INFO_InfoWin(victim)
                    end
                end
                --Update clock
                for _, victim in pairs(game.connected_players) do
                    UTIL_DrawMapClock(victim)
                end
            end
        end)

        -- Reset interval message
        CMD_AddCommand("resetint", "System use only.", function(param)
            if CMD_SysOnly(param) then
                return
            end

            local input = ""
            if param.parameter then
                input = param.parameter
            end
            storage.SM_Store.resetDate = input
        end)

        -- Enable / disable friendly fire
        CMD_AddCommand("friendlyfire", "System use only.", function(param)
            local player = (param and param.player_index) and game.players[param.player_index] or nil
            if CMD_SysOnly(param) then
                return
            end

            if param and param.parameter then
                local pforce = game.forces["player"]

                if pforce then
                    if string.lower(param.parameter) == "off" then
                        pforce.friendly_fire = false
                        UTIL_SmartPrint(player, "friendly fire disabled.")
                    elseif string.lower(param.parameter) == "on" then
                        pforce.friendly_fire = true
                        UTIL_SmartPrint(player, "friendly fire enabled.")
                    end
                end
            else
                UTIL_SmartPrint(player, "on or off?")
            end
        end)

        -- Enable / disable blueprints
        CMD_AddCommand("blueprints", "System use only.", function(param)
            local player = (param and param.player_index) and game.players[param.player_index] or nil
            if CMD_SysOnly(param) then
                return
            end

            PERMS_EnsureGroups()

            if param and param.parameter then
                local pforce = game.forces["player"]

                if pforce then
                    if string.lower(param.parameter) == "off" then
                        storage.SM_Store.noBlueprints = true
                        PERMS_SetBlueprintsAllowed(storage.SM_Store.defGroup, false)
                        PERMS_SetBlueprintsAllowed(storage.SM_Store.memGroup, false)
                        PERMS_SetBlueprintsAllowed(storage.SM_Store.regGroup, false)
                        PERMS_SetBlueprintsAllowed(storage.SM_Store.vetGroup, false)
                        PERMS_SetBlueprintsAllowed(storage.SM_Store.modGroup, false)
                        UTIL_SmartPrint(player, "blueprints disabled...")
                    elseif string.lower(param.parameter) == "on" then
                        storage.SM_Store.noBlueprints = false
                        PERMS_SetBlueprintsAllowed(storage.SM_Store.defGroup, true)
                        PERMS_SetBlueprintsAllowed(storage.SM_Store.memGroup, true)
                        PERMS_SetBlueprintsAllowed(storage.SM_Store.regGroup, true)
                        PERMS_SetBlueprintsAllowed(storage.SM_Store.vetGroup, true)
                        PERMS_SetBlueprintsAllowed(storage.SM_Store.modGroup, true)
                        UTIL_SmartPrint(player, "blueprints enabled...")
                    end
                end
            else
                UTIL_SmartPrint(player, "on or off?")
            end
        end)

        -- Enable / disable cheat mode
        CMD_AddCommand("enablecheats", "System use only.", function(param)
            local player = (param and param.player_index) and game.players[param.player_index] or nil
            if CMD_SysOnly(param) then
                return
            end

            if param and param.parameter then
                local pforce = game.forces["player"]

                if pforce then
                    if string.lower(param.parameter) == "off" then
                        storage.SM_Store.cheats = false
                        for _, victim in ipairs(game.connected_players) do
                            victim.cheat_mode = false
                        end
                        UTIL_SmartPrint(player, "cheats disabled...")
                    elseif string.lower(param.parameter) == "on" then
                        storage.SM_Store.cheats = true
                        for _, victim in ipairs(game.connected_players) do
                            victim.cheat_mode = true
                        end
                        pforce.research_all_technologies()
                        UTIL_SmartPrint(player, "cheats enabled...")
                    end
                end
            else
                UTIL_SmartPrint(player, "on or off?")
            end
        end)

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
                        local victim = game.players[param.parameter]

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
                    victim = game.players[param.parameter]
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

        -- change new player restrictions
        CMD_AddCommand("restrict", "System Use Only.", function(param)
            local player
            if CMD_SysOnly(param) then
                return
            end

            -- Process argument
            if not param.parameter then
                UTIL_SmartPrint(player, "options: on, off")
                return
            elseif string.lower(param.parameter) == "off" then
                storage.SM_Store.restrictNew = false
                PERMS_SetPermissions()
                UTIL_SmartPrint(player, "New player restrictions disabled.")
                return
            elseif string.lower(param.parameter) == "on" then
                storage.SM_Store.restrictNew = true
                PERMS_SetPermissions()
                UTIL_SmartPrint(player, "New player restrictions enabled.")
                return
            end
            UTIL_SmartPrint(player, "options: on, off")
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
                print("[ACCESS] " .. ptype .. " " .. player.name .. " " .. param.parameter)
                UTIL_SmartPrint(player, "Sending registration code...")
                return
            end
            UTIL_SmartPrint(player, "You need to provide a registration code!")
        end)

        -- softmod version
        CMD_AddCommand("sversion", "System use only.", function(param)
            local player
            if CMD_SysOnly(param) then
                return
            end

            -- ChatWire calls /sversion after boot; historically this also refreshed state for existing saves.
            RunSetup()

            if param and param.player_index then
                player = game.players[param.player_index]
            end

            if player then
                UTIL_SmartPrint(player, "[SVERSION] " .. (storage.SM_Version or SM_VERSION or "?"))
            else
                print("[SVERSION] " .. (storage.SM_Version or SM_VERSION or "?"))
            end
        end)

        -- Server name
        CMD_AddCommand("cname", "System use only.", function(param)
            if CMD_SysOnly(param) then
                return
            end

            STORAGE_EnsureGlobal()

            if param.parameter then
                storage.SM_Store.serverName = param.parameter

                LOGO_DrawLogo(true)
            end
        end)

        -- Server chat
        CMD_AddCommand("cchat", "System use only.", function(param)
            if CMD_SysOnly(param) then
                return
            end

            if param.parameter then
                UTIL_MsgPlayers(param.parameter)
            end
        end)

        -- Server whisper
        CMD_AddCommand("cwhisper", "System use only.", function(param)
            if CMD_SysOnly(param) then
                return
            end

            -- Must have arguments
            if param.parameter then
                local args = UTIL_SplitStr(param.parameter, " ")

                -- Require two args
                if args and args[1] ~= "" and args[2] then
                    -- Find player
                    local player = game.players[args[1]]
                    if player and player.connected then
                        args[1] = ""
                        UTIL_SmartPrint(player, table.concat(args, " "))
                        return
                    end
                end
            end
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
                local victim = game.players[param.parameter]
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
                local victim = game.players[param.parameter]

                if not victim then
                    UTIL_SmartPrint(player, "Player not found.")
                    return
                end
                PERMS_MakeMember(player, victim)
            end
        end)

        -- Set player to veteran
        CMD_AddCommand("veteran", "System use only.", function(param)
            local player

            if CMD_SysOnly(param) then
                return
            end

            -- Argument required
            if param.parameter then
                local victim = game.players[param.parameter]
                if not victim then
                    UTIL_SmartPrint(player, "Player not found.")
                    return
                end
                PERMS_MakeVeteran(player, victim)
            end
        end)

        -- Set player to regular
        CMD_AddCommand("regular", "System use only.", function(param)
            local player
            if CMD_SysOnly(param) then
                return
            end

            -- Argument required
            if param.parameter then
                local victim = game.players[param.parameter]
                if not victim then
                    UTIL_SmartPrint(player, "Player not found.")
                    return
                end
                PERMS_MakeRegular(player, victim)
            end
        end)

        -- Set player to patreon
        CMD_AddCommand("patreon", "System use only.", function(param)
            local player
            if CMD_SysOnly(param) then
                return
            end

            -- Argument required
            if param.parameter then
                local victim = game.players[param.parameter]

                if (victim) then
                    if victim then
                        if not storage.PData[victim.index].patreon then
                            storage.PData[victim.index].patreon = true
                            UTIL_SmartPrint(victim,
                                "*** Welcome back, and thank you for being a supporter " .. victim.name .. "!!! ***")
                            UTIL_SmartPrint(victim, "NEWS: See the new /stash and /unstash commands!")
                            UTIL_SmartPrint(victim,
                                "/stash will take your currently equipped armor, weapons and ammo and 'stashes' them.")
                            UTIL_SmartPrint(victim, "When you need them again, such as on respawn /unstash them!")
                            UTIL_SmartPrint(victim,
                                "It is very similar to putting them in a box at spawn, but they are safe from being lost or taken.")
                            victim.tag = "(supporter)"
                            ONLINE_MarkDirty()
                        end
                    end
                end
            end
        end)

        -- Set player to nitro
        CMD_AddCommand("nitro", "System use only.", function(param)
            local player
            if CMD_SysOnly(param) then
                return
            end

            -- Argument required
            if param.parameter then
                local victim = game.players[param.parameter]

                if (victim) then
                    if victim then
                        if not storage.PData[victim.index].nitro then
                            storage.PData[victim.index].nitro = true
                            UTIL_SmartPrint(player, "Player given nitro status.")
                            ONLINE_MarkDirty()
                        else
                            UTIL_SmartPrint(player, "Player already has nitro status.")
                        end

                        return
                    end
                end
            end
            UTIL_SmartPrint(player, "Player not found.")
        end)

        -- Add player to patreon credits
        CMD_AddCommand("patreonlist", "System use only.", function(param)
            local player
            if CMD_SysOnly(param) then
                return
            end

            -- Argument required
            if param.parameter then
                storage.SM_Store.patreonCredits = UTIL_SplitStr(param.parameter, ",")
            end
        end)

        -- Add player to nitro credits
        CMD_AddCommand("nitrolist", "System use only.", function(param)
            local player
            if CMD_SysOnly(param) then
                return
            end

            -- Argument required
            if param.parameter then
                storage.SM_Store.nitroCredits = UTIL_SplitStr(param.parameter, ",")
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
            "Moderators only: <size> [x,y]|[gps=x,y]|[gps=x,y,surface] -- Reveals map from a given position or the center of map. Size is in tiles. Default size 1024. Min 128, Max 8192.",
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

                if param.parameter then
                    local str = param.parameter

                    -- Attempt to extract gps format
                    local gx, gy, gsurf = str:match("%[gps=([-%d%.]+),([-%d%.]+),([%w_]+)%]")
                    if not gx then gx, gy = str:match("%[gps=([-%d%.]+),([-%d%.]+)%]") end

                    local x, y = str:match("([-%d%.]+),([-%d%.]+)")
                    local surfname = str:match("^%s*([%w_]+)%s*$")

                    local tokens = {}
                    for token in str:gmatch("[^%s,]+") do
                        table.insert(tokens, token)
                    end

                    -- First numeric token = size
                    local s = tonumber(tokens[1])
                    if s then
                        size = math.max(128, math.min(8192, s))
                        table.remove(tokens, 1)
                    end

                    -- Handle GPS
                    if gx and gy then
                        center = { x = tonumber(gx), y = tonumber(gy) }
                        if gsurf and game.surfaces[gsurf] then
                            psurface = game.surfaces[gsurf]
                        end
                        -- Handle x,y
                    elseif x and y then
                        center = { x = tonumber(x), y = tonumber(y) }
                        -- Handle surface name if valid
                    elseif surfname and game.surfaces[surfname] then
                        psurface = game.surfaces[surfname]
                        center = { x = 0, y = 0 }
                    end
                end

                if psurface and pforce and center then
                    local area = {
                        lefttop = { x = center.x - size / 2, y = center.y - size / 2 },
                        rightbottom = { x = center.x + size / 2, y = center.y + size / 2 }
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
                local victim = game.players[param.parameter]

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

                local str = param.parameter
                local surface = player.surface -- default surface
                local xpos, ypos

                -- Try [gps=x,y] or [gps=x,y,surface]
                local gx, gy, gsurf = str:match("%[gps=([-%d%.]+),([-%d%.]+),([%w_]+)%]")
                if not gx then
                    gx, gy = str:match("%[gps=([-%d%.]+),([-%d%.]+)%]")
                end
                if gx and gy then
                    xpos = tonumber(gx)
                    ypos = tonumber(gy)
                    if gsurf and game.surfaces[gsurf] then
                        surface = game.surfaces[gsurf]
                    end
                else
                    -- Try x,y format
                    local x, y = str:match("([-%d%.]+),([-%d%.]+)")
                    if x and y then
                        xpos = tonumber(x)
                        ypos = tonumber(y)
                    else
                        -- Try surface name
                        local named_surface = game.surfaces[str]
                        if named_surface then
                            surface = named_surface
                            xpos = 0
                            ypos = 0
                        end
                    end
                end

                if xpos and ypos then
                    local position = { x = xpos, y = ypos }
                    local newpos = surface.find_non_colliding_position("character", position, 1024, 1, false)
                    UTIL_ExitRemoteView(player)
                    if newpos then
                        player.teleport(newpos, surface)
                        UTIL_SmartPrint(player,
                            "You teleport to (" .. xpos .. "," .. ypos .. ") on surface '" .. surface.name .. "'.")
                    else
                        player.teleport(position, surface)
                        UTIL_SmartPrint(player, "Area appears to be full.")
                        UTIL_ConsolePrint("[ERROR] tp: unable to find non_colliding_position.")
                    end
                elseif surface then
                    local position = { x = 0, y = 0 }
                    local newpos = surface.find_non_colliding_position("character", position, 1024, 1, false)
                    UTIL_ExitRemoteView(player)
                    player.teleport(newpos or position, surface)
                    UTIL_SmartPrint(player, "You teleport to spawn of surface '" .. surface.name .. "'.")
                else
                    UTIL_SmartPrint(player, "Invalid location or surface.")
                end
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
                local victim = game.players[param.parameter]
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

                local args = UTIL_SplitStr(param.parameter, " ")
                local victim_name = args[1]
                local target = args[2]

                if not victim_name or not target then
                    UTIL_SmartPrint(player, "Usage: /transport <player> <x,y>, <surface>, or [gps=x,y,surface]")
                    return
                end

                local victim = game.players[victim_name]
                if not victim then
                    UTIL_SmartPrint(player, "There isn't a player with that name.")
                    return
                elseif UTIL_Is_Banished(victim) then
                    UTIL_SmartPrint(player, "They are in jail, use /unjail <name>")
                    return
                end

                local surface = victim.surface
                local xpos, ypos

                -- Try GPS tag [gps=x,y,surface]
                local gx, gy, gsurf = target:match("%[gps=([-%d%.]+),([-%d%.]+),([%w_]+)%]")
                if not gx then
                    gx, gy = target:match("%[gps=([-%d%.]+),([-%d%.]+)%]")
                end
                if gx and gy then
                    xpos = tonumber(gx)
                    ypos = tonumber(gy)
                    if gsurf and game.surfaces[gsurf] then
                        surface = game.surfaces[gsurf]
                    end
                else
                    -- Try x,y format
                    local x, y = target:match("([-%d%.]+),([-%d%.]+)")
                    if x and y then
                        xpos = tonumber(x)
                        ypos = tonumber(y)
                    else
                        -- Try surface name
                        local named_surface = game.surfaces[target]
                        if named_surface and named_surface.valid then
                            surface = named_surface
                            xpos = 0
                            ypos = 0
                        end
                    end
                end

                if xpos and ypos then
                    local position = { x = xpos, y = ypos }
                    local newpos = surface.find_non_colliding_position("character", position, 1024, 1, false)
                    if not newpos then
                        newpos = position
                        UTIL_ConsolePrint("[ERROR] transport: unable to find non_colliding_position.")
                    end
                    UTIL_ExitRemoteView(victim)
                    victim.teleport(newpos, surface)
                    UTIL_SmartPrint(player,
                        "You transported " ..
                        victim.name .. " to (" .. xpos .. "," .. ypos .. ") on '" .. surface.name .. "'.")
                    UTIL_SmartPrint(victim, actor_name .. " has transported you.")
                elseif surface then
                    local position = { x = 0, y = 0 }
                    local newpos = surface.find_non_colliding_position("character", position, 1024, 1, false)
                    UTIL_ExitRemoteView(victim)
                    victim.teleport(newpos or position, surface)
                    UTIL_SmartPrint(player,
                        "You transported " .. victim.name .. " to the spawn of '" .. surface.name .. "'.")
                    UTIL_SmartPrint(victim, actor_name .. " has transported you.")
                else
                    UTIL_SmartPrint(player, "Transport target location invalid.")
                end
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
