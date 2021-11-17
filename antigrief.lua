--Carl Frank Otto III
--carlotto81@gmail.com
require "utility"

function findobj(name, position, ghost)
  for pos, obj in pairs(global.objmap) do
    if obj.name == name and obj.position == position and obj.ghost == ghost then
      return obj
    end
  end

  console_print("Could not find object " .. name .. " at " .. position.x .. "," .. position.y)
  return nil
end

function on_robot_built_entity(event)
  if event and event.created_entity then
    local entity = event.created_entity
    local name = "bot"

    if entity.name ~= "tile-ghost" and entity.name ~= "tile" then
      if entity.name == "entity-ghost" then
        --Log item placement
        console_print(
          name .. 
            " +ghost " ..
            entity.ghost_name ..
                " [gps=" ..
                entity.position.x .. "," .. entity.position.y .. "]," .. entity.direction
        )
        table.insert(global.objmap, {name=name, obj=entity.ghost_name, pos=entity.position, dir=entity.direction, tick=game.tick, ghost=true})
      else
        --Log item placement
        console_print(
          name ..
            " +" ..
            entity.name ..
                " [gps=" ..
                entity.position.x .. "," .. entity.position.y .. "]," .. entity.direction
        )
        table.insert(global.objmap, {name=name, obj=entity.name, pos=entity.position, dir=entity.direction, tick=game.tick, ghost=false})
      end
    end
  else
    console_print("on_robot_built_entity: invalid obj")
  end
end

--Build stuff -- activity
function on_built_entity(event)
  if event and event.created_entity then
    local player = game.players[event.player_index]
    local created_entity = event.created_entity

    local name = "bot"

    if created_entity and created_entity.valid then
      if player and player.valid then
        name = player.name

        if not global.last_speaker_warning then
          global.last_speaker_warning = 0
        end

        if
          created_entity.name == "programmable-speaker" or
            (created_entity.name == "entity-ghost" and created_entity.ghost_name == "programmable-speaker")
         then
          if (global.last_speaker_warning and game.tick - global.last_speaker_warning >= 30) then
            if player.admin == false then --Don't bother with admins
              gsysmsg(
                player.name ..
                  " placed a speaker at [gps=" ..
                    math.floor(created_entity.position.x) .. "," .. math.floor(created_entity.position.y) .. "]"
              )
              global.last_speaker_warning = game.tick
            end
          end
        end
      end

      if created_entity.name ~= "tile-ghost" and created_entity.name ~= "tile" then
        if created_entity.name == "entity-ghost" then
          --Log item placement
          console_print(
            name ..
              " +ghost " ..
                created_entity.ghost_name ..
                  " [gps=" ..
                    created_entity.position.x .. "," .. created_entity.position.y .. "]," .. created_entity.direction
          )
          table.insert(global.objmap, {name=name, obj=entity.ghost_name, pos=entity.position, dir=entity.direction, tick=game.tick, ghost=true})
        else
          --Log item placement
          console_print(
            name ..
              " +" ..
                created_entity.name ..
                  " [gps=" ..
                    created_entity.position.x .. "," .. created_entity.position.y .. "]," .. created_entity.direction
          )
          table.insert(global.objmap, {name=name, obj=entity.ghost_name, pos=entity.position, dir=entity.direction, tick=game.tick, ghost=false})
        end
      end
    end
  else
    console_print("on_built_entity: invalid obj")
  end
end

--Pre-Mined item
function on_pre_player_mined_item(event)
  --Sanity check
  if event and event.entity then
    local player = game.players[event.player_index]
    local obj = event.entity

    local name = "bot"
    if player and player.valid then
      name = player.name
    end

    --Check player, surface and object are valid
    if obj and obj.valid then
      if obj.name ~= "tile-ghost" and obj.name ~= "tile" then
        if obj.name == "entity-ghost" then
          --Log item removal
          console_print(
            name ..
              " -ghost " ..
              obj.ghost_name ..
                  " [gps=" ..
                  obj.position.x .. "," .. obj.position.y .. "]," .. obj.direction
          )
          local opos = findobj(obj.ghost_name, obj.position, obj.direction, true)
          if opos then
            table.remove(global.objmap, opos)
            console_print("Removed " .. opos .. " from objmap")
          end
        else
          --Log item removal
          console_print(
            name ..
              " -" ..
              obj.name ..
                  " [gps=" ..
                  obj.position.x .. "," .. obj.position.y .. "]," .. obj.direction
          )
          table.insert(global.objmap, {name=name, obj=entity.ghost_name, pos=entity.position, dir=entity.direction, tick=game.tick, ghost=false})
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
      console_print(
        "bot -" .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "]," .. obj.direction
      )
      table.insert(global.objmap, {name=name, obj=entity.ghost_name, pos=entity.position, dir=entity.direction, tick=game.tick, ghost=false})
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

    local name = "bot"

    if player and player.valid then
      name = player.name
    end

    --If player and object are valid
    if obj and obj.valid then
      --Don't let new players rotate other players items, unrotate and untouch the item.
      console_print(
        name .. " *" .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "]," .. obj.direction
      )
      table.insert(global.objmap, {name=name, obj=entity.ghost_name, pos=entity.position, dir=entity.direction, tick=game.tick, ghost=true})
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
