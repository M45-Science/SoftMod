--Carl Frank Otto III
--carlotto81@gmail.com
local svers = "v535-1-10-2021-1106p-exp"

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

local function round(number, precision)
    local fmtStr = string.format("%%0.%sf", precision)
    number = string.format(fmtStr, number)
    return number
end

--add logo to spawn area
local function dodrawlogo()
    local surf = game.surfaces["nauvis"]
    if surf then
        --Only draw if needed
        if not global.drawlogo then
            --Destroy if already exists
            if global.m45logo then
                rendering.destroy(global.m45logo)
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

            --Set drawn flag
            global.drawlogo = true
            global.m45logo =
                rendering.draw_sprite {
                sprite = "file/img/m45-pad.png",
                render_layer = "floor",
                target = cpos,
                x_scale = 0.5,
                y_scale = 0.5,
                surface = surf
            }
            if not global.servname then
                global.servname = ""
            end
            global.m45text =
                rendering.draw_text {
                text = "M45-Science",
                draw_on_ground = true,
                surface = surf,
                target = {cpos.x + 0, cpos.y + -6},
                scale = 3.0,
                color = {1, 1, 1},
                alignment = "center",
                scale_with_zoom = false
            }
            global.servtext =
                rendering.draw_text {
                text = global.servname,
                draw_on_ground = true,
                surface = surf,
                target = {cpos.x + 0, cpos.y + 4.5},
                scale = 2.0,
                color = {1, 1, 1},
                alignment = "center",
                scale_with_zoom = false
            }
        end
    end
end

--safe console print
local function console_print(message)
    if message then
        print("~" .. message)
    end
end

--smart console print--
local function smart_print(player, message)
    if message then
        if player then
            player.print(message)
        else
            rcon.print("~" .. message)
        end
    end
end

--Global messages
local function message_all(message)
    if message then
        game.print(message)
        print("[MSG] " .. message)
    end
end

--Global messages (players only)
local function message_allp(message)
    if message then
        game.print(message)
    end
end

--Global messages-- (discord only)
local function message_alld(message)
    if message then
        print("[MSG] " .. message)
    end
end

--Check if player should be considered a regular
local function is_regular(victim)
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
local function is_member(victim)
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
local function is_new(victim)
    if victim and victim.valid and not victim.admin then
        if is_member(victim) == false and is_regular(victim) == false then
            return true
        end
    end

    return false
end

--Check if player should be considered banished
local function is_banished(victim)
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

