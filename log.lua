-- Carl Frank Otto III
-- carlotto81@gmail.com
-- GitHub: https://github.com/M45-Science/SoftMod
-- License: MPL 2.0

local DISCONNECT_REASON = {
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
    "(unknown reason)",
}

local function protectPin(event)
    local player = game.players[event.player_index]

    local map_pin = storage.SM_Store and storage.SM_Store.mapPin
    if map_pin and map_pin.valid and event.tag and event.tag.valid and map_pin.tag_number == event.tag.tag_number then
        UTIL_MapPin()
        UTIL_SmartPrint(player, "*** You can not edit or delete the discord invite pin.")
        return true
    end

    return false
end

local function rejectPin(event)
    local player = game.players[event.player_index]

    local ltext = string.lower(event.tag.text)
    if string.find(ltext, "http") or
        string.find(ltext, "discord.gg") then
        UTIL_SmartPrint(player, "URLs are not allowed in map pins.")
        event.tag.destroy()
        return true
    end

    return false
end

function LOG_TagAdded(event)
    if not event or not event.player_index or not event.tag then
        return
    end
    local player = game.players[event.player_index]

    if rejectPin(event) then
        return
    end

    if event.tag.icon and event.tag.icon.name then
        UTIL_MsgAll(player.name .. " add-tag "
            .. UTIL_GPSObj(event.tag) .. " : " .. event.tag.icon.name .. " " .. event.tag.text)
    else
        UTIL_MsgAll(player.name .. " add-tag "
            .. UTIL_GPSObj(event.tag) .. " : " .. event.tag.text)
    end
end

function LOG_TagMod(event)
    if not event or not event.player_index or not event.tag then
        return
    end
    local player = game.players[event.player_index]

    if protectPin(event) then
        return
    end

    if rejectPin(event) then
        return
    end

    if event.tag.icon and event.tag.icon.name then
        UTIL_MsgAll(player.name .. " edit-tag "
            .. UTIL_GPSObj(event.tag) .. " : " .. event.tag.icon.name .. " " .. event.tag.text)
    else
        UTIL_MsgAll(player.name .. " edit-tag "
            .. UTIL_GPSObj(event.tag) .. " : " .. event.tag.text)
    end
end

function LOG_TagDel(event)
    if not event or not event.player_index or not event.tag then
        return
    end
    local player = game.players[event.player_index]

    if protectPin(event) then
        return
    end

    if event.tag.icon and event.tag.icon.name then
        UTIL_MsgAll(player.name .. " delete-tag "
            .. UTIL_GPSObj(event.tag) .. " : " .. event.tag.icon.name .. " " .. event.tag.text)
    else
        UTIL_MsgAll(player.name .. " delete-tag "
            .. UTIL_GPSObj(event.tag) .. " : " .. event.tag.text)
    end
end

function LOG_PlayerLeft(event)
    if not event or not event.player_index or not storage.PData or not storage.PData[event.player_index] then
        return
    end
    if storage.PData[event.player_index].lastOnline then
        storage.PData[event.player_index].lastOnline = game.tick
    end
    local player = game.players[event.player_index]
    local player_name = (player and player.name) or event.player_name or "<unknown player>"

    if event.reason then
        local reason = DISCONNECT_REASON[event.reason + 1] or "(unknown reason)"
        UTIL_MsgDiscord(player_name .. " disconnected. " .. reason)
    else
        UTIL_MsgDiscord(player_name .. " disconnected!")
    end

    ONLINE_MarkDirty()
end

function LOG_Redo(event)
    if not event or not event.player_index or not event.actions then
        return
    end
    local player = game.players[event.player_index]

    if not player or not player.character then
        return
    end

    if not UTIL_Is_New(player) and not UTIL_Is_Member(player) then
        return
    end

    local buf = ""
    for _, act in ipairs(event.actions) do
        if buf ~= "" then
            buf = buf .. ", "
        end
        buf = buf .. act.type
    end
    UTIL_ConsolePrint("[ACT] " .. player.name .. " redo " .. buf .. player.character.gps_tag)
end

function LOG_Undo(event)
    if not event or not event.player_index or not event.actions then
        return
    end
    local player = game.players[event.player_index]

    if not player or not player.character then
        return
    end

    if not UTIL_Is_New(player) and not UTIL_Is_Member(player) then
        return
    end

    local buf = ""
    for _, act in ipairs(event.actions) do
        if buf ~= "" then
            buf = buf .. ", "
        end
        buf = buf .. act.type
    end
    UTIL_ConsolePrint("[ACT] " .. player.name .. " undo " .. buf .. player.character.gps_tag)
