--Carl Frank Otto III
--carlotto81@gmail.com
require "utility"

function make_info_button(player)
  if player.gui.top.m45_button then
    player.gui.top.m45_button.destroy()
  end
  if not player.gui.top.m45_button then
    local m45_32 =
      player.gui.top.add {
      type = "sprite-button",
      name = "m45_button",
      sprite = "file/img/buttons/m45-64.png",
      tooltip = "Opens the server info window"
    }
    m45_32.style.size = {64, 64}
  end
end

--M45 Info/Welcome window
function make_m45_info_window(player)
  --M45 Welcome--
  if player.gui.center then
    if player.gui.screen.m45_info_window then
      player.gui.screen.m45_info_window.destroy()
    end
    if not player.gui.screen.m45_info_window then
      if not global.info_window_timer then
        global.info_window_timer = {}
      end
      if not global.info_window_timer[player.index] then
        global.info_window_timer[player.index] = game.tick
      end

      local main_flow =
        player.gui.screen.add {
        type = "frame",
        name = "m45_info_window",
        direction = "vertical"
      }
      main_flow.style.horizontal_align = "center"
      main_flow.style.vertical_align = "center"
      main_flow.force_auto_center()

      --Info Title Bar--
      local info_titlebar =
        main_flow.add {
        type = "flow",
        direction = "horizontal"
      }
      info_titlebar.drag_target = main_flow
      info_titlebar.style.horizontal_align = "center"
      info_titlebar.style.horizontally_stretchable = true

      if global.servname == "" then
        info_titlebar.add {
          type = "label",
          name = "online_title",
          style = "frame_title",
          caption = "M45 Science, a gaming community."
        }
      else
        info_titlebar.add {
          type = "label",
          name = "online_title",
          style = "frame_title",
          caption = "Server Name: " .. global.servname
        }
      end
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
        caption = global.svers
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
        caption = "[color=purple]Hawkeey[/color]"
      }
      tab1_lframe.add {
        type = "label",
        caption = "[color=purple]BigDogTV[/color]"
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
        caption = "[color=purple]HanBai[/color]"
      }
      tab1_lframe.add {
        type = "label",
        caption = "[color=purple]GeneralSnipe[/color]"
      }
      tab1_lframe.add {
        type = "label",
        caption = "[color=purple]Lionheart[/color]"
      }
      tab1_lframe.add {
        type = "label",
        caption = "[color=purple]CM42[/color]"
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
      if global.resetint then
        local reset_warning =
          tab1_info_top.add {
          type = "label",
          caption = "[virtual-signal=signal-everything]  [color=red][font=default-large-bold]MAP RESETS " .. string.upper(global.resetint) .. "[/font][/color]"
        }
      end
      local restrictions =
        tab1_info_top.add {
        type = "label",
        caption = "[entity=character]  [color=red][font=default-large-bold]New players start with some restrictions![/font][/color]"
      }
      local perms_limit =
        tab1_info_top.add {
        type = "label",
        caption = "[item=locomotive]  [font=default-large]You will also not be allowed to modify trains or logistics.[/font]"
      }
      local friendly_fire =
        tab1_info_top.add {
        type = "label",
        caption = "[recipe=combat-shotgun] [font=default-large]Friendly fire is off, for players and buildings.[/font]"
      }
      tab1_info_top.add {
        type = "label",
        caption = ""
      }
      tab1_info_top.add {
        type = "label",
        caption = "[font=default-large]Click the '[item=automation-science-pack] Membership' tab above, to find out how to become a member.[/font]"
      }
      tab1_info_top.add {
        type = "label",
        caption = ""
      }

      --Contextual editing
      if player.force.friendly_fire then
        friendly_fire.caption = "Friendly fire is currently ON (normally off)."
      end
      if global.defaultgroup and global.defaultgroup.allows_action(defines.input_action.drag_train_schedule) then
        perms_limit.caption = "New players are currently allowed to use trains and logistics (normally off)."
      end

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
        text = "https://discord.gg/rQANzBheVh",
        tooltip = "(if not selected), drag-select with mouse, control-c to copy."
      }
      --URL Style
      tab1_discord_sub2_frame.discord_url.style.font = "default-large"
      tab1_discord_sub2_frame.discord_url.style.minimal_width = 350

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
        caption = "[recipe=inserter]   [font=default-bold]New players have these permissions limitations:[/font]"
      }
      tab2_main_frame.add {
        type = "label",
        caption = "Modify wires, trains, combinators, signals, speakers, launch rockets or edit logistics."
      }
      tab2_main_frame.add {
        type = "label",
        caption = "Level 3 players (regulars) can banish you with 1 vote."
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
        caption = "[recipe=fast-inserter]   Permissions restrictions are lifted."
      }
      tab2_main_frame.add {
        type = "label",
        caption = "Votes needed to banish you increases to 2. Access to deconstruction planner (warns other players, with location)."
      }
      tab2_main_frame.add {
        type = "label",
        caption = "Access to members-only servers."
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
        caption = "[recipe=stack-inserter]   Allowed to vote-banish other players."
      }
      tab2_main_frame.add {
        type = "label",
        caption = "Deconstruction planner warning removed."
      }
      tab2_main_frame.add {
        type = "label",
        caption = "tinyurl.com/ycktpy45"
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
        caption = "(links to: https://discord.gg/rQANzBheVh)"
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

--GUI clicks
function on_gui_click(event)
  if event and event.element and event.element.valid and event.player_index then
    local player = game.players[event.player_index]

    local args = mysplit(event.element.name, ",")

    if player and player.valid then
      --debug
      console_print("GUI_CLICK: " .. player.name .. ": " .. event.element.name)

      --Info window close
      if event.element.name == "m45_info_close_button" and player.gui and player.gui.center and player.gui.screen.m45_info_window then
        if not global.info_window_timer then
          global.info_window_timer = {}
        end
        if not global.info_window_timer[player.index] then
          global.info_window_timer[player.index] = game.tick
        end
        ----------------------------------------------------------------
        if is_member(player) or is_regular(player) or player.admin or (is_new(player) and game.tick - global.info_window_timer[player.index] > (60 * 10)) then
          player.gui.screen.m45_info_window.destroy()
        else
          smart_print(player, "[color=red](SYSTEM) *** PLEASE READ THE INFO WINDOW BEFORE CLOSING IT!!! ***[/color]")
          smart_print(player, "[color=green](SYSTEM) **** PLEASE READ THE INFO WINDOW BEFORE CLOSING IT!!! ****[/color]")
          smart_print(player, "[color=blue](SYSTEM) ***** PLEASE READ THE INFO WINDOW BEFORE CLOSING IT!!! *****[/color]")
        end
      elseif event.element.name == "patreon_button" and player.gui and player.gui.center and player.gui.screen.m45_info_window then
        ----------------------------------------------------------------
        --QR changetab button (info window)
        player.gui.screen.m45_info_window.m45_info_window_tabs.selected_tab_index = 6
      elseif event.element.name == "qr_button" and player.gui and player.gui.center and player.gui.screen.m45_info_window then
        --QR Discord button
        player.gui.screen.m45_info_window.m45_info_window_tabs.selected_tab_index = 5
      elseif event.element.name == "m45_button" then
        ----------------------------------------------------------------
        --Online window toggle
        if player.gui and player.gui.center and player.gui.screen.m45_info_window then
          player.gui.screen.m45_info_window.destroy()
        else
          make_m45_info_window(player)
        end
      end
    end
  end
end

--Auto-Fix text-boxes (no-edit text boxes feel odd)
function on_gui_text_changed(event)
  -- Automatically fix URLs, because read-only/selectable text is confusing to players --
  if event and event.element and event.player_index and event.text and event.element.name then
    local args = mysplit(event.element.name, ",")
    local player = game.players[event.player_index]

    if event.element.name == "discord_url" then
      event.element.text = "https://discord.gg/rQANzBheVh"
    elseif event.element.name == "old_maps" then
      event.element.text = "http://m45sci.xyz/u/fact/old-maps/"
    elseif event.element.name == "patreon_url" then
      event.element.text = "https://www.patreon.com/m45sci"
    elseif event.element.name == "wube_dl" then
      event.element.text = "https://factorio.com/download"
    end
  end
end
