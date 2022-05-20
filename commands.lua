--Carl Frank Otto III
--carlotto81@gmail.com
--GitHub: https://github.com/Distortions81/M45-SoftMod
--License: MPL 2.0
require "utility"
require "banish"
require "logo"

--Custom commands
script.on_load(
  function()
    --Only add if no commands yet
    if (not commands.commands.server_interface) then
      add_banish_commands()
      --banish.lua

      --Reset interval message
      commands.add_command(
        "resetint",
        "on/off",
        function(param)
          local player
          local victim

          --Admins only
          if param and param.player_index then
            player = game.players[param.player_index]
            if player and player.admin == false then
              smart_print(player, "Admins only.")
              return
            end
          end

          if param.parameter then
            global.resetint = param.parameter
          end
        end
      )

      --Enable / disable friendly fire
      commands.add_command(
        "friendlyfire",
        "on/off",
        function(param)
          local player
          local victim

          --Admins only
          if param and param.player_index then
            player = game.players[param.player_index]
            if player and player.admin == false then
              smart_print(player, "Admins only.")
              return
            end
          end

          if param and param.parameter then
            local pforce = game.forces["player"]

            if pforce then
              if string.lower(param.parameter) == "off" then
                pforce.friendly_fire = false
                smart_print(player, "friendly fire disabled.")
              elseif string.lower(param.parameter) == "on" then
                pforce.friendly_fire = true
                smart_print(player, "friendly fire enabled.")
              end
            end
          else
            smart_print(player, "on or off?")
          end
        end
      )

      --Enable / disable blueprints
      commands.add_command(
        "blueprints",
        "on/off",
        function(param)
          local player
          local victim

          --Admins only
          if param and param.player_index then
            player = game.players[param.player_index]
            if player and player.admin == false then
              smart_print(player, "Admins only.")
              return
            end
          end

          create_groups()

          if param and param.parameter then
            local pforce = game.forces["player"]

            if pforce then
              if string.lower(param.parameter) == "off" then
                set_blueprints_enabled(global.defaultgroup, false)
                set_blueprints_enabled(global.membersgroup, false)
                set_blueprints_enabled(global.regularsgroup, false)
                smart_print(player, "blueprints disabled...")
              elseif string.lower(param.parameter) == "on" then
                set_blueprints_enabled(global.defaultgroup, true)
                set_blueprints_enabled(global.membersgroup, true)
                set_blueprints_enabled(global.regularsgroup, true)
                smart_print(player, "blueprints enabled...")
              end
            end
          else
            smart_print(player, "on or off?")
          end
        end
      )

      --Enable / disable cheat mode
      commands.add_command(
        "enablecheats",
        "on/off",
        function(param)
          local player
          local victim

          --Admins only
          if param and param.player_index then
            player = game.players[param.player_index]
            if player and player.admin == false then
              smart_print(player, "Admins only.")
              return
            end
          end

          create_groups()

          if param and param.parameter then
            local pforce = game.forces["player"]

            if pforce then
              if string.lower(param.parameter) == "off" then
                global.cheatson = false
                for _, player in pairs(game.players) do
                  player.cheat_mode = false
                end
                smart_print(player, "cheats disabled...")
              elseif string.lower(param.parameter) == "on" then
                global.cheatson = true
                for _, player in pairs(game.players) do
                  player.cheat_mode = true
                end
                pforce.research_all_technologies()
                smart_print(player, "cheats enabled...")
              end
            end
          else
            smart_print(player, "on or off?")
          end
        end
      )

      --adjust run speed
      commands.add_command(
        "run",
        "<float> (0 is normal speed)",
        function(param)
          local player
          local victim

          --Admins only
          if param and param.player_index then
            player = game.players[param.player_index]
            if player and player.admin == false then
              smart_print(player, "Admins only.")
              return
            end
          end

          if player and player.valid then
            if player.character and player.character.valid then
              if tonumber(param.parameter) then
                local speed = tonumber(param.parameter)

                --Factorio doesn't like speeds less than -1
                if speed < -0.99 then
                  speed = -0.99
                end

                --Cap to reasonable amount
                if speed > 1000 then
                  speed = 1000
                end

                player.character.character_running_speed_modifier = speed
              else
                smart_print(player, "Numbers only.")
              end
            else
              smart_print(player, "Can't set walk speed, because you don't have a body.")
            end
          else
            smart_print(player, "The console can't walk...")
          end
        end
      )

      --turn invincible
      commands.add_command(
        "immortal",
        "optional: <name> (toggle player immortality, default self)",
        function(param)
          local player
          local victim

          --Admins only
          if param and param.player_index then
            player = game.players[param.player_index]
            if player and player.admin == false then
              smart_print(player, "Admins only.")
              return
            end
          end

          local target = player

          if param and param.parameter then
            victim = game.players[param.parameter]
          end

          if victim and victim.valid then
            target = victim
          end

          if target and target.valid then
            if target.character and target.character.valid then
              if target.character.destructible then
                target.character.destructible = false
                smart_print(player, target.name .. " is now immortal.")
              else
                target.character.destructible = true
                smart_print(player, target.name .. " is now mortal.")
              end
            else
              smart_print(player, "They don't have a body right now.")
            end
          else
            smart_print(player, "Couldn't find a player by that name.")
          end
        end
      )

      --change new player restrictions
      commands.add_command(
        "restrict",
        "change player restrictions",
        function(param)
          local player

          --Admins only
          if param and param.player_index then
            player = game.players[param.player_index]
            if player and player.admin == false then
              smart_print(player, "Admins only.")
              return
            end
          end

          --Process argument
          if not param.parameter then
            smart_print(player, "options: on, off")
            return
          elseif string.lower(param.parameter) == "off" then
            global.restrict = false
            set_perms()
            smart_print(player, "New player restrictions disabled.")
            return
          elseif string.lower(param.parameter) == "on" then
            global.restrict = true
            set_perms()
            smart_print(player, "New player restrictions enabled.")
            return
          end
          create_player_globals()
        end
      )

      --game tick
      commands.add_command(
        "gt",
        "(Shows game tick)",
        function(param)
          local player

          if param and param.player_index then
            player = game.players[param.player_index]
          end

          smart_print(player, "[GT] " .. game.tick)
        end
      )

      --register command
      commands.add_command(
        "register",
        "<code>\n(Requires a registration code from discord)",
        function(param)
          --This command is disabled
          if param and param.player_index then
            local player = game.players[param.player_index]

            --Only if arguments
            if param.parameter and player and player.valid then
              --Init global if needed
              if not global.access_count then
                global.access_count = {}
              end

              --Init player if needed, else add to
              if not global.access_count[player.index] then
                global.access_count[player.index] = 1
              else
                if global.access_count[player.index] > 3 then
                  smart_print(player, "You have exhausted your registration attempts.")
                  return
                end
                global.access_count[player.index] = global.access_count[player.index] + 1
              end

              local ptype = "Error"

              if player.admin then
                ptype = "admin"
              elseif is_regular(player) then
                ptype = "regular"
              elseif is_member(player) then
                ptype = "trusted"
              else
                ptype = "normal"
              end

              --Send to ChatWire
              print("[ACCESS] " .. ptype .. " " .. player.name .. " " .. param.parameter)
              smart_print(player, "Sending registration code...")
              return
            end
            smart_print(player, "You need to provide a registration code!")
            return
          end
          smart_print(nil, "I don't think the console needs to use this command...")
        end
      )

      --softmod version
      commands.add_command(
        "sversion",
        "(Shows soft-mod version)",
        function(param)
          local player

          if param and param.player_index then
            player = game.players[param.player_index]
          end

          smart_print(player, "[SVERSION] " .. global.svers)
        end
      )

      --Server name
      commands.add_command(
        "cname",
        "<name here>\n(Names the factorio server)",
        function(param)
          --Admins only
          if param and param.player_index then
            local player = game.players[param.player_index]
            if not player.admin then
              smart_print(player, "This command is for system and admin use only.")
              return
            end
          end

          if param.parameter then
            global.servname = param.parameter

            --Set logo to be redrawn
            global.drawlogo = false
            --Redraw
            dodrawlogo()

            global.servers = nil
            global.ports = nil
            create_myglobals()
          end
        end
      )

      --Server chat
      commands.add_command(
        "cchat",
        "<message here>\n(Used for Discord bridge)",
        function(param)
          --Console only, no players
          if param and param.player_index then
            local player = game.players[param.player_index]
            smart_print(player, "This command is for system use only.")
            return
          end

          if param.parameter then
            message_allp(param.parameter)
          end
        end
      )

      --Server whisper
      commands.add_command(
        "cwhisper",
        "<message here>\n(Used for Discord Bridge)",
        function(param)
          --Console only, no players
          if param and param.player_index then
            local player = game.players[param.player_index]
            smart_print(player, "This command is for system use only.")
            return
          end

          --Must have arguments
          if param.parameter then
            local args = mysplit(param.parameter, " ")

            --Require two args
            if args ~= {} and args[1] and args[2] then
              --Find player
              for _, player in pairs(game.connected_players) do
                if player.name == args[1] then
                  args[1] = ""
                  smart_print(player, table.concat(args, " "))
                  return
                end
              end
            end
          end
        end
      )

      --Reset players's time and status
      commands.add_command(
        "reset",
        "<player>\n(Set player to NEW)",
        function(param)
          local player

          --Admins only
          if param and param.player_index then
            player = game.players[param.player_index]
            if player and player.admin == false then
              smart_print(player, "Admins only.")
              return
            end
          end

          --Argument needed
          if param.parameter then
            local victim = game.players[param.parameter]

            if victim and victim.valid then
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
          smart_print(player, "Player not found.")
        end
      )

      --Trust player
      commands.add_command(
        "member",
        "<player>\n(Makes the player a member)",
        function(param)
          local player

          --Admins only
          if param and param.player_index then
            player = game.players[param.player_index]
            if player.admin == false then
              smart_print(player, "Admins only.")
              return
            end
          end

          --Argument required
          if param.parameter then
            local victim = game.players[param.parameter]

            if (victim) then
              if victim and victim.valid and global.membersgroup then
                smart_print(player, "Player given members status.")
                global.membersgroup.add_player(victim)
                update_player_list() --online.lua
                return
              end
            end
          end
          smart_print(player, "Player not found.")
        end
      )

      --Set player to regular
      commands.add_command(
        "regular",
        "<player>\n(Makes the player a regular)",
        function(param)
          local player

          --Admins only
          if param and param.player_index then
            player = game.players[param.player_index]
            if player and player.admin == false then
              smart_print(player, "Admins only.")
              return
            end
          end

          --Argument required
          if param.parameter then
            local victim = game.players[param.parameter]

            if (victim) then
              if victim and victim.valid and global.regularsgroup then
                smart_print(player, "Player given regulars status.")
                global.regularsgroup.add_player(victim)
                update_player_list() --online.lua
                return
              end
            end
          end
          smart_print(player, "Player not found.")
        end
      )

      --Set player to patreon
      commands.add_command(
        "patreon",
        "<player>\n(Makes the player a patreon)",
        function(param)
          local player

          --Admins only
          if param and param.player_index then
            player = game.players[param.player_index]
            if player and player.admin == false then
              smart_print(player, "Admins only.")
              return
            end
          end

          --Argument required
          if param.parameter then
            local victim = game.players[param.parameter]

            if (victim) then
              if victim and victim.valid then
                if not global.patreons then
                  global.patreons = {}
                end
                if not global.patreons[victim.index] then
                  global.patreons[victim.index] = true
                  smart_print(player, "Player given patreon status.")
                  update_player_list() --online.lua
                else
                  smart_print(player, "Player already has patreon status.")
                end

                return
              end
            end
          end
          smart_print(player, "Player not found.")
        end
      )

      --Set player to nitro
      commands.add_command(
        "nitro",
        "<player>\n(Makes the player a nitro booster)",
        function(param)
          local player

          --Admins only
          if param and param.player_index then
            player = game.players[param.player_index]
            if player and player.admin == false then
              smart_print(player, "Admins only.")
              return
            end
          end

          --Argument required
          if param.parameter then
            local victim = game.players[param.parameter]

            if (victim) then
              if victim and victim.valid then
                if not global.nitros then
                  global.nitros = {}
                end
                if not global.nitros[victim.index] then
                  global.nitros[victim.index] = true
                  smart_print(player, "Player given nitro status.")
                  update_player_list() --online.lua
                else
                  smart_print(player, "Player already has nitro status.")
                end

                return
              end
            end
          end
          smart_print(player, "Player not found.")
        end
      )

      --Add player to patreon credits
      commands.add_command(
        "patreonlist",
        "(Update patreon credits)",
        function(param)
          local player

          --Console only, no players
          if param and param.player_index then
            local player = game.players[param.player_index]
            smart_print(player, "This command is for system use only.")
            return
          end

          --Argument required
          if param.parameter then
            global.patreonlist = mysplit(param.parameter, ",")
          end
        end
      )

      --Add player to nitro credits
      commands.add_command(
        "nitrolist",
        "(Update nitro credits)",
        function(param)
          local player

          --Console only, no players
          if param and param.player_index then
            local player = game.players[param.player_index]
            smart_print(player, "This command is for system use only.")
            return
          end

          --Argument required
          if param.parameter then
            global.nitrolist = mysplit(param.parameter, ",")
          end
        end
      )

      --Change default spawn point
      commands.add_command(
        "cspawn",
        "<x,y> (OPTIONAL)\n(Sets spawn point to <x,y>, or where admin is standing)",
        function(param)
          local victim
          local new_pos_x = 0.0
          local new_pos_y = 0.0

          --Admins only
          if param and param.player_index then
            victim = game.players[param.player_index]

            if victim and victim.admin == false then
              smart_print(victim, "Admins only.")
              return
            end
          end

          local psurface = game.surfaces[1]
          local pforce = game.forces["player"]

          --use admin's force and position if available.
          if victim and victim.valid then
            pforce = victim.force

            new_pos_x = victim.position.x
            new_pos_y = victim.position.y
          end

          --Location supplied
          if param.parameter then
            local xytable = mysplit(param.parameter, ",")
            if xytable ~= {} and tonumber(xytable[1]) and tonumber(xytable[2]) then
              local argx = xytable[1]
              local argy = xytable[2]
              new_pos_x = argx
              new_pos_y = argy
            else
              smart_print(victim, "Invalid argument. /cspawn x,y. No argument uses your current location.")
              return
            end
          end

          --Set new spawn spot
          if pforce and psurface and new_pos_x and new_pos_y then
            pforce.set_spawn_position({ new_pos_x, new_pos_y }, psurface)
            smart_print(
              victim,
              string.format("New spawn point set: %d,%d", math.floor(new_pos_x), math.floor(new_pos_y))
            )
            smart_print(victim, string.format("Force: %s", pforce.name))

            --Set logo to be redrawn
            global.drawlogo = false
            --Redraw
            dodrawlogo()
          else
            smart_print(victim, "Couldn't find force...")
          end
        end
      )

      --Reveal map
      commands.add_command(
        "reveal",
        "<size> (OPTIONAL)\n(Reveals <size> units of the map, or 1024 by default. Min 128, Max 8192)",
        function(param)
          local victim

          --Admins only
          if param and param.player_index then
            victim = game.players[param.player_index]
            if victim and victim.admin == false then
              smart_print(victim, "Admins only.")
              return
            end
          end

          --Get surface and force
          local psurface = game.surfaces[1]
          local pforce = game.forces["player"]
          --Default size
          local size = 1024

          --Use admin's surface and force if possible
          if victim and victim.valid then
            psurface = victim.surface
            pforce = victim.force
          end

          --If size specified
          if param.parameter then
            if tonumber(param.parameter) then
              local rsize = tonumber(param.parameter)

              --Limit size of area
              if rsize > 0 then
                if rsize < 128 then
                  rsize = 128
                else
                  if rsize > 8192 then
                    rsize = 8192
                  end
                  size = rsize
                end
              end
            else
              smart_print(victim, "Numbers only.")
              return
            end
          end

          --Chart the area
          if psurface and pforce and size then
            pforce.chart(
              psurface,
              {
                lefttop = { x = -size / 2, y = -size / 2 },
                rightbottom = { x = size / 2, y = size / 2 }
              }
            )
            local sstr = math.floor(size)
            smart_print(victim, "Revealing " .. sstr .. "x" .. sstr .. " tiles")
          else
            smart_print(victim, "Invalid force or surface.")
          end
        end
      )

      --Rechart map
      commands.add_command(
        "rechart",
        "(Refreshes all chunks that exist)",
        function(param)
          local victim

          --Admins only
          if param and param.player_index then
            victim = game.players[param.player_index]
            if victim and victim.admin == false then
              smart_print(victim, "Admins only.")
              return
            end
          end

          local pforce = game.forces["player"]

          --Use admin's force
          if victim and victim.valid then
            pforce = victim.force
          end

          if pforce then
            pforce.clear_chart()
            smart_print(victim, "Recharting map...")
          else
            smart_print(victim, "Couldn't find force.")
          end
        end
      )

      --Online
      commands.add_command(
        "online",
        "(See who is online)",
        function(param)
          local victim

          if param and param.player_index then
            victim = game.players[param.player_index]
          end
          show_players(victim)
        end
      )

      --Game speed, without walk speed mod
      commands.add_command(
        "aspeed",
        "<x.x>\nSet game UPS, and do not adjust walk speed.",
        function(param)
          local player

          if param and param.player_index then
            player = game.players[param.player_index]
          end

          --Admins only
          if player and player.admin == false then
            smart_print(player, "Admins only.")
            return
          end

          --Need argument
          if (not param.parameter) then
            smart_print(player, "But what speed? 4 to 1000")
            return
          end

          --Decode arg
          if tonumber(param.parameter) then
            local value = tonumber(param.parameter)

            --Limit speed range
            if (value >= 4 and value <= 1000) then
              game.speed = (value / 60.0)
            else
              smart_print(player, "That doesn't seem like a good idea...")
            end
          else
            smart_print(player, "Numbers only.")
          end
        end
      )

      --Game speed
      commands.add_command(
        "gspeed",
        "<x.x>\n(Changes game speed)\nDefault speed: 1.0 (60 UPS), Min 0.1 (6 UPS), Max  10.0 (600 UPS)",
        function(param)
          local player

          if param and param.player_index then
            player = game.players[param.player_index]
          end

          --Admins only
          if player and player.admin == false then
            smart_print(player, "Admins only.")
            return
          end

          --Need argument
          if (not param.parameter) then
            smart_print(player, "But what speed? 0.1 to 10")
            return
          end

          --Decode arg
          if tonumber(param.parameter) then
            local value = tonumber(param.parameter)

            --Limit speed range
            if (value >= 0.1 and value <= 10.0) then
              game.speed = value

              --Get default force
              local pforce = game.forces["player"]

              --Use admin's force
              if player and player.valid then
                pforce = player.force
              end

              --If force found
              if pforce then
                --Calculate walk speed for UPS
                pforce.character_running_speed_modifier = ((1.0 / value) - 1.0)
                smart_print(
                  player,
                  "Game speed: " .. value .. " Walk speed: " .. pforce.character_running_speed_modifier
                )

                --Don't show message if run via console (ChatWire)
                if (player) then
                  message_all("Game speed set to " .. (game.speed * 100.00) .. "%")
                end
              else
                smart_print(player, "Couldn't find a valid force")
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
          --No console :P
          if not param.player_index then
            smart_print(nil, "You want me to teleport a remote console somewhere???")
            return
          end
          local player = game.players[param.player_index]

          --Admin only
          if (player and player.valid and player.connected and player.character and player.character.valid) then
            if (player.admin == false) then
              smart_print(player, "Admins only.")
              return
            end

            --Argument required
            if param.parameter then
              local victim = game.players[param.parameter]

              if (victim and victim.valid) then
                local newpos = victim.surface.find_non_colliding_position("character", victim.position, 100, 0.1, false)
                if (newpos) then
                  player.teleport(newpos, victim.surface)
                  smart_print(player, "*Poof!*")
                else
                  smart_print(player, "Area appears to be full.")
                  console_print("error: tto: unable to find non_colliding_position.")
                end
                return
              end
            end
            smart_print(player, "Teleport to who?")
          end
        end
      )

      --Teleport x,y
      commands.add_command(
        "tp",
        "<x,y> -- teleport to <x,y>",
        function(param)
          --No console :P
          if not param.player_index then
            smart_print(nil, "You want me to teleport a remote console somewhere???")
            return
          end
          local player = game.players[param.player_index]

          --Admins only
          if (player and player.valid and player.connected and player.character and player.character.valid) then
            if (player.admin == false) then
              smart_print(player, "Admins only.")
              return
            end

            local surface = player.surface

            --Argument required
            if param.parameter then
              local str = param.parameter
              local xpos = "0.0"
              local ypos = "0.0"

              --Find surface from argument
              local n = game.surfaces[param.parameter]
              if n then
                surface = n
                local position = { x = xpos, y = ypos }
                local newpos = surface.find_non_colliding_position("character", position, 100, 0.1, false)
                if newpos then
                  player.teleport(newpos, surface)
                  return
                else
                  player.teleport(position, surface)
                  console_print("error: tp: unable to find non_colliding_position.")
                end
              end

              --Find x/y from argument
              --Matches two potentially negative numbers separated by a comma, gps compatible
              --str could be "-353,19" or "[gps=80,-20]" or "[gps=5,3,hell]"
              xpos, ypos = str:match("(%-?%d+),%s*(%-?%d+)")
              if tonumber(xpos) and tonumber(ypos) then
                local position = { x = xpos, y = ypos }

                if position then
                  if position.x and position.y then
                    local newpos = surface.find_non_colliding_position("character", position, 100, 0.1, false)
                    if (newpos) then
                      player.teleport(newpos, surface)
                      smart_print(player, "*Poof!*")
                    else
                      smart_print(player, "Area appears to be full.")
                      console_print("error: tp: unable to find non_colliding_position.")
                    end
                  else
                    smart_print(player, "Invalid location.")
                  end
                end
                return
              else
                smart_print(player, "Numbers only.")
              end
            end
            smart_print(player, "Teleport where? x,y or surface name")
          end
        end
      )

      --Teleport player to me
      commands.add_command(
        "tfrom",
        "<player> -- teleport <player> to me",
        function(param)
          --No console :P
          if not param.player_index then
            smart_print(nil, "You want me to teleport a remote console somewhere???")
            return
          end
          local player = game.players[param.player_index]

          --Admins only
          if (player and player.valid and player.connected and player.character and player.character.valid) then
            if (player.admin == false) then
              smart_print(player, "Admins only.")
              return
            end

            --Argument required
            if param.parameter then
              local victim = game.players[param.parameter]

              if (victim and victim.valid) then
                local newpos = player.surface.find_non_colliding_position("character", player.position, 100, 0.1, false)
                if (newpos) then
                  victim.teleport(newpos, player.surface)
                  smart_print(player, "*Poof!*")
                else
                  smart_print(player, "Area appears to be full.")
                  console_print("error: tfrom: unable to find non_colliding_position.")
                end
              else
                smart_print(player, "Who do you want to teleport to you?")
              end
            end
          end
        end
      )
    end
  end
)
