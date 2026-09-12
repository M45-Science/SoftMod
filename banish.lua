-- Carl Frank Otto III
-- carlotto81@gmail.com
-- GitHub: https://github.com/M45-Science/SoftMod
-- License: MPL 2.0

function BANISH_UnbanishPlayer(victim)
    if not victim then
        return
    end

    table.insert(storage.SM_Store.sendToSurface, {
        victim = victim,
        surface = 1,
        position = UTIL_GetDefaultSpawn()
    })

    if victim and victim.permission_group.name == storage.SM_Store.jailGroup.name then
        UTIL_MsgAll(victim.name .. " moved out of jailed group.")
    end

    storage.PData[victim.index].banished = 0
    storage.SM_Store.jailGroup.remove_player(victim)
    storage.SM_Store.defGroup.add_player(victim)

    --Close banished window
    if victim.gui and victim.gui.screen and victim.gui.screen.banished_inform then
        victim.gui.screen.banished_inform.destroy()
    end

    BANISH_SendToSurface(victim)
end

function BANISH_DoReport(player, report)
    if player and player.valid and report then
        if CMD_NoBanished(player) then
            return
        end

        storage.PData[player.index].reports = storage.PData[player.index].reports + 1

        -- Limit and list number of reports
        if storage.PData[player.index].reports <= 5 then
            CW_EmitText("report", player.name .. " " .. report)
            UTIL_SmartPrint(player, "Report sent! You have now used " .. storage.PData[player.index].reports ..
                " of your 5 available reports.")
        else
            UTIL_SmartPrint(player, "You are not allowed to send any more reports.")
        end
    else
        UTIL_SmartPrint(player, "Usage: /report (your message to moderators here)")
    end
end

function BANISH_UpdateVotes()
    -- Reset banished list
    local banishedtemp = {}

    -- Loop through votes, tally them
    for _, vote in ipairs(storage.SM_Store.votes) do
        -- only if everything seems to exist
        if vote and vote.voter and vote.victim then
            -- only if data exists
            if vote.voter.valid then
                -- valid defendant
                if not vote.victim.admin then
                    -- valid voter
                    if UTIL_Is_Regular(vote.voter) or UTIL_Is_Veteran(vote.voter) or vote.voter.admin then
                        -- vote isn't overruled or withdrawn
                        if not vote.withdrawn and not vote.overruled then
                            local points = 1

                            if vote.voter.admin then
                                points = 1000 -- Admins get single-vote banish
                            elseif UTIL_Is_Veteran(vote.voter) then
                                points = 2    -- Veterans get extra votes
                            end

                            --Add vote, or init if needed
                            if banishedtemp[vote.victim.index] then
                                banishedtemp[vote.victim.index] = banishedtemp[vote.victim.index] + points
                            else
                                -- was empty, init
                                banishedtemp[vote.victim.index] = points
                            end
                        end
                    end
                end
            end
        end
    end

    -- Loop though players, look for matches
    local player_indices = {}
    for player_index, _ in pairs(game.players) do
        table.insert(player_indices, player_index)
    end
    table.sort(player_indices)
    for _, player_index in ipairs(player_indices) do
        local victim = game.players[player_index]
        local prevstate = 0
        local newstate = 0
        if storage.PData[victim.index].banished then
            prevstate = storage.PData[victim.index].banished
        end

        if banishedtemp[victim.index] then
            newstate = banishedtemp[victim.index]
        end


        local pointsNeeded = 1
        if UTIL_Is_Regular(victim) then
            pointsNeeded = 2
        end
        if UTIL_Is_Veteran(victim) then
            pointsNeeded = 4
        end
        if victim.admin then
            pointsNeeded = 99999
        end

        -- Was banished, but not anymore
        if newstate < pointsNeeded and prevstate >= pointsNeeded then
            local msg = victim.name .. " is no longer banished."
            CW_EmitText("report", "SYSTEM " .. msg)
            UTIL_MsgAllSys(msg)

            BANISH_UnbanishPlayer(victim)
        elseif newstate >= pointsNeeded and prevstate < pointsNeeded then
            -- Was not banished, but is now.
            local msg = victim.name .. " has been banished."
            UTIL_MsgAllSys(msg)
            CW_EmitText("report", "SYSTEM " .. msg)

            BANISH_DoJail(victim)
        end

        --Apply new state
        if banishedtemp[victim.index] then
            storage.PData[victim.index].banished = banishedtemp[victim.index]
        else
            storage.PData[victim.index].banished = 0
        end
    end
end