local function make_m45_info_window(player)
    --M45 Welcome--
    if player.gui.center then
        if player.gui.center.splash_screen then
            player.gui.center.splash_screen.destroy()
        end
        if not player.gui.center.splash_screen then
            local info_pane = player.gui.center.add {type = "tabbed-pane", name = "splash_screen"}
            info_pane.style.minimal_width = 700


            local tab1 = info_pane.add {type = "tab", caption = "Welcome"}
            local tab2 = info_pane.add {type = "tab", caption = "Membership"}
            local tab3 = info_pane.add {type = "tab", caption = "Servers"}


            --Tab 1 -- Welcome
            local tab1_frame =
                info_pane.add {
                type = "flow",
                direction = "vertical"
            }
            tab1_frame.style.horizontal_align = "center"

            --Tab 1 -- Title Bar
            local tab1_title_bar_frame =
                tab1_frame.add {
                type = "frame",
                direction = "horizontal"
            }
            tab1_title_bar_frame.style.horizontal_align = "center"
            tab1_title_bar_frame.style.horizontally_stretchable = true
            tab1_title_bar_frame.add {
                type = "label",
                name = "tab1_title",
                caption = "[item=iron-gear-wheel]  [font=default-large-bold]Server Name: [M45] " .. global.servname .. "[/font]"
            }

            --CLOSE BUTTON--
            local tab1_close_button =
            tab1_title_bar_frame.add {
                type = "flow",
                direction = "horizontal"
            }
            tab1_close_button.style.horizontal_align = "right"
            tab1_close_button.style.horizontally_stretchable = true
            tab1_close_button.add {
                type = "sprite-button",
                name = "splash_close_button",
                sprite = "file/img/close-16.png",
                tooltip = "Close this window"
            }
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
                sprite = "file/img/m45-128.png",
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
                caption = "[entity=character]  [color=red][font=default-large-bold]New players start with some RESTRICTIONS![/font][/color]"
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
                caption = "Click the \"Members\" tab above, to find out how to become a member."
            }
            tab1_info_top.add {
                type = "label",
                caption = ""
            }

            --Tab 1 Main -- Reporting
            local tab1_info_center =
                tab1_rframe.add {
                type = "flow",
                direction = "vertical"
            }
            tab1_info_center.style.horizontally_stretchable = true
            tab1_info_center.add {
                type = "label",
                caption = "[color=orange][font=default-large-bold]Issues or griefers?[/font][/color]"
            }
            tab1_info_center.add {
                type = "label",
                caption = "[font=default-large]In chat: /report <name> <problem>[/font]"
            }
            tab1_info_center.add {
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
                sprite = "file/img/discord-64.png",
                tooltip = ""
            }
            tab1_discord_sub2_frame.add {
                type = "text-box",
                name = "discord_url",
                text = "https://discord.gg/Ps2jnm7"
            }
            --URL Style
            tab1_discord_sub2_frame.discord_url.style.font = "default-large"
            tab1_discord_sub2_frame.discord_url.style.minimal_width = 250

            --Tab 1 Main -- Discord -- Bottom Info Text
            tab1_discord_sub1_frame.add {
                type = "label",
                caption = "(drag select with your mouse, and then use control-c to copy.)"
            }
            info_pane.add_tab(tab1, tab1_frame)

            ------------------------
            --TAB 2 -- MEMBERSHIP --
            --tab 2 -- Welcome    --
            ------------------------
            --tab 2 -- Welcome
            local tab2_frame =
                info_pane.add {
                type = "flow",
                direction = "vertical"
            }
            tab2_frame.style.vertically_squashable = true
            tab2_frame.style.horizontal_align = "center"

            --tab 2 -- Title Bar
            local tab2_title_bar_frame =
                tab2_frame.add {
                type = "frame",
                direction = "horizontal"
            }
            tab2_title_bar_frame.style.horizontal_align = "center"
            tab2_title_bar_frame.style.horizontally_stretchable = true
            tab2_title_bar_frame.add {
                type = "label",
                name = "tab2_title",
                caption = "[item=iron-gear-wheel]  [color=red][font=default-large-bold]Your Activity Score: " .. math.floor(global.active_playtime[player.index] / 60 / 60) .. "[/font][/color]"
            }
            local tab2_close_button =
                tab2_title_bar_frame.add {
                type = "flow",
                direction = "horizontal"
            }
            tab2_close_button.style.horizontal_align = "right"
            tab2_close_button.style.horizontally_stretchable = true
            tab2_close_button.add {
                type = "sprite-button",
                name = "splash_close_button",
                sprite = "file/img/close-16.png",
                tooltip = "Close this window"
            }

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
                caption = "   [font=default-bold]Membership is automatic, and based on activity.[/font] Your current activity score is listed above."
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
                caption = "   [font=default-bold]New players can not pick-up or rotate other people's objects,[/font] and have these permissions limitations:"
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
                caption = "Ability to pick-up and rotate other's objects, and permissions restrictions are lifted."
            }
            tab2_main_frame.add {
                type = "label",
                caption = "Votes needed to banish you increases to 3. Access to deconstruction planner (warns other users on use)."
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
                caption = "Access to /banish command (5 votes per map), other players can not banish you."
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
            info_pane.selected_tab_index = 1
        end
    end
end

--Count up banish votes
local function update_banished_votes()
    --Reset banished list
    local banishedtemp = {}

    --Init if needed
    if not global.banishvotes then
        global.banishvotes = {voter = {}, victim = {}, reason = {}, tick = {}, withdrawn = {}, overruled = {}}
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

            local surf = game.surfaces["nauvis"]
            if surf and surf.name then
                local newpos = victim.surface.find_non_colliding_position("character", {0, 0}, 99, 0.01, false)
                if newpos then
                    victim.teleport(newpos, surf)
                else
                    victim.teleport({0, 0}, surf) --Screw it
                end
            else
                message_all("default surface is missing, unable to un-banish player.")
            end
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
                            settings = {["sand-1"] = {frequency = "normal", size = "normal", richness = "normal"}}
                        }
                    },
                    starting_area = "none"
                }
                game.create_surface("hell", my_map_gen_settings)
            end

            --Kill them, so items are left behind
            if victim.character and victim.character.valid then
                victim.character.die(victim.force, victim.character)
            end

            --Teleport them to new surface
            local surf = game.surfaces["hell"]
            if surf and surf.name then
                local newpos = victim.surface.find_non_colliding_position("character", {0, 0}, 99, 0.01, false)
                if newpos then
                    victim.teleport(newpos, surf)
                else
                    victim.teleport({0, 0}, surf) --Screw it
                end
            end
        end
    end
