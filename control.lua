--Carl Frank Otto III
--carlotto81@gmail.com
local svers = "545-1-28-2021-0358p-exp"
--require "darkness"

local loremipsum = "Lorem ipsum dolor sit amet"

local function todo_key(i)
  if global.todo_list and global.todo_list[i] then
    return global.todo_list[i].id
  else
    return "ERROR"
  end
end

local function todo_id_to_index(id)
  if global.todo_list then
    for i, item in pairs(global.todo_list) do
      if item and item.id then
        if item.id == id then
          return i
        end
      end
    end
  end
  console_print("todo_id_to_index: could not find note id: " .. id)
  return -1
end

--Quickly turn tables into strings
function dump(o)
  if type(o) == "table" then
    local s = "{ "
    for k, v in pairs(o) do
      if type(k) ~= "number" then
        k = '"' .. k .. '"'
      end
      s = s .. "[" .. k .. "] = " .. dump(v) .. ","
    end
    return s .. "} "
  else
    return tostring(o)
  end
end

function d_sameobj(obj_a, obj_b)
  --Valid objects?
  if obj_a and obj_b and obj_a.valid and obj_b.valid then
    --Same surface?
    if obj_a.surface.name == obj_b.surface.name then
      --Same name and type?
      if obj_a.object_name == obj_b.object_name and obj_a.type == obj_b.type then
        --Same position?
        if obj_a.position.x == obj_b.position.x and obj_a.position.y == obj_b.position.y then
          return true
        end
      end
    end
  end

  return false
end

--Cut off extra precision
function round(number, precision)
  local fmtStr = string.format("%%0.%sf", precision)
  number = string.format(fmtStr, number)
  return number
end

--Add M45 Logo to spawn area
local function dodrawlogo()
  if game.surfaces[1] then
    --Only draw if needed
    if not global.drawlogo then
      --Destroy if already exists
      if global.m45logo then
        rendering.destroy(global.m45logo)
      end
      if global.m45logo_light then
        rendering.destroy(global.m45logo_light)
      end
      if global.m45text then
        rendering.destroy(global.m45text)
      end
      if global.servtext then
        rendering.destroy(global.servtext)
      end

      --Get spawn position
      local cpos = {x = 0, y = 0}
      if global.cspawnpos and global.cspawnpos.x then
        cpos = global.cspawnpos
      end

      --Find nice clear area for spawn
      local newpos = game.surfaces[1].find_non_colliding_position("crash-site-spaceship", cpos, 1000, 0.1, false)
      --Set spawn position if we found a better spot
      if newpos and newpos.x ~= 0 and newpos.y ~= 0 then
        cpos = newpos
        global.cspawnpos = newpos
      end

      --Clear map at start to hide everything
      if not global.map_started then
        global.map_started = true
        game.forces["player"].clear_chart()
      end

      --Set drawn flag
      global.drawlogo = true
      global.m45logo =
        rendering.draw_sprite {
        sprite = "file/img/world/m45-pad-v4.png",
        render_layer = "floor",
        target = cpos,
        x_scale = 0.5,
        y_scale = 0.5,
        surface = game.surfaces[1]
      }
      global.m45logo_light =
        rendering.draw_light {
        sprite = "utility/light_medium",
        render_layer = 148,
        target = cpos,
        scale = 8,
        surface = game.surfaces[1],
        minimum_darkness = 0.5
      }
      if not global.servname then
        global.servname = ""
      end
      global.m45text =
        rendering.draw_text {
        text = "M45-Science",
        draw_on_ground = true,
        surface = game.surfaces[1],
        target = {cpos.x + -0.125, cpos.y - 0.75},
        scale = 1.25,
        color = {1, 1, 1},
        alignment = "center",
        scale_with_zoom = false
      }
      global.servtext =
        rendering.draw_text {
        text = global.servname,
        draw_on_ground = true,
        surface = game.surfaces[1],
        target = {cpos.x - 0.125, cpos.y + 2.125},
        scale = 1.0,
        color = {1, 1, 1},
        alignment = "center",
        scale_with_zoom = false
      }
    end
  end
end

--Safe console print
function console_print(message)
  if message then
    print("~" .. message)
  end
end

--Smart/safe Print
function smart_print(player, message)
  if message then
    if player then
      player.print(message)
    else
      rcon.print("~ " .. message)
    end
  end
end

--Global messages (game/discord)
function message_all(message)
  if message then
    game.print(message)
    print("[MSG] " .. message)
  end
end

--Global messages (game only)
function message_allp(message)
  if message then
    game.print(message)
  end
end

--Global messages (discord only)
function message_alld(message)
  if message then
    print("[MSG] " .. message)
  end
end

--Check if player should be considered a regular
function is_regular(victim)
  if victim and victim.valid and not victim.admin then
    --If in group
    if victim.permission_group and global.regularsgroup then
      if victim.permission_group.name == global.regularsgroup.name or victim.permission_group.name == global.regularsgroup.name .. "_satellite" then
        return true
      end
    end
  end

  return false
end

--Check if player should be considered a member
function is_member(victim)
  if victim and victim.valid and not victim.admin then
    --If in group
    if victim.permission_group and global.membersgroup then
      if victim.permission_group.name == global.membersgroup.name or victim.permission_group.name == global.membersgroup.name .. "_satellite" then
        return true
      end
    end
  end

  return false
end

--Check if player should be considered new
function is_new(victim)
  if victim and victim.valid and not victim.admin then
    if is_member(victim) == false and is_regular(victim) == false then
      return true
    end
  end

  return false
end

--Check if player should be considered banished
function is_banished(victim)
  if victim and victim.valid and not victim.admin then
    --Admins and regulars can not be marked as banished
    if is_regular(victim) or victim.admin then
      return false
    elseif global.thebanished and global.thebanished[victim.index] then
      if (is_new(victim) and global.thebanished[victim.index] >= 2) or (is_member(victim) and global.thebanished[victim.index] >= 3) then
        return true
      end
    end
  end

  return false
end

--Count online players, store
local function update_player_list()
  --Sort by active time
  local results = {}
  local count = 0

  --Init if needed
  if not global.active_playtime then
    global.active_playtime = {}
  end

  --Make a table with active time, handle missing data
  for i, victim in pairs(game.connected_players) do
    local utag

    --Catch all
    if victim.permission_group then
      local gname = victim.permission_group.name
      utag = gname
    else
      utag = "none"
    end

    --Normal groups
    if is_new(victim) then
      utag = "NEW"
    end
    if is_member(victim) then
      utag = "Members"
    end
    if is_regular(victim) then
      utag = "Regulars"
    end
    if is_banished(victim) then
      utag = "BANISHED"
    end
    if victim.admin then
      utag = "ADMINS"
    end

    if global.active_playtime[victim.index] then
      table.insert(
        results,
        {
          victim = victim,
          score = global.active_playtime[victim.index],
          time = victim.online_time,
          type = utag
        }
      )
    else
      table.insert(results, {victim = victim, score = 0, time = victim.online_time, type = utag})
    end

    count = i
  end
  table.sort(
    results,
    function(k1, k2)
      return k1.time > k2.time
    end
  )

  for _, item in pairs(results) do
    if item.victim.gui and item.victim.gui.top and item.victim.gui.top.online_button then
      item.victim.gui.top.online_button.number = count
    end
  end
  global.player_count = count
  global.player_list = results
end

local function make_m45_online_submenu(player, target_name)
  local target = game.players[target_name]

  --make online root submenu
  if player and target and target.valid then
    if player.gui and player.gui.screen then
      if not player.gui.screen.m45_online_submenu then
        if not player.gui.screen.m45_online_submenu then
          local main_flow =
            player.gui.screen.add {
            type = "frame",
            name = "m45_online_submenu",
            direction = "vertical"
          }
          main_flow.force_auto_center()
          main_flow.style.horizontal_align = "center"
          main_flow.style.vertical_align = "center"

          --Online Title Bar--
          local online_submenu_titlebar =
            main_flow.add {
            type = "frame",
            direction = "horizontal"
          }
          online_submenu_titlebar.drag_target = main_flow
          online_submenu_titlebar.style.horizontal_align = "center"
          online_submenu_titlebar.style.horizontally_stretchable = true

          if not global.player_count or not global.player_list then
            update_player_list()
          end

          online_submenu_titlebar.add {
            type = "label",
            style = "frame_title",
            caption = "Player: " .. target_name
          }
          local pusher =
            online_submenu_titlebar.add {
            type = "empty-widget",
            style = "draggable_space_header"
          }
          pusher.style.vertically_stretchable = true
          pusher.style.horizontally_stretchable = true
          pusher.drag_target = main_flow

          online_submenu_titlebar.add {
            type = "sprite-button",
            name = "m45_online_submenu_close_button",
            sprite = "utility/close_white",
            style = "frame_action_button",
            tooltip = "Close this window"
          }

          local online_submenu_main =
            main_flow.add {
            type = "frame",
            name = "main",
            direction = "vertical"
          }
          online_submenu_main.style.horizontal_align = "center"

          --FIND ON MAP
          local find_on_map_frame =
            online_submenu_main.add {
            type = "flow",
            direction = "vertical"
          }
          find_on_map_frame.style.horizontal_align = "center"
          local find_on_map =
            find_on_map_frame.add {
            type = "button",
            caption = "[item=artillery-targeting-remote] Find On Map",
            name = "find_on_map"
          }
          find_on_map.style.horizontal_align = "center"

          --WHISPER
          local whisper_frame =
            online_submenu_main.add {
            type = "flow",
            name = "whisper_frame",
            direction = "vertical"
          }
          whisper_frame.style.horizontal_align = "center"
          local whisper =
            whisper_frame.add {
            type = "label",
            caption = "[font=default-large-bold]Whisper To:[/font]",
            name = "whisper"
          }
          local whiser_textbox =
            whisper_frame.add {
            type = "text-box",
            text = "",
            name = "whisper_textbox"
          }
          whisper_frame.add {
            type = "button",
            caption = "Send",
            name = "send_whisper",
            style = "green_button"
          }
          whisper_frame.add {
            type = "label",
            caption = " "
          }
          whiser_textbox.style.width = 500
          whiser_textbox.style.height = 64
          whiser_textbox.word_wrap = true
          whiser_textbox.style.horizontal_align = "left"

          --REPORT
          local report_frame =
            online_submenu_main.add {
            type = "flow",
            direction = "vertical",
            name = "report_frame"
          }
          report_frame.style.horizontal_align = "center"
          local report =
            report_frame.add {
            type = "label",
            caption = "[font=default-large-bold]Report player:[/font]",
            name = "report"
          }
          local report_textbox =
            report_frame.add {
            type = "text-box",
            text = "",
            name = "report_textbox"
          }
          report_frame.add {
            type = "label",
            caption = "(Posts to #moderation on Discord)",
            name = "report_note"
          }

          report_textbox.style.width = 500
          report_textbox.style.height = 64
          report_textbox.word_wrap = true
          report_textbox.style.horizontal_align = "left"

          local report_button =
            report_frame.add {
            type = "button",
            caption = "REPORT",
            style = "red_button",
            name = "report_player"
          }

          report_frame.add {
            type = "label",
            caption = " "
          }

          --BANISH
          local banish_frame =
            online_submenu_main.add {
            type = "flow",
            direction = "vertical",
            name = "banish_frame"
          }
          banish_frame.style.horizontal_align = "center"
          local banish =
            banish_frame.add {
            type = "label",
            caption = "[font=default-large-bold]Banish Player:[/font]",
            name = "banish"
          }
          local banish_textbox =
            banish_frame.add {
            type = "text-box",
            text = "",
            name = "banish_textbox"
          }

          banish_textbox.style.width = 500
          banish_textbox.style.height = 64
          banish_textbox.word_wrap = true
          banish_textbox.style.horizontal_align = "center"

          local banish_button =
            banish_frame.add {
            type = "button",
            caption = "VOTE TO BANISH",
            style = "red_button",
            name = "banish_player"
          }

          if is_regular(player) or player.admin then
            if is_regular(target) or target.admin then
              local bansh_note =
                banish_frame.add {
                type = "label",
                caption = "(regulars and admins cannot be banished)"
              }
              bansh_note.enabled = false
              banish.enabled = false
              banish_textbox.enabled = false
              banish_button.enabled = false
            end
          else
            local bansh_note =
              banish_frame.add {
              type = "label",
              caption = "(only regulars and admins have banish privleges)"
            }
            bansh_note.enabled = false
            banish.enabled = false
            banish_textbox.enabled = false
            banish_button.enabled = false
          end

          banish_frame.add {
            type = "label",
            caption = " "
          }
        end
      end
    end
  end
end

local function destroy_m45_online_submenu(player)
  if player.gui and player.gui.screen and player.gui.screen.m45_online_submenu then
    player.gui.screen.m45_online_submenu.destroy()
  end
end

local function handle_m45_online_submenu(player, target_name)
  --init if needed
  if not global.m45_online_submenu_target then
    global.m45_online_submenu_target = {}
  end

  if player and player.valid and target_name then
    global.m45_online_submenu_target[player.index] = target_name
    destroy_m45_online_submenu(player)
    make_m45_online_submenu(player, target_name)
  end