local function informBanished(victim)
    if victim and victim.gui and victim.gui.screen then
        if victim.gui.screen.banished_inform then
            victim.gui.screen.banished_inform.destroy()
        end
        if not victim.gui.screen.banished_inform then
            local main_flow = victim.gui.screen.add {
                type = "frame",
                name = "banished_inform",
                direction = "vertical"
            }
            main_flow.force_auto_center()
            local banished_titlebar = main_flow.add {
                type = "frame",
                direction = "horizontal"
            }
            banished_titlebar.style.horizontal_align = "center"
            banished_titlebar.style.horizontally_stretchable = true

            banished_titlebar.add {
                type = "label",
                style = "frame_title",
                caption = "YOU HAVE BEEN BANISHED!"
            }

            local pusher = banished_titlebar.add {
                type = "empty-widget",
                style = "draggable_space_header"
            }
            pusher.style.vertically_stretchable = true
            pusher.style.horizontally_stretchable = true
            pusher.drag_target = main_flow

            banished_titlebar.add {
                type = "sprite-button",
                name = "m45_banish_close_button",
                sprite = "utility/close",
                style = "frame_action_button",
                tooltip = "Close this window"
            }

            local banished_main = main_flow.add {
                type = "frame",
                name = "main",
                direction = "vertical"
            }
            banished_main.style.horizontal_align = "center"

            banished_main.add {
                type = "sprite",
                sprite = "file/img/world/turd.png"
            }
            banished_main.add {
                type = "label",
                caption = ""
            }
            banished_main.add {
                type = "label",
                caption = "[font=default-large]Moderators will review the public action-logs on m45sci.xyz and perm-ban you if the vote-banish was for good a reason.[/font]"
            }
            banished_main.add {
                type = "label",
                caption = ""
            }
            banished_main.add {
                type = "label",
                caption = "[font=default-large]We share our ban list with many other factorio communities. We put the reason, date and a link to the log file in the ban.[/font]"
            }
            banished_main.add {
                type = "label",
                caption = ""
            }
            banished_main.add {
                type = "label",
                caption = "[font=default-large]Any items you took have been left at the spawn area so they can be retrieved.[/font]"
            }
            banished_main.add {
                type = "label",
                caption = ""
            }
            banished_main.add {
                type = "label",
                caption = "[font=default-large]Players can simply vote to rewind to the previous autosave... or moderators can do it with a single command.[/font]"
            }
            banished_main.add {
                type = "label",
                caption = ""
            }
            banished_main.add {
                type = "label",
                caption = "[font=default-large]If you were griefing, I hope you think carefully about why you were doing this.[/font]"
            }
            banished_main.add {
                type = "label",
                caption = ""
            }
            banished_main.add {
                type = "label",
                caption = "[font=default-large]It seems most of you are like a little kid kicking a sand castle... angry because you do not have the skills to contribute.[/font]"
            }
            banished_main.add {
                type = "label",
                caption = ""
            }
            banished_main.add {
                type = "label",
                caption = "[font=default-large]I hope you learn from this, and eventually become a functioning adult...[/font]"
            }
            banished_main.add {
                type = "label",
                caption = ""
            }
            banished_main.add {
                type = "label",
                caption = "[font=default-large]Before you suffer real-world consequences for this type of behavior elsewhere.[/font]"
            }
        end
    end
end

function BANISH_DoJail(victim)
    informBanished(victim)

    if victim then
        storage.SM_Store.jailGroup.add_player(victim)
        UTIL_MsgAll(victim.name .. " moved to jailed group.")
    end

    storage.PData[victim.index].score = 0
    storage.PData[victim.index].lastPromoScore = 0
    UTIL_DumpInv(victim, true)
    UTIL_MsgAllSys(victim.name ..
        "'s inventory has been dumped at spawn so the items can be recovered.")

    local newpos = game.surfaces["jail"].find_non_colliding_position("character", { x = 0, y = 0 }, 1024, 1, false)
    table.insert(storage.SM_Store.sendToSurface, {
        victim = victim,
        surface = "jail",
        position = newpos
    })
    BANISH_SendToSurface(victim)
    ONLINE_MarkDirty()
end