end

function LOG_TrainSchedule(event)
    if not event or not event.player_index or not event.train then
        return
    end
    local player = game.players[event.player_index]

    local tObj = event.train.front_stock
    if tObj then
        local msg = player.name ..
            " changed schedule on train ID " .. event.train.id .. " at " .. UTIL_GPSObj(tObj)

        if UTIL_Is_Regular(player) or UTIL_Is_Veteran(player) or player.admin then
            UTIL_ConsolePrint("[ACT] " .. msg)
        else
            UTIL_MsgAll(msg)
        end
    end
end

function LOG_EntDied(event)
    if event and event.entity then
        if event.entity.name == "character" then
            return
        end
        UTIL_ConsolePrint(event.entity.name .. " died at " .. event.entity.gps_tag)
    end
end

function LOG_PickedItem(event)
    if event and event.player_index and event.item_stack then
        local player = game.players[event.player_index]

        if not player or not player.character then
            return
        end

        if not UTIL_Is_New(player) and not UTIL_Is_Member(player) then
            return
        end

        local stack = event.item_stack
        local buf = ""
        if stack.name then
            buf = buf .. stack.name
        end
        if stack.quality then
            local quality = stack.quality
            if quality ~= nil and type(quality) ~= "string" and quality.name then
                quality = quality.name
            end
            buf = buf .. " " .. tostring(quality)
        end
        if stack.count then
            buf = buf .. " " .. stack.count
        end

        if buf ~= "" then
            UTIL_ConsolePrint("[ACT] " .. player.name .. " picked up " .. buf .. " at " .. player.character.gps_tag)
        end
    end
end

function LOG_DroppedItem(event)
    if event and event.player_index and event.entity then
        local player = game.players[event.player_index]
        if not player or not player.character then
            return
        end

        UTIL_ConsolePrint("[ACT] " ..
            player.name .. " dropped " .. event.entity.name .. " at " .. player.character.gps_tag)
    end
end

-- Deconstruction planner warning
function LOG_Decon(event)
    if event and event.player_index and event.area then
        local player = game.players[event.player_index]
        local area = event.area
        local surface = event.surface


        if not player or not player.character then
            return
        end

        local pdata = storage and storage.PData and storage.PData[player.index]
        if not pdata then
            return
        end
        pdata.last_decon_check = pdata.last_decon_check or 0
        if game.tick < pdata.last_decon_check + 60 then
            return
        end
        pdata.last_decon_check = game.tick

        if player and area and area.left_top then
            local decon_size = UTIL_Distance(area.left_top, area.right_bottom)

            -- Don't bother if selection is zero.
            if decon_size < 1 then
                return
            end

            -- Ignore if the selection only contains naturally generated entities
            local found_non_natural = false
            local player_ents = surface.find_entities_filtered { area = area, force = "player", limit = 1 }
            if player_ents and player_ents[1] then
                found_non_natural = true
            else
                local enemy_ents = surface.find_entities_filtered { area = area, force = "enemy", limit = 1 }
                if enemy_ents and enemy_ents[1] then
                    found_non_natural = true
                end
            end
            if not found_non_natural then
                return
            end

            local msg = ""
            if event.alt then
                msg = "[ACT] " ..
                    player.name .. " undecon " .. UTIL_Area(surface, decon_size, event.area)
            else
                msg = "[ACT] " ..
                    player.name .. " decon " .. UTIL_Area(surface, decon_size, event.area)

                if UTIL_Is_New(player) or UTIL_Is_Member(player) then -- Dont bother with regulars/moderators
                    if not UTIL_Is_Banished(player) then              -- Don't let bansihed players use this to spam
                        UTIL_MsgAll(msg)
                    end
                end
            end

            UTIL_ConsolePrint(msg)
        end
    end
end

function LOG_MarkedUpgrade(event)
    if event and event.player_index and event.entity then
        local player = game.players[event.player_index]
        local obj = event.entity

        if player then
            local msg = "[ACT] " .. player.name .. " upgrade " .. obj.name .. " at " .. UTIL_GPSObj(obj)

            if UTIL_Is_New(player) or UTIL_Is_Member(player) then -- Dont bother with regulars/moderators
                if not UTIL_Is_Banished(player) then              -- Don't let bansihed players use this to spam
                    if UTIL_WarnOkay(event.player_index) then
                        UTIL_MsgAll(msg)
                    end
                end
            end

            UTIL_ConsolePrint(msg)
        end
    end
