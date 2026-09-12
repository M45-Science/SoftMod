-- Carl Frank Otto III
-- carlotto81@gmail.com
-- GitHub: https://github.com/M45-Science/SoftMod
-- License: MPL 2.0

function PERMS_MakeNew(player, victim)
    if victim  then
            local changed = not storage.PData or not storage.PData[victim.index] or storage.PData[victim.index].level ~= 0
            UTIL_SmartPrint(player, "Player set to new.")
            UTIL_MsgAll(victim.name .. " is now reset!")
            if storage.PData and storage.PData[victim.index] then
                storage.PData[victim.index].level = 0
                storage.PData[victim.index].score = 0
                storage.PData[victim.index].lastPromoScore = 0
            end
            if victim and storage.SM_Store.defGroup then
                storage.SM_Store.defGroup.add_player(victim)
            end
            if changed and CW_EmitEvent then
                CW_EmitEvent("player-level", { name = victim.name, level = 0 })
            end
            ONLINE_MarkDirty()
        return
    end
end

function PERMS_MakeMember(player, victim)
    if victim then
        if victim and storage.SM_Store.memGroup then
            local changed = not storage.PData or not storage.PData[victim.index] or storage.PData[victim.index].level ~= 1
            UTIL_SmartPrint(player, "Player given members status.")
            UTIL_MsgAll(victim.name .. " is now a member!")
            if storage.PData and storage.PData[victim.index] then
                storage.PData[victim.index].level = 1
            end
            storage.SM_Store.memGroup.add_player(victim)
            if changed and CW_EmitEvent then
                CW_EmitEvent("player-level", { name = victim.name, level = 1 })
            end
            ONLINE_MarkDirty()
            return
        end
    end
end

function PERMS_MakeRegular(player, victim)
    if (victim) then
        if victim  and storage.SM_Store.regGroup then
            local changed = not storage.PData or not storage.PData[victim.index] or storage.PData[victim.index].level ~= 2
            UTIL_SmartPrint(player, "Player given regulars status.")
            UTIL_MsgAll(victim.name .. " is now a regular!")

            if storage.PData and storage.PData[victim.index] then
                storage.PData[victim.index].level = 2
            end
            storage.SM_Store.regGroup.add_player(victim)
            if changed and CW_EmitEvent then
                CW_EmitEvent("player-level", { name = victim.name, level = 2 })
            end
            ONLINE_MarkDirty()
            return
        end
    end
end

function PERMS_MakeVeteran(player, victim)
    if (victim) then
        if victim and storage.SM_Store.vetGroup then
            local changed = not storage.PData or not storage.PData[victim.index] or storage.PData[victim.index].level ~= 3
            UTIL_SmartPrint(player, "Player given veterans status.")
            UTIL_MsgAll(victim.name .. " is now a veteran!")
            if storage.PData and storage.PData[victim.index] then
                storage.PData[victim.index].level = 3
            end
            storage.SM_Store.vetGroup.add_player(victim)
            if changed and CW_EmitEvent then
                CW_EmitEvent("player-level", { name = victim.name, level = 3 })
            end
            ONLINE_MarkDirty()
            return
        end
    end
end

-- Create player groups if they don't exist, and create storage links to them
-- Actions that the default group should never be allowed to perform
local DEF_GROUP_ALWAYS_DISABLED = {
    defines.input_action.deconstruct,
    defines.input_action.activate_paste,
    defines.input_action.copy_large_opened_item,
    defines.input_action.copy_large_opened_blueprint,
}

-- Input actions toggled in PERMS_SetPermissions for the default group
local DEF_GROUP_TOGGLED = {
    defines.input_action.change_programmable_speaker_alert_parameters,
    defines.input_action.change_programmable_speaker_circuit_parameters,
    defines.input_action.change_programmable_speaker_parameters,
    defines.input_action.launch_rocket,
    --defines.input_action.cancel_research, -- intentionally disabled
    defines.input_action.cancel_upgrade,
    defines.input_action.upgrade,
    -- Added 1-2022
    defines.input_action.delete_blueprint_library,
    defines.input_action.drop_blueprint_record,
    defines.input_action.import_blueprint,
    defines.input_action.import_blueprint_string,
    defines.input_action.import_blueprints_filtered,
    defines.input_action.reassign_blueprint,
    defines.input_action.cancel_deconstruct,
}