end

function make_m45_todo_submenu(player, i, edit_mode)
  if player and player.valid then
    --Always refresh when called
    if player.gui and player.gui.screen and player.gui.screen.m45_todo_submenu then
      player.gui.screen.m45_todo_submenu.destroy()
    end

    if global.todo_list and global.todo_list[i] then
      local target = global.todo_list[i]

      local no_edit = false
      if not edit_mode or is_new(player) or (not player.admin and player.name ~= target.owner and not target.can_edit) then
        no_edit = true
      end

      --make todo root submenu
      if player and target and target.time then
        if player.gui and player.gui.screen then
          if not player.gui.screen.m45_todo_submenu then
            local main_flow =
              player.gui.screen.add {
              type = "frame",
              name = "m45_todo_submenu",
              direction = "vertical"
            }
            main_flow.force_auto_center()
            main_flow.style.horizontal_align = "center"
            main_flow.style.vertical_align = "center"
            main_flow.style.maximal_width = 600

            --Online Title Bar--
            local todo_submenu_titlebar =
              main_flow.add {
              type = "flow",
              direction = "horizontal",
              name = "titlebar"
            }
            todo_submenu_titlebar.drag_target = main_flow
            todo_submenu_titlebar.style.horizontal_align = "center"
            todo_submenu_titlebar.style.horizontally_stretchable = true

            if not global.player_count or not global.player_list then
              update_player_list()
            end

            todo_submenu_titlebar.add {
              type = "label",
              style = "frame_title",
              caption = "To-Do ID# " .. target.id
            }
            local pusher =
              todo_submenu_titlebar.add {
              type = "empty-widget",
              style = "draggable_space_header"
            }
            pusher.style.vertically_stretchable = true
            pusher.style.horizontally_stretchable = true
            pusher.drag_target = main_flow

            todo_submenu_titlebar.add {
              type = "sprite-button",
              name = "m45_todo_submenu_close_button",
              sprite = "utility/close_white",
              style = "frame_action_button",
              tooltip = "Close this window"
            }

            local todo_submenu_main =
              main_flow.add {
              type = "flow",
              name = "main",
              direction = "horizontal"
            }
            todo_submenu_main.style.horizontal_align = "center"

            todo_submenu_main.add {
              type = "label",
              caption = "[font=default-large-bold]Priority: [/font]"
            }
            local priority_textbox =
              todo_submenu_main.add {
              type = "text-box",
              text = target.priority,
              name = "todo_priority_textbox"
            }
            priority_textbox.read_only = no_edit
            if no_edit then
              priority_textbox.selectable = false
            end

            priority_textbox.style.width = 100
            todo_submenu_main.add {
              type = "label",
              caption = "[font=default-large-bold]Subject: [/font]"
            }
            local subject_textbox =
              todo_submenu_main.add {
              type = "text-box",
              text = target.subject,
              name = "todo_subject_textbox"
            }
            subject_textbox.style.width = 200
            subject_textbox.read_only = no_edit
            if no_edit then
              subject_textbox.selectable = false
            end

            local todo_submenu_body =
              main_flow.add {
              type = "flow",
              name = "todo_body",
              direction = "vertical"
            }
            local lock_spacer =
              todo_submenu_main.add {
              type = "empty-widget"
            }
            lock_spacer.style.width = 32
            local todo_lock =
              todo_submenu_main.add {
              type = "checkbox",
              caption = "Protected",
              name = "todo_protected",
              state = (not target.can_edit)
            }
            if no_edit then
              todo_lock.enabled = false
            end

            todo_submenu_body.add {
              type = "label",
              caption = ""
            }
            todo_submenu_body.add {
              type = "label",
              caption = "[font=default-large-bold]Notes:   [/font]" .. "Owner: " .. target.owner .. ",  Last Edit: " .. target.last_user
            }

            local notes_textbox =
              todo_submenu_body.add {
              type = "text-box",
              text = target.text,
              name = "todo_text_textbox"
            }
            notes_textbox.style.minimal_width = 575
            notes_textbox.style.minimal_height = 200
            notes_textbox.style.maximal_height = 600
            notes_textbox.read_only = no_edit
            if no_edit then
              notes_textbox.selectable = false
            end

            local todo_save_frame =
              todo_submenu_body.add {
              type = "flow",
              name = "save_frame",
              direction = "horizontal"
            }
            todo_save_frame.style.horizontal_align = "right"
            todo_save_frame.style.horizontally_stretchable = true

            if edit_mode then
              local whoedit = ""
              local c = 0
              for _, victim in pairs(game.players) do
                if victim.name ~= player.name and global.todo_player_editing_id[victim.index] == global.todo_player_editing_id[player.index] then
                  c = c + 1
                  if c > 1 then
                    whoedit = whoedit .. ", "
                  end
                  whoedit = whoedit .. victim.name
                end
              end
              if whoedit ~= "" then
                local edit_note =
                  todo_save_frame.add {
                  type = "label",
                  caption = "[font=default-large-bold][color=red]CURRENTLY BEING EDITED BY: " .. whoedit .. "[/color][/font]"
                }
                local lock_spacer =
                  todo_save_frame.add {
                  type = "empty-widget"
                }
                lock_spacer.style.width = 32
              end
              local delete_button =
                todo_save_frame.add {
                type = "button",
                caption = "Delete",
                style = "red_button",
                name = "m45_todo_hide," .. global.todo_player_editing_id[player.index]
              }
              local lock_spacer =
                todo_save_frame.add {
                type = "empty-widget"
              }
              lock_spacer.style.width = 16
              local save_button =
                todo_save_frame.add {
                type = "button",
                caption = "Save",
                style = "green_button",
                name = "m45_todo_save," .. global.todo_player_editing_id[player.index]
              }

              if no_edit then
                save_button.enabled = false
                delete_button.enabled = false
              end
            end
          end
        end
      end
    end
  end
end

--M45 ToDo Window
local function make_m45_todo_window(player)
  if player.gui and player.gui.screen then
    if player.gui.screen.m45_todo then
      player.gui.screen.m45_todo.destroy()
    end
    if not player.gui.screen.m45_todo then
      local main_flow =
        player.gui.screen.add {
        type = "frame",
        name = "m45_todo",
        direction = "vertical"
      }
      main_flow.style.horizontal_align = "left"
      main_flow.style.vertical_align = "top"
      main_flow.style.minimal_width = 300
      main_flow.style.vertically_stretchable = true

      --Todo Title Bar--
      local todo_titlebar =
        main_flow.add {
        type = "flow",
        direction = "horizontal"
      }
      todo_titlebar.style.horizontal_align = "center"
      todo_titlebar.style.horizontally_stretchable = true
      todo_titlebar.style.vertically_stretchable = false

      todo_titlebar.add {
        type = "label",
        name = "online_title",
        style = "frame_title",
        caption = "To-Do List:"
      }
      local pusher = todo_titlebar.add {type = "empty-widget"}
      pusher.style.horizontally_stretchable = true

      --CLOSE BUTTON--
      local todo_close_button =
        todo_titlebar.add {
        type = "flow",
        direction = "horizontal"
      }
      todo_close_button.style.horizontal_align = "right"
      todo_close_button.style.horizontally_stretchable = false
      todo_close_button.add {
        type = "sprite-button",
        name = "m45_todo_close_button",
        sprite = "utility/close_white",
        style = "frame_action_button",
        tooltip = "Close this window"
      }

      local pframe =
        main_flow.add {
        type = "flow",
        direction = "horizontal"
      }
      pframe.style.vertically_stretchable = false
      pframe.style.horizontal_align = "right"

      local todo_main =
        main_flow.add {
        type = "scroll-pane",
        direction = "vertical"
      }

      pframe.style.horizontally_stretchable = true

      local submenu =
        pframe.add {
        type = "label",
        caption = "VIEW / EDIT"
      }
      submenu.style.width = 120

      pframe.add {
        type = "label",
        caption = " "
      }
      local id_label =
        pframe.add {
        type = "label",
        caption = " ID#"
      }
      id_label.style.width = 53
      local name_label =
        pframe.add {
        type = "label",
        caption = "Priority"
      }
      name_label.style.width = 100
      local time_label =
        pframe.add {
        type = "label",
        caption = "Subject"
      }
      time_label.style.width = 200
      local notes_label =
        pframe.add {
        type = "label",
        caption = " Notes"
      }

      if global.vis_todo_count <= 0 then
        pframe.add {
          type = "label",
          caption = "Nothing here."
        }
      end

      if global.vis_todo_count > 0 then
        for i, target in pairs(global.todo_list) do
          --Skip hidden items
          if not target.hidden then


          todo_main.add {
            type = "line",
            direction = "horizontal"
          }
          local pframe =
            todo_main.add {
            type = "flow",
            direction = "horizontal"
          }
          pframe.style.horizontally_stretchable = true
          pframe.style.vertically_stretchable = false
          pframe.style.maximal_width = 1600
          local submenu_view =
            pframe.add {
            type = "sprite-button",
            sprite = "utility/search_white",
            style = "frame_action_button",
            name = "m45_todo_submenu_view," .. i --pass-item
          }
          submenu_view.style.size = {36, 36}
          submenu_view.style.padding = 4

          local submenu_edit =
            pframe.add {
            type = "sprite-button",
            sprite = "utility/rename_icon_small_white",
            style = "frame_action_button",
            name = "m45_todo_submenu_edit," .. i --pass-item
          }
          submenu_edit.style.size = {36, 36}
          submenu_edit.style.padding = 4
          --Disable button if we can't edit
          if is_new(player) or (not player.admin and player.name ~= target.owner and not target.can_edit) then
            submenu_edit.enabled = false
          end

          local gps_spacer =
            pframe.add {
            type = "empty-widget"
          }
          gps_spacer.style.width = 54
          local id_label =
            pframe.add {
            type = "label",
            caption = target.id
          }
          id_label.style.width = 45
          local pri_label =
            pframe.add {
            type = "label",
            caption = target.priority
          }
          pri_label.style.width = 100
          local name_label =
            pframe.add {
            type = "label",
            caption = target.subject
          }
          name_label.style.width = 200

          --Show who owns item, who edited and if locked
          local locked = ""
          if not target.can_edit then
            locked = " (locked)"
          end
          local notes_label =
            pframe.add {
            type = "label",
            caption = "  " .. target.text .. "  ",
            tooltip = "Last User: " .. target.last_user .. ", Owner: " .. target.owner .. locked
          }

          gps_button =
            pframe.add {
            type = "sprite-button",
            sprite = "utility/spawn_flag",
            name = "m45_todo_gps," .. i --Pass name
          }
          gps_button.style.size = {38, 38}
          if not target.gps then
            gps_button.visible = false
          end

          local gps_spacer =
            pframe.add {
            type = "empty-widget"
          }
          gps_spacer.style.width = 16

          notes_label.style.horizontally_stretchable = true
          notes_label.style.horizontally_squashable = true
          notes_label.style.minimal_width = 300
          notes_label.style.horizontal_align = "left"
          local spacer =
            pframe.add {
            type = "empty-widget"
          }
          spacer.style.horizontally_stretchable = true

          local move_ud_frame =
            pframe.add {
            type = "flow",
            direction = "vertical"
          }

          --Invisible space for up arrow when hidden
          if i == 1 then
            local invis_space =
              move_ud_frame.add {
              type = "label",
              caption = " "
            }
            invis_space.style.height = 18
          end

          local moveup =
            move_ud_frame.add {
            type = "sprite-button",
            sprite = "file/img/todo/up.png",
            name = "m45_todo_moveup," .. i, --pass-item
            style = "frame_action_button",
            tooltip = "move up"
          }
          moveup.style.size = {18, 18}

          local movedown =
            move_ud_frame.add {
            type = "sprite-button",
            sprite = "file/img/todo/down.png",
            name = "m45_todo_movedown," .. i, --pass-item
            style = "frame_action_button",
            tooltip = "move down"
          }
          movedown.style.size = {18, 18}

          if is_new(player) then
            movedown.visible = false
            moveup.visible = false
          end

          --Hide buttons that would do nothing, first item up, last item down
          if i == 1 then
            moveup.visible = false
          end
          if i == global.vis_todo_count then
            local invis_space =
              move_ud_frame.add {
              type = "label",
              caption = " "
            }
            invis_space.style.height = 18
            movedown.visible = false
          end

          notes_label.style.rich_text_setting = defines.rich_text_setting.enabled
          notes_label.style.horizontally_stretchable = false
        end
        end
      end

      --ADD LINE
      local add_frame =
        main_flow.add {
        type = "flow",
        direction = "horizontal"
      }

      add_frame.style.horizontal_align = "right"
      add_frame.style.horizontally_stretchable = false

      local add =
        add_frame.add {
        type = "sprite-button",
        sprite = "file/img/todo/add.png",
        name = "m45_todo_add"
      }
      if is_new(player) then
        add.enabled = false
      end
      local add_note =
        add_frame.add {
        type = "label",
        caption = "Add item"
      }
      add.style.size = {24, 24}
      notes_label.style.rich_text_setting = defines.rich_text_setting.highlight
      notes_label.style.horizontally_stretchable = true
    end
  end
end