end

--Sort players
local function sorttime(a, b)
    if (not a or not b) then
        return false
    end

    if (not a.time or not b.time) then
        return false
    end

    if (a.time < b.time) then
        return true
    elseif (a.time > b.time) then
        return false
    else
        return nil
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
        global.banishvotes = {voter = {}, victim = {}, reason = {}, tick = {}, withdrawn = {}, overruled = {}}
    end
    if not global.thebanished then
        global.thebanished = {}
    end
    if not global.no_fastreplace then
        global.no_fastreplace = false
    end

    --Server List
    if not global.servers then
        global.servers = {
            "Our Servers:",
            "A-Rail World",
            "B-Peaceful",
            "C-Death World",
            "[ v EXPERIMENTAL v ]",
            "XA-Rail World-2 *",
            "XB-Peaceful-2 *",
            "XC-Death World-2 *",
            "XD-Fear-The-Dark *",
            "[ v REGULARS-ONLY v ]",
            "RA-Space-Krastorio",
            "RC-Death World-3 *",
            "RD-Fortress Island *",
            "* = Factorio 1.1.x"
        }
    end
    if not global.ports then
        global.ports = {
            "",
            "50000",
            "50001",
            "50002",
            "",
            "50200",
            "50201",
            "50202",
            "50101",
            --RB
            "",
            "50100",
            "50102",
            "50103",
            ""
        }
    end
    if not global.domain then
        global.domain = "m45sci.xyz:"
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
local function mysplit(inputstr, sep)
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

--Set our default settings
local function game_settings(player)
    if player and player.valid and player.force and not global.gset then
        global.gset = true --Only apply these once
        player.force.friendly_fire = false --friendly fire
        player.force.research_queue_enabled = true --nice to have
        game.disable_replay() --Smaller saves, prevent desync on script upgrade
    end
end

--Auto permisisons--
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
local function show_players(victim)
    local numpeople = 0

    --Cleaned up 12-2020
    for _, player in pairs(game.connected_players) do
        if (player and player.valid and player.connected) then
            numpeople = (numpeople + 1)
            local utag = "error"

            --Catch all
            if player.permission_group then
                local gname = player.permission_group.name
                utag = gname
            else
                utag = "none"
            end

            --Normal groups
            if is_new(player) then
                utag = "NEW"
            end
            if is_member(player) then
                utag = "Members"
            end
            if is_regular(player) then
                utag = "Regulars"
            end
            if is_banished(player) then
                utag = "BANISHED"
            end
            if player.admin then
                utag = "ADMINS"
            end

            if (global.active_playtime and global.active_playtime[player.index]) then
                smart_print(victim, string.format("%-3d: %-18s Activity: %-4.3fh, Online: %-4.3fh, (%s)", numpeople, player.name, (global.active_playtime[player.index] / 60.0 / 60.0 / 60.0), (player.online_time / 60.0 / 60.0 / 60.0), utag))
            end
        end
    end
    --No one is online
    if numpeople == 0 then
        smart_print(victim, "No players online.")
    end
end