-- Blueprint related actions that can be toggled per permission group
local BLUEPRINT_ACTIONS = {
    defines.input_action.alt_select_blueprint_entities,
    defines.input_action.cancel_new_blueprint,
    defines.input_action.copy_opened_blueprint,
    defines.input_action.cycle_blueprint_book_backwards,
    defines.input_action.cycle_blueprint_book_forwards,
    defines.input_action.delete_blueprint_library,
    defines.input_action.delete_blueprint_record,
    defines.input_action.drop_blueprint_record,
    defines.input_action.edit_blueprint_tool_preview,
    defines.input_action.export_blueprint,
    defines.input_action.grab_blueprint_record,
    defines.input_action.import_blueprint,
    defines.input_action.import_blueprint_string,
    defines.input_action.import_blueprints_filtered,
    defines.input_action.open_blueprint_library_gui,
    defines.input_action.open_blueprint_record,
    defines.input_action.reassign_blueprint,
    defines.input_action.select_blueprint_entities,
    defines.input_action.setup_blueprint,
    defines.input_action.setup_single_blueprint_record,
    defines.input_action.upgrade_opened_blueprint_by_item,
    defines.input_action.upgrade_opened_blueprint_by_record,
}

function PERMS_EnsureGroups()
    if STORAGE_EnsureGlobal then
        STORAGE_EnsureGlobal()
    end
    if not storage or not storage.SM_Store then
        return false
    end

    local created = false

    local function ensure_group(name, store_key)
        local group = game.permissions.get_group(name)
        if not group then
            game.permissions.create_group(name)
            group = game.permissions.get_group(name)
            created = true
        end
        storage.SM_Store[store_key] = group
    end

    ensure_group("Jailed", "jailGroup")
    ensure_group("Default", "defGroup")
    ensure_group("Members", "memGroup")
    ensure_group("Regulars", "regGroup")
    ensure_group("Veterans", "vetGroup")
    ensure_group("Moderators", "modGroup")

    if created then
        storage.SM_Store.perms_static_applied = false
    end

    return created
end

function PERMS_ApplyStaticPermissions()
    if STORAGE_EnsureGlobal then
        STORAGE_EnsureGlobal()
    end
    if not storage or not storage.SM_Store then
        return
    end

    PERMS_EnsureGroups()

    if storage.SM_Store.perms_static_applied then
        return
    end

    --Always disabled
    if storage.SM_Store.defGroup then
        for _, action in ipairs(DEF_GROUP_ALWAYS_DISABLED) do
            storage.SM_Store.defGroup.set_allows_action(action, false)
        end
    end

    if not storage.SM_Store.jailGroup then
        return
    end

    --No longer version specific, because wube will just... deletes enums apparently.
    local allowedActions = {
        [defines.input_action.gui_click] = true,
        [defines.input_action.start_walking] = true,
        [defines.input_action.write_to_console] = true,
    }

    -- Jailed players may walk, talk, and close the banish notice. Deny every
    -- other current input action, including map, surface, and remote-view access.
    for _, action in pairs(defines.input_action) do
        storage.SM_Store.jailGroup.set_allows_action(action, allowedActions[action] == true)
    end

    storage.SM_Store.perms_static_applied = true
end

-- Back-compat entrypoint for older call sites.
function PERMS_MakeUserGroups()
    PERMS_ApplyStaticPermissions()
end

function PERMS_SetBlueprintsAllowed(group, option)
    PERMS_EnsureGroups()
    if group then
        for _, action in ipairs(BLUEPRINT_ACTIONS) do
            group.set_allows_action(action, option)
        end
    end
end

