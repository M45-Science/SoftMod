--Carl Frank Otto III
--carlotto81@gmail.com
--Fear The Dark scenario
local sdvers = "v004-1-28-2021-0104p-dm2"
require "util"

--TODO
local function auto_add_light()
end

local function add_light()
end

local function remove_light()
end

local function auto_add_chunk()
end

local function add_chunk()
end

local function remove_chunk()
end

local function auto_add_object()
end

local function add_object()
end

local function remove_object()
end

--Flicker table
local flame_flicker = {0.90648, 0.8645, 0.80456, 0.85338, 0.90851, 0.9113, 0.96406, 0.90881, 0.96274, 0.93995, 0.83402, 0.88302, 0.94693, 0.98987, 0.8951, 0.8688, 0.83505, 0.9028, 0.95712, 0.94197, 0.82492, 0.94341, 0.99033, 0.88004, 0.96833, 0.9848, 0.98248, 0.85463, 0.97102, 0.85634, 0.96485, 0.90413, 0.88691, 0.80006, 0.99193, 0.95971, 0.95974, 0.92892, 0.9678, 0.891, 0.87938, 0.90854, 0.9166, 0.85609, 0.83346, 0.88063, 0.93676, 0.89179, 0.89177, 0.90834, 0.94741, 0.92123, 0.90505, 0.86668, 0.8959, 0.80808, 0.91154, 0.81389, 0.90361, 0.97848, 0.87746, 0.90936, 0.8129, 0.88373, 0.89041, 0.8502, 0.80365, 0.90434, 0.88674, 0.90248, 0.86622, 0.89062, 0.87728, 0.8967, 0.81572, 0.87971, 0.8626, 0.88267, 0.95814, 0.93425, 0.91485, 0.89655, 0.93271, 0.95657, 0.94861, 0.92524, 0.80756, 0.87241, 0.90004, 0.97894, 0.92157, 0.92438, 0.80138, 0.84152, 0.8799, 0.84183, 0.97022, 0.86229, 0.82513, 0.97933}
local frame_offset = {50, 17, 43, 35, 87, 54, 36, 47, 4, 73, 81, 84, 66, 81, 62, 35, 45, 91, 9, 5, 36, 66, 70, 86, 44, 75, 96, 46, 8, 41, 86, 77, 19, 58, 96, 5, 48, 34, 4, 27, 10, 83, 74, 72, 36, 4, 56, 13, 19, 48, 45, 17, 1, 47, 87, 69, 10, 63, 10, 38, 90, 77, 12, 83, 72, 79, 10, 14, 49, 22, 83, 1, 89, 17, 59, 91, 59, 60, 66, 25, 4, 81, 10, 73, 31, 46, 13, 49, 7, 52, 62, 66, 18, 36, 24, 7, 44, 58, 37, 30}

--GLOBALS
--Create globals, if needed
local function make_dark_globals()
  --Lamp radius
  if not global.d_lightd then
    global.d_lightd = 14
  end
  --Radar radius
  if not global.d_radard then
    global.d_radard = 48
  end

  --CHUNKS
  --Default value, chunks per frame
  if not global.d_cpf then
    global.d_cpf = 10
  end
  --Scan rate minimum
  if not global.d_chrt_sec then
    global.d_chrt_sec = 10
  end
  --Max scan chunks per frame
  --(attempt to keep scan rate, until this limit)
  if not global.d_cpf_max then
    global.d_cpf_max = 100
  end

  --LIGHTS
  --Default value, lights per frame
  if not global.lpf then
    global.lpf = 100
  end
  --Scan rate minimum 
  if not global.d_light_sec then
    global.d_light_sec = 5
  end
  --Max lights per frame
  --(attempt to keep scan rate, until this limit)
  if not global.lpf_max then
    global.lpf_max = 1000
  end

  --Limited fire life
  if not global.d_firelife then
    global.d_firelife = 5400
  end

  if not global.d_player_dmg then
    global.d_player_dmg = {}
  end

  if not global.fire_offset then
    global.fire_offset = 1
  end
end