local function update_vis_todo_count()
  global.vis_todo_count = 0
  for _, item in pairs(global.todo_list) do
    if not item.hidden then
      global.vis_todo_count = global.vis_todo_count + 1
    end
  end
end

local function update_todo_windows()
  for _, player in pairs(game.connected_players) do
    --Already handles destroying
    if player.gui and player.gui.screen and player.gui.screen.m45_todo then
      make_m45_todo_window(player)
      if player.gui.screen.m45_todo_submenu then
        player.gui.screen.m45_todo_submenu.bring_to_front()
      end
    end
  end
end

--M45 Online Players Window
local function make_m45_online_window(player)
  if player.gui and player.gui.left then
    if player.gui.left.m45_online then
      player.gui.left.m45_online.destroy()
    end
    if not player.gui.left.m45_online then
      local main_flow =
        player.gui.left.add {
        type = "frame",
        name = "m45_online",
        direction = "vertical"
      }
      main_flow.style.horizontal_align = "left"
      main_flow.style.vertical_align = "top"
      main_flow.style.vertically_squashable = true
      main_flow.style.vertically_stretchable = true
      main_flow.style.horizontally_squashable = true
      main_flow.style.horizontally_stretchable = true

      --Online Title Bar--
      local online_titlebar =
        main_flow.add {
        type = "flow",
        direction = "horizontal"
      }
      online_titlebar.style.horizontal_align = "center"
      online_titlebar.style.horizontally_stretchable = true

      if not global.player_count or not global.player_list then
        update_player_list()
      end

      online_titlebar.add {
        type = "label",
        name = "online_title",
        style = "frame_title",
        caption = "Players Online: " .. global.player_count
      }

      --CLOSE BUTTON--
      local online_close_button =
        online_titlebar.add {
        type = "flow",
        direction = "horizontal"
      }
      online_close_button.style.horizontal_align = "right"
      online_close_button.style.horizontally_stretchable = true
      online_close_button.add {
        type = "sprite-button",
        name = "m45_online_close_button",
        sprite = "utility/close_white",
        style = "frame_action_button",
        tooltip = "Close this window"
      }

      local online_main =
        main_flow.add {
        type = "scroll-pane",
        direction = "vertical"
      }

      local pframe =
        online_main.add {
        type = "frame",
        direction = "horizontal"
      }

      local submenu =
        pframe.add {
        type = "label",
        caption = "MENU"
      }
      submenu.style.width = 45

      pframe.add {
        type = "label",
        caption = "  "
      }
      pframe.add {
        type = "line",
        direction = "vertical"
      }
      local name_label =
        pframe.add {
        type = "label",
        caption = "  Name:"
      }
      name_label.style.width = 200
      pframe.add {
        type = "line",
        direction = "vertical"
      }
      local time_label =
        pframe.add {
        type = "label",
        caption = " Time:"
      }
      time_label.style.width = 100
      pframe.add {
        type = "line",
        direction = "vertical"
      }
      local score_label =
        pframe.add {
        type = "label",
        caption = "  Level:"
      }
      score_label.style.width = 100

      --for x = 0, 100, 1 do
      for i, target in pairs(global.player_list) do
        local victim = target.victim

        local pframe =
          online_main.add {
          type = "frame",
          direction = "horizontal"
        }
        local submenu
        --Yeah don't need this menu for ourself
        if victim.name == player.name then
          submenu =
            pframe.add {
            type = "sprite-button",
            sprite = "utility/player_force_icon",
            name = "m45_online_submenu_open," .. victim.name --Pass name
          }
          submenu.enabled = false
        else
          submenu =
            pframe.add {
            type = "sprite-button",
            sprite = "utility/expand",
            name = "m45_online_submenu_open," .. victim.name --Pass name
          }
        end
        submenu.style.size = {24, 24}

        local gps_spacer =
          pframe.add {
          type = "empty-widget"
        }
        gps_spacer.style.width = 16

        pframe.add {
          type = "label",
          caption = "  "
        }
        pframe.add {
          type = "line",
          direction = "vertical"
        }
        local name_label =
          pframe.add {
          type = "label",
          caption = "  " .. victim.name
        }
        if victim.admin then
          name_label.style.font_color = {r = 1, g = 0, b = 0}
        elseif is_regular(victim) then
          name_label.style.font_color = {r = 1, g = 1, b = 0}
        elseif is_member(victim) then
          name_label.style.font_color = {r = 0, g = 1, b = 0}
        end
        name_label.style.font = "default-bold"
        name_label.style.width = 200
        local name_label =
          pframe.add {
          type = "line",
          direction = "vertical"
        }
        local time_label =
          pframe.add {
          type = "label",
          caption = " " .. math.floor(victim.online_time / 60.0 / 60.0) .. "m"
        }
        time_label.style.width = 100
        local name_label =
          pframe.add {
          type = "line",
          direction = "vertical"
        }
        local utag = ""
        if is_new(victim) then
          utag = "NEW"
        end
        if is_member(victim) then
          utag = "Members"
        end
        if is_regular(victim) then
          utag = "Regulars"
        end
        if is_banished(victim) then
          utag = "BANISHED"
        end
        if victim.admin then
          utag = "ADMINS"
        end
        local score_label =
          pframe.add {
          type = "label",
          caption = "  " .. utag
        }
        score_label.style.width = 100
      end
    --end
    end
  end
end

