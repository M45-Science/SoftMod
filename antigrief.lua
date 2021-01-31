--Carl Frank Otto III
--carlotto81@gmail.com
require "util"



--Build stuff -- activity
function on_built_entity(event)
  if event and event.player_index and event.created_entity and event.stack then
    local player = game.players[event.player_index]
    local created_entity = event.created_entity
    local stack = event.stack

    if player and player.valid then
      --Blueprint safety
      if stack and stack.valid and stack.valid_for_read and stack.is_blueprint then
        local count = stack.get_blueprint_entity_count()

        --Add item to blueprint throttle, (new) 5 items a second
        if is_new(player) and global.restrict then
          if global.blueprint_throttle and global.blueprint_throttle[player.index] then
            global.blueprint_throttle[player.index] = global.blueprint_throttle[player.index] + 12
          end
        end

        --Silently destroy blueprint items, if blueprint is too big
        if player.admin then
          return
        elseif is_new(player) and count > 500 and global.restrict then
          if created_entity then
            created_entity.destroy()
          end
          --stack.clear()
          player.clear_cursor()
          return
        elseif count > 10000 then
          if created_entity then
            created_entity.destroy()
          end
          --stack.clear()
          player.clear_cursor()
          return
        end
      end

      --Block direct from blueprint book
      if created_entity.name == "entity-ghost" then
        if global.restrict and is_new(player) then
          --player.clear_cursor()
        end
      end

      if created_entity and created_entity.valid then
        if not global.last_speaker_warning then
          global.last_speaker_warning = 0
        end

        if created_entity.name == "programmable-speaker" then
          console_print(player.name .. " placed a speaker at [gps=" .. math.floor(created_entity.position.x) .. "," .. math.floor(created_entity.position.y) .. "]")

          if (global.last_speaker_warning and game.tick - global.last_speaker_warning >= 30) then
            if player.admin == false then --Don't bother with admins
              message_all("[color=red](SYSTEM) " .. player.name .. " placed a speaker at [gps=" .. math.floor(created_entity.position.x) .. "," .. math.floor(created_entity.position.y) .. "][/color]")
              global.last_speaker_warning = game.tick
            end
          end
        end
      end

      if created_entity.name ~= "tile-ghost" and created_entity.name ~= "tile" then
        if created_entity.name == "entity-ghost" then
          --Log item placement
          console_print(player.name .. " +ghost " .. created_entity.ghost_name .. " [gps=" .. math.floor(created_entity.position.x) .. "," .. math.floor(created_entity.position.y) .. "]")
        else
          --Log item placement
          console_print(player.name .. " +" .. created_entity.name .. " [gps=" .. math.floor(created_entity.position.x) .. "," .. math.floor(created_entity.position.y) .. "]")
        end
      end
    end
  end
end

--Cursor stack, block huge blueprints
function on_player_cursor_stack_changed(event)
  if event and event.player_index then
    local player = game.players[event.player_index]

    if player and player.valid then
      if player.cursor_stack then
        local stack = player.cursor_stack
        if stack and stack.valid and stack.valid_for_read and stack.is_blueprint then
          local count = stack.get_blueprint_entity_count()

          --blueprint throttle if needed
          if not player.admin and global.restrict then
            if global.blueprint_throttle and global.blueprint_throttle[player.index] then
              if global.blueprint_throttle[player.index] > 0 then
                console_print(player.name .. " wait " .. round(global.blueprint_throttle[player.index] / 60, 2) .. "s to bp")
                smart_print(player, "[color=red](SYSTEM) You must wait " .. round(global.blueprint_throttle[player.index] / 60, 2) .. " seconds before blueprinting again.[/color]")
                --player.insert(player.cursor_stack)
                --stack.clear()
                player.clear_cursor()
                return
              end
            end
          end
          if player.admin then
            return
          elseif is_new(player) and count > 500 and global.restrict then --new player limit
            console_print(player.name .. " tried to bp " .. count .. " items (DELETED).")
            smart_print(player, "[color=red](SYSTEM) You aren't allowed to use blueprints that large yet.[/color]")
            --stack.clear()
            player.clear_cursor()
            return
          elseif count > 10000 then --lag protection
            console_print(player.name .. " tried to bp " .. count .. " items (DELETED).")
            smart_print(player, "[color=red](SYSTEM) That blueprint is too large![/color]")
            --stack.clear()
            player.clear_cursor()
            return
          end
        end
      end
    end
  end
end