--Custom commands
script.on_load(
    function()
        --Only add if no commands yet
        if (not commands.commands.server_interface) then
            commands.add_command(
                "destroym45gui",
                "for migrating maps/user m45 guis",
                function(param)
                    local player
                    local ccount = 0
                    local ecount = 0

                    --Admins only
                    if param and param.player_index then
                        player = game.players[param.player_index]
                        if player and player.admin == false then
                            smart_print(player, "Admins only.")
                            return
                        end
                    end

                    --Refresh spawn logo
                    global.drawlogo = nil
                    dodrawlogo()

                    if param and param.parameter then
                        if param.parameter == "confirm" then
                            for _, player in pairs(game.players) do
                                if player.gui then
                                    if player.gui.top then
                                        ccount = ccount + 1

                                        if player.gui.top.dicon then
                                            player.gui.top.dicon.destroy()
                                            ecount = ecount + 1
                                        end
                                        if player.gui.top.zout then
                                            player.gui.top.zout.destroy()
                                            ecount = ecount + 1
                                        end
                                        if player.gui.top.serverlist then
                                            player.gui.top.serverlist.destroy()
                                            ecount = ecount + 1
                                        end
                                        if player.gui.top.discordurl then
                                            player.gui.top.discordurl.destroy()
                                            ecount = ecount + 1
                                        end
                                    end
                                end
                            end
                            smart_print(player, ccount .. " player GUIs, and " .. ecount .. " elements were destroyed.")
                        else
                            smart_print(player, "This shouldnot normally be used, and is used for m45 map/user GUI migration.")
                            smart_print(player, "/clearm45gui confirm if you are completely sure.")
                        end
                    end
                end
            )

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
                                if speed > 100 then
                                    speed = 100
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
                                            ["sand-1"] = {frequency = "normal", size = "normal", richness = "normal"}
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

                            if (victim and victim.valid) then
                                --If they have a character, kill it to release items
                                if victim.character and victim.character.valid then
                                    victim.character.die(victim.force, victim.character)
                                end

                                local surf = game.surfaces["hell"]
                                if surf and surf.name then
                                    local newpos = victim.surface.find_non_colliding_position("character", {0, 0}, 99, 0.01, false)
                                    if newpos then
                                        victim.teleport(newpos, surf)
                                        return
                                    else
                                        victim.teleport({0, 0}, surf) --Screw it
                                        return
                                    end
                                end
                            end
                        end
                        smart_print(player, "Couldn't find that player.")
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
                                    if victim and victim.valid then
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
                                    if victim and victim.valid and victim.name then
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
                                        smart_print(player, "I didn't find a player by that name, you can use the first few letters, and <tab> (autocomplete) to help.")
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
                        if player and param.parameter then
                            --Regulars/admins only
                            if is_regular(player) or player.admin then
                                --get arguments
                                local args = mysplit(param.parameter, " ")

                                --Must have arguments
                                if args ~= {} and args[1] and args[2] then
                                    local victim = game.players[args[1]]

                                    --Quick arg combine
                                    local reason = args[2]
                                    for n, arg in pairs(args) do
                                        if n > 2 and n < 100 then -- at least two words, max 100
                                            reason = reason .. " " .. args[n]
                                        end
                                    end

                                    if string.len(reason) < 8 then
                                        smart_print(player, "You must supply a more descriptive complaint.")
                                    else
                                        --Must have valid victim
                                        if victim and victim.valid and victim.name then
                                            --Victim must be new or member
                                            if is_new(victim) or is_member(victim) then
                                                --Check if we already voted against them
                                                if global.banishvotes and global.banishvotes ~= {} then
                                                    local votecount = 0
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
                                                    smart_print(player, "Your vote has been added, and posted on Discord!")
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
                                            smart_print(player, "I didn't find a player by that name, you can use the first few letters, and press <tab> (to autocomplete).")
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
                            smart_print(player, "Usage: /banish <player> <reason for banishment>")
                        end
                    else
                        smart_print(nil, "The console can't vote.")
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
                        if player and player.valid and param.parameter then
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
                            if global.reportlimit[player.index] < 5 then
                                print("[REPORT] " .. player.name .. " " .. param.parameter)
                                smart_print(player, "Report sent! You have now used " .. global.reportlimit[player.index] .. " of your 5 available reports.")
                            else
                                smart_print("You are not allowed to send any more reports.")
                            end
                        else
                            smart_print(player, "Usage: /report (your message to moderators here)")
                        end
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

                    local psurface = game.surfaces["nauvis"]
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
                        global.cspawnpos = {x = (math.floor(new_pos_x) + 0.5), y = (math.floor(new_pos_y) + 0.5)}

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
                    local psurface = game.surfaces["nauvis"]
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
                        pforce.chart(psurface, {lefttop = {x = -size / 2, y = -size / 2}, rightbottom = {x = size / 2, y = size / 2}})
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
                    local is_admin = true

                    --Check if admin for active argument
                    if param and param.player_index then
                        victim = game.players[param.player_index]
                        if victim and victim.admin == false then
                            is_admin = false
                        end
                    end

                    --If admin, show active players if specified
                    if (param.parameter == "active" and is_admin) then
                        local plen = 0
                        local playtime = {}
                        for pos, player in pairs(game.players) do
                            playtime[pos] = {
                                time = global.active_playtime[player.index],
                                name = game.players[player.index].name
                            }
                            plen = plen + 1
                            if plen > 3000 then --Max number of players to scan (lag)
                                break
                            end
                        end

                        --Sort players
                        table.sort(playtime, sorttime)

                        --Lets limit number of results shown
                        for ipos, time in pairs(playtime) do
                            if (time) then
                                if (time.time) then
                                    if ipos > (plen - 20) then
                                        smart_print(victim, string.format("%-4d: %-32s Active: %-4.2fm", ipos, time.name, time.time / 60.0 / 60.0))
                                    end
                                end
                            end
                        end
                        return
                    end

                    --Show players
                    smart_print(victim, "PLAYERS ONLINE:")
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
                                local newpos = victim.surface.find_non_colliding_position("character", victim.position, 15, 0.01, false)
                                if (newpos) then
                                    player.teleport(newpos, victim.surface)
                                    smart_print(player, "*Poof!*")
                                else
                                    smart_print(player, "Area appears to be full.")
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
                                local newpos = surface.find_non_colliding_position("character", position, 15, 0.01, false)
                                if newpos then
                                    player.teleport(newpos, surface)
                                    return
                                end
                            end

                            --Find x/y from argument
                            xpos, ypos = str:match("([^,]+),([^,]+)")
                            if tonumber(xpos) and tonumber(ypos) then
                                local position = {x = xpos, y = ypos}

                                if position then
                                    if position.x and position.y then
                                        local newpos = surface.find_non_colliding_position("character", position, 15, 0.01, false)
                                        if (newpos) then
                                            player.teleport(newpos, surface)
                                            smart_print(player, "*Poof!*")
                                        else
                                            smart_print(player, "Area appears to be full.")
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
                                local newpos = player.surface.find_non_colliding_position("character", player.position, 15, 0.01, false)
                                if (newpos) then
                                    victim.teleport(newpos, player.surface)
                                    smart_print(player, "*Poof!*")
                                else
                                    smart_print(player, "Area appears to be full.")
                                end
                            end
                        end
                        smart_print(player, "Who do you want to teleport to you?")
                    end
                end
            )
        end
    end
)

