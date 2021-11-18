--Carl Frank Otto III
--carlotto81@gmail.com
require "utility"

function findobj(name, position, surface)
  for pos, obj in pairs(global.objmap) do
    if obj.name == name and obj.position == position and obj.surface == surface then
      return pos
    end
  end

  --console_print("error: findobj: obj not found: " .. name .. " [gps=" .. position.x .. "," .. position.y .. "]")
  return nil
end

function on_robot_built_entity(event)
  local obj = event.created_entity
  local bot = event.robot

  if obj and obj.valid then
    if bot and bot.valid then
      if obj.name ~= "tile-ghost" and obj.name ~= "tile" then
        if obj.name == "entity-ghost" then
          --Save to db
          --table.insert(global.objmap, olog)
          --log
          --console_print(bot.name.." +"..obj.name.." [gps="..obj.position.x..","..obj.position.y.."]")

          --Map data export
          local olog = {tick = game.tick, creator = bot.name, name = obj.name, type = obj.type, position = obj.position, direction = obj.direction, surface = obj.surface.name, force = obj.force.name, rotated = false, mined = false, robot = true}
          game.write_file("mapdata.dat", game.table_to_json(olog).."\n", true, 0)
        else
          --console_print("bot +"..obj.name.." [gps="..obj.position.x..","..obj.position.y.."] ", obj.ghost_name)
        end
      end
    else
      console_print("on_robot_built_entity: invalid bot")
    end
  else
    console_print("on_robot_built_entity: invalid obj")
  end
end

--Build stuff -- activity
function on_built_entity(event)
  local player = game.players[event.player_index]
  local obj = event.created_entity

  if player and player.valid then
    if obj and obj.valid then
      if not global.last_speaker_warning then
        global.last_speaker_warning = 0
      end

      if obj.name == "programmable-speaker" or (obj.name == "entity-ghost" and obj.ghost_name == "programmable-speaker") then
        if (global.last_speaker_warning and game.tick - global.last_speaker_warning >= 30) then
          if player.admin == false then --Don't bother with admins
            gsysmsg(player.name .. " placed a speaker at [gps=" .. math.floor(obj.position.x) .. "," .. math.floor(obj.position.y) .. "]")
            global.last_speaker_warning = game.tick
          end
        end
      end

      if obj.name ~= "tile-ghost" and obj.name ~= "tile" then
        if obj.name ~= "entity-ghost" then
          --log
          console_print(player.name.." +"..obj.name.." [gps="..obj.position.x..","..obj.position.y.."]")

          --Map data export
          local olog = {tick = game.tick, creator = player.name, name = obj.name, type = obj.type, position = obj.position, direction = obj.direction, surface = obj.surface.name, force = obj.force.name, rotated = false, mined = false, robot = false}
          game.write_file("mapdata.dat", game.table_to_json(olog).."\n", true, 0)

        --Save to db
        --table.insert(global.objmap, olog)
        else
          console_print(player.name.." +"..obj.name.." [gps="..obj.position.x..","..obj.position.y.."] " .. obj.ghost_name)
        end
      end
    else
      console_print("on_built_entity: invalid obj")
    end
  else
    console_print("on_built_entity: invalid player")
  end
end

--Pre-Mined item
function on_pre_player_mined_item(event)
  --Sanity check
  if event and event.entity and event.player_index then
    local player = game.players[event.player_index]
    local obj = event.entity

    if obj and obj.valid and player and player.valid then
      if obj.name ~= "tile-ghost" and obj.name ~= "tile" then
        if obj.name ~= "entity-ghost" then
          --Remove from db
          --deleteobj(obj.name, obj.position, obj.surface)

          --log
          console_print(player.name .. " -" .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "]")

          --Map data export
          local olog = {tick = game.tick, creator = player.name, name = obj.name, type = obj.type, position = obj.position, direction = obj.direction, surface = obj.surface.name, force = obj.force.name, rotated = false, mined = true, robot = false}
          game.write_file("mapdata.dat", game.table_to_json(olog).."\n", true, 0)
        else
          console_print(player.name .. " -" .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "] " .. obj.ghost_name)
        end
      end
    else
      console_print("pre_player_mined_item: invalid obj")
    end
  end
end

function on_robot_pre_mined(event)
  --Sanity check
  if event and event.entity then
    local obj = event.entity
    local bot = event.robot

    --Check player, surface and object are valid
    if obj and obj.valid then
      if bot and bot.valid then
        if obj.name ~= "tile-ghost" and obj.name ~= "tile" then
          if obj.name ~= "entity-ghost" then
            --Remove from db
            --deleteobj(obj.name, obj.position, obj.surface)

            --log
            --console_print("bot " .. " -" .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "]")

            --Map data export
            local olog = {tick = game.tick, creator = bot.name, name = obj.name, type = obj.type, position = obj.position, direction = obj.direction, surface = obj.surface.name, force = obj.force.name, rotated = false, mined = true, robot = true}
            game.write_file("mapdata.dat", game.table_to_json(olog).."\n", true, 0)
          else
            --console_print("robot " .. " -" .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "] " .. obj.ghost_name)
          end
        end
      else
        console_print("on_robot_pre_mined: invalid bot")
      end
    end
  else
    console_print("on_robot_pre_mined: invalid obj")
  end
end

--Rotated item, block some users
function on_player_rotated_entity(event)
  --Sanity check
  if event and event.player_index and event.previous_direction then
    local player = game.players[event.player_index]
    local obj = event.entity

    --If player and object are valid
    if player and player.valid then
      if obj and obj.valid then
        if obj.name ~= "tile-ghost" and obj.name ~= "tile" then
          if obj.name ~= "entity-ghost" then
            --update in storage
            --local pos = findobj(obj.name, obj.position, obj.surface)
            --global.objmap[pos].direction = obj.direction

            --log
            console_print(player.name .. " *" .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "]")

            --Map data export
            local olog = {tick = game.tick, creator = player.name, name = obj.name, type = obj.type, position = obj.position, direction = obj.direction, surface = obj.surface.name, force = obj.force.name, rotated = true, mined = false, robot = false}
            game.write_file("mapdata.dat", game.table_to_json(olog).."\n", true, 0)
          else
            console_print(player.name .. " *" .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "] " .. obj.ghost_name)
          end
        end
      else
        console_print("on_player_rotated_entity: invalid obj")
      end
    else
      console_print("on_player_rotated_entity: invalid player")
    end
  end
end

--Banned -- kill player to return items
function on_player_banned(event)
  if event and event.player_index then
    local player = game.players[event.player_index]
    if player and player.valid and player.character then
      player.character.die("player")
    end
  end
end
