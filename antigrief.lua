--Carl Frank Otto III
--carlotto81@gmail.com
require "utility"

--Build stuff -- activity
function on_built_entity(event)
  if event and event.player_index and event.created_entity and event.stack then
    local player = game.players[event.player_index]
    local created_entity = event.created_entity
    local stack = event.stack

    local name = "bot"

    if player and player.valid then
      name = player.name

      if created_entity and created_entity.valid then
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
    end

    if created_entity.name ~= "tile-ghost" and created_entity.name ~= "tile" then
      if created_entity.name == "entity-ghost" then
        --Log item placement
        console_print(
          name ..
            " +ghost " ..
              created_entity.ghost_name ..
                " [gps=" .. math.floor(created_entity.position.x) .. "," .. math.floor(created_entity.position.y) .. "]," ..created_entity.direction
        )
      else
        --Log item placement
        console_print(
          name ..
            " +" ..
              created_entity.name ..
                " [gps=" .. math.floor(created_entity.position.x) .. "," .. math.floor(created_entity.position.y) .. "]," ..created_entity.direction
        )
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

    --Check player, surface and object are valid
    if player and player.valid and player.index and player.surface and player.surface.valid and obj and obj.valid then
      console_print(
        player.name ..
          " -" .. obj.name .. " [gps=" .. math.floor(obj.position.x) .. "," .. math.floor(obj.position.y) .. "]"
      )
    else
      console_print("pre_player_mined_item: invalid player, obj or surface.")
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
        name .. " *" .. obj.name .. " [gps=" .. math.floor(obj.position.x) .. "," .. math.floor(obj.position.y) .. "]"
      )
    end
  end
end

--Banned -- kill player to return items
function on_player_banned(event)
  if event and event.player_index then
    local player = game.players[event.player_index]
    if player and player.valid and player.character then
      --send_to_default_spawn(player)
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
      smart_print(
        item.victim,
        "[color=red](SYSTEM) You are a new player, and are not allowed to mine or replace other people's objects yet![/color]"
      )
      if item.victim and item.victim.valid and item.victim.character and item.victim.character.valid then
        item.victim.character.damage(15, "enemy") --Little discouragement
      end
    end
  end
end