end

function LOG_CancelUpgrade(event)
    if event and event.player_index and event.entity then
        local player = game.players[event.player_index]
        local obj = event.entity

        if player then
            local msg = "[ACT] " .. player.name .. " cancel upgrade " .. obj.name .. " at " .. UTIL_GPSObj(obj)

            if UTIL_Is_New(player) or UTIL_Is_Member(player) then -- Dont bother with regulars/moderators
                if not UTIL_Is_Banished(player) then              -- Don't let bansihed players use this to spam
                    if UTIL_WarnOkay(event.player_index) then
                        UTIL_MsgAll(msg)
                    end
                end
            end

            UTIL_ConsolePrint(msg)
        end
    end
end

function LOG_MarkDecon(event)
    if event and event.player_index and event.entity then
        local player = game.players[event.player_index]
        local obj = event.entity

        if player then
            if UTIL_IsNatural(obj) then
                return
            end
            local msg = "[ACT] " .. player.name .. " decon " .. obj.name .. " at " .. UTIL_GPSObj(obj)

            if UTIL_Is_New(player) or UTIL_Is_Member(player) then -- Dont bother with regulars/moderators
                if not UTIL_Is_Banished(player) then              -- Don't let bansihed players use this to spam
                    if UTIL_WarnOkay(event.player_index) then
                        UTIL_MsgAll(msg)
                    end
                end
            end

            UTIL_ConsolePrint(msg)
        end
    end
end

function LOG_CancelDecon(event)
    if event and event.player_index and event.entity then
        local player = game.players[event.player_index]
        local obj = event.entity

        if not UTIL_Is_New(player) and not UTIL_Is_Member(player) then
            return
        end

        if player then
            local msg = "[ACT] " .. player.name .. " undecon " .. obj.name .. " at " .. UTIL_GPSObj(obj)

            if UTIL_Is_New(player) or UTIL_Is_Member(player) then -- Dont bother with regulars/moderators
                if not UTIL_Is_Banished(player) then              -- Don't let bansihed players use this to spam
                    if UTIL_WarnOkay(event.player_index) then
                        UTIL_MsgAll(msg)
                    end
                end
            end

            UTIL_ConsolePrint(msg)
        end
    end
end

function LOG_Flushed(event)
    if event and event.player_index then
        local player = game.players[event.player_index]
        local obj = event.entity

        if player and event.amount and event.fluid and event.amount >= 1 then
            local msg = "[ACT] " ..
                player.name ..
                " flushed " ..
                obj.name ..
                " of " .. math.floor(event.amount) .. " " .. event.fluid .. " at " .. obj.gps_tag


            if UTIL_Is_New(player) or UTIL_Is_Member(player) then -- Dont bother with regulars/moderators
                UTIL_MsgAll(msg)
            end

            UTIL_ConsolePrint(msg)
        end
    end
end

function LOG_PlayerDrive(event)
    if event.player_index and event.entity then
        local player = game.players[event.player_index]

        if player then
            local msg = ""
            if player.vehicle then
                msg = "[ACT] " ..
                    player.name ..
                    " got in a " ..
                    event.entity.name .. " at " .. event.entity.gps_tag
            else
                msg = "[ACT] " ..
                    player.name ..
                    " got out of a " ..
                    event.entity.name .. " at " .. event.entity.gps_tag
            end

            if UTIL_Is_New(player) or UTIL_Is_Member(player) then -- Dont bother with regulars/moderators
                UTIL_MsgAll(msg)
            end

            UTIL_ConsolePrint(msg)
        end
    end
end

function LOG_OrderLaunch(event)
    if event.player_index and event.rocket_silo then
        local player = game.players[event.player_index]

        local msg = "[ACT] " ..
            player.name .. " ordered a rocket launch at " .. event.rocket_silo.gps_tag
        UTIL_ConsolePrint(msg)
        UTIL_MsgAll(msg)
    end
end

function LOG_FastTransferred (event)
    if event and event.player_index and event.entity then
        local player = game.players[event.player_index]
        local obj = event.entity

        if not UTIL_Is_New(player) and not UTIL_Is_Member(player) then
            return
        end

        if player and obj then
            if event.from_player then
                UTIL_ConsolePrint("[ACT] " ..
                    player.name .. " fast-transferred items to " .. obj.name .. " at " .. obj.gps_tag)
            else
                UTIL_ConsolePrint("[ACT] " ..
                    player.name .. " fast-transferred items from " .. obj.name .. " at " .. obj.gps_tag)
            end
        end
    end