--DARK-- CONVERT -- Position to chunk position
function d_pos2cpos(pos)
  if pos and pos.x and tonumber(pos.x) then
    return {x = math.floor(pos.x / 32), y = math.floor(pos.y / 32)}
  else
    return {x = 0, y = 0}
  end
end

--DARK-- CONVERT -- Chunk position to position
function d_cpos2pos(pos)
  if pos and pos.x and tonumber(pos.x) then
    return {x = math.floor(pos.x * 32), y = math.floor(pos.y * 32)}
  else
    return {x = 0, y = 0}
  end
end

--DARK-- CONVERT -- Chunk position to chunk area
function d_cpos2carea(cpos)
  if cpos and cpos.x then
    return {
      left_top = {x = cpos.x * 32, y = cpos.y * 32},
      right_bottom = {x = cpos.x + 32, y = cpos.y + 32}
    }
  else
    return {left_top = {0, 0}, right_bottom = {0, 0}}
  end
end

--DARK-- CONVERT -- position to chunk area
function d_pos2carea(pos)
  local cpos = d_pos2cpos(pos)
  return d_cpos2carea(cpos)
end

--DARK-- CONVERT -- Position to chunk area
function d_pos2area(pos, size)
  if pos and pos.x then
    return {
      left_top = {x = (pos.x * size) - 0.5, y = (pos.y * size) - 0.5},
      right_bottom = {x = pos.x + 0.5, y = pos.y + 0.5}
    }
  else
    return {left_top = {0, 0}, right_bottom = {0, 0}}
  end
end

--DARK-- CONVERT -- Area to position
function d_area2pos(area)
  if area and area.left_top then
    local x = area.left_top.x + 0.5
    local y = area.left_top.y + 0.5

    return {x = x, y = y}
  end
end

--DARK-- CONVERT -- Chunk key to x/y
function d_ckey_to_xy(chunk)
  if chunk then
    local args = mysplit(chunk, ",")
    if args and args[2] then
      return {x = tonumber(args[1]), y = tonumber(args[2])}
    end
  end

  return {x = 0, y = 0}
end

--DARK-- UTIL
--DARK-- UTIL -- Object keys
function d_objkey(obj)
  return obj.position.x .. "," .. obj.position.y .. "," .. obj.name
end

--DARK-- UTIL --Chunk keys
function d_ckey(chunk)
  return chunk.x .. "," .. chunk.y
end

--DARK-- KEYLIST --Make chunk keylist
local function d_ckeylst()
  global.chunk_keylist = {}
  global.cpos = 1

  local count = 0
  for _, chunk in pairs(global.d_cindex) do
    count = count + 1
    if chunk and chunk.x then
      table.insert(global.chunk_keylist, d_ckey({x = chunk.x, y = chunk.y}))
    end
  end
  global.chunk_max = count

  global.d_cpf = math.ceil(count / global.d_chrt_sec / 60.0) + 1

  --Cap to a maximum number per frame
  if global.d_cpf_max and global.d_cpf > global.d_cpf_max then
    global.d_cpf = global.d_cpf_max
  end
end

--DARK-- KEYLIST --Make light keylist
local function d_lkeylst()
  global.d_lkeylist = {}
  global.lpos = 1

  local count = 1
  for _, light in pairs(global.d_lmap) do
    if light.obj and light.valid then
      count = count + 1
      table.insert(global.d_lkeylist, d_objkey(light.obj))
    else
      console_print("d_lkeylst: non-existent light.")
    end
  end
  global.light_max = count
  global.lpf = math.ceil(count / global.d_light_sec / 60.0) + 1

  if global.lpf_max and global.lpf > global.lpf_max then
    global.lpf = global.lpf_max
  end
end

