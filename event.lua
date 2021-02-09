--Carl Frank Otto III
--carlotto81@gmail.com
require "antigrief"
require "info"
require "log"
require "todo"

local function insert_weapons(player, ammo_amount)
  if player.force.technologies["military-2"].researched then
    player.insert {name = "piercing-rounds-magazine", count = ammo_amount}
  else
    player.insert {name = "firearm-magazine", count = ammo_amount}
  end

  if player.force.technologies["military"].researched then
    player.insert {name = "submachine-gun", count = 1}
  else
    player.insert {name = "pistol", count = 1}
  end
end

--Looping timer, 30 seconds
--delete old corpse map pins
--Check spawn area map pin
--Add to player active time if needed
--Refresh players online window

script.on_nth_tick(
  1800,
  function(event)
    update_player_list() --online.lua

    --Remove old corpse tags
    if (global.corpselist) then
      local toremove = nil
      local index = nil
      for i, corpse in pairs(global.corpselist) do
        if (corpse.tick and (corpse.tick + (15 * 60 * 60)) < game.tick) then
          if (corpse.tag and corpse.tag.valid) then
            corpse.tag.destroy()
          end
          toremove = corpse
          index = i
          break
        end
      end
      --Properly remove items
      if global.corpselist and index then
        table.remove(global.corpselist, index)
      end
    else
      create_myglobals()
    end

    --Server tag
    if (global.servertag and not global.servertag.valid) then
      global.servertag = nil
    end
    if (global.servertag and global.servertag.valid) then
      global.servertag.destroy()
      global.servertag = nil
    end
    if (not global.servertag) then
      local label = "Spawn Area"
      local xpos = 0
      local ypos = 0

      if global.servname and global.servname ~= "" then
        label = global.servname
      end

      if global.cspawnpos and global.cspawnpos.x then
        xpos = global.cspawnpos.x
        ypos = global.cspawnpos.y
      end

      local chartTag = {
        position = {xpos, ypos},
        icon = {type = "item", name = "heavy-armor"},
        text = label
      }
      local pforce = game.forces["player"]
      local psurface = game.surfaces[1]

      if pforce and psurface then
        global.servertag = pforce.add_chart_tag(psurface, chartTag)
      end
    end

    --Add time to connected players
    if global.active_playtime then
      for _, player in pairs(game.connected_players) do
        if global.playeractive[player.index] then
          if global.playeractive[player.index] == true then
            global.playeractive[player.index] = false --Turn back off

            if global.active_playtime[player.index] then
              global.active_playtime[player.index] = global.active_playtime[player.index] + 1800 --Same as loop time
            else
              --INIT
              global.active_playtime[player.index] = 0
            end
          end
        else
          --INIT
          global.playeractive[player.index] = false
        end
      end
    end

    get_permgroup() --See if player qualifies now
  end
)

--Main event handler
script.on_event(
  {
    --Player join/leave respawn
    defines.events.on_player_created,
    defines.events.on_pre_player_died,
    defines.events.on_player_respawned,
    --
    defines.events.on_player_joined_game,
    defines.events.on_player_left_game,
    --activity
    defines.events.on_player_changed_position,
    defines.events.on_console_chat,
    defines.events.on_player_repaired_entity,
    --gui
    defines.events.on_gui_click,
    defines.events.on_gui_text_changed,
    --log
    defines.events.on_console_command,
    defines.events.on_chart_tag_removed,
    defines.events.on_chart_tag_modified,
    defines.events.on_chart_tag_added,
    defines.events.on_research_finished,
    -- anti-grief
    defines.events.on_player_deconstructed_area,
    defines.events.on_player_banned,
    defines.events.on_player_rotated_entity,
    defines.events.on_pre_player_mined_item,
    defines.events.on_player_cursor_stack_changed,
    --darkness
    defines.events.on_chunk_charted,
    defines.events.on_player_dropped_item,
    defines.events.on_built_entity,
    defines.events.on_post_entity_died,
    defines.events.on_robot_mined,
    defines.events.on_sector_scanned
  },
  function(event)
    --If no event, or event is a tick
    if not event or (event and event.name == defines.events.on_tick) then
      return
    end

    --Mark player active
    if event.player_index then
      local player = game.players[event.player_index]
      if player and player.valid then
        --Only mark active on movement if walking
        if event.name == defines.events.on_player_changed_position then
          if player.walking_state then
            if player.walking_state.walking == true and (player.walking_state.direction == defines.direction.north or player.walking_state.direction == defines.direction.northeast or player.walking_state.direction == defines.direction.east or player.walking_state.direction == defines.direction.southeast or player.walking_state.direction == defines.direction.south or player.walking_state.direction == defines.direction.southwest or player.walking_state.direction == defines.direction.west or player.walking_state.direction == defines.direction.northwest) then
              set_player_active(player)
            end
          end
        else
          set_player_active(player)
        end
      end
    end

    --Player join/leave respawn
    if event.name == defines.events.on_player_created then
      on_player_created(event)
    elseif event.name == defines.events.on_pre_player_died then
      on_pre_player_died(event)
    elseif event.name == defines.events.on_player_respawned then
      --
      on_player_respawned(event)
    elseif event.name == defines.events.on_player_joined_game then
      on_player_joined_game(event)
    elseif event.name == defines.events.on_player_left_game then
      --activity
      --changed-position
      --console_chat
      --repaired_entity
      --
      --gui
      on_player_left_game(event)
    elseif event.name == defines.events.on_gui_click then
      on_gui_click(event)
      online_on_gui_click(event) --online.lua
    elseif event.name == defines.events.on_gui_text_changed then
      --log
      on_gui_text_changed(event)
    elseif event.name == defines.events.on_console_command then
      on_console_command(event)
    elseif event.name == defines.events.on_chart_tag_removed then
      on_chart_tag_removed(event)
    elseif event.name == defines.events.on_chart_tag_modified then
      on_chart_tag_modified(event)
    elseif event.name == defines.events.on_chart_tag_added then
      on_chart_tag_added(event)
    elseif event.name == defines.events.on_research_finished then
      --anti-grief
      on_research_finished(event)
    elseif event.name == defines.events.on_player_deconstructed_area then
      on_player_deconstructed_area(event)
    elseif event.name == defines.events.on_player_banned then
      on_player_banned(event)
    elseif event.name == defines.events.on_player_rotated_entity then
      on_player_rotated_entity(event)
    elseif event.name == defines.events.on_pre_player_mined_item then
      on_pre_player_mined_item(event)
    elseif event.name == defines.events.on_player_cursor_stack_changed then
      on_player_cursor_stack_changed(event)
    elseif event.name == defines.events.on_built_entity then
      on_built_entity(event)
    end

    --darkness--
    --chunk_charted
    --player_dropped_item
    --built_entity
    --entity_died

    --To-Do--
    --player_joined_game
    --on_gui_click
    todo_event_handler(event)

    --External module event send
    --dark_event_handler(event)
  end
)

