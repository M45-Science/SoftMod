-- Carl Frank Otto III
-- carlotto81@gmail.com
-- GitHub: https://github.com/M45-Science/SoftMod
-- License: MPL 2.0

function INFO_MakeClock(player)
    -- Online button--
    if player.gui.top.reset_clock then
        player.gui.top.reset_clock.destroy()
    end
    if not player.gui.top.reset_clock then
        local rclock = player.gui.top.add {
            type = "button",
            name = "reset_clock",
            style = "red_button",
            tooltip = {"strings.reset_clock_tooltip"},
            visible = false,
        }

        UTIL_DrawMapClock(player)
    end
end

function INFO_MakeButton(player)
    if player.gui.top.m45_button then
        player.gui.top.m45_button.destroy()
    end
    if not player.gui.top.m45_button then
        local m45_32 = player.gui.top.add {
            type = "sprite-button",
            name = "m45_button",
            sprite = "file/img/buttons/m45-64.png",
            tooltip = {"strings.m45_button_tooltip"}
        }
        m45_32.style.size = { 64, 64 }
    end
end

-- M45 Info/Welcome window
function INFO_InfoWin(player)
    -- M45 Welcome--

    -- Auto close membership welcome window--
    if player then
        if player.gui.screen then
            if player.gui.screen.member_welcome then
                if not player.gui.screen.m45_info_window then
                    player.gui.screen.member_welcome.destroy()
                end
            end
        else
            return
        end
    else
        return
    end

    if player.gui.center then
        if player.gui.screen.m45_info_window then
            player.gui.screen.m45_info_window.destroy()
        end
        if not player.gui.screen.m45_info_window then
            local main_flow = player.gui.screen.add {
                type = "frame",
                name = "m45_info_window",
                direction = "vertical"
            }
            main_flow.style.horizontal_align = "center"
            main_flow.style.vertical_align = "center"
            main_flow.force_auto_center()

            -- Info Title Bar--
            local info_titlebar = main_flow.add {
                type = "flow",
                direction = "horizontal"
            }
            info_titlebar.drag_target = main_flow
            info_titlebar.style.horizontal_align = "center"
            info_titlebar.style.horizontally_stretchable = true

            if storage.SM_Store.serverName == "" then
                info_titlebar.add {
                    type = "label",
                    name = "online_title",
                    style = "frame_title",
                    caption = {"strings.info_title_welcome"}
                }
            else
                info_titlebar.add {
                    type = "label",
                    name = "online_title",
                    style = "frame_title",
                    caption = {"", {"strings.info_title_map"}, " ", storage.SM_Store.serverName}
                }
            end
            local pusher = info_titlebar.add {
                type = "empty-widget",
                style = "draggable_space_header"
            }

            info_titlebar.add {
                type = "label",
                name = "online_title_note",
                style = "frame_title",
                caption = {"strings.info_title_note"}
            }

            pusher.style.vertically_stretchable = true
            pusher.style.horizontally_stretchable = true
            pusher.drag_target = main_flow

            info_titlebar.add {
                type = "sprite-button",
                name = "m45_info_close_button",
                sprite = "utility/close",
                style = "frame_action_button",
                tooltip = {"strings.info_close_tooltip"}
            }

            local info_pane = main_flow.add {
                type = "tabbed-pane",
                name = "m45_info_window_tabs"
            }
            info_pane.style.minimal_width = 725

            local tab1 = info_pane.add {
                type = "tab",
                caption = {"", "[virtual-signal=signal-info] ", {"strings.info_tab_welcome"}}
            }
            local tab2 = info_pane.add {
                type = "tab",
                caption = {"", "[entity=item-request-proxy] ", {"strings.info_tab_membership"}}
            }
            local tab3 = info_pane.add {
                type = "tab",
                caption = {"", "[virtual-signal=signal-deny] ", {"strings.info_tab_rules"}}
            }
            local tab5 = info_pane.add {
                type = "tab",
                caption = {"", "[item=lab] ", {"strings.info_tab_discord"}}
            }
            local tab6 = info_pane.add {
                type = "tab",
                caption = {"", "[item=production-science-pack] ", {"strings.info_tab_patreon"}}
            }

            -- Tab 1 -- Welcome
            local tab1_frame = info_pane.add {
                type = "flow",
                direction = "vertical"
            }
            tab1_frame.style.horizontal_align = "center"

            -- Tab 1 -- Main
            local tab1_main_frame = tab1_frame.add {
                type = "flow",
                direction = "horizontal"
            }

            -- Tab 1 left-frame logo-patreons
            local tab1_lframe = tab1_main_frame.add {
                type = "flow",
                direction = "vertical"
            }
            tab1_lframe.style.padding = 4
            tab1_lframe.add {
                type = "sprite",
                sprite = "file/img/info-win/m45-128.png",
                tooltip = ""
            }
            local m45_label = tab1_lframe.add {
                type = "label",
                caption = {"strings.info_m45_science"}
            }
            m45_label.style.font = "default-large-bold"
            tab1_lframe.add {
                type = "label",
                caption = " "
            }

            -- PATREON
            if storage.SM_Store.patreonCredits[1] then
                local supporters_label = tab1_lframe.add {
                    type = "label",
                    caption = {"strings.info_supporters"}
                }
                supporters_label.style.font_color = { r = 0.5, g = 0, b = 0.5 }
                local i = 1
                while storage.SM_Store.patreonCredits[i] do
                    if storage.SM_Store.patreonCredits[i + 1] then
                        tab1_lframe.add {
                            type = "label",
                            caption = "[color=purple]" .. storage.SM_Store.patreonCredits[i] .. ", " .. storage.SM_Store.patreonCredits[i + 1] ..
                                "[/color]"
                        }
                        i = i + 1
                    else
                        tab1_lframe.add {
                            type = "label",
                            caption = "[color=purple]" .. storage.SM_Store.patreonCredits[i] .. "[/color]"
                        }
                    end
                    i = i + 1
                end
            end

            tab1_lframe.add {
                type = "label",
                caption = ""
            }

            -- NITRO
            if storage.SM_Store.nitroCredits[1] then
                local nitro_label = tab1_lframe.add {
                    type = "label",
                    caption = {"strings.info_discord_nitro"}
                }
                nitro_label.style.font_color = { r = 0, g = 1, b = 1 }
                local i = 1
                while storage.SM_Store.nitroCredits[i] do
                    if storage.SM_Store.nitroCredits[i + 1] then
                        tab1_lframe.add {
                            type = "label",
                            caption = "[color=cyan]" .. storage.SM_Store.nitroCredits[i] .. ", " .. storage.SM_Store.nitroCredits[i + 1] ..
                                "[/color]"
                        }
                        i = i + 1
                    else
                        tab1_lframe.add {
                            type = "label",
                            caption = "[color=cyan]" .. storage.SM_Store.nitroCredits[i] .. "[/color]"
                        }
                    end
                    i = i + 1
                end
            end
            tab1_lframe.add {
                type = "label",
                caption = ""
            }
            tab1_lframe.style.horizontal_align = "center"

            -- Tab 1 -- left/right divider line
            tab1_main_frame.add {
                type = "line",
                direction = "vertical"
            }

            -- Tab 1 right-frame
            local tab1_rframe = tab1_main_frame.add {
                type = "flow",
                direction = "vertical"
            }
            -- Tab 1 Center -- Info
            local tab1_info_center = tab1_main_frame.add {
                type = "flow",
                direction = "vertical"
            }
            tab1_info_center.style.horizontal_align = "center"

            tab1_info_center.style.horizontally_stretchable = true
            local tip1 = tab1_info_center.add {
                type = "label",
                caption = {"strings.info_regulars_tip1"}
            }
            tip1.style.font = "default-large-bold"
            tip1.style.font_color = { r = 1, g = 0.55, b = 0 }
            tab1_info_center.add {
                type = "sprite",
                sprite = "file/img/info-win/tips/onetwothree.png"
            }
            local tip2 = tab1_info_center.add {
                type = "label",
                caption = {"", {"strings.info_regulars_tip2"}, " [item=rocket-launcher]"}
            }
            tip2.style.font = "default-large-bold"
            tip2.style.font_color = { r = 1, g = 0.55, b = 0 }
            tab1_info_center.add {
                type = "label",
                caption = " "
            }
            tab1_info_center.add {
                type = "label",
                caption = "M45-SoftMod"
            }
            tab1_info_center.add {
                type = "label",
                caption = "v" .. storage.SM_Version
            }

            local tab1_cframe = { tab1_main_frame.add {
                type = "flow",
                direction = "vertical"
            } }
            tab1_rframe.style.horizontal_align = "right"
            tab1_rframe.style.vertical_align = "bottom"
            tab1_rframe.style.padding = 4

            -- Tab 1 Main -- New Player Warning
            local tab1_info_top = tab1_rframe.add {
                type = "flow",
                direction = "vertical"
            }
            tab1_info_top.style.horizontally_stretchable = true
            if storage.SM_Store.resetDate and storage.SM_Store.resetDate ~= "" then
                tab1_info_top.add {
                    type = "label",
                    caption = "[virtual-signal=signal-everything]  [color=orange][font=default-large-bold]Next map reset: " ..
                        string.upper(storage.SM_Store.resetDate) .. "[/font][/color]"
                }
            else
                tab1_info_top.add {
                    type = "label",
                    caption = "[virtual-signal=signal-everything]  [color=orange][font=default-large-bold]No map reset is currently scheduled.[/font][/color]"
                }
            end
            if storage.SM_Store.resetDuration and storage.SM_Store.resetDuration ~= "" then
                tab1_info_top.add {
                    type = "label",
                    caption = "[virtual-signal=signal-everything]  [color=orange][font=default-large-bold]Map will reset in: " ..
                        string.upper(storage.SM_Store.resetDuration) .. "[/font][/color]"
                }
            end
            tab1_info_top.add {
                type = "label",
                caption = "[entity=character]  [color=yellow][font=default-large-bold]New recruits have some restrictions.[/font][/color]"
            }
            local friendly_fire = tab1_info_top.add {
                type = "label",
                caption = "[recipe=combat-shotgun] [font=default-large-bold]Friendly fire is OFF; your buddies and bases are safe.[/font]"
            }
            if storage.SM_Store.oneLifeMode then
                tab1_info_top.add {
                    type = "label",
                    caption = "[color=red][font=default-large-bold]THIS SERVER IS PERMA-DEATH. YOU HAVE ONE LIFE TO LIVE PER MAP![/font][/color]"
                }
            elseif storage.SM_Store.noBlueprints then
                tab1_info_top.add {
                    type = "label",
                    caption = "[color=cyan][font=default-large-bold]BLUEPRINTS ARE DISABLED! BUILD STUFF ON YOUR OWN![/font][/color]"
                }
            elseif storage.SM_Store.cheats then
                tab1_info_top.add {
                    type = "label",
                    caption = "[color=red][font=default-large-bold]CHEATS ARE ENABLED![/font][/color]"
                }
            end

            -- Contextual editing
            if player.force.friendly_fire then
                friendly_fire.caption = "[recipe=combat-shotgun] [font=default-large-bold]Friendly fire is ON.[/font]"
            end

            -- server list URL
            tab1_info_top.add {
                type = "label",
                caption = ""
            }
            local maps_label = tab1_info_top.add {
                type = "label",
                caption = {"strings.info_other_maps_label"}
            }
            maps_label.style.font = "default-large"
            tab1_info_top.add {
                type = "text-box",
                name = "server_list",
                text = "http://factorio.go-game.net/?tag=M45",
                tooltip = {"strings.copy_tooltip"}
            }
            tab1_info_top.server_list.style.font = "default-large"
            tab1_info_top.server_list.style.minimal_width = 350
            tab1_info_top.add {
                type = "label",
                caption = "  "
            }
            -- relay url
            local relay_label = tab1_info_top.add {
                type = "label",
                caption = {"strings.info_relay_label"}
            }
            relay_label.style.font = "default-large"
            tab1_info_top.add {
                type = "text-box",
                name = "relay_url",
                text = "http://eu.m45sci.xyz",
                tooltip = {"strings.copy_tooltip"}
            }
            tab1_info_top.relay_url.style.font = "default-large"
            tab1_info_top.relay_url.style.minimal_width = 350
            tab1_info_top.add {
                type = "label",
                caption = "  "
            }

            -- localization contribution url
            local locale_label = tab1_info_top.add {
                type = "label",
                caption = {"strings.info_locale_label"}
            }
            locale_label.style.font = "default-large"
            tab1_info_top.add {
                type = "text-box",
                name = "locale_url",
                text = "https://github.com/M45-Science/SoftMod/tree/main/locale",
                tooltip = {"strings.copy_tooltip"}
            }
            tab1_info_top.locale_url.style.font = "default-large"
            tab1_info_top.locale_url.style.minimal_width = 500
            tab1_info_top.add {
                type = "label",
                caption = "  "
            }

            -- Tab 1 Main -- Discord
            local tab1_discord_frame = tab1_rframe.add {
                type = "frame",
                direction = "vertical"
            }
            tab1_discord_frame.style.horizontally_stretchable = true
            tab1_discord_frame.style.vertically_squashable = true
            local tab1_discord_sub1_frame = tab1_discord_frame.add {
                type = "flow",
                direction = "vertical"
            }

            -- Tab 1 Main -- Discord -- Info Text
            local commands_tip = tab1_discord_sub1_frame.add {
                type = "label",
                caption = {"strings.info_commands_tip"}
            }
            commands_tip.style.font = "default-large-bold"
            local commands_usage = tab1_discord_sub1_frame.add {
                type = "label",
                caption = {"strings.info_commands_usage"}
            }
            commands_usage.style.font = "default-large"
            local commands_newmap = tab1_discord_sub1_frame.add {
                type = "label",
                caption = {"strings.info_commands_newmap"}
            }
            commands_newmap.style.font = "default-large"
            local commands_web = tab1_discord_sub1_frame.add {
                type = "label",
                caption = {"strings.info_commands_website"}
            }
            commands_web.style.font = "default-large"

            -- Tab 1 Main -- Discord -- Logo/URL frame
            local tab1_discord_sub2_frame = tab1_discord_sub1_frame.add {
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
                tooltip = {"strings.copy_tooltip"}
            }

            -- URL Style
            tab1_discord_sub2_frame.discord_url.style.font = "default-large"
            tab1_discord_sub2_frame.discord_url.style.minimal_width = 350

            tab1_discord_sub2_frame.add {
                type = "label",
                caption = "  "
            }

            -- Tab 1 Main -- Discord -- Bottom Info Text
            tab1_discord_sub2_frame.add {
                type = "button",
                caption = {"strings.info_get_qr"},
                style = "rounded_button",
                name = "qr_button"
            }
            info_pane.add_tab(tab1, tab1_frame)

            ------------------------
            -- TAB 2 -- MEMBERSHIP --
            ------------------------
            local tab2_frame = info_pane.add {
                type = "flow",
                direction = "vertical"
            }
            tab2_frame.style.vertically_squashable = true
            tab2_frame.style.horizontal_align = "center"

            -- tab 2 -- Main
            local tab2_main_frame = tab2_frame.add {
                type = "scroll-pane",
                direction = "vertical"
            }
            tab2_main_frame.style.horizontal_align = "right"
            tab2_main_frame.style.padding = 4

            tab2_main_frame.style.horizontally_stretchable = true
            tab2_main_frame.add {
                type = "label",
                name = "tab2_score",
                caption = {
                    "",
                    "[color=orange][font=default-large-bold]",
                    {"strings.info_score_current", math.floor(storage.PData[player.index].score / 60 / 60)},
                    "[/font][/color]"
                }
            }
            tab2_main_frame.add {
                type = "label",
                caption = ""
            }
            tab2_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large-bold]", {"strings.info_score_auto"}, "[/font]"}
            }
            tab2_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large]", {"strings.info_score_specific"}, "[/font]"}
            }
            tab2_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large]", {"strings.info_score_persistent"}, "[/font]"}
            }
            tab2_main_frame.add {
                type = "label",
                caption = ""
            }
            tab2_main_frame.add {
                type = "line",
                direction = "horizontal"
            }
            if UTIL_Is_New(player) then
                tab2_main_frame.add {
                    type = "label",
                    caption = {"", "[recipe=burner-inserter]   [font=default-large-bold][color=red]", {"strings.info_score_level1"}, "[/color][/font]"}
                }
            else
                tab2_main_frame.add {
                    type = "label",
                    caption = {"", "[recipe=burner-inserter]   [font=default-large-bold]", {"strings.info_score_level1"}, "[/font]"}
                }
            end
            tab2_main_frame.add {
                type = "label",
                caption = ""
            }

            tab2_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large-bold]", {"strings.info_score_new_perm"}, "[/font]"}
            }
            tab2_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large-bold]", {"strings.info_score_new_vote"}, "[/font]"}
            }
            tab2_main_frame.add {
                type = "label",
                caption = ""
            }
            tab2_main_frame.add {
                type = "line",
                direction = "horizontal"
            }

            if UTIL_Is_Member(player) then
                tab2_main_frame.add {
                    type = "label",
                    caption = {"", "[recipe=inserter]   [font=default-large-bold][color=red]", {"strings.info_score_level2"}, "[/color][/font]"}
                }
            else
                tab2_main_frame.add {
                    type = "label",
                    caption = {"", "[recipe=inserter]   [font=default-large-bold]", {"strings.info_score_level2"}, "[/font]"}
                }
            end
            tab2_main_frame.add {
                type = "label",
                caption = ""
            }
            tab2_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large]", {"strings.info_score_l2_lift"}, "[/font]"}
            }
            tab2_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large-bold]", {"strings.info_score_l2_decon"}, "[/font]"}
            }
            tab2_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large-bold][color=green]", {"strings.info_score_l2_join"}, "[/color][/font]"}
            }
            tab2_main_frame.add {
                type = "label",
                caption = " "
            }
            tab2_main_frame.add {
                type = "line",
                direction = "horizontal"
            }

            if UTIL_Is_Regular(player) then
                tab2_main_frame.add {
                    type = "label",
                    caption = {"", "[recipe=fast-inserter]   [font=default-large-bold][color=red]", {"strings.info_score_level3"}, "[/color][/font]"}
                }
            else
                tab2_main_frame.add {
                    type = "label",
                    caption = {"", "[recipe=fast-inserter]   [font=default-large-bold]", {"strings.info_score_level3"}, "[/font]"}
                }
            end
            tab2_main_frame.add {
                type = "label",
                caption = ""
            }
            tab2_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large-bold]", {"strings.info_score_l3_banish"}, "[/font]"}
            }
            tab2_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large]", {"strings.info_score_l3_decon"}, "[/font]"}
            }
            tab2_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large]", {"strings.info_score_l3_vote"}, "[/font]"}
            }
            tab2_main_frame.add {
                type = "label",
                caption = " "
            }
            tab2_main_frame.add {
                type = "line",
                direction = "horizontal"
            }
            if UTIL_Is_Veteran(player) then
                tab2_main_frame.add {
                    type = "label",
                    caption = {"", "[recipe=stack-inserter]   [font=default-large-bold][color=red]", {"strings.info_score_level4"}, "[/color][/font]"}
                }
            else
                tab2_main_frame.add {
                    type = "label",
                    caption = {"", "[recipe=stack-inserter]   [font=default-large-bold]", {"strings.info_score_level4"}, "[/font] "}
                }
            end
            tab2_main_frame.add {
                type = "label",
                caption = ""
            }
            tab2_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large-bold]", {"strings.info_score_l4_banish"}, "[/font]"}
            }
            tab2_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large-bold]", {"strings.info_score_l4_vote"}, "[/font]"}
            }
            tab2_main_frame.add {
                type = "label",
                caption = ""
            }
            -- Close Button Frame
            local tab2_close_frame = tab2_main_frame.add {
                type = "flow",
                direction = "vertical"
            }
            tab2_close_frame.style.horizontal_align = "right"

            info_pane.add_tab(tab2, tab2_frame)

            ------------------------
            -- tab 3 -- Rules --
            ------------------------
            local tab3_frame = info_pane.add {
                type = "flow",
                direction = "vertical"
            }
            tab3_frame.style.vertically_squashable = true
            tab3_frame.style.horizontal_align = "center"

            -- tab 3 -- Main
            local tab3_main_frame = tab3_frame.add {
                type = "scroll-pane",
                direction = "vertical"
            }
            tab3_main_frame.style.horizontal_align = "right"
            tab3_main_frame.style.padding = 4

            tab3_main_frame.style.horizontally_stretchable = true
            tab3_main_frame.add {
                type = "label",
                caption = {"", "[item=rail-signal] [font=default-large-bold]", {"strings.info_rules_header"}, "[/font]"}
            }
            tab3_main_frame.add {
                type = "label",
                caption = ""
            }
            tab3_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large-bold]1: [recipe=cluster-grenade] ", {"strings.info_rule1"}, "[/font]"}
            }
            tab3_main_frame.add {
                type = "label",
                caption = ""
            }
            tab3_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large-bold]2: [item=programmable-speaker] ", {"strings.info_rule2"}, "[/font]"}
            }
            tab3_main_frame.add {
                type = "label",
                caption = ""
            }
            tab3_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large-bold]3: [virtual-signal=signal-everything] ", {"strings.info_rule3"}, "[/font]"}
            }
            tab3_main_frame.add {
                type = "label",
                caption = ""
            }
            tab3_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large-bold]4: [item=repair-pack] ", {"strings.info_rule4"}, "[/font]"}
            }
            tab3_main_frame.add {
                type = "label",
                caption = ""
            }
            tab3_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large-bold]5: [fluid=steam] ", {"strings.info_rule5"}, "[/font]"}
            }
            tab3_main_frame.add {
                type = "label",
                caption = ""
            }
            tab3_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large-bold]6: [item=radar] ", {"strings.info_rule6"}, "[/font]"}
            }
            tab3_main_frame.add {
                type = "label",
                caption = ""
            }
            tab3_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large-bold]7: [item=blueprint-book] ", {"strings.info_rule7"}, "[/font]"}
            }
            tab3_main_frame.add {
                type = "label",
                caption = ""
            }
            tab3_main_frame.add {
                type = "label",
                caption = {"", "[font=default-large-bold]8: [item=locomotive] ", {"strings.info_rule8"}, "[/font]"}
            }

            -- Close Button Frame
            local tab3_close_frame = tab3_main_frame.add {
                type = "flow",
                direction = "vertical"
            }
            tab3_close_frame.style.horizontal_align = "right"

            info_pane.add_tab(tab3, tab3_frame)

            ---------------
            --- Discord QR CODE ---
            ---------------
            local tab5_frame = info_pane.add {
                type = "flow",
                direction = "vertical"
            }

            local tab5_qr_frame = tab5_frame.add {
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
            local durl = tab5_qr_frame.add {
                type = "text-box",
                text = "https://discord.gg/rQANzBheVh",
                name = "discord_url",
                tooltip = {"strings.copy_tooltip"}
            }
            durl.style.minimal_width = 350
            tab5_qr_frame.add {
                type = "label",
                caption = ""
            }
            local tab5_qr = tab5_qr_frame.add {
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
                caption = {"strings.info_qr_hint"}
            }

            info_pane.add_tab(tab5, tab5_frame)

            --------------
            --- Patreon    ---
            ---------------
            local tab6_frame = info_pane.add {
                type = "flow",
                direction = "vertical"
            }

            local tab6_qr_frame = tab6_frame.add {
                type = "flow",
                direction = "vertical"
            }
            tab6_qr_frame.style.horizontally_stretchable = true
            tab6_qr_frame.style.vertically_stretchable = true
            tab6_qr_frame.style.horizontal_align = "center"
            tab6_qr_frame.style.vertical_align = "center"
            tab6_qr_frame.add {
                type = "sprite",
                name = "tab6_patreon_logo",
                sprite = "file/img/info-win/patreon-64.png",
                tooltip = ""
            }
            local purl = tab6_qr_frame.add {
                type = "text-box",
                text = "https://www.patreon.com/m45sci",
                name = "patreon_url",
                tooltip = {"strings.copy_tooltip"}
            }
            purl.style.minimal_width = 350
            tab6_qr_frame.add {
                type = "label",
                caption = ""
            }
            local tab6_qr = tab6_qr_frame.add {
                type = "sprite",
                sprite = "file/img/info-win/patreon-qr.png",
                tooltip = "Just open camera on a cellphone!"
            }
            tab6_qr_frame.add {
                type = "label",
                caption = ""
            }
            tab6_qr_frame.add {
                type = "label",
                caption = {"strings.info_qr_hint"}
            }

            info_pane.add_tab(tab6, tab6_frame)
        end
        player.gui.screen.m45_info_window.m45_info_window_tabs.selected_tab_index = 1
    end
end

-- GUI clicks
function INFO_Clicks(event)
    if event and event.element and event.element.valid and event.player_index then
        local player = game.players[event.player_index]

        local args = UTIL_SplitStr(event.element.name, ",")

        if player and player.valid and event.element.name then
            if event.element.name == "discord_url" or
                event.element.name == "server_list" or
                event.element.name == "relay_url" or
                event.element.name == "patreon_url" then
                event.element.select_all()
            end

            -- debug
            UTIL_ConsolePrint("[ACT] GUI_CLICK: " .. player.name .. ": " .. event.element.name)

            -- Info window close
            if event.element.name == "m45_info_close_button" and player.gui and player.gui.center and
                --Info Window
                player.gui.screen.m45_info_window then
                player.gui.screen.m45_info_window.destroy()
            elseif event.element.name == "patreon_button" and player.gui and player.gui.center and
                player.gui.screen.m45_info_window then
                -- QR changetab button (info window)
                player.gui.screen.m45_info_window.m45_info_window_tabs.selected_tab_index = 5
            elseif event.element.name == "qr_button" and player.gui and player.gui.center and
                player.gui.screen.m45_info_window then
                -- QR Discord button
                player.gui.screen.m45_info_window.m45_info_window_tabs.selected_tab_index = 4
            elseif event.element.name == "m45_button" then
                -- Online window toggle
                if player.gui and player.gui.center and player.gui.screen.m45_info_window then
                    player.gui.screen.m45_info_window.destroy()
                else
                    INFO_InfoWin(player)
                end
            elseif event.element.name == "reset_clock" then
                -- reset-clock-close
                if player.gui and player.gui.top and player.gui.top.reset_clock then
                    if storage.PData then
                        if storage.PData[player.index].hideClock and
                            storage.SM_Store.resetDuration ~= "" then
                            storage.PData[player.index].hideClock = false
                        else
                            if event.button and event.button == defines.mouse_button_type.right and event.control then
                                storage.PData[player.index].hideClock = true
                            end
                        end
                        UTIL_DrawMapClock(player)
                    end
                end
            end
        end
    end
end

-- Auto-Fix text-boxes (no-edit text boxes feel odd)
function INFO_TextChanged(event)
    -- Automatically fix URLs, because read-only/selectable text is confusing to players --
    if event and event.element and event.player_index and event.text and event.element.name then
        local args = UTIL_SplitStr(event.element.name, ",")
        local player = game.players[event.player_index]

        if event.element.name == "discord_url" then
            event.element.text = "https://discord.gg/rQANzBheVh"
        elseif event.element.name == "server_list" then
            event.element.text = "http://factorio.go-game.net/?tag=M45"
        elseif event.element.name == "relay_url" then
            event.element.text = "http://eu.m45sci.xyz"
        elseif event.element.name == "patreon_url" then
            event.element.text = "https://www.patreon.com/m45sci"
        end
    end
end