--DARK-- CHART --Gen/Regen chunk_index
local function d_gen_cindex(target_chunk)
  console_print("Rebuilding dmap database.")
  make_dark_globals()

  --get rid of this --TODO
  local chunk_list = {}
  if not target_chunk then
    local clist = game.surfaces[1].get_chunks()
    for chunk in clist do
      table.insert(chunk_list, {x = chunk.x, y = chunk.y, area = chunk.area})
    end
  else
    chunk_list = {target_chunk}
  end

  if not target_chunk then
    global.d_cindex = {}
    global.d_lmap = {}
    global.object_map = {}
    global.chunk_pos = 0
  end

  --Count chunks
  local count = 0
  local ucount = 0
  local ocount = 0
  local lcount = 0
  local llcount = 0

  for _, chunk in pairs(chunk_list) do
    --Is it a real chunk?
    if game.surfaces[1].is_chunk_generated({chunk.x, chunk.y}) then
      --Is chunk occupied?
      local item_count = game.surfaces[1].count_entities_filtered {area = chunk.area, force = "player"}
      if item_count > 0 then
        ocount = ocount + item_count

        --Find lamps
        local light_found =
          game.surfaces[1].find_entities_filtered {
          area = chunk.area,
          force = "player",
          type = {"lamp", "radar"}
        }

        --Find objects
        local object_found = game.surfaces[1].find_entities_filtered {area = chunk.area, force = "player"}

        --Cache objects first, then insert lights into objects
        local objects_map = {}
        for _, item in pairs(object_found) do
          --Don't cache characters or fires (use online_players and fire_list)
          --TODO bp/ghost exclude
          if item.type ~= "character" and item.type ~= "simple-entity-with-force" then
            global.object_map[d_objkey(item)] = {
              obj = item,
              lit_lights = {},
              unlit_lights = {}
            }
          end
        end

        --Cache lights
        local lights_map = {}
        local is_lit = false
        local is_vision = false
        for _, light in pairs(light_found) do
          --Count total lights
          lcount = lcount + 1

          --Get light status
          local power = false
          if light.status ~= defines.entity_status.no_power then
            power = true
            is_lit = true
            llcount = llcount + 1
          end

          --Radar
          if light.type == "radar" then
            if light.status ~= defines.entity_status.no_power then
              is_vision = true
            end
          end

          --Store subjects of light
          local subjects_found =
            game.surfaces[1].find_entities_filtered {
            position = light.position,
            radius = global.d_lightd,
            force = "player"
          }
          local subjects = {}
          for _, subj in pairs(subjects_found) do
            --Don't cache characters or fires (use online_players and fire_list)
            --TODO bp/ghost exclude
            --Skip self
            if subj.type ~= "character" and subj.type ~= "simple-entity-with-force" and not d_sameobj(subj, light) then
              local obj_key = d_objkey(subj)
              local light_key = d_objkey(light)

              subjects[obj_key] = subj
            end
          end

          local lkey = d_objkey(light)
          local light_data = {
            obj = light,
            has_power = power,
            subjects = subjects,
            type = light.type
          }

          lights_map[lkey] = light_data
          global.d_lmap[lkey] = light_data
        end

        --Count used and total chunks
        count = count + 1
        if item_count > 0 then
          ucount = ucount + 1
        end

        --Store chunk data in chunk map by key
        global.d_cindex[d_ckey(chunk)] = {
          area = chunk.area,
          x = chunk.x,
          y = chunk.y,
          item_count = item_count,
          light_map = lights_map,
          is_lit = is_lit,
          is_vision = is_vision
        }
      else
        --Empty, clear it if stored.
        if global.d_cindex[d_ckey(chunk)] then
          --Report this, should not happen
          console_print("Dead chunk data found, deleting: " .. d_ckey(chunk))
          global.d_cindex[d_ckey(chunk)] = {}
        end
      end
    end
  end
  --Store lights into objects
  if light and light.light_map then
    for light_key, light in pairs(global.d_lmap) do
      if light and light.subjects then
        for obj_key, obj in pairs(light.subjects) do
          if global.object_map[obj_key] then
            if light.status ~= defines.entity_status.no_power then
              global.object_map[obj_key].lit_lights[light_key] = light.position
            else
              global.object_map[obj_key].unlit_lights[light_key] = light.position
            end
          else
            console_print("Light: " .. light_key .. " contained non-cached object: " .. obj_key)
          end
        end
      end
    end
  end

  d_ckeylst()
  d_lkeylst()

  console_print("chunks: " .. count .. ", used chunks: " .. ucount .. ", objects: " .. ocount .. ", lights: " .. lcount .. ", lit lights: " .. llcount)
  console_print(dump(global.object_map))