--EVENTS--
--Command logging
script.on_event(
    defines.events.on_console_command,
    function(event)
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
)

--Deconstuction planner warning
script.on_event(
    defines.events.on_player_deconstructed_area,
    function(event)
        if event and event.player_index and event.area then
            local player = game.players[event.player_index]
            local area = event.area

            if player and area and area.left_top then
                set_player_active(player)
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
)

--Player respawn, insert items
script.on_event(
    defines.events.on_player_respawned,
    function(event)
        if event and event.player_index then
            local player = game.players[event.player_index]
            if player and player.valid then
                player.insert {name = "firearm-magazine", count = 10}
                player.insert {name = "pistol", count = 1}
            end
        end
    end
)

--Player connected, make variables, draw UI, set permissions, and game settings
script.on_event(
    defines.events.on_player_joined_game,
    function(event)
        if event and event.player_index then
            local player = game.players[event.player_index]
            if player and player.valid then
                create_myglobals()
                create_player_globals(player)
                create_groups()
                game_settings(player)
                set_perms()

                dodrawlogo()

                if player.gui and player.gui.top then
                    --M45 button--
                    if not player.gui.top.m45_button then
                        player.gui.top.add {
                            type = "sprite-button",
                            name = "m45_button",
                            sprite = "file/img/m45-24.png",
                            tooltip = "Opens the server info window"
                        }
                    end
                end

                get_permgroup()
                if player.gui and player.gui.center and player.gui.center.splash_screen then
                    player.gui.center.splash_screen.destroy()
                end

                if is_new(player) then
                    make_m45_info_window(player)
                end
            end
        end
    end
)

script.on_event(
    defines.events.on_gui_text_changed,
    function(event)
        if event and event.element and event.player_index and event.text then
            if event.element.name and event.element.name == "discord_url" then
                event.element.text = "https://discord.gg/Ps2jnm7"
            end
        end
    end
)

--Player disconnected (Fact >= v1.1)
script.on_event(
    defines.events.on_player_left_game,
    function(event)
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
)

--New player created, insert items set perms, show players online, welcome to map.
script.on_event(
    defines.events.on_player_created,
    function(event)
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
                smart_print(player, "[color=red](SYSTEM) To see online players or your active time, chat /online[/color]")
                message_all("[color=green](SYSTEM) Welcome " .. player.name .. " to the map![/color]")
            end
        end
    end
)