--Handle killing ,and teleporting users to other surfaces
function on_player_respawned(event)
  send_to_surface(event) --banish.lua

  if event and event.player_index then
    local player = game.players[event.player_index]

    --Cutoff-point, just becomes annoying.
    if not player.force.technologies["military-science-pack"].researched then
      insert_weapons(player, 10)
    end
  end
end

--Player connected, make variables, draw UI, set permissions, and game settings
function on_player_joined_game(event)
  update_player_list() --online.lua

  --Gui stuff
  if event and event.player_index then
    local player = game.players[event.player_index]
    if player then
      create_myglobals()
      create_player_globals(player)
      create_groups()
      game_settings(player)
      set_perms()
      get_permgroup()

      --Delete old UIs (migrate old saves)
      if player.gui.top.dicon then
        player.gui.top.dicon.destroy()
      end
      if player.gui.top.discordurl then
        player.gui.top.discordurl.destroy()
      end
      if player.gui.top.zout then
        player.gui.top.zout.destroy()
      end
      if player.gui.top.serverlist then
        player.gui.top.serverlist.destroy()
      end
      if player.gui.center.dark_splash then
        player.gui.center.dark_splash.destroy()
      end
      if player.gui.center.splash_screen then
        player.gui.center.splash_screen.destroy()
      end

      dodrawlogo() --logo.lua

      if player.gui and player.gui.top then
        make_info_button(player) --info.lua
        make_online_button(player) --online.lua
      end

      --Always show to new players, everyone else at least once per map
      if is_new(player) or not global.info_shown[player.index] then
        global.info_shown[player.index] = true
        make_m45_online_window(player) --online.lua
        make_m45_info_window(player) --info.lua
        make_m45_todo_window(player)
      end
    end
  end
end

--New player created, insert items set perms, show players online, welcome to map.
function on_player_created(event)
  if event and event.player_index then
    local player = game.players[event.player_index]

    update_player_list() --online.lua

    if player and player.valid then
      --Cutoff-point, just becomes annoying.
      if not player.force.technologies["military-2"].researched then
        player.insert {name = "iron-plate", count = 50}
        player.insert {name = "copper-plate", count = 50}
        player.insert {name = "wood", count = 50}
        player.insert {name = "burner-mining-drill", count = 2}
        player.insert {name = "stone-furnace", count = 2}
        player.insert {name = "iron-chest", count = 1}
      end
      player.insert {name = "light-armor", count = 1}

      insert_weapons(player, 50) --research-based

      set_perms()
      show_players(player)
      message_all("[color=green](SYSTEM) Welcome " .. player.name .. " to the map![/color]")
    end
  end
end

--Corpse Map Marker
function on_pre_player_died(event)
  if event and event.player_index then
    local player = game.players[event.player_index]
    --Sanity check
    if player and player.valid and player.character then
      --Make map pin
      local centerPosition = player.position
      local label = ("Body of: " .. player.name)
      local chartTag = {position = centerPosition, icon = nil, text = label}
      local qtag = player.force.add_chart_tag(player.surface, chartTag)

      create_myglobals()
      create_player_globals(player)

      --Add to list of pins
      table.insert(global.corpselist, {tag = qtag, tick = game.tick})

      --Log to discord
      if event.cause and event.cause.valid then
        cause = event.cause.name
        message_all("[color=red](SYSTEM) " .. player.name .. " was killed by " .. cause .. " at [gps=" .. math.floor(player.position.x) .. "," .. math.floor(player.position.y) .. "][/color]")
      else
        message_all("[color=red](SYSTEM) " .. player.name .. " was killed at [gps=" .. math.floor(player.position.x) .. "," .. math.floor(player.position.y) .. "][/color]")
      end
    end
  end
end