-- Disable some permissions for new players, minimal mode
function PERMS_SetPermissions()
    -- Auto set default group permissions
    PERMS_EnsureGroups()

    if storage.SM_Store.defGroup then
        -- If new user restrictions are on, then disable all permissions
        -- Otherwise undo
        local option = true
        if storage.SM_Store.restrictNew then
            option = false
        end

        for _, action in ipairs(DEF_GROUP_TOGGLED) do
            storage.SM_Store.defGroup.set_allows_action(action, option)
        end
    end
end

-- Flag player as currently moving
function PERMS_SetPlayerMoving(player)
    if (player and player.connected) then
        -- banished players don't get move score
        if not UTIL_Is_Banished(player) then
            storage.PData[player.index].moving = true
        end
    end
end

-- Flag player as currently active
function PERMS_SetPlayerActive(player)
    if (player and player.connected) then
        -- banished players don't get activity score
        if not UTIL_Is_Banished(player) then
            storage.PData[player.index].active = true
        end
    end
end

function PERMS_PromotePlayer(player)
    if not storage.SM_Store then
        return
    end

    PERMS_EnsureGroups()

    if not player.permission_group then
        --Fix nil permissions
        if storage.SM_Store.defGroup then
            storage.SM_Store.defGroup.add_player(player)
        end
    end

    -- Check if groups are valid
    if player.permission_group then
        --Workaround for sandbox mod
        if string.match(player.permission_group.name, "^" .. "bpsb-perms-") then
            return
        end
        if UTIL_Is_Banished(player) then
            if player.permission_group.name ~= storage.SM_Store.jailGroup.name then
                storage.SM_Store.jailGroup.add_player(player)
                UTIL_MsgAll(player.name .. " moved to jailed group.")       
                ONLINE_MarkDirty()
            end
        elseif (player.admin and player.permission_group.name ~= storage.SM_Store.modGroup.name) then
            storage.SM_Store.modGroup.add_player(player)
            UTIL_MsgAll(player.name .. " moved to moderators group")
            ONLINE_MarkDirty()
            if storage.PData and storage.PData[player.index] then
                storage.PData[player.index].level = 255
            end
            CW_EmitEvent("player-level", { name = player.name, level = 255 })
        elseif (storage.PData[player.index].score and
                storage.PData[player.index].score > (4 * 60 * 60 * 60) and not player.admin) then
            -- Check if player has hours for regulars status, but isn't a in regulars group.
            if (player.permission_group.name ~= storage.SM_Store.regGroup.name and
                    player.permission_group.name ~= storage.SM_Store.vetGroup.name) then
                storage.SM_Store.regGroup.add_player(player)
                UTIL_MsgAll(player.name .. " is now a regular!")
                ONLINE_MarkDirty()
                PERMS_WelcomeMember(player)
                if storage.PData and storage.PData[player.index] then
                    storage.PData[player.index].level = 2
                end
                CW_EmitEvent("player-level", { name = player.name, level = 2 })
            end
        elseif (storage.PData[player.index].score and
                storage.PData[player.index].score > (30 * 60 * 60) and not player.admin) then
            -- Check if player has hours for members status, but isn't a in member group.
            if not UTIL_Is_Veteran(player) and not UTIL_Is_Regular(player) and not UTIL_Is_Member(player) and UTIL_Is_New(player) then
                storage.SM_Store.memGroup.add_player(player)
                UTIL_MsgAll(player.name .. " is now a member!")
                ONLINE_MarkDirty()
                if storage.PData and storage.PData[player.index] then
                    storage.PData[player.index].level = 1
                end
                CW_EmitEvent("player-level", { name = player.name, level = 1 })
                PERMS_WelcomeMember(player)
            end
        end
    end
end

