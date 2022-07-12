--Carl Frank Otto III
--carlotto81@gmail.com
--GitHub: https://github.com/Distortions81/M45-SoftMod
--License: MPL 2.0
require "utility"

--Create map tag -- log
function on_chart_tag_added(event)
  if event and event.player_index then
    local player = game.players[event.player_index]

    if player and player.valid and event.tag then
      console_print(
        "[ACT] " .. player.name ..
        " add-tag [gps=" ..
        math.floor(event.tag.position.x) .. "," .. math.floor(event.tag.position.y) .. "] " .. event.tag.text
      )
    end
  end
end

--Edit map tag -- log
function on_chart_tag_modified(event)
  if event and event.player_index then
    local player = game.players[event.player_index]
    if player and player.valid and event.tag then
      console_print(
        "[ACT] " .. player.name ..
        " mod-tag [gps=" ..
        math.floor(event.tag.position.x) .. "," .. math.floor(event.tag.position.y) .. "] " .. event.tag.text
      )
    end
  end
end

--Delete map tag -- log
function on_chart_tag_removed(event)
  if event and event.player_index then
    local player = game.players[event.player_index]

    --Because factorio will hand us an nil event... nice.
    if player and player.valid and event.tag then
      console_print(
        "[ACT] " .. player.name ..
        " del-tag [gps=" ..
        math.floor(event.tag.position.x) .. "," .. math.floor(event.tag.position.y) .. "] " .. event.tag.text
      )

      --Delete corpse map tag and corpse_lamp
      for i, ctag in pairs(global.corpselist) do
        if ctag.tag and ctag.tag.valid then
          if event.tag.text == ctag.tag.text and ctag.pos.x == event.tag.position.x and
              ctag.pos.y == event.tag.position.y
          then
            --Destroy corpse lamp
            rendering.destroy(ctag.corpse_lamp)

            index = i
            break
          end
        end
      end

      --Properly remove items
      if global.corpselist and index then
        table.remove(global.corpselist, index)
      end
    end
  end
end

--Player disconnect messages, with reason (Fact >= v1.1)
function on_player_left_game(event)

  if event and event.player_index and event.reason then
    local player = game.players[event.player_index]
    if player then


      if global.last_playtime then
        global.last_playtime[event.player_index] = game.tick
      end

      local reason = {
        "(quit)",
        "(dropped)",
        "(reconnecting)",
        "(wrong input)",
        "(too many desync)",
        "(cannot keep up)",
        "(afk)",
        "(kicked)",
        "(kicked and deleted)",
        "(banned)",
        "(switching servers)",
        "(unknown reason)"
      }
      message_alld(player.name .. " disconnected. " .. reason[event.reason + 1])

      update_player_list() --online.lua
      return
    end
  end


  local player = game.players[event.player_index]
  update_player_list() --online.lua
  message_alld(player.name .. " disconnected!")
end

--Deconstruction planner warning
function on_player_deconstructed_area(event)
  if event and event.player_index and event.area then
    local player = game.players[event.player_index]
    local area = event.area

    if player and area and area.left_top then
      local decon_size = dist_to(area.left_top, area.right_bottom)

      --Don't bother if selection is zero.
      if decon_size >= 1 then
        local msg =
        "[ACT] " .. player.name ..
            " deconstructing [gps=" ..
            math.floor(area.left_top.x) ..
            "," ..
            math.floor(area.left_top.y) ..
            "] to [gps=" ..
            math.floor(area.right_bottom.x) ..
            "," ..
            math.floor(area.right_bottom.y) .. "] AREA: " .. math.floor(decon_size * decon_size) .. "sq"
        console_print(msg)

        if is_new(player) or is_member(player) then --Dont bother with regulars/moderators
          if (global.last_decon_warning and game.tick - global.last_decon_warning >= 60) then
            global.last_decon_warning = game.tick
            gsysmsg(msg)
          end
        end
      end
    end
  end
end

--EVENTS--
--Command logging
function on_console_command(event)
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
    elseif command ~= "time" and command ~= "online" and command ~= "server-save" and command ~= "p" then --Ignore spammy console commands
      print(string.format("[CMD] NAME: CONSOLE, COMMAND: %s, ARGS: %s", command, args))
    end
  end
end

--Research Finished -- discord
function on_research_finished(event)
  if event and event.research and not event.by_script then
    if event.research.level and event.research.level > 1 then
      message_alld("Research " .. event.research.name .. " (level " .. event.research.level - 1 .. ") completed.")
    else
      message_alld("Research " .. event.research.name .. " completed.")
    end
  end
end