end

function LOG_InvChanged(event)
    if event and event.player_index then
        local player = game.players[event.player_index]

        if not player or not player.character then
            return
        end

        if not UTIL_Is_New(player) and not UTIL_Is_Member(player) then
            return
        end

        if player then
            UTIL_ConsolePrint("[ACT] " .. player.name .. " transferred some items at " .. player.character.gps_tag)
        end
    end
end

-- EVENTS--
-- Command logging
function LOG_ConsoleCmd(event)
    if event and event.command and event.parameters then
        local command = ""
        local args = ""

        if event.command then
            command = event.command
        else
            return
        end

        if event.parameters then
            args = event.parameters
        end

        if event.player_index then
            local player = game.players[event.player_index]
            print(string.format("[CMD] %s ran /%s %s", player.name, command, args))
        end
    end
end

-- Research Finished -- discord
function LOG_ResearchFinished(event)
    if event and event.research and not event.by_script then
        if event.research.level and event.research.level > 1 then
            UTIL_MsgDiscord("Research " ..
                event.research.name .. " (level " .. event.research.level - 1 .. ") completed.")
        else
            UTIL_MsgDiscord("Research " .. event.research.name .. " completed.")
        end
    end
end

function LOG_BuiltEnt(event)
    if not event or not event.player_index or not event.entity then
        return
    end
    local player = game.players[event.player_index]
    local obj = event.entity

    if obj.name == "programmable-speaker" or
        (obj.name == "entity-ghost" and obj.ghost_name == "programmable-speaker") then
        UTIL_MsgAll(player.name .. " placed a speaker at " .. obj.gps_tag)
        return
    end

    if obj.name ~= "tile-ghost" and obj.name ~= "tile" then
        if obj.name ~= "entity-ghost" then
            UTIL_ConsolePrint("[ACT] " .. player.name .. " placed " .. obj.name .. " " .. obj.gps_tag)
        else
            if UTIL_WarnOkay(event.player_index) then
                UTIL_ConsolePrint("[ACT] " ..
                    player.name .. " placed-ghost " .. obj.name .. " " .. obj.gps_tag ..
                    obj.ghost_name)
            end
        end
    end
end

function LOG_PreMined(event)
    if not event or not event.player_index or not event.entity then
        return
    end
    local player = game.players[event.player_index]
    local obj = event.entity

    local force_name = (obj.force and obj.force.name) or "neutral"
    if force_name ~= "enemy" and force_name ~= "neutral" then
        if obj.name ~= "tile-ghost" and obj.name ~= "tile" then
            if obj.name ~= "entity-ghost" then
                -- log
                UTIL_ConsolePrint("[ACT] " .. player.name .. " mined " .. obj.name .. " " .. obj.gps_tag)

                -- Mark player as having picked up an item, and needing to be cleaned.
                if storage and storage.PData and storage.PData[event.player_index] and storage.PData[event.player_index].cleaned then
                    storage.PData[event.player_index].cleaned = false
                end
            else
                UTIL_ConsolePrint("[ACT] " ..
                    player.name .. " mined-ghost " .. obj.name .. " " .. obj.gps_tag ..
                    obj.ghost_name)
            end
        end
    else
        EVENT_Loot(event)
    end
end

function LOG_Rotated(event)
    if not event or not event.player_index or not event.previous_direction then
        return
    end

    local player = game.players[event.player_index]
    local obj = event.entity

    -- If player and object are valid
    if obj.name ~= "tile-ghost" and obj.name ~= "tile" then
        if obj.name ~= "entity-ghost" then
            UTIL_ConsolePrint("[ACT] " .. player.name .. " rotated " .. obj.name .. " " .. obj.gps_tag)
        else
            UTIL_ConsolePrint("[ACT] " ..
                player.name .. " rotated ghost " .. obj.name .. obj.gps_tag ..
                " " .. obj.ghost_name)
        end
    end
end

function LOG_Banned(event)
    if not event or not event.player_index then
        return
    end
    local player = game.players[event.player_index]
    local player_name = (player and player.name) or event.player_name or "<unknown player>"
    UTIL_DumpInv(player, true)
    UTIL_MsgAllSys(player_name .. "'s items have been left at spawn, so they can be recovered.")
end