--M45 Info/Welcome window
local function make_m45_info_window(player)
  --M45 Welcome--
  if player.gui.center then
    --Delete old ones
    if player.gui.center.splash_screen then
      player.gui.center.splash_screen.destroy()
    end

    if player.gui.screen.m45_info_window then
      player.gui.screen.m45_info_window.destroy()
    end
    if not player.gui.screen.m45_info_window then
      local main_flow =
        player.gui.screen.add {
        type = "frame",
        name = "m45_info_window",
        direction = "vertical"
      }
      main_flow.style.horizontal_align = "center"
      main_flow.style.vertical_align = "center"
      main_flow.force_auto_center()

      --Online Title Bar--
      local info_titlebar =
        main_flow.add {
        type = "flow",
        direction = "horizontal"
      }
      info_titlebar.drag_target = main_flow
      info_titlebar.style.horizontal_align = "center"
      info_titlebar.style.horizontally_stretchable = true

      if not global.player_count or not global.player_list then
        update_player_list()
      end

      info_titlebar.add {
        type = "label",
        name = "online_title",
        style = "frame_title",
        caption = "M45 Science, a gaming community."
      }
      local pusher = info_titlebar.add {type = "empty-widget", style = "draggable_space_header"}
      pusher.style.vertically_stretchable = true
      pusher.style.horizontally_stretchable = true
      pusher.drag_target = main_flow

      info_titlebar.add {
        type = "sprite-button",
        name = "m45_info_close_button",
        sprite = "utility/close_white",
        style = "frame_action_button",
        tooltip = "Close this window"
      }

      local info_pane = main_flow.add {type = "tabbed-pane", name = "m45_info_window_tabs"}
      info_pane.style.minimal_width = 725

      local tab1 = info_pane.add {type = "tab", caption = "[entity=character] Welcome"}
      local tab2 = info_pane.add {type = "tab", caption = "[item=automation-science-pack] Membership"}
      local tab3 = info_pane.add {type = "tab", caption = "[item=steel-plate]Rules"}
      local tab4 = info_pane.add {type = "tab", caption = "[virtual-signal=signal-info] Tips & Tricks"}
      local tab5 = info_pane.add {type = "tab", caption = "[item=advanced-circuit] QR-Code"}
      local tab6 = info_pane.add {type = "tab", caption = "[item=production-science-pack] Patreon"}

      --Tab 1 -- Welcome
      local tab1_frame =
        info_pane.add {
        type = "flow",
        direction = "vertical"
      }
      tab1_frame.style.horizontal_align = "center"

      --Tab 1 -- Main
      local tab1_main_frame =
        tab1_frame.add {
        type = "flow",
        direction = "horizontal"
      }

      --Tab 1 left-frame logo-patreons
      local tab1_lframe =
        tab1_main_frame.add {
        type = "flow",
        direction = "vertical"
      }
      tab1_lframe.style.padding = 4
      tab1_lframe.add {
        type = "sprite",
        sprite = "file/img/info-win/m45-128.png",
        tooltip = ""
      }

      tab1_lframe.add {
        type = "label",
        caption = "[font=default-bold]M45-Science[/font]"
      }
      tab1_lframe.add {
        type = "label",
        caption = ""
      }
      tab1_lframe.add {
        type = "label",
        caption = "[color=purple]PATREONS:[/color]"
      }
      tab1_lframe.add {
        type = "label",
        caption = "[color=purple]SirVorlon[/color]"
      }
      tab1_lframe.add {
        type = "label",
        caption = "[color=purple]beefjrkytime[/color]"
      }
      tab1_lframe.add {
        type = "label",
        caption = "[color=purple]Dwits[/color]"
      }
      tab1_lframe.add {
        type = "label",
        caption = "[color=purple]Estabon[/color]"
      }
      tab1_lframe.add {
        type = "label",
        caption = "[color=purple]joloman2[/color]"
      }
      tab1_lframe.add {
        type = "label",
        caption = "[color=purple]LeoR998[/color]"
      }
      tab1_lframe.add {
        type = "label",
        caption = "[color=purple]Merciless210[/color]"
      }
      tab1_lframe.add {
        type = "label",
        caption = "[color=purple]NameisGareth[/color]"
      }
      tab1_lframe.add {
        type = "label",
        caption = "[color=purple]Livedeath[/color]"
      }

      tab1_lframe.add {
        type = "label",
        caption = ""
      }
      tab1_lframe.add {
        type = "button",
        caption = "Help Out!",
        style = "red_button",
        name = "patreon_button"
      }
      tab1_lframe.style.horizontal_align = "center"

      --Tab 1 -- left/right divider line
      tab1_main_frame.add {
        type = "line",
        direction = "vertical"
      }

      --Tab 1 right-frame
      local tab1_rframe =
        tab1_main_frame.add {
        type = "flow",
        direction = "vertical"
      }
      --Tab 1 Center -- Info
      local tab1_info_center =
        tab1_main_frame.add {
        type = "flow",
        direction = "vertical"
      }
      tab1_info_center.style.horizontal_align = "center"

      tab1_info_center.style.horizontally_stretchable = true
      tab1_info_center.add {
        type = "label",
        caption = "[color=orange][font=default-large-bold]Issues, trolls or griefers?[/font][/color]"
      }
      tab1_info_center.add {
        type = "sprite",
        sprite = "file/img/info-win/tips/onetwothree.png"
      }
      tab1_info_center.add {
        type = "label",
        caption = "[color=orange][font=default-large-bold]Report or banish them![/font][/color]"
      }

      local tab1_cframe = {
        tab1_main_frame.add {
          type = "flow",
          direction = "vertical"
        }
      }
      tab1_rframe.style.horizontal_align = "right"
      tab1_rframe.style.vertical_align = "bottom"
      tab1_rframe.style.padding = 4

      --Tab 1 Main -- New Player Warning
      local tab1_info_top =
        tab1_rframe.add {
        type = "flow",
        direction = "vertical"
      }
      tab1_info_top.style.horizontally_stretchable = true
      tab1_info_top.add {
        type = "label",
        caption = ""
      }
      tab1_info_top.add {
        type = "label",
        caption = "[entity=character]  [color=red][font=default-large-bold]New players start with some restrictions![/font][/color]"
      }
      tab1_info_top.add {
        type = "label",
        caption = "[entity=inserter]  [font=default-large]You can only remove or modify your own items![/font]"
      }
      tab1_info_top.add {
        type = "label",
        caption = "[item=locomotive]  [font=default-large]You will also not be allowed to modify trains or logistics.[/font]"
      }
      tab1_info_top.add {
        type = "label",
        caption = ""
      }
      tab1_info_top.add {
        type = "label",
        caption = "[recipe=combat-shotgun] [font=default-large]Friendly fire is off, for players and buildings.[/font]"
      }
      tab1_info_top.add {
        type = "label",
        caption = "[font=default-large]Click the '[item=automation-science-pack] Membership' tab above, to find out how to become a member.[/font]"
      }
      tab1_info_top.add {
        type = "label",
        caption = ""
      }

      --Tab 1 Main -- Discord
      local tab1_discord_frame =
        tab1_rframe.add {
        type = "frame",
        direction = "vertical"
      }
      tab1_discord_frame.style.horizontally_stretchable = true
      tab1_discord_frame.style.vertically_squashable = true
      local tab1_discord_sub1_frame =
        tab1_discord_frame.add {
        type = "flow",
        direction = "vertical"
      }

      --Tab 1 Main -- Discord -- Info Text
      tab1_discord_sub1_frame.add {
        type = "label",
        caption = "[font=default-large-bold]See our [color=blue]Discord Server[/color] for more info![/font]"
      }
      tab1_discord_sub1_frame.add {
        type = "label",
        caption = "[font=default-large]Visit [color=red]m45[/color][color=orange]sci[/color][color=yellow].xyz[/color], or copy-paste the Discord URL below:[/font]"
      }

      --Tab 1 Main -- Discord -- Logo/URL frame
      local tab1_discord_sub2_frame =
        tab1_discord_sub1_frame.add {
        type = "flow",
        direction = "horizontal"
      }
      tab1_discord_sub2_frame.style.vertical_align = "center"
      tab1_discord_sub2_frame.add {
        type = "sprite",
        name = "tab1_discord_logo",
        sprite = "file/img/info-win/discord-64.png",
        tooltip = ""
      }
      tab1_discord_sub2_frame.add {
        type = "text-box",
        name = "discord_url",
        text = "https://discord.gg/Ps2jnm7",
        tooltip = "(if not selected), drag-select with mouse, control-c to copy."
      }
      --URL Style
      tab1_discord_sub2_frame.discord_url.style.font = "default-large"
      tab1_discord_sub2_frame.discord_url.style.minimal_width = 250

      tab1_discord_sub2_frame.add {
        type = "label",
        caption = "  "
      }
      --Tab 1 Main -- Discord -- Bottom Info Text
      tab1_discord_sub2_frame.add {
        type = "button",
        caption = "Get QR Code",
        style = "rounded_button",
        name = "qr_button"
      }
      info_pane.add_tab(tab1, tab1_frame)

      ------------------------
      --TAB 2 -- MEMBERSHIP --
      ------------------------
      local tab2_frame =
        info_pane.add {
        type = "flow",
        direction = "vertical"
      }
      tab2_frame.style.vertically_squashable = true
      tab2_frame.style.horizontal_align = "center"

      --tab 2 -- Main
      local tab2_main_frame =
        tab2_frame.add {
        type = "scroll-pane",
        direction = "vertical"
      }
      tab2_main_frame.style.horizontal_align = "right"
      tab2_main_frame.style.padding = 4

      tab2_main_frame.style.horizontally_stretchable = true
      tab2_main_frame.add {
        type = "label",
        name = "tab2_score",
        caption = "[color=red][font=default-large-bold]Your Activity Score: " .. math.floor(global.active_playtime[player.index] / 60 / 60) .. "[/font][/color]"
      }
      tab2_main_frame.add {
        type = "label",
        caption = ""
      }
      tab2_main_frame.add {
        type = "label",
        caption = "[recipe=construction-robot]   [font=default-bold]Membership is automatic, and based on activity.[/font] Your current activity score is listed above."
      }
      tab2_main_frame.add {
        type = "label",
        caption = "The score is specific to this map, and does not carry over to other maps or servers."
      }
      tab2_main_frame.add {
        type = "label",
        caption = "Once you achieve a specific level, the level persists between maps and servers (but the activity score does not)."
      }
      tab2_main_frame.add {
        type = "label",
        caption = ""
      }
      tab2_main_frame.add {
        type = "label",
        caption = "[font=default-bold]Logged:[/font] Rotating, picking up, placing, and add/remove/edit map pins."
      }
      tab2_main_frame.add {
        type = "line",
        direction = "horizontal"
      }
      if is_new(player) then
        tab2_main_frame.add {
          type = "label",
          caption = "[color=red][font=default-bold]Level 1:[/font] New[/color]"
        }
      else
        tab2_main_frame.add {
          type = "label",
          caption = "[font=default-bold]Level 1:[/font] New"
        }
      end
      tab2_main_frame.add {
        type = "label",
        caption = ""
      }

      tab2_main_frame.add {
        type = "label",
        caption = "[recipe=inserter]   [font=default-bold]New players can not pick-up or rotate other people's objects,[/font] and have these permissions limitations:"
      }
      tab2_main_frame.add {
        type = "label",
        caption = "Modify wires, trains, combinators, signals, speakers, launch rockets or edit logistics."
      }
      tab2_main_frame.add {
        type = "label",
        caption = "Blueprints are limited to 500 items, and throttled ( rate/speed limited )."
      }
      tab2_main_frame.add {
        type = "label",
        caption = "Level 3 players (regulars) can banish you with two votes."
      }
      tab2_main_frame.add {
        type = "line",
        direction = "horizontal"
      }

      if is_member(player) then
        tab2_main_frame.add {
          type = "label",
          caption = "[color=red][font=default-bold]Level 2:[/font] Members[/color] (Score: 30)"
        }
      else
        tab2_main_frame.add {
          type = "label",
          caption = "[font=default-bold]Level 2:[/font] Members (Score: 30)"
        }
      end
      tab2_main_frame.add {
        type = "label",
        caption = ""
      }
      tab2_main_frame.add {
        type = "label",
        caption = "[recipe=fast-inserter]   Ability to pick-up and rotate other's objects, and permissions restrictions are lifted."
      }
      tab2_main_frame.add {
        type = "label",
        caption = "Votes needed to banish you increases to 3. Access to deconstruction planner (warns other players, with location)."
      }
      tab2_main_frame.add {
        type = "label",
        caption = "Blueprint size/speed limits increase."
      }
      tab2_main_frame.add {
        type = "label",
        caption = "[font=default-bold]Discord Role available[/font] (Members)."
      }

      tab2_main_frame.add {
        type = "line",
        direction = "horizontal"
      }

      if is_regular(player) then
        tab2_main_frame.add {
          type = "label",
          caption = "[color=red][font=default-bold]Level 3:[/font] Regulars[/color] (Score: 240)"
        }
      else
        tab2_main_frame.add {
          type = "label",
          caption = "[font=default-bold]Level 3:[/font] Regulars (Score: 240)"
        }
      end
      tab2_main_frame.add {
        type = "label",
        caption = ""
      }

      tab2_main_frame.add {
        type = "label",
        caption = "[recipe=stack-inserter]   Access to /banish command (5 votes per map), other players can not banish you."
      }
      tab2_main_frame.add {
        type = "label",
        caption = "Deconstruction planner warning removed, blueprint size/speed limits removed."
      }
      tab2_main_frame.add {
        type = "label",
        caption = "[font=default-bold]Discord role available[/font] (Regulars), gain access to regulars-only Discord channels, and private Factorio servers."
      }
      --Close Button Frame
      local tab2_close_frame =
        tab2_main_frame.add {
        type = "flow",
        direction = "vertical"
      }
      tab2_close_frame.style.horizontal_align = "right"

      info_pane.add_tab(tab2, tab2_frame)

      ------------------------
      --tab 3 -- Rules --
      ------------------------
      local tab3_frame =
        info_pane.add {
        type = "flow",
        direction = "vertical"
      }
      tab3_frame.style.vertically_squashable = true
      tab3_frame.style.horizontal_align = "center"

      --tab 3 -- Main
      local tab3_main_frame =
        tab3_frame.add {
        type = "scroll-pane",
        direction = "vertical"
      }
      tab3_main_frame.style.horizontal_align = "right"
      tab3_main_frame.style.padding = 4

      tab3_main_frame.style.horizontally_stretchable = true
      tab3_main_frame.add {
        type = "label",
        caption = ""
      }
      tab3_main_frame.add {
        type = "label",
        caption = "[font=default-large-bold]1: [recipe=cluster-grenade] No griefing, use common sense. Don't be toxic or annoying.[/font]"
      }
      tab3_main_frame.add {
        type = "label",
        caption = ""
      }
      tab3_main_frame.add {
        type = "label",
        caption = "[font=default-large-bold]2: [item=programmable-speaker] Don't advertise or link other servers.[/font]"
      }
      tab3_main_frame.add {
        type = "label",
        caption = ""
      }
      tab3_main_frame.add {
        type = "label",
        caption = "[font=default-large-bold]3: [item=blueprint-book] Read the Welcome, Rules and Membership tabs before asking for help.[/font]"
      }
      tab3_main_frame.add {
        type = "label",
        caption = ""
      }
      tab3_main_frame.add {
        type = "label",
        caption = "[font=default-large-bold]4: [item=repair-pack] Use [/font][font=default-game]report or banish[/font] [font=default-large-bold]if there are problem-players.[/font]"
      }
      tab3_main_frame.add {
        type = "label",
        caption = ""
      }
      tab3_main_frame.add {
        type = "label",
        caption = "[font=default-large-bold]5: [fluid=steam] This is a multiplayer server, try to cooperate with other players.[/font]"
      }
      tab3_main_frame.add {
        type = "label",
        caption = "[font=default-large-bold]   If you want everything your way, go play single player.[/font]"
      }

      --Close Button Frame
      local tab3_close_frame =
        tab3_main_frame.add {
        type = "flow",
        direction = "vertical"
      }
      tab3_close_frame.style.horizontal_align = "right"

      info_pane.add_tab(tab3, tab3_frame)

      ------------------------
      --tab 4 -- Tips & Tricks --
      ------------------------
      local tab4_frame =
        info_pane.add {
        type = "flow",
        direction = "vertical"
      }
      tab4_frame.style.vertically_squashable = true
      tab4_frame.style.horizontal_align = "center"

      --tab 4 -- Main
      local tab4_main_frame =
        tab4_frame.add {
        type = "scroll-pane",
        direction = "vertical"
      }
      tab4_main_frame.style.horizontal_align = "right"
      tab4_main_frame.style.padding = 4

      tab4_main_frame.style.horizontally_stretchable = true
      tab4_main_frame.add {
        type = "label",
        caption = ""
      }
      tab4_main_frame.add {
        type = "label",
        caption = "[font=default-large]You can bookmark servers, by clicking the gear icon in the server browser![/font]"
      }
      local tab4_img2_frame =
        tab4_main_frame.add {
        type = "frame",
        direction = "vertical"
      }
      tab4_img2_frame.add {
        type = "sprite",
        sprite = "file/img/info-win/tips/bookmark.png",
        tooltip = "The gear icon will turn orange, and the bookmarked servers appear first in the list."
      }
      tab4_main_frame.add {
        type = "label",
        caption = ""
      }

      tab4_main_frame.add {
        type = "label",
        caption = "[font=default-large]Map reset, but want to keep playing the old map?[/font]"
      }
      tab4_main_frame.add {
        type = "text-box",
        name = "old_maps",
        text = "http://m45sci.xyz/u/fact/old-maps/",
        tooltip = "drag-select with mouse, control-c to copy."
      }
      tab4_main_frame.old_maps.style.font = "default-large"
      tab4_main_frame.old_maps.style.minimal_width = 350
      tab4_main_frame.add {
        type = "label",
        caption = ""
      }

      tab4_main_frame.add {
        type = "label",
        caption = "[font=default-large]Mod portal down, or slow? Download modpacks here:[/font]"
      }
      tab4_main_frame.add {
        type = "text-box",
        name = "mod_pack",
        text = "http://m45sci.xyz:10001/",
        tooltip = "drag-select with mouse, control-c to copy."
      }
      tab4_main_frame.mod_pack.style.font = "default-large"
      tab4_main_frame.mod_pack.style.minimal_width = 250
      tab4_main_frame.add {
        type = "label",
        caption = ""
      }

      tab4_main_frame.add {
        type = "label",
        caption = "[font=default-large]Download a stand-alone copy of Factorio (no install)![/font]"
      }
      tab4_main_frame.add {
        type = "label",
        caption = "[font=default-large]It is a great way to have multiple versions, or mod-sets![/font]"
      }
      tab4_main_frame.add {
        type = "sprite",
        sprite = "file/img/info-win/tips/dl-fact.png",
        tooltip = "Place the unzipped folder wherever you want!"
      }
      tab4_main_frame.add {
        type = "text-box",
        name = "wube_dl",
        text = "https://factorio.com/download",
        tooltip = "drag-select with mouse, control-c to copy."
      }
      tab4_main_frame.wube_dl.style.font = "default-large"
      tab4_main_frame.wube_dl.style.minimal_width = 250

      info_pane.add_tab(tab4, tab4_frame)

      ---------------
      --- QR CODE ---
      ---------------
      local tab5_frame =
        info_pane.add {
        type = "flow",
        direction = "vertical"
      }

      local tab5_qr_frame =
        tab5_frame.add {
        type = "flow",
        direction = "vertical"
      }
      tab5_qr_frame.style.horizontally_stretchable = true
      tab5_qr_frame.style.vertically_stretchable = true
      tab5_qr_frame.style.horizontal_align = "center"
      tab5_qr_frame.style.vertical_align = "center"
      tab5_qr_frame.add {
        type = "sprite",
        name = "tab1_discord_logo",
        sprite = "file/img/info-win/discord-64.png",
        tooltip = ""
      }
      tab5_qr_frame.add {
        type = "label",
        caption = "Discord: M45-Science"
      }
      tab5_qr_frame.add {
        type = "label",
        caption = ""
      }
      local tab5_qr =
        tab5_qr_frame.add {
        type = "sprite",
        sprite = "file/img/info-win/m45-qr.png",
        tooltip = "Just open camera on a cellphone!"
      }
      tab5_qr_frame.add {
        type = "label",
        caption = ""
      }
      tab5_qr_frame.add {
        type = "label",
        caption = "(links to: https://discord.gg/Ps2jnm7)"
      }

      info_pane.add_tab(tab5, tab5_frame)

      --------------
      --- HELP    ---
      ---------------
      local tab6_frame =
        info_pane.add {
        type = "flow",
        direction = "vertical"
      }

      local tab6_main_frame =
        tab6_frame.add {
        type = "flow",
        direction = "vertical"
      }
      tab6_main_frame.add {
        type = "label",
        caption = ""
      }
      tab6_frame.style.horizontal_align = "center"
      tab6_frame.style.vertical_align = "center"
      tab6_main_frame.add {
        type = "sprite",
        sprite = "file/img/info-win/patreon-64.png"
      }
      tab6_main_frame.add {
        type = "label",
        caption = ""
      }
      tab6_main_frame.add {
        type = "label",
        caption = "[font=default-large-bold]Our patreons keep these servers online![/font]"
      }
      tab6_main_frame.add {
        type = "label",
        caption = "[font=default-large]CPU: Ryzen 9 3900X, 32GB RAM, NVME SSD, Gigabit Fiber[/font]"
      }
      tab6_main_frame.add {
        type = "label",
        caption = "(Rented in a datacenter, in Kansas City, Kansas, USA)"
      }
      tab6_main_frame.add {
        type = "label",
        caption = ""
      }
      tab6_main_frame.add {
        type = "label",
        caption = "[font=default-large]Our server costs are $84/mo USD[/font]"
      }
      tab6_main_frame.add {
        type = "label",
        caption = "[font=default-large]See the link below to find out more:[/font]"
      }
      tab6_main_frame.add {
        type = "label",
        caption = ""
      }
      local tab6_patreon_url =
        tab6_main_frame.add {
        type = "text-box",
        text = "https://www.patreon.com/m45sci",
        name = "patreon_url"
      }
      tab6_patreon_url.style.font = "default-large"
      tab6_patreon_url.style.minimal_width = 300

      tab6_main_frame.add {
        type = "label",
        caption = ""
      }
      tab6_main_frame.add {
        type = "sprite",
        sprite = "file/img/info-win/patreon-qr.png"
      }
      tab6_main_frame.add {
        type = "label",
        caption = "(Or scan this QR Code, it links to the address above)"
      }

      info_pane.add_tab(tab6, tab6_frame)

      info_pane.selected_tab_index = 1
      tab1_discord_sub2_frame.discord_url.focus()
      tab1_discord_sub2_frame.discord_url.select_all()
    end
  end