end

--DARK-- CHART --Update chart from cache--
--This eventually needs to be converted to event-based when that is done--
local function d_chunklit(ckey)
  if ckey then
    if global.d_cindex then
      local chunk = global.d_cindex[ckey]

      --Don't have it yet, add it
      if not chunk then
        local tcpos = d_ckey_to_xy(ckey)
        local tcarea = d_cpos2carea(tcpos)
        global.d_cindex[ckey] = {
          x = tcpos.x,
          y = tcpos.y,
          area = tcarea
        }
        --Scan
        d_gen_cindex(global.d_cindex[ckey])
      end
      if chunk and chunk.x then
        if chunk.light_map then
          for _, light in pairs(chunk.light_map) do
            if light and light.obj and light.obj.valid then
              local lkey = d_objkey(light.obj)
              if global.d_lmap[lkey].has_power then
                if chunk.is_lit == false then
                  console_print("chunk gained light: " .. ckey)
                  game.forces["player"].chart(game.surfaces[1], d_cpos2carea({x = chunk.x, y = chunk.y}))
                  chunk.is_lit = true
                end
                chunk.is_lit = true
                return --Nothing left to do
              end
            end
          end
        end

        --If chunk had light, but now does not
        if chunk.is_lit == true then
          console_print("chunk lost light: " .. ckey)
          chunk.is_lit = false
          game.forces["player"].unchart_chunk({x = chunk.x, y = chunk.y}, game.surfaces[1])
        end
      else
        console_print("invalid chunk data: " .. ckey)
      end
    end
  end
end

--Create caches if needed
local function d_do_cindex()
  if not global.d_lst_rebuild then
    global.d_lst_rebuild = game.tick
    global.d_cindex = nil
  end

  --TODO REPORT DISCREPANCIES
  --Rebuild cache every 30 minutes
  if game.tick - global.d_lst_rebuild > (30 * 60 * 60) then
    global.d_lst_rebuild = game.tick
    global.d_cindex = nil
  end

  --If we don't have a chunk list, generate a new one
  if not global.d_cindex then
    d_gen_cindex()
  else
    local x
    for x = 1, global.d_cpf, 1 do
      if global.cpos <= (global.chunk_max - 1) then
        global.cpos = global.cpos + 1
      else
        global.cpos = 1
        --Fix radar/player vision oddness
        game.forces["player"].cancel_charting(game.surfaces[1])
      end

      d_chunklit(global.chunk_keylist[global.cpos])
    end
  end
end

--Update light status, cache
local function d_light_update()
  if global.d_lmap then
    if global.d_lmap and global.d_lkeylist then
      for x = 1, global.lpf, 1 do
        local lkey = global.d_lkeylist[global.lpos]
        local light = global.d_lmap[lkey]

        if light and light.obj and light.obj.valid then
          if light.obj.status ~= defines.entity_status.no_power then
            if not light.has_power then
              light.has_power = true
              local cpos = d_pos2cpos(light.obj.position)
              local ckey = d_ckey(cpos)
              d_chunklit(ckey)
              console_print("light gained power: " .. dump(light.obj.position))
            end
          else
            if light.has_power then
              light.has_power = false
              local cpos = d_pos2cpos(light.obj.position)
              local ckey = d_ckey(cpos)
              d_chunklit(ckey)
              console_print("light lost power:" .. dump(light.obj.position))
            end
          end
        else
          --console_print("d_light_update: non-existent or deleted light: " .. global.lpos)
        end

        if global.lpos <= (global.light_max - 1) then
          global.lpos = global.lpos + 1
        else
          global.lpos = 1
        end
      end
    end
  end
end

