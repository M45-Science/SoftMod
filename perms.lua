--Carl Frank Otto III
--carlotto81@gmail.com
require "utility"

--Create player groups if they don't exist, and create global links to them
function create_groups()
  global.defaultgroup = game.permissions.get_group("Default")
  global.membersgroup = game.permissions.get_group("Members")
  global.regularsgroup = game.permissions.get_group("Regulars")
  global.adminsgroup = game.permissions.get_group("Admins")

  if (not global.defaultgroup) then
    game.permissions.create_group("Default")
  end

  if (not global.membersgroup) then
    game.permissions.create_group("Members")
  end

  if (not global.regularsgroup) then
    game.permissions.create_group("Regulars")
  end

  if (not global.adminsgroup) then
    game.permissions.create_group("Admins")
  end

  global.defaultgroup = game.permissions.get_group("Default")
  global.membersgroup = game.permissions.get_group("Members")
  global.regularsgroup = game.permissions.get_group("Regulars")
  global.adminsgroup = game.permissions.get_group("Admins")
end

--Disable some permissions for new players
function set_perms()
  --Auto set default group permissions

  if global.defaultgroup and not global.setperms then
    --Only set perms once, unless cleared
    global.setperms = true

    global.defaultgroup.set_allows_action(defines.input_action.wire_dragging, false)
    global.defaultgroup.set_allows_action(defines.input_action.activate_cut, false)
    global.defaultgroup.set_allows_action(defines.input_action.add_train_station, false)
    global.defaultgroup.set_allows_action(defines.input_action.build_terrain, false)
    global.defaultgroup.set_allows_action(defines.input_action.change_arithmetic_combinator_parameters, false)
    global.defaultgroup.set_allows_action(defines.input_action.change_decider_combinator_parameters, false)
    global.defaultgroup.set_allows_action(defines.input_action.switch_constant_combinator_state, false)
    global.defaultgroup.set_allows_action(defines.input_action.change_programmable_speaker_alert_parameters, false)
    global.defaultgroup.set_allows_action(defines.input_action.change_programmable_speaker_circuit_parameters, false)
    global.defaultgroup.set_allows_action(defines.input_action.change_programmable_speaker_parameters, false)
    global.defaultgroup.set_allows_action(defines.input_action.change_train_stop_station, false)
    global.defaultgroup.set_allows_action(defines.input_action.change_train_wait_condition, false)
    global.defaultgroup.set_allows_action(defines.input_action.change_train_wait_condition_data, false)
    global.defaultgroup.set_allows_action(defines.input_action.connect_rolling_stock, false)
    global.defaultgroup.set_allows_action(defines.input_action.deconstruct, false)
    global.defaultgroup.set_allows_action(defines.input_action.disconnect_rolling_stock, false)
    global.defaultgroup.set_allows_action(defines.input_action.drag_train_schedule, false)
    global.defaultgroup.set_allows_action(defines.input_action.drag_train_wait_condition, false)
    global.defaultgroup.set_allows_action(defines.input_action.launch_rocket, false)
    global.defaultgroup.set_allows_action(defines.input_action.remove_cables, false)
    global.defaultgroup.set_allows_action(defines.input_action.remove_train_station, false)
    global.defaultgroup.set_allows_action(defines.input_action.set_auto_launch_rocket, false)
    global.defaultgroup.set_allows_action(defines.input_action.set_circuit_condition, false)
    global.defaultgroup.set_allows_action(defines.input_action.set_circuit_mode_of_operation, false)
    global.defaultgroup.set_allows_action(defines.input_action.set_logistic_filter_item, false)
    global.defaultgroup.set_allows_action(defines.input_action.set_logistic_filter_signal, false)
    global.defaultgroup.set_allows_action(defines.input_action.set_request_from_buffers, false)
    global.defaultgroup.set_allows_action(defines.input_action.set_signal, false)
    global.defaultgroup.set_allows_action(defines.input_action.set_train_stopped, false)
    --Added 12-2020
    global.defaultgroup.set_allows_action(defines.input_action.cancel_research, false)
    global.defaultgroup.set_allows_action(defines.input_action.upgrade, false)
    global.defaultgroup.set_allows_action(defines.input_action.cancel_upgrade, false)
    global.defaultgroup.set_allows_action(defines.input_action.build_rail, true)
    global.defaultgroup.set_allows_action(defines.input_action.activate_paste, true)
    global.defaultgroup.set_allows_action(defines.input_action.flush_opened_entity_fluid, false)
    global.defaultgroup.set_allows_action(defines.input_action.flush_opened_entity_specific_fluid, false)
    global.defaultgroup.set_allows_action(defines.input_action.paste_entity_settings, false)
    global.defaultgroup.set_allows_action(defines.input_action.set_auto_launch_rocket, false)
    global.defaultgroup.set_allows_action(defines.input_action.use_artillery_remote, true)
    global.defaultgroup.set_allows_action(defines.input_action.upgrade, false)

    --Added 2-2020
    global.defaultgroup.set_allows_action(defines.input_action.drop_item, false)
  end