--Pre-Mined item, block some users
function on_pre_player_mined_item(event)
  --Sanity check
  if event and event.player_index and event.entity then
    local player = game.players[event.player_index]
    local obj = event.entity

    if global.restrict then
      --Check player, surface and object are valid
      if player and player.valid and player.index and player.surface and player.surface.valid and obj and obj.valid then
        --New players can't mine objects that they don't own!
        if is_new(player) and obj.last_user ~= nil and obj.last_user.name ~= player.name then
          --Create limbo surface if needed
          if game.surfaces["limbo"] == nil then
            local my_map_gen_settings = {
              default_enable_all_autoplace_controls = false,
              property_expression_names = {cliffiness = 0},
              autoplace_settings = {
                tile = {
                  settings = {
                    ["sand-1"] = {
                      frequency = "normal",
                      size = "normal",
                      richness = "normal"
                    }
                  }
                }
              },
              starting_area = "none"
            }
            game.create_surface("limbo", my_map_gen_settings)
          end

          --Get surface
          local surf = game.surfaces["limbo"]

          --Check if surface is valid
          if surf and surf.valid then
            --Clone object to limbo
            local saveobj = obj.clone({position = obj.position, surface = surf, force = obj.force})

            --Check that object was able to be cloned
            if saveobj and saveobj.valid then
              local signal_wires
              local copper_wires

              --Fix wires... grr
              signal_wires = obj.circuit_connection_definitions
              if obj.type == "electric-pole" then
                copper_wires = obj.neighbours["copper"]
              end
              --game.print("SIGNALS: "..dump(signal_wires))
              --game.print("COPPER: "..dump(copper_wires))

              --Destroy original object.
              obj.destroy()

              --Create list if needed
              if not global.repobj then
                global.repobj = {
                  obj = {},
                  victim = {},
                  surface = {},
                  swires = {},
                  cwires = {}
                }
              end

              --Add obj to list
              table.insert(
                global.repobj,
                {
                  obj = saveobj,
                  victim = player,
                  surface = player.surface,
                  swires = signal_wires,
                  cwires = copper_wires
                }
              )
            else
              console_print("pre_player_mined_item: unable to clone object.")
            end
          else
            console_print("pre_player_mined_item: unable to get limbo-surface.")
          end
        else
          --Normal player, just log it
          console_print(player.name .. " -" .. obj.name .. " [gps=" .. math.floor(obj.position.x) .. "," .. math.floor(obj.position.y) .. "]")
        end
      else
        console_print("pre_player_mined_item: invalid player, obj or surface.")
      end
    end
  end
end

--Rotated item, block some users
function on_player_rotated_entity(event)
  --Sanity check
  if event and event.player_index and event.previous_direction then
    local player = game.players[event.player_index]
    local obj = event.entity
    local prev_dir = event.previous_direction

    if global.restrict then
      --If player and object are valid
      if player and player.valid and obj and obj.valid then
        --Don't let new players rotate other players items, unrotate and untouch the item.
        if is_new(player) and obj.last_user ~= nil and obj.last_user.name ~= player.name then
          --Unrotate
          obj.direction = prev_dir

          --Create untouch list if needed
          if not global.untouchobj then
            global.untouchobj = {object = {}, prev = {}}
          end

          --Add to list
          table.insert(global.untouchobj, {object = obj, prev = obj.last_user})
          smart_print(player, "[color=red](SYSTEM) You are a new player, and are not allowed to rotate other people's objects yet![/color]")

          if player and player.valid and player.character and player.character.valid then
            player.character.damage(15, "enemy") --Little discouragement
          end
        else
          --Normal player, just log it
          console_print(player.name .. " *" .. obj.name .. " [gps=" .. math.floor(obj.position.x) .. "," .. math.floor(obj.position.y) .. "]")
        end
      end
    end
  end
end

--Banned -- kill player to return items
function on_player_banned(event)
  if event and event.player_index then
    local player = game.players[event.player_index]
    if player and player.valid and player.character then
      if global.cspawnpos then
        player.teleport(global.cspawnpos)
      else
        player.teleport({0, 0})
      end
      player.character.die("player")
    end
  end
end

--Replace an item with a clone, from limbo
function replace_with_clone(item)
  local rep = item.obj.clone({position = item.obj.position, surface = item.surface, force = item.obj.force})

  if rep then
    if item.cwires then
      for ind, pole in pairs(item.cwires) do
        rep.connect_neighbour(pole)
      end
    end

    --If we saved signal wire data, reconnect them now
    if item.swires then
      for ind, pole in pairs(item.swires) do
        rep.connect_neighbour(pole)
      end
    end

    if rep then
      smart_print(item.victim, "[color=red](SYSTEM) You are a new player, and are not allowed to mine or replace other people's objects yet![/color]")
      if item.victim and item.victim.valid and item.victim.character and item.victim.character.valid then
        item.victim.character.damage(15, "enemy") --Little discouragement
      end
    end
  end