--Old campfires burn out
local function d_delfire()
  local index

  if global.d_campfires then
    for x, fire in pairs(global.d_campfires) do
      if game.tick - fire.tick > global.d_firelife then
        rendering.destroy(fire.img)
        rendering.destroy(fire.light)

        if fire.obj and fire.obj.valid then
          game.surfaces[1].play_sound({path = "utility/item_deleted", position = fire.obj.position})

          local cpos = d_pos2cpos(fire.obj.position)
          local ckey = d_ckey(cpos)
          d_chunklit(ckey)

          fire.obj.destroy()
          index = x
          break
        else
          console_print("remove_campfire: Fire object was invalid?")
        end
      end
    end

    --Remove item from list
    if index then
      table.remove(global.d_campfires, index)
    end
  end
end

local function dark_startmap()
  --Generate chunk cache if needed
  d_do_cindex()

  --Starting map settings
  if not global.dark_settings_set then
    global.dark_settings_set = true

    game.surfaces[1].freeze_daytime = true
    game.surfaces[1].brightness_visual_weights = {1 / 0.85, 1 / 0.85, 1 / 0.85}
    game.surfaces[1].daytime = 0.5
  end

  --Get spawn position
  local cpos = {x = 0, y = 0}
  if global.cspawnpos and global.cspawnpos.x then
    cpos = global.cspawnpos
  end

  --Add lamp
  if global.m45logo_lamp then
    rendering.destroy(global.m45logo_lamp)
  end
  global.m45logo_lamp =
    rendering.draw_sprite {
    sprite = "entity/small-lamp",
    render_layer = "floor",
    target = {x = cpos.x, y = cpos.y + 3.5},
    x_scale = 2,
    y_scale = 2,
    surface = game.surfaces[1]
  }
end

local function d_player_globals(player)
  if not global.d_player_dmg then
    global.d_player_dmg = {}
  end

  global.d_player_dmg[player.index] = 0
end

----------
--EVENTS--
----------

--New player
local function on_player_created(event)
  if event and event.player_index then
    make_dark_globals()
    dark_startmap()

    local player = game.players[event.player_index]
    if player and player.valid then
      d_player_globals(player)
      player.insert {name = "small-lamp", count = 25}
      player.insert {name = "small-electric-pole", count = 25}
      player.insert {name = "wood", count = 25}
      player.character.disable_flashlight()
    end
  end
end

--Respawn
local function on_player_respawned(event)
  if event and event.player_index then
    local player = game.players[event.player_index]
    if player and player.valid then
      player.insert {name = "wood", count = 25}
      player.disable_flashlight()
    end
  end
end

--New item built
local function on_built_entity(event)
  if event and event.created_entity then
    local obj = event.created_entity
    --Detect lights/radars being placed, mark in sector cache as used
    if obj and obj.valid and obj.force and obj.force.name and obj.force.name == "player" then
      if global.object_map then
        --Insert item into object cache
        global.object_map[d_objkey(obj)] = {
          obj = obj,
          lit_lights = {},
          unlit_lights = {}
        }
      else
        console_print("Attempted to add item to empty object_map.")
      end
      if obj.type == "lamp" then
        local light_data = {
          obj = obj,
          has_power = false,
          subjects = nil,
          type = obj.type
        }
        local lkey = d_objkey(obj)
        global.d_lmap[lkey] = light_data
        table.insert(global.d_lkeylist, lkey)
      end
    end
  end
end

--Item mined
local function on_pre_player_mined_item(event)
end