end

--Flag player as currently active
function set_player_active(player)
  if (player and player.valid and player.connected and player.character and player.character.valid and global.playeractive) then
    --banished players don't get activity score
    if is_banished(player) == false then
      global.playeractive[player.index] = true
    end
  end
end

--Set our default game-settings
function game_settings(player)
  if player and player.valid and player.force and not global.gset then
    global.gset = true --Only apply these once
    player.force.friendly_fire = false --friendly fire
    player.force.research_queue_enabled = true --nice to have
    game.disable_replay() --Smaller saves, prevent desync on script upgrade
  end
end

--Automatically promote users to higher levels
function get_permgroup()
  if game.connected_players then
    --Check all connected players
    for _, player in pairs(game.connected_players) do
      if (player and player.valid) then
        --Check if groups are valid
        if (global.defaultgroup and global.membersgroup and global.regularsgroup and global.adminsgroup) then
          if player.permission_group then
            --(ADMINS) Check if they are in the right group, including se-remote-view
            if (player.admin and player.permission_group.name ~= global.adminsgroup.name and player.permission_group.name ~= global.adminsgroup.name .. "_satellite") then
              --(REGULARS) Check if they are in the right group, including se-remote-view
              global.adminsgroup.add_player(player)
              message_all(player.name .. " moved to Admins group")
            elseif (global.active_playtime and global.active_playtime[player.index] and global.active_playtime[player.index] > (4 * 60 * 60 * 60) and not player.admin) then
              --Check if player has hours for regulars status, but isn't a in regulars group.
              if (player.permission_group.name ~= global.regularsgroup.name and player.permission_group.name ~= global.regularsgroup.name .. "_satellite") then
                global.regularsgroup.add_player(player)
                message_all(player.name .. " is now a regular!")
                smart_print(player, "[color=red](SYSTEM) You have been active enough, that you have been promoted to the 'Regulars' group![/color]")
                smart_print(player, "[color=red](SYSTEM) You now have access to our 'Regulars' Discord role.[/color]")
                smart_print(player, "[color=red](SYSTEM) To find out more, click the (M45-Science) logo in the top-left of the screen (flask/inserter)[/color]")
                
                if player.character then
                  player.character.damage(0.001, "enemy") --Grab attention
                end
              end
            elseif (global.active_playtime and global.active_playtime[player.index] and global.active_playtime[player.index] > (30 * 60 * 60) and not player.admin) then
              --Check if player has hours for members status, but isn't a in member group.
              if is_regular(player) == false and is_member(player) == false and is_new(player) == true then
                global.membersgroup.add_player(player)
                message_all(player.name .. " is now a member!")
                smart_print(player, "[color=red](SYSTEM) You have been active enough, that the restrictions on your character have been lifted.[/color]")
                smart_print(player, "[color=red](SYSTEM) To find out more, click the (M45-Science) logo in the top-left of the screen (flask/inserter)[/color]")
                smart_print(player, "[color=red](SYSTEM) You now have access to our members-only servers![/color]")

                if player.character then
                  player.character.damage(0.001, "enemy") --Grab attention
                end
              end
            end
          end
        end
      end
    end
  end
end