end

--Blueprint throttle countdown
script.on_nth_tick(
  1,
  function(event)
    --game.force_crc()

    if global.restrict then
      if global.blueprint_throttle then
        --Loop through players, countdown blueprint throttle
        for _, player in pairs(game.connected_players) do
          --Init if needed
          if not global.blueprint_throttle[player.index] then
            global.blueprint_throttle[player.index] = 0
          end

          --Subtract from count
          if global.blueprint_throttle[player.index] > 0 then
            global.blueprint_throttle[player.index] = global.blueprint_throttle[player.index] - 1
          end

          --blueprint throttle if needed.
          if not player.admin then
            if player.cursor_stack then
              local stack = player.cursor_stack
              if stack and stack.valid and stack.valid_for_read and stack.is_blueprint then
                if global.blueprint_throttle and global.blueprint_throttle[player.index] then
                  if global.blueprint_throttle[player.index] > 0 then
                    console_print(player.name .. " wait" .. round(global.blueprint_throttle[player.index] / 60, 2) .. "s to bp.")
                    smart_print(player, "[color=red](SYSTEM) You must wait " .. round(global.blueprint_throttle[player.index] / 60, 2) .. " seconds before blueprinting again.[/color]")
                    --player.insert(player.cursor_stack)
                    --stack.clear()
                    player.clear_cursor()
                  end
                end
              end
            end
          end
        end
      end

      --Replace object list
      if global.repobj then
        for _, item in ipairs(global.repobj) do
          --Sanity check
          if item.obj and item.obj.valid then
            --Check if an item is in our way ( fast replace )
            local fast_replaced =
              item.surface.find_entities_filtered {
              position = item.obj.position,
              radius = 0.99,
              force = item.obj.force,
              limit = 100
            }

            local fixed_obj = false --Item is cloned or untouched
            local clone_obj = false --Do put a clone in place

            --If there are items in our way from fast replace
            if fast_replaced then
              --Loop through items in our way
              for _, fastobj in pairs(fast_replaced) do
                local do_untouch = true

                --Valid object please
                if fastobj and fastobj.valid then
                  --Skip these, we have to do this because fast replace can change item type...
                  if fastobj.type ~= "character" and fastobj.type ~= "item-on-ground" then
                    --Fast replace disabled? Delete fast-replace object, put clone in place.
                    if global.no_fastreplace then
                      --If the item changed type, replace with clone
                      if fastobj.type ~= "electric-pole" then
                        fastobj.destroy()
                        do_untouch = false
                        clone_obj = true
                      end
                    elseif fastobj.type ~= item.obj.type then
                      fastobj.destroy()
                      do_untouch = false
                      clone_obj = true
                    end

                    --If allow the fast replace ( same type ) untouch and restore rotation
                    if do_untouch then
                      fixed_obj = true

                      --Untouch object
                      if item.obj.last_user and item.obj.last_user.valid then
                        --Untouched
                        fastobj.last_user = item.obj.last_user
                      else
                        --Just in case
                        fastobj.last_user = game.players[1]
                      end

                      --Fix for players fast-replacing items to get around rotation block
                      if fastobj.supports_direction then
                        fastobj.direction = item.obj.direction
                      end
                    end
                  end
                end
              end
              --We deleted item in the way, put clone in place now.
              if clone_obj then
                replace_with_clone(item)
                fixed_obj = true
              end
            end

            --If there was no fast replace, just put a clone back in the place of the item
            if not fixed_obj then
              replace_with_clone(item)
            end
          else
            console_print("repobj: Invalid data")
          end

          --Clean up limbo object
          item.obj.destroy()
        end

        --Done with list, invalidate it.
        global.repobj = nil
      end

      --Untouch rotated objects
      if global.untouchobj then
        for _, item in pairs(global.untouchobj) do
          --Sanity Check
          if item.object and item.object.valid then
            --Set last user to previous state
            if item.prev and item.prev.valid then
              item.object.last_user = item.prev
            else --just in case
              item.object.last_user = game.players[1]
            end
          end
        end

        --Done with list, invalidate it
        global.untouchonj = nil
      end
    end
  end
)