--Handle dropped items, wood etc
local function on_player_dropped_item(event)
  if event and event.entity and event.player_index then
    --Delete expired camp fires
    --We do this here, so fires can be deleted at least as fast as they are made
    --This saves some processing
    d_delfire()

    local player = game.players[event.player_index]

    if not global.fire_limiter then
      global.fire_limiter = {}
    end

    if not global.d_campfires then
      global.d_campfires = {}
    end

    if global.d_cindex and player and player.character then
      if event.entity.name == "item-on-ground" and event.entity.stack and event.entity.stack.name == "wood" then
        --Rate-limit
        if global.fire_limiter and global.fire_limiter[player.index] then
          if game.tick - global.fire_limiter[player.index] < (60 * 3) then
            --mart_print(player, "Your flint sparks, but nothing happens.")
            player.insert {name = "wood", count = 1}
            event.entity.destroy()
            return
          end
        end

        --Mark chunk as used
        if event.entity and event.entity.force and event.entity.force.name and event.entity.force.name == "neutral" then
          local pos = event.entity.position
          local cpos = d_pos2cpos(pos)
          local cposf = {x = cpos.x, y = cpos.y}
          local carea = d_cpos2carea(cposf)
          local ckey = d_ckey(cposf)

          --Properly init chunk data here, empty isn't cool.

          --Init if needed
          if not global.d_cindex[ckey] then
            console_print("Scanning nil chunk and adding.")
            global.d_cindex[ckey] = {
              x = cpos.x,
              y = cpos.y,
              area = carea,
              item_count = 0,
              light_map = {},
              is_lit = true,
              is_vision = false
            }
          end

          if global.d_cindex[ckey] and global.d_cindex[ckey].item_count then
            global.d_cindex[ckey].item_count = global.d_cindex[ckey].item_count + 1
          else
            console_print("Added fire to a chunk with no item count: " .. ckey)
            global.d_cindex[ckey].item_count = 1
          end
          global.d_cindex[ckey].is_lit = true
        end

        local cpos = {event.entity.position.x, event.entity.position.y}
        event.entity.destroy()

        player.play_sound({path = "utility/item_deleted"})

        --Mark time
        global.fire_limiter[player.index] = game.tick

        local newpos = game.surfaces[1].find_non_colliding_position("steel-chest", cpos, 99, 0.1, false)
        local logobj =
          game.surfaces[1].create_entity {
          name = "simple-entity-with-force",
          position = newpos,
          force = "player",
          render_player_index = 65535, --hack to make item invisible
          player = player
        }
        logobj.minable = false
        logobj.rotatable = false
        logobj.destructible = false

        local fireimg =
          rendering.draw_sprite {
          sprite = "file/img/ftd/fire.png",
          target = logobj,
          render_layer = 122,
          surface = game.surfaces[1],
          color = {1.0, 1.0, 1.0},
          scale = 1,
          target_offset = {-0.25, -0.5}
        }
        local firelight =
          rendering.draw_light {
          sprite = "utility/light_medium",
          target = logobj,
          render_layer = 148,
          surface = game.surfaces[1],
          color = {1, 0.75, 0.15},
          scale = 5,
          target_offset = {-0.25, -0.5}
        }

        if global.d_campfires then
          table.insert(global.d_campfires, {obj = logobj, light = firelight, img = fireimg, tick = game.tick})
        else
          console_print("failed to insert campfire into list.")
        end
      end
    end
  end
end

--Block map charting in dark areas, using cache
local function on_chunk_charted(event)
  local found = false

  if global.d_cindex and event.surface_index == 1 then
    local pos = event.position
    local ckey = d_ckey(pos)
    local chunk = global.d_cindex[ckey]

    local spawn_pos = {x = 0, y = 0}
    if global.cspawnpos then
      spawn_pos = global.cspawnpos
    end

    if chunk and (chunk.is_lit or chunk.is_vision) then
      found = true
    elseif dist_to(d_pos2cpos(spawn_pos), pos) <= 2 then --reveal spawn
      found = true
    end
  end

  --Nothing found, unchart
  if not found then
    event.force.unchart_chunk(event.position, event.surface_index)
  end
end

local function on_post_entity_died()
end

local function on_robot_mined()
end

local function on_sector_scanned()
end

--Check new chunks, add them to our list?
local function on_chunk_generated(event)
end