--ACTIVITY EVENTS
--Build stuff
script.on_event(
    defines.events.on_built_entity,
    function(event)
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
)

--Cursor stack, block huge blueprints
script.on_event(
    defines.events.on_player_cursor_stack_changed,
    function(event)
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
)

--Pre-Mined item
script.on_event(
    defines.events.on_pre_player_mined_item,
    function(event)
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
                                            ["sand-1"] = {frequency = "normal", size = "normal", richness = "normal"}
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
                                local cwire
                                local rwire
                                local gwire

                                --Fix wires... grr
                                local wires = obj.circuit_connected_entities

                                --Save wire connections
                                if wires then
                                    cwire = wires["copper"]
                                    rwire = wires["red"]
                                    gwire = wires["green"]
                                end

                                if obj.type == "electric-pole" then
                                    wires = obj.neighbours
                                    --Save wire connections

                                    if wires then
                                        cwire = wires["copper"]
                                        rwire = wires["red"]
                                        gwire = wires["green"]
                                    end
                                end

                                --Destroy orignal object.
                                obj.destroy()

                                --Create list if needed
                                if not global.repobj then
                                    global.repobj = {obj = {}, victim = {}, copper = {}, red = {}, green = {}, surface = {}}
                                end

                                --Add obj to list
                                table.insert(global.repobj, {obj = saveobj, victim = player, copper = cwire, red = rwire, green = gwire, surface = player.surface})
                            else
                                console_print("pre_player_mined_item: unable to clone object.")
                            end
                        else
                            console_print("pre_player_mined_item: unable to get limbo-surface.")
                        end
                    else
                        --Normal player, just log it
                        console_print(player.name .. " -" .. obj.name .. " [gps=" .. math.floor(obj.position.x) .. "," .. math.floor(obj.position.y) .. "]")
                        set_player_active(player) --Set player as active
                    end
                else
                    console_print("pre_player_mined_item: invalid player, obj or surface.")
                end
            end
        end
    end
)

--Rotated item
script.on_event(
    defines.events.on_player_rotated_entity,
    function(event)
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
                    set_player_active(player) --Sey player active
                end
            end
        end
    end
)

--Mine tiles
script.on_event(
    defines.events.on_player_mined_tile,
    function(event)
        if event and event.player_index then
            local player = game.players[event.player_index]

            set_player_active(player)
        end
    end
)

--Repair entity
script.on_event(
    defines.events.on_player_repaired_entity,
    function(event)
        if event and event.player_index then
            local player = game.players[event.player_index]

            set_player_active(player)
        end
    end
)

--Chatting
script.on_event(
    defines.events.on_console_chat,
    function(event)
        --Can be triggered by console, so check for nil
        if event and event.player_index and event.message and event.message ~= "" then
            local player = game.players[event.player_index]
            set_player_active(player)
        end
    end
)

--Walking/Driving
script.on_event(
    defines.events.on_player_changed_position,
    function(event)
        if event and event.player_index then
            local player = game.players[event.player_index]

            --Only count if actually walking...
            if player and player.valid and player.walking_state then
                if
                    player.walking_state.walking == true and
                        (player.walking_state.direction == defines.direction.north or player.walking_state.direction == defines.direction.northeast or player.walking_state.direction == defines.direction.east or
                            player.walking_state.direction == defines.direction.southeast or
                            player.walking_state.direction == defines.direction.south or
                            player.walking_state.direction == defines.direction.southwest or
                            player.walking_state.direction == defines.direction.west or
                            player.walking_state.direction == defines.direction.northwest)
                 then
                    set_player_active(player)
                end
            end
        end
    end
)

--Create map tag
script.on_event(
    defines.events.on_chart_tag_added,
    function(event)
        if event and event.player_index then
            local player = game.players[event.player_index]

            if player and player.valid and event.tag then
                console_print(player.name .. " + tag [gps=" .. math.floor(event.tag.position.x) .. "," .. math.floor(event.tag.position.y) .. "] " .. event.tag.text)
            end
        end
    end
)

--Edit map tag
script.on_event(
    defines.events.on_chart_tag_modified,
    function(event)
        if event and event.player_index then
            local player = game.players[event.player_index]
            if player and player.valid and event.tag then
                console_print(player.name .. " -+ tag [gps=" .. math.floor(event.tag.position.x) .. "," .. math.floor(event.tag.position.y) .. "] " .. event.tag.text)
            end
        end
    end
)

