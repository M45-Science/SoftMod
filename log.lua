--Carl Frank Otto III
--carlotto81@gmail.com
require "util"

--Create map tag -- log
function on_chart_tag_added(event)
  if event and event.player_index then
    local player = game.players[event.player_index]

    if player and player.valid and event.tag then
      console_print(player.name .. " + tag [gps=" .. math.floor(event.tag.position.x) .. "," .. math.floor(event.tag.position.y) .. "] " .. event.tag.text)
    end
  end
end

--Edit map tag -- log
function on_chart_tag_modified(event)
  if event and event.player_index then
    local player = game.players[event.player_index]
    if player and player.valid and event.tag then
      console_print(player.name .. " -+ tag [gps=" .. math.floor(event.tag.position.x) .. "," .. math.floor(event.tag.position.y) .. "] " .. event.tag.text)
    end
  end
end

--Delete map tag -- log
function on_chart_tag_removed(event)
  if event and event.player_index then
    local player = game.players[event.player_index]

    if player and player.valid and event.tag then
      console_print(player.name .. "- tag [gps=" .. math.floor(event.tag.position.x) .. "," .. math.floor(event.tag.position.y) .. "] " .. event.tag.text)
    end
  end
end

--Player disconnect messages, with reason (Fact >= v1.1)
function on_player_left_game(event)
  update_player_list() --online.lua

  if event and event.player_index and event.reason then
    local player = game.players[event.player_index]
    if player and player.valid then
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

--Deconstruction planner warning
function on_player_deconstructed_area(event)
  if event and event.player_index and event.area then
    local player = game.players[event.player_index]
    local area = event.area

    if player and area and area.left_top then

      local decon_size = dist_to(area.left_top, area.right_bottom )
      
      --Don't bother if selection is zero.
      if decon_size >= 1 then
        local msg = player.name .. " deconstructing [gps=" .. math.floor(area.left_top.x) .. "," .. math.floor(area.left_top.y) .. "] to [gps=" .. math.floor(area.right_bottom.x) .. "," .. math.floor(area.right_bottom.y) .. "] AREA: "..math.floor(decon_size*decon_size).."sq"
        console_print(msg)

        if is_new(player) or is_member(player) then --Dont bother with regulars/admins
          if (global.last_decon_warning and game.tick - global.last_decon_warning >= 60) then
            global.last_decon_warning = game.tick
            message_all("[color=red](SYSTEM) " .. msg.."[/color]")
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
    elseif command ~= "time" and command ~= "online" and command ~= "server-save" then --Ignore spammy console commands
      print(string.format("[CMD] NAME: CONSOLE, COMMAND: %s, ARGS: %s", command, args))
    end
  end
end

--Research Finished -- discord
function on_research_finished(event)
  if event and event.research then
    message_alld("Research " .. event.research.name .. " completed.")
  end
end