--Darkness Damage, every 5 seconds
--Should process x per frame instead, to prevent hitching
script.on_nth_tick(
  300,
  function(event)
    --Delete expired camp fires
    d_delfire()
    dark_startmap()

    for _, player in pairs(game.connected_players) do
      if player and player.character then
        local found = false

        --Get spawn position
        local spawn_pos = {x = 0, y = 0}
        if global.cspawnpos then
          spawn_pos = global.cspawnpos
        end

        --If player is near spawn they are safe
        local distance = dist_to(spawn_pos, player.position)
        if distance < 25 then
          found = true
        end

        --Look for lamps
        if not found then
          local light_found =
            player.surface.find_entities_filtered {
            position = player.position,
            radius = global.d_lightd,
            force = "player",
            type = "lamp"
          }
          for _, light in pairs(light_found) do
            if light.status ~= defines.entity_status.no_power then
              found = true
              break --Found one, stop
            end
          end
        end

        --Find radars
        if not found then
          local radar_found =
            player.surface.find_entities_filtered {
            position = player.position,
            radius = global.d_radard,
            force = "player",
            type = "radar"
          }
          for _, radar in pairs(radar_found) do
            if radar.status ~= defines.entity_status.no_power then
              found = true
              break --Found one, stop
            end
          end
        end

        --Find fires
        if not found then
          local fire_found =
            player.surface.find_entities_filtered {
            position = player.position,
            radius = global.d_lightd,
            force = "player",
            type = "simple-entity-with-force"
          }
          for _, fire in pairs(fire_found) do
            if not fire.minable then
              found = true
              break --Found one, stop
            end
          end
        end

        if not global.d_player_dmg then
          global.d_player_dmg = {}
        end

        --Player is safe, reset damage
        if found then
          global.d_player_dmg[player.index] = 0
        else
          --No near by light found

          --Keeps immortals from overflowing the value
          if global.d_player_dmg[player.index] and global.d_player_dmg[player.index] < 500 then
            global.d_player_dmg[player.index] = (global.d_player_dmg[player.index] + global.d_player_dmg[player.index] + 1)
          else
            global.d_player_dmg[player.index] = 0 --Init
          end

          if global.d_player_dmg[player.index] and global.d_player_dmg[player.index] > 0 then
            player.character.damage(global.d_player_dmg[player.index], game.forces["enemy"])

            smart_print(player, "[color=red]The darkness gnaws at you...[/color]")
          end
        end
      end
    end
  end
)

local function random_flicker()
  --Init if needed
  if not global.fire_flicker_pos then
    global.fire_flicker_pos = 1
  end

  --Increment
  if global.fire_flicker_pos < 100 then
    global.fire_flicker_pos = global.fire_flicker_pos + 1
  else
    global.fire_flicker_pos = 1
  end

  --Set
  if global.fire_offset < 99 then
    global.fire_offset = global.fire_offset + 1
  else
    global.fire_offset = 1
  end

  local random_offset = frame_offset[global.fire_offset]
  local fpos = global.fire_flicker_pos + random_offset

  if fpos > 100 then
    fpos = fpos - 100
  end

  local val = flame_flicker[fpos]
  return val
end

local function d_flicker_fires()
  if global.d_campfires then
    for _, fire in pairs(global.d_campfires) do
      local val = random_flicker()
      local color = {val, val, 0.15}

      --Set color
      rendering.set_color(fire.light, color)
      --rendering.set_color(fire.img, color)
    end
  end
end

--Flame flicker
script.on_nth_tick(
  5,
  function(event)
    --Flick fires
    d_flicker_fires()
  end
)

--Spawn flicker
script.on_nth_tick(
  15,
  function(event)
    if global.m45logo_light then
      local val = random_flicker()
      local lval = val / 3 + 0.66
      local color = {lval / 4, lval, lval / 4}

      --Set color
      rendering.set_color(global.m45logo_light, color)
    end
  end
)

--Every-frame background processing
script.on_event(
  defines.events.on_tick,
  function(event)
    --Check all lights
    d_light_update()

    --Temporary until event-based
    d_do_cindex()
  end
)

function dark_event_handler(event)
  if event.name == defines.events.on_player_created then
    on_player_created(event)
  elseif event.name == defines.events.on_player_respawned then
    on_player_respawned(event)
  elseif event.name == defines.events.on_chunk_charted then
    on_chunk_charted(event)
  elseif event.name == defines.events.on_player_dropped_item then
    on_player_dropped_item(event)
  elseif event.name == defines.events.on_built_entity then
    on_built_entity(event)
  elseif event.name == defines.events.on_post_entity_died then
    on_post_entity_died(event)
  elseif event.name == defines.events.on_pre_player_mined_item then
    on_pre_player_mined_item(event)
  elseif event.name == defines.events.on_chunk_generated then
    on_chunk_generated(event)
  end
end