--Delete map tag
script.on_event(
    defines.events.on_chart_tag_removed,
    function(event)
        if event and event.player_index then
            local player = game.players[event.player_index]

            if player and player.valid and event.tag then
                console_print(player.name .. "- tag [gps=" .. math.floor(event.tag.position.x) .. "," .. math.floor(event.tag.position.y) .. "] " .. event.tag.text)
            end
        end
    end
)

--Banned
script.on_event(
    defines.events.on_player_banned,
    function(event)
        if event and event.player_index then
            local player = game.players[event.player_index]
            if player and player.valid and player.character then
                if global.cspawnpos then
                    player.teleport(global.cspawnpos)
                else
                    player.teleport({0, 0})
                end
                player.character.die(player.force, player.character)
            end
        end
    end
)

--OTHER EVENTS
--Corpse Marker
script.on_event(
    defines.events.on_pre_player_died,
    function(event)
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
)

--Research Finished
script.on_event(
    defines.events.on_research_finished,
    function(event)
        if event and event.research then
            message_alld("Research " .. event.research.name .. " completed.")
        end
    end
)

--Looping timer, 30 seconds
--delete old corpse map pins
--Check spawn area map pin
--Add to player active time if needed

script.on_nth_tick(
    1800,
    function(event)
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
            local psurface = game.surfaces["nauvis"]

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

--GUI clicks
script.on_event(
    defines.events.on_gui_click,
    function(event)
        if event and event.element and event.element.valid and event.player_index then
            local player = game.players[event.player_index]

            if player and player.valid then
                if event.element.name == "splash_close_button" then
                    player.gui.center.splash_screen.destroy()
                    return
                end
                if event.element.name == "m45_button" then
                    if player.gui.center.splash_screen then
                        player.gui.center.splash_screen.destroy()
                        return
                    else
                        make_m45_info_window(player)
                    end
                end
            end
        end
    end
)

local function replace_with_clone(item)
    local rep = item.obj.clone({position = item.obj.position, surface = item.surface, force = item.obj.force})

    if rep then
        --If we saved wire data, reconnect them now
        if item.copper then
            for ind, pole in pairs(item.copper) do
                if pole.type == "electric-pole" then
                    rep.connect_neighbour(pole)
                end
            end
        end
        if item.red then
            for ind, pole in pairs(item.red) do
                rep.connect_neighbour {target_entity = pole, wire = defines.wire_type.red}
            end
        end
        if item.green then
            for ind, pole in pairs(item.green) do
                rep.connect_neighbour {target_entity = pole, wire = defines.wire_type.green}
            end
        end

        if rep then
            smart_print(player, "[color=red](SYSTEM) You are a new player, and are not allowed to mine or replace other people's objects yet![/color]")
            if item.victim and item.victim.valid and item.victim.character and item.victim.character.valid then
                item.victim.character.damage(15, "enemy") --Little discouragement
            end
        end
    end
end

--Blueprint throttle countdown
script.on_nth_tick(
    1,
    function(event)
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
                        local fast_replaced = item.surface.find_entities_filtered {position = item.obj.position, radius = 0.99, force = item.obj.force, limit = 100}

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

--GUI state change, server list drop-down
script.on_event(
    defines.events.on_gui_selection_state_changed,
    function(event)
        --If event and player and element
        if event and event.player_index and event.element then
            local player = game.players[event.player_index]
            local ele = event.element
            --If player and element are valid
            if player and player.valid and ele.valid then
                --If object is server list
                if player.gui and player.gui.top and player.gui.top.serverlist and ele.index == player.gui.top.serverlist.index then
                    --Skip label
                    if ele.selected_index > 1 then
                        --if valid selected item, and globals
                        if ele.selected_index and global.servers and global.ports and global.domain then
                            --If item exists
                            if global.ports[ele.selected_index] and global.servers[ele.selected_index] then
                                if global.ports[ele.selected_index] ~= "" then
                                    local addr = global.domain .. global.ports[ele.selected_index]
                                    local servname = global.servers[ele.selected_index]
                                    --smart_print(player, "Connecting to: " .. addr)
                                    player.connect_to_server {address = addr, name = servname}
                                end

                                --Revert selection
                                player.gui.top.serverlist.selected_index = 1
                            end
                        end
                    end
                end
            end
        end
    end
)
