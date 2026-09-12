-- Banish-related command registrations

function BANISH_AddBanishCommands()
    CMD_AddCommand("jail", "<player> (/unjail to unjail)",
        function(param)
            local player
            if param and param.player_index then
                player = game.players[param.player_index]
            end
            if CMD_ModsOnly(param) then
                return
            end

            STORAGE_EnsureGlobal()

            -- Only if name provided
            if param.parameter then
                local victim = game.players[param.parameter]

                if (victim) then
                    STORAGE_MakePlayerStorage(victim)
                    if player and victim.index == player.index then
                        UTIL_SmartPrint(player, "You can't put yourself in jail. Go touch grass.")
                        return
                    end
                    storage.PData[victim.index].banished = 1000
                    BANISH_DoJail(victim)
                    UTIL_SmartPrint(player, "Jailed player.")
                else
                    UTIL_SmartPrint(player, "Couldn't find that player.")
                end
            else
                UTIL_SmartPrint(player, "Who do you want to jail?")
            end
        end)
    CMD_AddCommand("unjail", "<player>",
        function(param)
            local player
            if param and param.player_index then
                player = game.players[param.player_index]
            end
            if CMD_ModsOnly(param) then
                return
            end

            STORAGE_EnsureGlobal()

            -- Only if name provided
            if param.parameter then
                local victim = game.players[param.parameter]

                if (victim) then
                    STORAGE_MakePlayerStorage(victim)
                    if player and victim and victim.index == player.index then
                        UTIL_SmartPrint(player, "You can't unjail yourself.")
                        return
                    end
                    storage.PData[victim.index].banished = 0
                    for _, vote in ipairs(storage.SM_Store.votes) do
                        if vote and vote.victim then
                            if vote.victim.index == victim.index then
                                vote.overruled = true
                                break
                            end
                        end
                    end
                    if not victim.character then
                        UTIL_SmartPrint(player, "They are OFFLINE right now, but will be unjailed on login.")
                    else
                        UTIL_SmartPrint(player, "Unjailed player.")
                    end

                    BANISH_UnbanishPlayer(victim)
                else
                    UTIL_SmartPrint(player, "Couldn't find that player.")
                end
            else
                UTIL_SmartPrint(player, "Who do you want unjail?")
            end
        end)
    -- Mod vote overrrule
    CMD_AddCommand("overrule",
        "Moderators only: <defendant>\n(overrule votes against defendant)\n<clear>\n(clear all votes, will unbanish all)",
        function(param)
            local player
            if param and param.player_index then
                player = game.players[param.player_index]
            end
            if CMD_ModsOnly(param) then
                return
            end

            STORAGE_EnsureGlobal()

            -- Moderator only
            if storage.SM_Store and storage.SM_Store.votes then
                local input = (param and param.parameter) or ""
                input = input:match("^%s*(.-)%s*$")
                if input == "" then
                    UTIL_SmartPrint(player,
                        "Who do you want to overrule votes against? <player> or <clear> (clears/unbanishes all)")
                    return
                end

                -- get arguments
                local args = UTIL_SplitStr(input, " ")

                -- Must have arguments
                if args and args[1] ~= "" then
                    if args[1] == "clear" then
                        storage.SM_Store.votes = {}
                        UTIL_SmartPrint(player, "All votes cleared.")
                        BANISH_UpdateVotes()
                        return
                    end
                    local victim = game.players[args[1]]

                    -- If victim found
                    if victim then
                        local count = 0
                        for _, vote in ipairs(storage.SM_Store.votes) do
                            if vote and vote.victim then
                                if vote.victim == victim and not vote.overruled then
                                    vote.overruled = true
                                    count = count + 1
                                end
                            end
                        end
                        if count > 0 then
                            UTIL_SmartPrint(player, "Overruled " .. count .. " votes against " .. victim.name)
                        else
                            for _, vote in ipairs(storage.SM_Store.votes) do
                                if vote and vote.victim then
                                    if vote.victim == victim and vote.overruled then
                                        vote.overruled = false
                                        count = count + 1
                                    end
                                end
                            end
                            UTIL_SmartPrint(player,
                                "Withdrew " .. count .. " overrulings, against " .. victim.name)
                        end
                        BANISH_UpdateVotes()
                        return
                    else
                        UTIL_SmartPrint(player, "Couldn't find a player by that name.")
                    end
                else
                    UTIL_SmartPrint(player,
                        "Who do you want to overrule votes against? <player> or <clear> (clears/unbanishes all)")
                end
            else
                UTIL_SmartPrint(player, "There are no votes to overrule.")
            end
        end)

    -- Print votes
    CMD_AddCommand("votes", "(Shows banish votes)", function(param)
        local player = CMD_GetPlayer(param)

        if not player then
            CMD_RejectConsole("The console can't review banish votes this way.")
            return
        end

        if CMD_NoBanished(player) then
            return
        end

        -- Only if banish data found
        if storage.SM_Store and storage.SM_Store.votes then
            -- Print votes
            local pcount = 0
            for _, vote in ipairs(storage.SM_Store.votes) do
                if vote and vote.voter and vote.voter.valid and vote.victim then
                    local notes = ""
                    if vote.withdrawn then
                        notes = "(WITHDRAWN) "
                    end
                    if vote.overruled then
                        notes = "(OVERRULED) "
                    end
                    pcount = pcount + 1
                    UTIL_SmartPrint(player, notes .. "plaintiff: " .. vote.voter.name .. ", defendant: " ..
                        vote.victim.name .. ", complaint:\n" .. vote.reason)
                end
            end

            -- Tally votes before proceeding
            BANISH_UpdateVotes()

            local player_indices = {}
            for player_index, _ in pairs(game.players) do
                table.insert(player_indices, player_index)
            end
            table.sort(player_indices)

            -- Print accused
            if storage.PData then
                for _, victim_index in ipairs(player_indices) do
                    local victim = game.players[victim_index]
                    if storage.PData[victim.index].banished and storage.PData[victim.index].banished > 0 then
                        UTIL_SmartPrint(player, victim.name .. " has had " .. storage.PData[victim.index].banished ..
                            " complaints against them.")
                        pcount = pcount + 1
                    end
                end
            end
            -- Show summery of votes against them
            if storage.SM_Store.votes then
                for _, victim_index in ipairs(player_indices) do
                    local victim = game.players[victim_index]
                    local votecount = 0
                    for _, vote in ipairs(storage.SM_Store.votes) do
                        if victim == vote.voter then
                            votecount = votecount + 1
                        end
                    end
                    if votecount > 2 then
                        UTIL_SmartPrint(player, victim.name .. " has voted against " .. votecount .. " players.")
                        pcount = pcount + 1
                    end
                end
            end
            -- Nothing found, report it
            if pcount <= 0 then
                UTIL_SmartPrint(player, "The docket is clean.")
            end
            return
        else
            -- No vote data
            UTIL_SmartPrint(player, "The docket is clean.")
            BANISH_UpdateVotes()
            return
        end
    end)

    -- Banish command
    CMD_AddCommand("unbanish", "<player>\n(Withdraws a banish vote)", function(param)
        if param and param.player_index then
            local player = game.players[param.player_index]
            if CMD_NoBanished(player) then
                return
            end

            if player and param.parameter then
                -- regulars/moderators players only
                if UTIL_Is_Regular(player) or UTIL_Is_Veteran(player) or player.admin then
                    -- get arguments
                    local args = UTIL_SplitStr(param.parameter, " ")

                    -- Must have arguments
                    if args and args[1] ~= "" then
                        local victim = game.players[args[1]]

                        -- Must have valid victim
                        if victim and victim.character and victim.character.valid then
                            -- Check if we voted against them
                            if storage.SM_Store.votes then
                                for _, vote in ipairs(storage.SM_Store.votes) do
                                    if vote and vote.voter and vote.victim then
                                        if vote.voter == player and vote.victim == victim then
                                            if vote.withdrawn then
                                                UTIL_SmartPrint(player, "You've already withdrawn your vote.")
                                                return
                                            end
                                            -- Send report to discord and withdraw vote
                                            local message = player.name .. " WITHDREW their vote to banish: " ..
                                                victim.name
                                            UTIL_MsgAllSys(message)
                                            CW_EmitText("report", message)
                                            UTIL_SmartPrint(player,
                                                "Your vote has been withdrawn, and posted on Discord.")
                                            vote.withdrawn = true
                                            BANISH_UpdateVotes() -- Must do this to delete from tally
                                            return
                                        end
                                    end
                                end
                                UTIL_SmartPrint(player, "I don't see a vote from you, against that player, to withdraw.")
                            end
                        else
                            UTIL_SmartPrint(player, "There are no players online by that name.")
                        end
                    else
                        UTIL_SmartPrint(player, "Usage: /unbanish <player>")
                    end
                else
                    UTIL_SmartPrint(player, "Only regulars/moderator status players can vote.")
                    return
                end
            else
                UTIL_SmartPrint(player, "Usage: /unbanish <player>")
            end
        else
            UTIL_SmartPrint(nil, "The console can't vote.")
        end
    end)

    -- Banish command
    CMD_AddCommand("banish", "<player> <reason for banishment>\n(Sends player to a confined area, off-map)",
        function(param)
            local player = CMD_GetPlayer(param)
            if not player then
                CMD_RejectConsole("The console can't file banish votes.")
                return
            end

            if not param.parameter then
                UTIL_SmartPrint(player, "Banish who?")
                return
            end
            local args = UTIL_SplitStr(param.parameter, " ")
            if not args[2] then
                UTIL_SmartPrint(player, "You must specify a reason.")
                return
            end
            local victim = game.players[args[1]]

            -- Quick arg combine
            local reason = table.concat(args, " ", 2)

            if UTIL_Is_Banished(victim) then
                UTIL_SmartPrint(player, "They are already banished!")
                return
            end

            BANISH_DoBanish(player, victim, reason)
        end)

    -- User report command
    CMD_AddCommand("report", "<detailed report here>\n(Sends in a report to the moderators)", function(param)
        if param and param.player_index then
            local player = game.players[param.player_index]
            if CMD_NoBanished(player) then
                return
            end
            BANISH_DoReport(player, param.parameter)
        else
            UTIL_SmartPrint(nil, "The console doesn't need to send in reports this way.")
        end
    end)
end
