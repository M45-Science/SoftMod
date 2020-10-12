--v0490-10-12-2020_728

--Most of this code is written by:
--Carl Frank Otto III (aka Distortions864)
--carlotto81@gmail.com
--Regulars-only version of script ( very cut down )

local handler = require("event_handler")
handler.add_lib(require("freeplay"))
handler.add_lib(require("silo-script"))


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

--Set our default settings
local function game_settings(player)
    if player and player.valid and player.force then
        player.force.friendly_fire = false --friendly fire
        player.force.research_queue_enabled = true --nice to have
    end
end

local function show_players(victim)
    local numpeople = 0

    for _, player in pairs(game.connected_players) do
        if (player and player.valid and player.connected) then
            numpeople = (numpeople + 1)

                smart_print(
                    victim,
                    string.format(
                        "%-3d: %s",
                        numpeople,
                        player.name
                    )
                )
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

            --register command
            commands.add_command(
                "register",
                "<code>",
                function(param)
                    local player
                    if param and param.player_index then
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
                    if param and param.player_index then
                        local player = game.players[param.player_index]
                        smart_print(player, "This command is for console use only.")
                        return
                    end

                    if param.parameter then
                        message_allp(param.parameter)
                    end
                end
            )


            --Online
            commands.add_command(
                "online",
                "See who is online!",
                function(param)
                    local victim

                    if param and param.player_index then
                        victim = game.players[param.player_index]
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

                    if param and param.player_index then
                        player = game.players[param.player_index]
                    end

                    if (not param.parameter) then
                        smart_print(player, "But what speed? 0.1 to 1")
                        return
                    end

                    if tonumber(param.parameter) then
                        local value = tonumber(param.parameter)
                        if (value >= 0.1 and value <= 1.0) then
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

                        local surface = player.surface

                        if param.parameter then
                            local str = param.parameter
                            local xpos = "0.0"
                            local ypos = "0.0"

                            local n = game.surfaces[param.parameter]
                            if n then
                                surface = n
                                local position = {x = xpos, y = ypos}
                                local newpos =
                                    surface.find_non_colliding_position("character", position, 15, 0.01, false)
                                if newpos then
                                    player.teleport(newpos, surface)
                                    return
                                end
                            end

                            xpos, ypos = str:match("([^,]+),([^,]+)")
                            if tonumber(xpos) and tonumber(ypos) then
                                local position = {x = xpos, y = ypos}

                                if position then
                                    if position.x and position.y then
                                        local newpos =
                                            surface.find_non_colliding_position("character", position, 15, 0.01, false)
                                        if (newpos) then
                                            player.teleport(newpos, surface)
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

--Player connected
script.on_event(
    defines.events.on_player_joined_game,
    function(event)
        if event and event.player_index then
            local player = game.players[event.player_index]

            if player.gui.top.discord then
                player.gui.top.discord.destroy()
            end
        end
    end
)