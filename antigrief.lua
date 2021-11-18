--Carl Frank Otto III
--carlotto81@gmail.com
require "utility"

function findobj(name, position)
  for pos, obj in pairs(global.objmap) do
    if obj.oname == name and obj.pos.x == position.x and obj.pos.y == position.y then
      return pos
    end
  end

  console_print("Could not find object " .. name .. " at " .. position.x .. "," .. position.y)
  return nil
end

function on_robot_built_entity(event)
  local obj = event.created_entity
  local name = "bot"

  if obj and obj.valid then
    if obj.name ~= "tile-ghost" and obj.name ~= "tile" then
      if obj.name == "entity-ghost" then
        --Log item placement
        --console_print(name .. " +ghost " .. obj.ghost_name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "]," .. obj.direction)
      else
        --Log item placement
        console_print(name .. " +" .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "]," .. obj.direction)
        table.insert(global.objmap, {name = name, oname = obj.name, pos = obj.position, dir = obj.direction, tick = game.tick, bot = true})
      end
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
        if obj.name == "entity-ghost" then
          --Log item placement
          console_print(player.name .. " +ghost " .. obj.ghost_name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "]," .. obj.direction)
        else
          --Log item placement
          console_print(player.name .. " +" .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "]," .. obj.direction)
          table.insert(
            global.objmap,
            {
              name = player.name,
              oname = obj.name,
              pos = obj.position,
              dir = obj.direction,
              tick = game.tick,
              bot = false
            }
          )
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
        if obj.name == "entity-ghost" then
          --Log item removal
          console_print(player.name .. " -ghost " .. obj.ghost_name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "]," .. obj.direction)
        else
          --Log item removal
          console_print(player.name .. " -" .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "]," .. obj.direction)
          local opos = findobj(obj.name, obj.position)
          if opos then
            table.remove(global.objmap, opos)
          --console_print("Removed " .. opos .. " from objmap")
          end
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

    --Check player, surface and object are valid
    if obj and obj.valid then
      if obj.name ~= "tile-ghost" and obj.name ~= "tile" then
        if obj.name == "entity-ghost" then
          --console_print("bot -" .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "]," .. obj.direction)
        else
          local opos = findobj(obj.name, obj.position)
          if opos then
            table.remove(global.objmap, opos)
          --console_print("Removed " .. opos .. " from objmap")
          end
        end
      end
    else
      console_print("on_robot_pre_mined: invalid obj")
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

    local name = "unknown"

    if player and player.valid then
      name = player.name
    end

    --TODO: UPDATE ROTATE IN MEMORY

    --If player and object are valid
    if obj and obj.valid then
      --Don't let new players rotate other players items, unrotate and untouch the item.
      console_print(name .. " *" .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "]," .. obj.direction)
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