end

--Process banish votes
local function update_banished_votes()
  --Reset banished list
  local banishedtemp = {}

  --Init if needed
  if not global.banishvotes then
    global.banishvotes = {
      voter = {},
      victim = {},
      reason = {},
      tick = {},
      withdrawn = {},
      overruled = {}
    }
  end

  if not global.thebanished then
    global.thebanished = {}
  end

  --Loop through votes, tally them
  for _, vote in pairs(global.banishvotes) do
    --only if everything seems to exist
    if vote and vote.voter and vote.victim then
      --only if data exists
      if vote.voter.valid and vote.victim.valid then
        --valid defendant
        if is_new(vote.victim) or is_member(vote.victim) then
          --valid voter
          if is_regular(vote.voter) or vote.voter.admin then
            --vote isn't overruled or withdrawn
            if vote.withdrawn == false and vote.overruled == false then
              if banishedtemp[vote.victim.index] then
                banishedtemp[vote.victim.index] = banishedtemp[vote.victim.index] + 1 --Add vote against them
              else
                --was empty, init
                banishedtemp[vote.victim.index] = 1
              end
            end
          end
        end
      end
    end
  end

  --Loop though players, look for matches
  for _, victim in pairs(game.players) do
    local prevstate = is_banished(victim)

    --Add votes to global list, erase old votes
    if banishedtemp[victim.index] then
      global.thebanished[victim.index] = banishedtemp[victim.index]
    else
      global.thebanished[victim.index] = 0 --Erase/init
    end

    --Was banished, but not anymore
    if is_banished(victim) == false and prevstate == true then
      local msg = victim.name .. " is no longer banished."
      print("[REPORT] SYSTEM " .. msg)
      message_all("[color=red](SYSTEM) " .. msg .. "[/color]")

      --Kill them, so items are left behind
      if victim.character and victim.character.valid then
        victim.character.die("player")
      end
      if not global.send_to_surface then
        global.send_to_surface = {}
      end
      local spawnpos = {0, 0}
      if global.cspawnpos and global.cspawnpos.x then
        spawnpos = global.cspawnpos
      end
      table.insert(global.send_to_surface, {victim = victim, surface = "nauvis", position = spawnpos})
    elseif is_banished(victim) == true and prevstate == false then
      --Was not banished, but is now.
      local msg = victim.name .. " has been banished."
      message_all("[color=red](SYSTEM) " .. msg .. "[/color]")
      print("[REPORT] SYSTEM " .. msg)

      --Create area if needed
      if game.surfaces["hell"] == nil then
        local my_map_gen_settings = {
          width = 100,
          height = 100,
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
        game.create_surface("hell", my_map_gen_settings)
      end

      --Kill them, so items are left behind
      if victim.character and victim.character.valid then
        victim.character.die("player")
      end

      if not global.send_to_surface then
        global.send_to_surface = {}
      end
      table.insert(global.send_to_surface, {victim = victim, surface = "hell", position = {0, 0}})
    end
  end
end

--Create player groups if they don't exist, and create global links to them
local function create_groups()
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
local function set_perms()
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
    global.defaultgroup.set_allows_action(defines.input_action.build_rail, false)
    global.defaultgroup.set_allows_action(defines.input_action.activate_paste, false)
    global.defaultgroup.set_allows_action(defines.input_action.flush_opened_entity_fluid, false)
    global.defaultgroup.set_allows_action(defines.input_action.flush_opened_entity_specific_fluid, false)
    global.defaultgroup.set_allows_action(defines.input_action.paste_entity_settings, false)
    global.defaultgroup.set_allows_action(defines.input_action.set_auto_launch_rocket, false)
    global.defaultgroup.set_allows_action(defines.input_action.use_artillery_remote, false)
    global.defaultgroup.set_allows_action(defines.input_action.upgrade, false)
  end
end

--Create globals, if needed
local function create_myglobals()
  if global.restrict == nil then
    global.restrict = true
  end
  if not global.playeractive then
    global.playeractive = {}
  end
  if not global.active_playtime then
    global.active_playtime = {}
  end
  if not global.blueprint_throttle then
    global.blueprint_throttle = {}
  end

  if not global.last_speaker_warning then
    global.last_speaker_warning = 0
  end
  if not global.last_decon_warning then
    global.last_decon_warning = 0
  end

  if not global.corpselist then
    global.corpselist = {tag = {}, tick = {}}
  end
  if not global.banishvotes then
    global.banishvotes = {
      voter = {},
      victim = {},
      reason = {},
      tick = {},
      withdrawn = {},
      overruled = {}
    }
  end
  if not global.thebanished then
    global.thebanished = {}
  end
  if not global.no_fastreplace then
    global.no_fastreplace = false
  end

  --For layout testing
  if not global.todo_list then
    global.todo_list = {
      {priority = 9001, subject = "Main Objective", text = "Destroy All Trees", time = 0, last_user = "Nemaster", can_edit = false, owner = "Nemaster", gps = {x = 0, y = 0}, id = 0, hidden = false}
    }
  end

  if not global.todo_list_id then
    global.todo_list_id = 0
  end

  if not global.vis_todo_count then
    global.vis_todo_count = 1
  end
end

--Create player globals, if needed
local function create_player_globals(player)
  if player and player.valid then
    if global.playeractive and player and player.index then
      if not global.playeractive[player.index] then
        global.playeractive[player.index] = false
      end

      if not global.active_playtime[player.index] then
        global.active_playtime[player.index] = 0
      end

      if not global.blueprint_throttle[player.index] then
        global.blueprint_throttle[player.index] = 0
      end

      if not global.thebanished[player.index] then
        global.thebanished[player.index] = 0
      end
    end
  end
end

--Flag player as currently active
local function set_player_active(player)
  if (player and player.valid and player.connected and player.character and player.character.valid and global.playeractive) then
    --banished players don't get activity score
    if is_banished(player) == false then
      global.playeractive[player.index] = true
    end
  end
end

--Split strings
function mysplit(inputstr, sep)
  if inputstr and sep and inputstr ~= "" then
    local t = {}
    local x = 0

    --Handle nil/empty strings
    if not sep or not inputstr then
      return t
    end
    if sep == "" or inputstr == "" then
      return t
    end

    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
      x = x + 1
      if x > 100 then --Max 100 args
        break
      end

      table.insert(t, str)
    end
    return t
  end
  return {""}
end

--Set our default game-settings
local function game_settings(player)
  if player and player.valid and player.force and not global.gset then
    global.gset = true --Only apply these once
    player.force.friendly_fire = false --friendly fire
    player.force.research_queue_enabled = true --nice to have
    game.disable_replay() --Smaller saves, prevent desync on script upgrade
  end
end

--Automatically promote users to higher levels
local function get_permgroup()
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
                smart_print(player, "[color=red](SYSTEM) You now have access to our 'Regulars' Discord role, and can get access to regulars-only Factorio servers, and Discord channels.[/color]")
                smart_print(player, "[color=red](SYSTEM) Find out more on our Discord server, the link can be copied from the text in the top-left of your screen.[/color]")
                smart_print(player, "[[color=red](SYSTEM) Select text with mouse, then press control-c. Or, just visit https://m45sci.xyz/[/color]")
              end
            elseif (global.active_playtime and global.active_playtime[player.index] and global.active_playtime[player.index] > (30 * 60 * 60) and not player.admin) then
              --Check if player has hours for members status, but isn't a in member group.
              if is_regular(player) == false and is_member(player) == false and is_new(player) == true then
                global.membersgroup.add_player(player)
                message_all(player.name .. " is now a member!")
                smart_print(player, "[color=red](SYSTEM) You have been active enough, that the restrictions on your character have been lifted.[/color]")
                smart_print(player, "[color=red](SYSTEM) You now have access to our 'Members' Discord role![/color]")
                smart_print(player, "[color=red](SYSTEM) Find out more on our Discord server, the link can be copied from the text in the top-left of your screen.[/color]")
                smart_print(player, "[color=red](SYSTEM) Select text with mouse, then press control-c. Or, just visit https://m45sci.xyz/[/color]")
              end
            end
          end
        end
      end
    end
  end
end

--Show players online to a player
function show_players(victim)
  if not global.player_list then
    update_player_list()
  end

  local buf = ""
  local count = 0

  --Cleaned up 12-2020
  for i, target in pairs(global.player_list) do
    buf = buf .. string.format("~%16s: - Score: %d - Online: %dm - (%s)\n", target.victim.name, math.floor(target.score / 60 / 60), math.floor(target.time / 60 / 60), target.type)
  end
  --No one is online
  if global.player_count == 0 then
    smart_print(victim, "No players online.")
  else
    smart_print(victim, "Players Online: " .. global.player_count .. "\n" .. buf)
  end
end

function g_report(player, report)
  if player and player.valid and report then
    --Init limit list if needed
    if not global.reportlimit then
      global.reportlimit = {}
    end

    --Add or init player's limit
    if global.reportlimit[player.index] then
      global.reportlimit[player.index] = global.reportlimit[player.index] + 1
    else
      global.reportlimit[player.index] = 1
    end

    --Limit and list number of reports
    if global.reportlimit[player.index] <= 5 then
      print("[REPORT] " .. player.name .. " " .. report)
      smart_print(player, "Report sent! You have now used " .. global.reportlimit[player.index] .. " of your 5 available reports.")
    else
      smart_print("You are not allowed to send any more reports.")
    end
  else
    smart_print(player, "Usage: /report (your message to moderators here)")
  end
end

function g_banish(player, victim, reason)
  if player and player.valid then
    --Regulars/admins only
    if is_regular(player) or player.admin then
      --Must have arguments
      if victim and reason then
        if victim.name == player.name then
          smart_print(player, "You can't banish yourself. Have you considered therapy?")
          return
        end

        if string.len(reason) < 4 then
          smart_print(player, "You must supply a more descriptive complaint.")
          return
        else
          --Must have valid victim
          if victim and victim.valid and victim.character and victim.character.valid then
            --Victim must be new or member
            if is_new(victim) or is_member(victim) then
              --Check if we already voted against them
              if global.banishvotes and global.banishvotes ~= {} then
                local votecount = 1
                for _, vote in pairs(global.banishvotes) do
                  if vote and vote.voter and vote.victim then
                    --Count player's total votes, cap them
                    if vote.voter == player then
                      votecount = votecount + 1
                    end
                    --Limit number of votes player gets
                    if votecount >= 5 then
                      smart_print(player, "You have exhausted your voting privlege for this map.")
                      return
                    end

                    --Can't vote twice
                    if vote.voter == player and vote.victim == victim then
                      smart_print(player, "You already voted against them!")
                      smart_print(player, "/unbanish <player> to withdraw your vote.")
                      smart_print(player, "[color=red](WARNING) If you withdraw a vote, you CAN NOT reintroduce it.[/color]")
                      return
                    end
                  end
                end

                --Send report to discord and add to vote list
                local message = "[color=red](SYSTEM) " .. player.name .. " voted to banish: " .. victim.name .. " for: " .. reason .. "[/color]"
                message_all(message)
                print("[REPORT] " .. message)
                smart_print(player, "(SYSTEM): Your vote has been added, and posted on Discord!")
                smart_print(player, "/unbanish <player> to withdraw your vote.")
                smart_print(player, "[color=red](WARNING) If you withdraw a vote, you CAN NOT reintroduce it.[/color]")
                smart_print(player, "You have used " .. votecount .. " of your 5 available votes.")
              end

              --Init if needed
              if not global.banishvotes then
                global.banishvotes = {
                  voter = {},
                  victim = {},
                  reason = {},
                  tick = {},
                  withdrawn = {},
                  overruled = {}
                }
              end
              table.insert(
                global.banishvotes,
                {
                  voter = player,
                  victim = victim,
                  reason = reason,
                  tick = game.tick,
                  withdrawn = false,
                  overruled = false
                }
              )
              update_banished_votes() --Must do this to add to tally
            else
              smart_print(player, "You can only vote against new players, or members!")
            end
          else
            smart_print(player, "There are no players online by that name.")
          end
        end
      else
        smart_print(player, "Usage: /banish <player> <reason for banishment>")
      end
    else
      smart_print(player, "This command is for regulars-status players and admins only!")
      return
    end
  else
    smart_print(nil, "The console can't vote.")
  end
end

--Custom commands
script.on_load(
  function()
    --Only add if no commands yet
    if (not commands.commands.server_interface) then
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
            smart_print(player, "options: on, off, perms, fast, nofast")
            return
          elseif param.parameter == "perms" then
            global.setperms = false
            set_perms()

            smart_print(player, "New player perms-restrictions set.")
            return
          elseif param.parameter == "off" then
            global.restrict = false
            smart_print(player, "New player restrictions disabled.")
            return
          elseif param.parameter == "on" then
            global.restrict = true
            smart_print(player, "New player restrictions enabled.")
            return
          elseif param.parameter == "fast" then
            global.no_fastreplace = flase
            smart_print(player, "New player fast-replace is now allowed.")
            return
          elseif param.parameter == "nofast" then
            global.no_fastreplace = true
            smart_print(player, "New player fast-replace is no longer allowed.")
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

      --Damn them!
      commands.add_command(
        "damn",
        "<player>\n(sends player to hell, tfrom <player> to teleport them back out.)",
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

          --Handle console too
          if (player and player.admin) or (not player) then
            if game.surfaces["hell"] == nil then
              local my_map_gen_settings = {
                width = 100,
                height = 100,
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
              game.create_surface("hell", my_map_gen_settings)
            end

            --Only if name provided
            if param.parameter then
              local victim = game.players[param.parameter]

              if (victim and victim.valid and victim.character and victim.character.valid) then
                --If they have a character, kill it to release items
                if victim.character and victim.character.valid then
                  victim.character.die("player")
                end
                if not global.send_to_surface then
                  global.send_to_surface = {}
                end
                table.insert(global.send_to_surface, {victim = victim, surface = "hell", position = {0, 0}})
              else
                smart_print(player, "Couldn't find that player.")
              end
            end
          else
            smart_print(player, "Admins only.")
          end
        end
      )
      --Admin vote overrrule
      commands.add_command(
        "overrule",
        "<defendant>\n(overrule votes against defendant)\n<clear>\n(clear all votes, will unbanish all)",
        function(param)
          if param and param.player_index then
            local player = game.players[param.player_index]

            --Admins only
            if (player and player.admin) then
              if global.banishvotes then
                --get arguments
                local args = mysplit(param.parameter, " ")

                --Must have arguments
                if args ~= {} and args[1] then
                  if args[1] == "clear" then
                    global.banishvotes = nil
                    smart_print(player, "All votes cleared.")
                    update_banished_votes()
                    return
                  end
                  local victim = game.players[args[1]]

                  --If victim found
                  if victim and victim.valid and victim.character and victim.character.valid then
                    local count = 0
                    for _, vote in pairs(global.banishvotes) do
                      if vote and vote.victim and vote.victim.valid then
                        if vote.victim == victim and vote.overruled == false then
                          vote.overruled = true
                          count = count + 1
                        end
                      end
                    end
                    if count > 0 then
                      smart_print(player, "Overruled " .. count .. " votes against " .. victim.name)
                    else
                      for _, vote in pairs(global.banishvotes) do
                        if vote and vote.victim and vote.victim.valid then
                          if vote.victim == victim and vote.overruled == true then
                            vote.overruled = false
                            count = count + 1
                          end
                        end
                      end
                      smart_print(player, "Withdrew " .. count .. " overrulings, against " .. victim.name)
                    end
                    update_banished_votes()
                    return
                  else
                    smart_print(player, "Couldn't find a player by that name.")
                  end
                else
                  smart_print(player, "Who do you want to overrule votes against? <player> or <clear> (clears/unbanishes all)")
                end
              else
                smart_print(player, "There are no votes to overrule.")
              end
            else
              smart_print(player, "Admins only.")
            end
          end
        end
      )

      --Print votes
      commands.add_command(
        "votes",
        "(Shows banish votes)",
        function(param)
          if param and param.player_index then
            local player = game.players[param.player_index]

            --Only if banish data found
            if global.banishvotes then
              --Print votes
              local pcount = 0
              for _, vote in pairs(global.banishvotes) do
                if vote and vote.voter and vote.voter.valid and vote.victim and vote.victim.valid then
                  local notes = ""
                  if vote.withdrawn then
                    notes = "(WITHDRAWN) "
                  end
                  if vote.overruled then
                    notes = "(OVERRULED) "
                  end
                  pcount = pcount + 1
                  smart_print(player, notes .. "plaintiff: " .. vote.voter.name .. ", defendant: " .. vote.victim.name .. ", complaint:\n" .. vote.reason)
                end
              end

              --Tally votes before proceeding
              update_banished_votes()

              --Print accused
              if global.thebanished then
                for _, victim in pairs(game.players) do
                  if global.thebanished[victim.index] and global.thebanished[victim.index] > 1 then
                    smart_print(player, victim.name .. " has had " .. global.thebanished[victim.index] .. " complaints agianst them.")
                    pcount = pcount + 1
                  end
                end
              end
              --Show summery of votes against them
              if global.banishvotes then
                for _, victim in pairs(game.players) do
                  local votecount = 0
                  for _, vote in pairs(global.banishvotes) do
                    if victim == vote.voter then
                      votecount = votecount + 1
                    end
                  end
                  if votecount > 2 then
                    smart_print(player, victim.name .. " has voted against " .. votecount .. " players.")
                    pcount = pcount + 1
                  end
                end
              end
              --Nothing found, report it
              if pcount <= 0 then
                smart_print(player, "The docket is clean.")
              end
              return
            else
              --No vote data
              smart_print(player, "The docket is clean.")
              update_banished_votes()
              return
            end
          end
        end
      )

      --Banish command
      commands.add_command(
        "unbanish",
        "<player>\n(Withdraws a banish vote)",
        function(param)
          if param and param.player_index then
            local player = game.players[param.player_index]
            if player and param.parameter then
              --regulars/admin players only
              if is_regular(player) or player.admin then
                --get arguments
                local args = mysplit(param.parameter, " ")

                --Must have arguments
                if args ~= {} and args[1] then
                  local victim = game.players[args[1]]

                  --Must have valid victim
                  if victim and victim.valid and victim.character and victim.character.valid then
                    --Check if we voted against them
                    if global.banishvotes and global.banishvotes ~= {} then
                      for _, vote in pairs(global.banishvotes) do
                        if vote and vote.voter and vote.victim then
                          if vote.voter == player and vote.victim == victim then
                            --Send report to discord and withdraw vote
                            local message = "[color=red](SYSTEM) " .. player.name .. " WITHDREW their vote to banish: " .. victim.name .. "[/color]"
                            message_all(message)
                            print("[REPORT] " .. message)
                            smart_print(player, "Your vote has been withdrawn, and posted on Discord.")
                            vote.withdrawn = true
                            update_banished_votes() --Must do this to delete from tally
                            return
                          end
                        end
                      end
                      smart_print(player, "I don't see a vote from you, against that player, to withdraw.")
                    end
                  else
                    smart_print(player, "There are no players online by that name.")
                  end
                else
                  smart_print(player, "Usage: /unbanish <player>")
                end
              else
                smart_print(player, "Only regulars/admin status players can vote.")
                return
              end
            else
              smart_print(player, "Usage: /unbanish <player>")
            end
          else
            smart_print(nil, "The console can't vote.")
          end
        end
      )

      --Banish command
      commands.add_command(
        "banish",
        "<player> <reason for banishment>\n(Sends player to a confined area, off-map)",
        function(param)
          if param and param.player_index then
            local player = game.players[param.player_index]

            if not param.parameter then
              smart_print(player, "Banish who?")
              return
            end
            local args = mysplit(param.parameter, " ")
            if not args[2] then
              smart_print(player, "You must specify a reason.")
              return
            end
            local victim = game.players[args[1]]

            --Quick arg combine
            local reason = args[2]
            for n, arg in pairs(args) do
              if n > 2 and n < 100 then -- at least two words, max 100
                reason = reason .. " " .. args[n]
              end
            end
            --TODO, add target/reason code here
            g_banish(player, victim, reason)
          end
        end
      )

      --User report command
      commands.add_command(
        "report",
        "<detailed report here>\n(Sends in a report to the moderators)",
        function(param)
          if param and param.player_index then
            local player = game.players[param.player_index]
            g_report(player, param.parameter)
          else
            smart_print(nil, "The console doesn't need to send in reports this way.")
          end
        end
      )

      --register command
      commands.add_command(
        "register",
        "<code>\n(Requires a registration code)",
        function(param)
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

          smart_print(player, svers)
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
              smart_print(player, "This command is for console and admin use only.")
              return
            end
          end

          --
          --Clear limbo surfaces on reboot, just in case
          --Could actually cause desync if run by admin with very bad timing.
          --
          if param.parameter then
            --Get limbo surface
            local surf = game.surfaces["limbo"]

            --Check if surface is valid
            if surf and surf.valid then
              --Clear surface
              surf.clear()
              console_print("Limbo surface cleared.")
            end

            global.servname = param.parameter
            global.drawlogo = false
            dodrawlogo()

            global.servers = nil
            global.ports = nil
            create_myglobals()

            set_perms()
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
            smart_print(player, "This command is for console use only.")
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
            smart_print(player, "This command is for console use only.")
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
                return
              end
            end
          end
          smart_print(player, "Player not found.")
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
            pforce.set_spawn_position({new_pos_x, new_pos_y}, psurface)
            smart_print(victim, string.format("New spawn point set: %d,%d", math.floor(new_pos_x), math.floor(new_pos_y)))
            smart_print(victim, string.format("Force: %s", pforce.name))
            global.cspawnpos = {
              x = (math.floor(new_pos_x) + 0.5),
              y = (math.floor(new_pos_y) + 0.5)
            }

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
                lefttop = {x = -size / 2, y = -size / 2},
                rightbottom = {x = size / 2, y = size / 2}
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
              if victim and victim.valid then
                pforce = player.force
              end

              --If force found
              if pforce then
                --Calculate walk speed for UPS
                pforce.character_running_speed_modifier = ((1.0 / value) - 1.0)
                smart_print(player, "Game speed: " .. value .. " Walk speed: " .. pforce.character_running_speed_modifier)

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

            --Aegument required
            if param.parameter then
              local str = param.parameter
              local xpos = "0.0"
              local ypos = "0.0"

              --Find surface from argument
              local n = game.surfaces[param.parameter]
              if n then
                surface = n
                local position = {x = xpos, y = ypos}
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
              xpos,
                ypos = str:match("([^,]+),([^,]+)")
              if tonumber(xpos) and tonumber(ypos) then
                local position = {x = xpos, y = ypos}

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

--EVENTS--
--Command logging
local function on_console_command(event)
  if event and event.command and event.parameters then
    local command = ""
    local args = ""

    if event.command then
      command = event.command
    end

    if event.parameters then
      args = event.parameters
    end

    if event.player_index then
      local player = game.players[event.player_index]
      print(string.format("[CMD] NAME: %s, COMMAND: %s, ARGS: %s", player.name, command, args))
    elseif command ~= "time" and command ~= "online" and command ~= "server-save" then --Ignore spammy console commands
      print(string.format("[CMD] NAME: CONSOLE, COMMAND: %s, ARGS: %s", command, args))
    end
  end
end

--Deconstuction planner warning
local function on_player_deconstructed_area(event)
  if event and event.player_index and event.area then
    local player = game.players[event.player_index]
    local area = event.area

    if player and area and area.left_top then
      --Don't bother if selection is zero.
      if area.left_top == area.right_bottom.x and area.left_top.y == area.right_bottom.y then
        local msg = player.name .. " decon [gps=" .. math.floor(area.left_top.x) .. "," .. math.floor(area.left_top.y) .. "] to [gps=" .. math.floor(area.right_bottom.x) .. "," .. math.floor(area.right_bottom.y) .. "]"
        console_print(msg)

        if is_new(player) or is_member(player) then --Dont bother with regulars/admins
          if (global.last_decon_warning and game.tick - global.last_decon_warning >= 60) then
            global.last_decon_warning = game.tick
            message_all("[color=red](SYSTEM)" .. msg .. "[/color]")
          end
        end
      end
    end
  end
end

--Player connected, make variables, draw UI, set permissions, and game settings
local function on_player_joined_game(event)
  update_player_list()

  if event and event.player_index then
    local player = game.players[event.player_index]
    if player then
      create_myglobals()
      create_player_globals(player)
      create_groups()
      game_settings(player)
      set_perms()

      dodrawlogo()

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

      --Refresh open player-online windows
      for _, victim in pairs(game.connected_players) do
        if victim and victim.valid and victim.gui and victim.gui.left and victim.gui.left.m45_online then
          make_m45_online_window(victim)
        end
      end

      if player.gui and player.gui.top then
        --M45 button--

        if player.gui.top.m45_button then
          player.gui.top.m45_button.destroy()
        end
        if not player.gui.top.m45_button then
          local m45_32 =
            player.gui.top.add {
            type = "sprite-button",
            name = "m45_button",
            sprite = "file/img/buttons/m45-32.png",
            tooltip = "Opens the server info window"
          }
          m45_32.style.size = {32, 32}
        end

        --Online button--
        if player.gui.top.online_button then
          player.gui.top.online_button.destroy()
        end
        if not player.gui.top.online_button then
          local online_32 =
            player.gui.top.add {
            type = "sprite-button",
            name = "online_button",
            sprite = "file/img/buttons/online-32.png",
            tooltip = "See players online"
          }
          online_32.style.size = {32, 32}
        end

        --To-Do button--
        if player.gui.top.todo_button then
          player.gui.top.todo_button.destroy()
        end
        if not player.gui.top.todo_button then
          local todo_32 =
            player.gui.top.add {
            type = "sprite-button",
            name = "todo_button",
            sprite = "file/img/buttons/todo-32.png",
            tooltip = "Read or edit the To-Do list."
          }
          todo_32.style.size = {32, 32}
        end
      end

      get_permgroup()
      if player.gui and player.gui.screen and player.gui.screen.m45_info_window then
        player.gui.screen.m45_info_window.destroy()
      end

      if is_new(player) then
        make_m45_online_window(player)
        make_m45_info_window(player)
      end
    end
  end
end

--Auto-Fix text-boxes (no-edit text boxes feel odd)
local function on_gui_text_changed(event)
  -- Automatically fix URLs, because read-only/selectable text is confusing to players --
  if event and event.element and event.player_index and event.text and event.element.name then
    local args = mysplit(event.element.name, ",")
    local player = game.players[event.player_index]

    if event.element.name == "discord_url" then
      event.element.text = "https://discord.gg/Ps2jnm7"
    elseif event.element.name == "old_maps" then
      event.element.text = "http://m45sci.xyz/u/fact/old-maps/"
    elseif event.element.name == "mod_pack" then
      event.element.text = "http://m45sci.xyz:10001/"
    elseif event.element.name == "patreon_url" then
      event.element.text = "https://www.patreon.com/m45sci"
    elseif event.element.name == "wube_dl" then
      event.element.text = "https://factorio.com/download"
    end
  end
end

--Player disconnect messages, with reason (Fact >= v1.1)
local function on_player_left_game(event)
  update_player_list()

  if event and event.player_index and event.reason then
    local player = game.players[event.player_index]
    if player and player.valid then
      --Refresh open player-online windows
      for _, victim in pairs(game.connected_players) do
        if victim and victim.valid and victim.gui and victim.gui.left and victim.gui.left.m45_online then
          make_m45_online_window(victim)
        end
      end

      local reason = {
        "(Quit)",
        "(Dropped)",
        "(Reconnecting)",
        "(WRONG INPUT)",
        "(TOO MANY DESYNC)",
        "(CPU TOO SLOW!!!)",
        "(AFK)",
        "(KICKED)",
        "(KICKED AND DELETED)",
        "(BANNED)",
        "(Switching servers)",
        "(Unknown)"
      }
      message_alld(player.name .. " disconnected. " .. reason[event.reason + 1])
    end
  end
end

--New player created, insert items set perms, show players online, welcome to map.
local function on_player_created(event)
  if event and event.player_index then
    local player = game.players[event.player_index]
    if player and player.valid then
      player.insert {name = "iron-plate", count = 8}
      player.insert {name = "wood", count = 1}
      player.insert {name = "pistol", count = 1}
      player.insert {name = "firearm-magazine", count = 10}
      player.insert {name = "burner-mining-drill", count = 1}
      player.insert {name = "stone-furnace", count = 1}

      set_perms()
      show_players(player)
      message_all("[color=green](SYSTEM) Welcome " .. player.name .. " to the map![/color]")
    end
  end
end

--Build stuff -- activity
local function on_built_entity(event)
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
          stack.clear()
          return
        elseif count > 10000 then
          if created_entity then
            created_entity.destroy()
          end
          stack.clear()
          return
        end
      end

      if created_entity and created_entity.valid then
        if created_entity.name == "programmable-speaker" then
          console_print(player.name .. " placed a speaker at [gps=" .. math.floor(created_entity.position.x) .. "," .. math.floor(created_entity.position.y) .. "]")
          global.last_speaker_warning = game.tick

          if (global.last_speaker_warning and game.tick - global.last_speaker_warning >= 30) then
            if player.admin == false then --Dont bother with admins
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
local function on_player_cursor_stack_changed(event)
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
                smart_print(player, "[color=red](SYSTEM) You are blueprinting too quickly. You must wait " .. round(global.blueprint_throttle[player.index] / 60, 2) .. " seconds before blueprinting again.[/color]")
                player.insert(player.cursor_stack)
                stack.clear()
                return
              end
            end
          end
          if player.admin then
            return
          elseif is_new(player) and count > 500 and global.restrict then --new player limt
            console_print(player.name .. " tried to bp " .. count .. " items (DELETED).")
            smart_print(player, "[color=red](SYSTEM) You aren't allowed to use blueprints that large yet.[/color]")
            stack.clear()
            return
          elseif count > 10000 then --lag protection
            console_print(player.name .. " tried to bp " .. count .. " items (DELETED).")
            smart_print(player, "[color=red](SYSTEM) That blueprint is too large![/color]")
            stack.clear()
            return
          end
        end
      end
    end
  end
end

--Pre-Mined item, block some users
local function on_pre_player_mined_item(event)
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

              --Destroy orignal object.
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
local function on_player_rotated_entity(event)
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

--Create map tag -- log
local function on_chart_tag_added(event)
  if event and event.player_index then
    local player = game.players[event.player_index]

    if player and player.valid and event.tag then
      console_print(player.name .. " + tag [gps=" .. math.floor(event.tag.position.x) .. "," .. math.floor(event.tag.position.y) .. "] " .. event.tag.text)
    end
  end
end

--Edit map tag -- log
local function on_chart_tag_modified(event)
  if event and event.player_index then
    local player = game.players[event.player_index]
    if player and player.valid and event.tag then
      console_print(player.name .. " -+ tag [gps=" .. math.floor(event.tag.position.x) .. "," .. math.floor(event.tag.position.y) .. "] " .. event.tag.text)
    end
  end
end

--Delete map tag -- log
local function on_chart_tag_removed(event)
  if event and event.player_index then
    local player = game.players[event.player_index]

    if player and player.valid and event.tag then
      console_print(player.name .. "- tag [gps=" .. math.floor(event.tag.position.x) .. "," .. math.floor(event.tag.position.y) .. "] " .. event.tag.text)
    end
  end
end

--Banned -- kill player to return items
local function on_player_banned(event)
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

--Corpse Map Marker
local function on_pre_player_died(event)
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

--Research Finished -- discord
local function on_research_finished(event)
  if event and event.research then
    message_alld("Research " .. event.research.name .. " completed.")
  end
end

--GUI clicks
local function on_gui_click(event)
  if event and event.element and event.element.valid and event.player_index then
    local player = game.players[event.player_index]

    local args = mysplit(event.element.name, ",")

    if player and player.valid then
      --Grab target if we have one
      local victim_name
      local victim
      if global.m45_online_submenu_target and global.m45_online_submenu_target[player.index] then
        victim_name = global.m45_online_submenu_target[player.index]
        victim = game.players[victim_name]
      end

      --debug
      console_print("GUI_CLICK: " .. player.name .. ": " .. event.element.name)

      --Info window close
      if event.element.name == "m45_info_close_button" and player.gui and player.gui.center and player.gui.screen.m45_info_window then
        ----------------------------------------------------------------
        --Online sun-menu root
        player.gui.screen.m45_info_window.destroy()
      elseif event.element.name == "m45_online_submenu_close_button" then
        ----------------------------------------------------------------
        --Close online submenu
        if player.gui and player.gui.screen and player.gui.screen.m45_online_submenu then
          player.gui.screen.m45_online_submenu.destroy()
          if global.m45_online_submenu_target then
            global.m45_online_submenu_target[player.index] = nil
          end
        end
      elseif event.element.name == "m45_todo_submenu_close_button" then
        ----------------------------------------------------------------
        --Close online submenu
        if player.gui and player.gui.screen and player.gui.screen.m45_todo_submenu then
          player.gui.screen.m45_todo_submenu.destroy()

          if global.todo_player_editing_id and global.todo_player_editing_id[player.index] then
            local id = global.todo_player_editing_id[player.index]
            global.todo_player_editing_id[player.index] = nil
          end
        end
      elseif args and args[2] and args[1] == "m45_todo_moveup" then
        ----------------------------------------------------------------
        local i = tonumber(args[2])
        if i > 1 then
          table.insert(global.todo_list, i - 1, table.remove(global.todo_list, i))
          update_todo_windows()
        else
          smart_print(player, "It is already the first item!")
        end
        local moved_item = todo_key(i)
        console_print("[TODO] " .. player.name .. " moved item " .. todo_key(i) .. " up.")
      elseif args and args[2] and args[1] == "m45_todo_movedown" then
        ----------------------------------------------------------------
        local i = tonumber(args[2])
        local count = 0
        for _, _ in pairs(global.todo_list) do
          count = count + 1
        end
        if i < count then
          table.insert(global.todo_list, i + 1, table.remove(global.todo_list, i))
          update_todo_windows()
        else
          smart_print(player, "It is already at the end of the list.")
        end
        console_print("[TODO] " .. player.name .. " moved item " .. todo_key(i) .. " down.")
      elseif args and args[2] and args[1] == "m45_todo_gps" then
        ----------------------------------------------------------------
        if player and player.valid and player.character and player.character.valid then
          local i = tonumber(args[2])
          if global.todo_list[i] and global.todo_list[i].gps and global.todo_list[i].gps.x then
            player.zoom_to_world(global.todo_list[i].gps, 0.5)
          else
            smart_print(player, "Invalid location")
          end
        end
      elseif args and args[2] and args[1] == "m45_todo_submenu_edit" then
        ----------------------------------------------------------------
        if player and player.valid and player.character and player.character.valid then
          local i = tonumber(args[2])
          if global.todo_list and global.todo_list[i] then
            --Init if needed
            if not global.todo_player_editing_id then
              global.todo_player_editing_id = {}
            end
            --Save what ID we are editing for updates
            local item = global.todo_list[i]
            global.todo_player_editing_id[player.index] = global.todo_list[i].id
            make_m45_todo_submenu(player, i, true)
          else
            local error = "ERROR: m45_todo_submenu_edit: Unable to find item: " .. i
            smart_print(player, error)
            console_print(error)
          end
        end
      elseif args and args[2] and args[1] == "m45_todo_submenu_view" then
        ----------------------------------------------------------------
        if player and player.valid and player.character and player.character.valid then
          local i = tonumber(args[2])
          if global.todo_list and global.todo_list[i] then
            make_m45_todo_submenu(player, i, false)
          end
        end
      elseif event.element.name == "m45_todo_add" then
        ----------------------------------------------------------------
        if not global.todo_throttle then
          global.todo_throttle = {}
        end

        --edit/create throttle
        if global.todo_throttle[player.index] then
          if game.tick - global.todo_throttle[player.index] < (60 * 10) then --10 seconds
            smart_print(player, "(SYSTEM) Please wait 10 seconds before attempting to make a new item.")
            global.todo_throttle[player.index] = game.tick --Reset timer, prevent spamming
            return
          end
        end
        global.todo_throttle[player.index] = game.tick

        if not global.todo_max then
          global.todo_max = {}
        end
        if global.todo_max[player.index] then
          if global.todo_max[player.index] < 25 then
            global.todo_max[player.index] = global.todo_max[player.index] + 1
          else
            smart_print(player, "You have personally created 25 todo items, limit reached.")
            return
          end
        else
          global.todo_max[player.index] = 1
        end

        global.todo_list_id = global.todo_list_id + 1
        table.insert(global.todo_list, {priority = 0, subject = "new", text = loremipsum, time = game.tick, owner = player.name, last_user = player.name, can_edit = true, id = global.todo_list_id, hidden = false})

        update_vis_todo_count()
        update_todo_windows()
        console_print("[TODO] " .. player.name .. " added a new todo item: " .. todo_key(i))
      elseif args and args[2] and args[1] == "m45_todo_hide" then
        ----------------------------------------------------------------
        local id = tonumber(args[2]) --Grab passed ID
        local i = todo_id_to_index(id) --Find by ID, index can change
        if i > 0 then --If we found the note
          --Sanity check
          if global.todo_list and global.todo_list[i] and player and player.valid and player.gui and player.gui.screen and player.gui.screen.m45_todo_submenu and player.gui.screen.m45_todo_submenu.todo_body and player.gui.screen.m45_todo_submenu.todo_body.todo_text_textbox and player.gui.screen.m45_todo_submenu.todo_body.todo_text_textbox.text then
            if not global.todo_throttle then
              global.todo_throttle = {}
            end
            if global.todo_throttle[player.index] then
              if game.tick - global.todo_throttle[player.index] < (60 * 15) then --15 seconds
                smart_print(player, "[color=red](SYSTEM) CHANGES NOT SAVED, PLEASE WAIT 15 SECONDS BEFORE TRYING TO SAVE AGAIN.[/color]")
                smart_print(player, "[color=cyan](SYSTEM) CHANGES NOT SAVED, PLEASE WAIT 15 SECONDS BEFORE TRYING TO SAVE AGAIN.[/color]")
                smart_print(player, "[color=white](SYSTEM) CHANGES NOT SAVED, PLEASE WAIT 15 SECONDS BEFORE TRYING TO SAVE AGAIN.[/color]")
                global.todo_throttle[player.index] = game.tick --Reset timer so you can't spam.
                return
              end
            else
              --init
              global.todo_throttle[player.index] = game.tick
            end

            --Set timer, hide, update count
            global.todo_throttle[player.index] = game.tick
            global.todo_list[i].hidden = true
            update_vis_todo_count()

            --Log action
            console_print("[TODO] " .. player.name .. " hid todo item: " .. todo_key(i))

            --Destroy window
            player.gui.screen.m45_todo_submenu.destroy()

            --Update windows
            update_todo_windows()

            --We are no longer editing, clear
            global.todo_player_editing_id[player.index] = nil
          else
            --Something is broken
            smart_print(player, "Sorry, something went wrong, unable to delete. Please report this issue.")
          end
        else
          smart_print(player, "Error: Could not find note id: " .. id)
        end
      elseif args and args[2] and args[1] == "m45_todo_save" then
        ----------------------------------------------------------------
        local id = tonumber(args[2]) --Grab passed ID
        local i = todo_id_to_index(id) --Find by ID, index can change
        if i > 0 then --If we found the note
          --Sanity check
          if global.todo_list and global.todo_list[i] and player and player.valid and player.gui and player.gui.screen and player.gui.screen.m45_todo_submenu and player.gui.screen.m45_todo_submenu.todo_body and player.gui.screen.m45_todo_submenu.todo_body.todo_text_textbox and player.gui.screen.m45_todo_submenu.todo_body.todo_text_textbox.text then
            --Store current state
            local prev_priority = global.todo_list[i].priority
            local prev_subject = global.todo_list[i].subject
            local prev_can_edit = global.todo_list[i].can_edit
            local prev_text = global.todo_list[i].text

            --Save new state
            local priority = player.gui.screen.m45_todo_submenu.main.todo_priority_textbox.text
            local subject = player.gui.screen.m45_todo_submenu.main.todo_subject_textbox.text
            local can_edit = (not player.gui.screen.m45_todo_submenu.main.todo_protected.state)
            local text = player.gui.screen.m45_todo_submenu.todo_body.todo_text_textbox.text

            --Only save & archive if something was changed
            if prev_priority ~= priority or prev_subject ~= subject or prev_can_edit ~= can_edit or prev_text ~= text then
              if not global.todo_throttle then
                global.todo_throttle = {}
              end
              if global.todo_throttle[player.index] then
                if game.tick - global.todo_throttle[player.index] < (60 * 15) then --15 seconds
                  smart_print(player, "[color=red](SYSTEM) CHANGES NOT SAVED, PLEASE WAIT 15 SECONDS BEFORE TRYING TO SAVE AGAIN.[/color]")
                  smart_print(player, "[color=cyan](SYSTEM) CHANGES NOT SAVED, PLEASE WAIT 15 SECONDS BEFORE TRYING TO SAVE AGAIN.[/color]")
                  smart_print(player, "[color=white](SYSTEM) CHANGES NOT SAVED, PLEASE WAIT 15 SECONDS BEFORE TRYING TO SAVE AGAIN.[/color]")
                  global.todo_throttle[player.index] = game.tick --Reset timer so you can't spam.
                  return
                end
              else
                --init
                global.todo_throttle[player.index] = game.tick
              end

              --Init if needed
              if not global.todo_list[i].history then
                global.todo_list[i].history = {}
              end
              --Save previous version
              table.insert(global.todo_list[i].history, {priority = global.todo_list[i].priority, subject = global.todo_list[i].subject, text = global.todo_list[i].text, last_user = global.todo_list[i].last_user, time = global.todo_list[i].time})

              --Update & save
              global.todo_list[i].priority = priority
              global.todo_list[i].subject = subject
              global.todo_list[i].can_edit = can_edit
              global.todo_list[i].text = text
              global.todo_list[i].last_user = player.name
              global.todo_list[i].time = game.tick

              global.todo_throttle[player.index] = game.tick

              --Log action
              console_print("[TODO] " .. player.name .. " editied todo item: " .. todo_key(i))

              --Destroy window
              player.gui.screen.m45_todo_submenu.destroy()

              --Update windows
              update_todo_windows()

              --We are no longer editing, clear
              global.todo_player_editing_id[player.index] = nil
            else
              --Nothing changed
              smart_print(player, "No changes to save.")
            end
          else
            --Something is broken
            smart_print(player, "Sorry, something went wrong, unable to save. Please report this issue.")
          end
        else
          smart_print(player, "Error: Could not find note id: " .. id)
        end
      elseif event.element.name == "m45_todo_close_button" then
        ----------------------------------------------------------------
        if player.gui and player.gui.screen then
          if player.gui.screen.m45_todo then
            if global.todo_player_editing_id and global.todo_player_editing_id[player.index] then
              local id = global.todo_player_editing_id[player.index]
              global.todo_player_editing_id[player.index] = nil
            end
            player.gui.screen.m45_todo.destroy()
          end
        end
      elseif args and args[1] == "m45_online_submenu_open" then
        ----------------------------------------------------------------
        --Online sub-menu
        handle_m45_online_submenu(player, args[2])
      elseif event.element.name == "send_whisper" then
        ----------------------------------------------------------------
        if player.gui and player.gui.screen and player.gui.screen.m45_online_submenu and player.gui.screen.m45_online_submenu.main and player.gui.screen.m45_online_submenu.main.whisper_frame and player.gui.screen.m45_online_submenu.main.whisper_frame.whisper_textbox then
          if victim and victim.valid then
            local text = player.gui.screen.m45_online_submenu.main.whisper_frame.whisper_textbox.text
            if text and string.len(text) > 0 then
              --Remove newlines if there are any
              if string.match(text, "\n") then
                text = string.gsub(text, "\n", " ")
              end
              smart_print(player, player.name .. " (whisper): " .. text)
              smart_print(victim, player.name .. " (whisper): " .. text)
            end
            player.gui.screen.m45_online_submenu.main.whisper_frame.whisper_textbox.text = ""

            if not victim.connected then
              smart_print(player, "They aren't online right now, but message will appear in chat history.")
            end
          else
            smart_print(player, "(SYSTEM) That player does not exist.")
          end
        else
          console_print("send_whisper: text-box not found")
        end
      elseif event.element.name == "banish_player" then
        ----------------------------------------------------------------
        if player.gui and player.gui.screen and player.gui.screen.m45_online_submenu and player.gui.screen.m45_online_submenu.main and player.gui.screen.m45_online_submenu.main.banish_frame and player.gui.screen.m45_online_submenu.main.banish_frame.banish_textbox then
          if victim and victim.valid then
            local reason = player.gui.screen.m45_online_submenu.main.banish_frame.banish_textbox.text
            if reason and string.len(reason) > 0 then
              --Remove newlines if there are any
              if string.match(reason, "\n") then
                reason = string.gsub(reason, "\n", " ")
              end
              g_banish(player, victim, reason)
            end
            player.gui.screen.m45_online_submenu.main.banish_frame.banish_textbox.text = ""
          else
            smart_print(player, "(SYSTEM) That player does not exist.")
          end
        else
          console_print("send_whisper: text-box not found")
        end
      elseif event.element.name == "report_player" then
        ----------------------------------------------------------------
        if player.gui and player.gui.screen and player.gui.screen.m45_online_submenu and player.gui.screen.m45_online_submenu.main and player.gui.screen.m45_online_submenu.main.report_frame and player.gui.screen.m45_online_submenu.main.report_frame.report_textbox then
          if victim and victim.valid then
            local reason = player.gui.screen.m45_online_submenu.main.report_frame.report_textbox.text
            if reason and string.len(reason) > 0 then
              --Remove newlines if there are any
              if string.match(reason, "\n") then
                reason = string.gsub(reason, "\n", " ")
              end
              g_report(player, ": " .. victim.name .. ": " .. reason)
            end
            player.gui.screen.m45_online_submenu.main.report_frame.report_textbox.text = ""
          else
            smart_print(player, "(SYSTEM) That player does not exist.")
          end
        else
          console_print("send_whisper: text-box not found")
        end
      elseif event.element.name == "find_on_map" then
        ----------------------------------------------------------------
        if victim and victim.valid then
          player.zoom_to_world(victim.position, 1.0)
        else
          smart_print(player, "Invalid target.")
        end
      elseif event.element.name == "m45_button" then
        ----------------------------------------------------------------
        --Online window toggle
        if player.gui and player.gui.center and player.gui.screen.m45_info_window then
          player.gui.screen.m45_info_window.destroy()
        else
          make_m45_info_window(player)
        end
      elseif event.element.name == "online_button" then
        ----------------------------------------------------------------
        --Online window close
        if player.gui and player.gui.left and player.gui.left.m45_online then
          player.gui.left.m45_online.destroy()
        else
          make_m45_online_window(player)
        end
      elseif event.element.name == "todo_button" then
        ----------------------------------------------------------------
        --Online window close
        if player.gui and player.gui.left and player.gui.left.m45_todo then
          player.gui.left.m45_todo.destroy()
        else
          make_m45_todo_window(player)
        end
      elseif event.element.name == "m45_online_close_button" then
        ----------------------------------------------------------------
        --Close online window
        if player.gui and player.gui.left and player.gui.left.m45_online then
          player.gui.left.m45_online.destroy()
        end
      elseif event.element.name == "patreon_button" and player.gui and player.gui.center and player.gui.screen.m45_info_window then
        ----------------------------------------------------------------
        --QR changetab button (info window)
        player.gui.screen.m45_info_window.m45_info_window_tabs.selected_tab_index = 6
      elseif event.element.name == "qr_button" and player.gui and player.gui.center and player.gui.screen.m45_info_window then
        player.gui.screen.m45_info_window.m45_info_window_tabs.selected_tab_index = 5
      end
    end
  end
end

--Handle killing ,and teleporting users to other surfaces
local function on_player_respawned(event)
  --Anything queued?
  if global.send_to_surface then
    --Event and player?
    if event and event.player_index then
      local player = game.players[event.player_index]

      --Valid player?
      if player and player.valid and player.character and player.character.valid then
        local index = nil
        --Check list
        for i, item in pairs(global.send_to_surface) do
          --Check if item is valid
          if item and item.victim and item.victim.valid and item.victim.character and item.victim.character.valid and item.position and item.surface then
            --Check if names match
            if item.victim.name == player.name then
              --If surface is valid
              local surf = game.surfaces[item.surface]
              if surf and surf.valid then
                local newpos = surf.find_non_colliding_position("character", item.position, 100, 0.1, false)
                if newpos then
                  player.teleport(newpos, surf)
                else
                  player.teleport(item.position, surf) -- screw it
                  console_print("error: send_to_surface(respawn): unable to find non_colliding_position.")
                end
                index = i
                break
              end
            end
          end
        end
        --Remove item we processed
        if index then
          game.print("item removed: " .. index)
          table.remove(global.send_to_surface, index)
        end
      end
    end
  end

  if event and event.player_index then
    local player = game.players[event.player_index]
    if player and player.valid then
      player.insert {name = "firearm-magazine", count = 10}
      player.insert {name = "pistol", count = 1}
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

--Looping timer, 30 seconds
--delete old corpse map pins
--Check spawn area map pin
--Add to player active time if needed
--Refresh players online window

script.on_nth_tick(
  1800,
  function(event)
    update_player_list()

    --Refresh open players-online windows
    for _, victim in pairs(game.connected_players) do
      if victim and victim.valid and victim.gui and victim.gui.left and victim.gui.left.m45_online then
        victim.gui.left.m45_online.destroy()
        make_m45_online_window(victim)
      end
    end

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

--Blueprint throttle countdown
script.on_nth_tick(
  1,
  function(event)
    --game.force_crc()
    --testing only, host server does not trigger join

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
                    player.insert(player.cursor_stack)
                    stack.clear()
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
    --dark_event_handler(event)

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
    end

    --darkness--
    --chunk_charted
    --player_dropped_item
    --built_entity
    --entity_died
  end
)
