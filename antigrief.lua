--Carl Frank Otto III
--carlotto81@gmail.com
--GitHub: https://github.com/Distortions81/M45-SoftMod
--License: MPL 2.0
require "utility"

function surfnum(surface)
  local pos = 0
  for _, s in pairs(game.surfaces) do
    if s == surface then
      return pos
    end
    pos = pos + 1
  end
  return nil
end

function forcenum(force)
  local pos = 0
  for _, f in pairs(game.forces) do
    if f == force then
      return pos
    end
    pos = pos + 1
  end
  return nil
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
        if (global.last_speaker_warning and game.tick - global.last_speaker_warning >= 5) then
          if player.admin == false then --Don't bother with admins
            gsysmsg(player.name .. " placed a speaker at [gps=" .. math.floor(obj.position.x) .. "," .. math.floor(obj.position.y) .. "]")
            global.last_speaker_warning = game.tick
          end
        end
      end

      if obj.name ~= "tile-ghost" and obj.name ~= "tile" then
        if obj.name ~= "entity-ghost" then
          console_print("[ACT] ".. player.name .. " placed " .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "]")
        else
          if not global.last_ghost_log then
            global.last_ghost_log = {}
          end
          if global.last_ghost_log[player.index] then
            if game.tick - global.last_ghost_log[player.index] > (60 * 2) then
              console_print("[ACT] ".. player.name .. " placed-ghost " .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "] " .. obj.ghost_name)
            end
          end
          global.last_ghost_log[player.index] = game.tick
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
      if obj.force.name ~= "enemy" and obj.force.name ~= "neutral" then
        if obj.name ~= "tile-ghost" and obj.name ~= "tile" then
          if obj.name ~= "entity-ghost" then
            --log
            console_print("[ACT] ".. player.name .. " mined " .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "]")
          else
            console_print("[ACT] ".. player.name .. " mined-ghost " .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "] " .. obj.ghost_name)
          end
        end
      end
    else
      console_print("pre_player_mined_item: invalid obj")
    end
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
            console_print("[ACT] ".. player.name .. " rotated " .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "]")
          else
            console_print("[ACT] ".. player.name .. " rotated ghost " .. obj.name .. " [gps=" .. obj.position.x .. "," .. obj.position.y .. "] " .. obj.ghost_name)
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