-- Automatically promote users to higher levels
function PERMS_PromoteAllPlayers()
    PERMS_EnsureGroups()

    -- Check all connected players
    for _, player in ipairs(game.connected_players) do
        if (player and player.valid) then
            if not storage.PData or not storage.PData[player.index] then
                STORAGE_MakePlayerStorage(player)
            end

            local pdata = storage.PData and storage.PData[player.index]
            if pdata then
                local next_tick = pdata.nextPromoTick or 0
                if game.tick >= next_tick then
                    -- Only reevaluate when score changes (unless admin/banished/uninitialized group)
                    local score = pdata.score or 0
                    local should_check = true
                    if player.permission_group and (not player.admin) and (not UTIL_Is_Banished(player)) then
                        if pdata.lastPromoScore == score then
                            should_check = false
                        end
                    end

                    if should_check or (not player.permission_group) then
                        pdata.lastPromoScore = score
                        PERMS_PromotePlayer(player)
                    end

                    -- Default cadence: once per minute per online player
                    pdata.nextPromoTick = game.tick + (60 * 60)
                end
            else
                PERMS_PromotePlayer(player)
            end
        end
    end
end

function PERMS_WelcomeMember(player)
    if player then
        if player.gui.screen then
            if player.gui.screen.member_welcome then
                player.gui.screen.member_welcome.destroy()
            else
                local tfont = "[font=default-large-bold]"
                local efont = "[/font]"

                local lname = "members"
                if UTIL_Is_Regular(player) then
                    lname = "regulars"
                end

                local main_flow = player.gui.screen.add {
                    type = "frame",
                    name = "member_welcome",
                    direction = "vertical"
                }

                local info_titlebar = main_flow.add {
                    type = "flow",
                    direction = "horizontal"
                }

                info_titlebar.drag_target = main_flow
                info_titlebar.add {
                    type = "label",
                    name = "member_welcome_title",
                    style = "frame_title",
                    caption = "Congratulations!"
                }

                local pusher = info_titlebar.add {
                    type = "empty-widget",
                    style = "draggable_space_header"
                }

                pusher.style.vertically_stretchable = true
                pusher.style.horizontally_stretchable = true
                pusher.drag_target = main_flow

                info_titlebar.add {
                    type = "sprite-button",
                    name = "m45_member_welcome_close",
                    sprite = "utility/close",
                    style = "frame_action_button",
                    tooltip = "Close this window"
                }

                main_flow.style.padding = 4
                local mframe = main_flow.add {
                    type = "flow",
                    direction = "horizontal"
                }
                local lframe = mframe.add {
                    type = "flow",
                    direction = "vertical"
                }
                lframe.style.padding = 4
                lframe.add {
                    type = "sprite",
                    sprite = "file/img/info-win/m45-128.png",
                    tooltip = ""
                }

                local rframe = mframe.add {
                    type = "flow",
                    direction = "vertical"
                }
                rframe.add {
                    type = "label",
                    caption = tfont .. "You have been active enough, that you have automatically been promoted to the '" ..
                        lname .. "' group!" .. efont
                }
                rframe.add {
                    type = "label",
                    caption = tfont .. "You can now access members-only servers and have increased permissions!" ..
                        efont
                }

                if UTIL_Is_Regular(player) then
                    rframe.add {
                        type = "label",
                        caption = tfont .. "You now also have access to BANISH in the players-online window:" .. efont
                    }
                    local online_32 = rframe.add {
                        type = "sprite-button",
                        name = "online_button",
                        sprite = "file/img/buttons/online-64.png",
                        tooltip = "See players online, report and banish."
                    }
                    online_32.style.size = { 64, 64 }
                    rframe.add {
                        type = "label",
                        caption = tfont .. "You can also vote to rewind, reset, or skip-reset the map on Discord." ..
                            efont
                    }
                end

                rframe.add {
                    type = "label",
                    caption = ""
                }

                rframe.add {
                    type = "label",
                    caption = tfont .. "To find out more, click the HELP-INFO button here: " .. efont
                }
                local m45_32 = rframe.add {
                    type = "sprite-button",
                    name = "m45_button",
                    sprite = "file/img/buttons/m45-64.png",
                    tooltip = "Opens the server-info window."
                }
                m45_32.style.size = { 64, 64 }
            end
        end
    end
end