function BANISH_MakeJail()
    --Migrate old maps
    if game.surfaces["hell"] ~= nil then
        game.delete_surface("hell")
    end
    -- Create area if needed
    if game.surfaces["jail"] == nil then
        local my_map_gen_settings = {
            width = 100,
            height = 100,
            default_enable_all_autoplace_controls = false,
            property_expression_names = {
                cliffiness = 0
            },
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
        game.create_surface("jail", my_map_gen_settings)
        game.surfaces["jail"].show_clouds = false
        game.surfaces["jail"].request_to_generate_chunks({ x = 0, y = 0 }, 1)
    end

    local pforce = game.forces["player"]
    if pforce then
        pforce.set_surface_hidden("jail", true)
        pforce.clear_chart("jail")
    end
end

function BANISH_DoBanish(player, victim, reason)
    if player and player.valid then
        if CMD_NoBanished(player) then
            return
        end

        -- Regulars/mods only
        if UTIL_Is_Regular(player) or UTIL_Is_Veteran(player) or player.admin then
            -- Must have arguments
            if victim and reason then
                if victim.index == player.index then
                    UTIL_SmartPrint(player, "You can't banish yourself. Have you considered therapy?")
                    return
                end
                if UTIL_Is_Banished(player) then
                    UTIL_SmartPrint(player, "You are banished, you can't vote.")
                    return
                end

                if string.len(reason) < 4 then
                    UTIL_SmartPrint(player, "You must supply a more descriptive complaint.")
                    return
                else
                    -- Must have valid victim
                    if victim then
                        -- Victim can not be an moderator
                        if not victim.admin then
                            -- Check if we already voted against them
                            if storage.SM_Store.votes then
                                local votecount = 1
                                for _, vote in ipairs(storage.SM_Store.votes) do
                                    if vote and vote.voter and vote.victim then
                                        -- Count player's total votes, cap them
                                        if vote.voter == player then
                                            votecount = votecount + 1
                                            -- Limit number of votes player gets
                                            if not vote.voter.admin and votecount >= 5 then
                                                UTIL_SmartPrint(player,
                                                    "You have exhausted your voting privilege for this map.")
                                                return
                                            end
                                        end

                                        -- Can't vote twice
                                        if vote.voter == player and vote.victim == victim then
                                            UTIL_SmartPrint(player, "You already voted against them!")
                                            UTIL_SmartPrint(player, "/unbanish <player> to withdraw your vote.")
                                            UTIL_SmartPrint(player,
                                                "[color=red](WARNING) If you withdraw a vote, you CAN NOT reintroduce it.[/color]")
                                            return
                                        end
                                    end
                                end

                                -- Send report to discord and add to vote list
                                local message = player.name .. " voted to banish: " .. victim.name .. " for: " .. reason
                                UTIL_MsgAllSys(message)
                                CW_EmitText("report", message)
                                UTIL_SmartPrint(player, "(SYSTEM): Your vote has been added, and posted on Discord!")
                                UTIL_SmartPrint(player, "/unbanish <player> to withdraw your vote.")
                                UTIL_SmartPrint(player,
                                    "[color=red](WARNING) If you withdraw a vote, you CAN NOT reintroduce it.[/color]")
                                UTIL_SmartPrint(player, "You have used " .. votecount .. " of your 5 available votes.")
                            end

                            -- Insert newest vote at the start of the list
                            -- index 1 is the first valid position in Lua
                            table.insert(storage.SM_Store.votes, 1, {
                                voter = player,
                                victim = victim,
                                reason = reason,
                                tick = game.tick,
                                withdrawn = false,
                                overruled = false
                            })
                            BANISH_UpdateVotes() -- Must do this to add to tally
                        else
                            UTIL_SmartPrint(player, "Moderators can not be banished.")
                        end
                    else
                        UTIL_SmartPrint(player, "There are no players by that name.")
                    end
                end
            else
                UTIL_SmartPrint(player, "Usage: /banish <player> <reason for banishment>")
            end
        else
            UTIL_SmartPrint(player, "This command is for regulars/veterans (level 3+) players and moderators only!")
            return
        end
    else
        UTIL_SmartPrint(nil, "The console can't vote.")
    end
end

function BANISH_SendToSurface(player)
    -- Anything queued?
    if storage.SM_Store and storage.SM_Store.sendToSurface then
        -- Valid player?
        if player and player.valid and player.character and player.character.valid then
            local index = nil
            -- Check list
            for i, item in ipairs(storage.SM_Store.sendToSurface) do
                -- Check if item is valid
                if item and item.victim and item.victim.character then
                    -- Check if names match
                    if item.victim.index == player.index then
                        -- If surface is valid
                        local surf = game.surfaces[item.surface]
                        if not surf then
                            UTIL_ConsolePrint(
                                "[ERROR] send_to_surface(respawn): INVALID SURFACE")

                            index = i
                            break
                        end
                        UTIL_ExitRemoteView(player)
                        if item.position then
                            local newpos = surf.find_non_colliding_position("character", item.position, 1024, 1,
                                false)
                            if newpos then
                                player.teleport(newpos, surf)
                            else
                                player.teleport(item.position, surf) -- screw it
                                UTIL_ConsolePrint(
                                    "[ERROR] send_to_surface(respawn): unable to find non_colliding_position.")
                            end
                            ONLINE_MarkDirty()

                            index = i
                            break
                        else
                            player.teleport({ x = 0, y = 0 }, surf) -- screw it
                            UTIL_ConsolePrint(
                                "[ERROR] send_to_surface(respawn): invalid position!")
                            index = i
                            ONLINE_MarkDirty()
                            break
                        end
                    end
                end
            end
            -- Remove item we processed
            if index then
                UTIL_ConsolePrint("send_to_surface: processed queue item " .. index)
                table.remove(storage.SM_Store.sendToSurface, index)
            end
        end
    end
end

-- Command registration moved to commands_banish.lua
function BANISH_AddBanishCommands()
    -- see commands_banish.lua
end
