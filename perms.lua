-- Carl Frank Otto III
-- carlotto81@gmail.com
-- GitHub: https://github.com/M45-Science/SoftMod
-- License: MPL 2.0

function PERMS_MakeNew(player, victim)
    if victim  then
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
        return
    end
end

function PERMS_MakeMember(player, victim)
    if victim then
        if victim and storage.SM_Store.memGroup then
            UTIL_SmartPrint(player, "Player given members status.")
            UTIL_MsgAll(victim.name .. " is now a member!")
            if storage.PData and storage.PData[victim.index] then
                storage.PData[victim.index].level = 1
            end
            storage.SM_Store.memGroup.add_player(victim)
            ONLINE_MarkDirty()
            return
        end
    end
end

function PERMS_MakeRegular(player, victim)
    if (victim) then
        if victim  and storage.SM_Store.regGroup then
            UTIL_SmartPrint(player, "Player given regulars status.")
            UTIL_MsgAll(victim.name .. " is now a regular!")

            if storage.PData and storage.PData[victim.index] then
                storage.PData[victim.index].level = 2
            end
            storage.SM_Store.regGroup.add_player(victim)
            ONLINE_MarkDirty()
            return
        end
    end
end

function PERMS_MakeVeteran(player, victim)
    if (victim) then
        if victim and storage.SM_Store.vetGroup then
            UTIL_SmartPrint(player, "Player given veterans status.")
            UTIL_MsgAll(victim.name .. " is now a veteran!")
            if storage.PData and storage.PData[victim.index] then
                storage.PData[victim.index].level = 3
            end
            storage.SM_Store.vetGroup.add_player(victim)
            ONLINE_MarkDirty()
            return
        end
    end
end

-- Create player groups if they don't exist, and create storage links to them

-- Walk the input_action lists below with pairs(), never ipairs(). When Factorio
-- removes an action, defines.input_action.<name> evaluates to nil and leaves a
-- hole in the table constructor. ipairs() stops at that hole and silently skips
-- every remaining entry; pairs() skips only the missing one. This is not
-- theoretical: enable_transitional_requests was removed during 2.0.5x and
-- translate_string in 2.1.7, which truncated the jail list to its first 90 of
-- 265 actions until 2026-08.

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
        for _, action in pairs(DEF_GROUP_ALWAYS_DISABLED) do
            storage.SM_Store.defGroup.set_allows_action(action, false)
        end
    end

    if not storage.SM_Store.jailGroup then
        return
    end

    local actionList = {
        defines.input_action.activate_interrupt,
        defines.input_action.activate_paste,
        defines.input_action.add_decider_combinator_condition,
        defines.input_action.add_decider_combinator_else_output,
        defines.input_action.add_decider_combinator_output,
        defines.input_action.add_logistic_section,
        defines.input_action.add_permission_group,
        defines.input_action.add_pin,
        defines.input_action.add_train_interrupt,
        defines.input_action.add_train_station,
        defines.input_action.adjust_blueprint_snapping,
        defines.input_action.admin_action,
        defines.input_action.alt_reverse_select_area,
        defines.input_action.alt_select_area,
        defines.input_action.alt_select_blueprint_entities,
        defines.input_action.alternative_copy,
        defines.input_action.begin_mining,
        defines.input_action.begin_mining_terrain,
        defines.input_action.build,
        defines.input_action.build_rail,
        defines.input_action.build_terrain,
        defines.input_action.cancel_craft,
        defines.input_action.cancel_deconstruct,
        defines.input_action.cancel_delete_space_platform,
        defines.input_action.cancel_new_blueprint,
        defines.input_action.cancel_research,
        defines.input_action.cancel_upgrade,
        defines.input_action.change_active_character_tab,
        defines.input_action.change_active_item_group_for_crafting,
        defines.input_action.change_active_item_group_for_filters,
        defines.input_action.change_active_quick_bar,
        defines.input_action.change_arithmetic_combinator_parameters,
        defines.input_action.change_entity_label,
        defines.input_action.change_item_label,
        defines.input_action.change_logistic_point_group,
        defines.input_action.change_multiplayer_config,
        defines.input_action.change_picking_state,
        defines.input_action.change_programmable_speaker_alert_parameters,
        defines.input_action.change_programmable_speaker_circuit_parameters,
        defines.input_action.change_programmable_speaker_parameters,
        defines.input_action.change_research_condition,
        defines.input_action.change_riding_state,
        defines.input_action.change_selector_combinator_parameters,
        defines.input_action.change_shooting_state,
        defines.input_action.change_train_name,
        defines.input_action.change_train_station,
        defines.input_action.change_train_stop_station,
        defines.input_action.change_train_wait_condition,
        defines.input_action.change_train_wait_condition_data,
        defines.input_action.clear_cursor,
        defines.input_action.connect_rolling_stock,
        defines.input_action.copy,
        defines.input_action.copy_entity_settings,
        defines.input_action.copy_large_opened_blueprint,
        defines.input_action.copy_large_opened_item,
        defines.input_action.copy_opened_blueprint,
        defines.input_action.copy_opened_item,
        defines.input_action.craft,
        defines.input_action.create_space_platform,
        defines.input_action.cursor_split,
        defines.input_action.cursor_transfer,
        defines.input_action.custom_input,
        defines.input_action.cycle_blueprint_book_backwards,
        defines.input_action.cycle_blueprint_book_forwards,
        defines.input_action.cycle_quality_down,
        defines.input_action.cycle_quality_up,
        defines.input_action.deconstruct,
        defines.input_action.delete_blueprint_library,
        defines.input_action.delete_blueprint_record,
        defines.input_action.delete_custom_tag,
        defines.input_action.delete_logistic_group,
        defines.input_action.delete_permission_group,
        defines.input_action.delete_space_platform,
        defines.input_action.destroy_item,
        defines.input_action.destroy_opened_item,
        defines.input_action.disconnect_rolling_stock,
        defines.input_action.drag_decider_combinator_condition,
        defines.input_action.drag_decider_combinator_else_output,
        defines.input_action.drag_decider_combinator_output,
        defines.input_action.drag_research_condition,
        defines.input_action.drag_train_schedule,
        defines.input_action.drag_train_schedule_interrupt,
        defines.input_action.drag_train_wait_condition,
        defines.input_action.drop_blueprint_record,
        defines.input_action.drop_item,
        defines.input_action.edit_blueprint_tool_preview,
        defines.input_action.edit_custom_tag,
        defines.input_action.edit_display_panel,
        defines.input_action.edit_display_panel_always_show,
        defines.input_action.edit_display_panel_icon,
        defines.input_action.edit_display_panel_parameters,
        defines.input_action.edit_display_panel_show_in_chart,
        defines.input_action.edit_interrupt,
        defines.input_action.edit_permission_group,
        defines.input_action.edit_pin,
        defines.input_action.export_blueprint,
        defines.input_action.fast_entity_split,
        defines.input_action.fast_entity_transfer,
        defines.input_action.flip_entity,
        defines.input_action.flush_opened_entity_fluid,
        defines.input_action.flush_opened_entity_specific_fluid,
        defines.input_action.go_to_train_station,
        defines.input_action.grab_blueprint_record,
        defines.input_action.gui_checked_state_changed,
        defines.input_action.gui_confirmed,
        defines.input_action.gui_elem_changed,
        defines.input_action.gui_hover,
        defines.input_action.gui_inventory_action,
        defines.input_action.gui_inventory_bar_changed,
        defines.input_action.gui_inventory_filter_changed,
        defines.input_action.gui_leave,
        defines.input_action.gui_location_changed,
        defines.input_action.gui_selected_tab_changed,
        defines.input_action.gui_selection_state_changed,
        defines.input_action.gui_switch_state_changed,
        defines.input_action.gui_text_changed,
        defines.input_action.gui_value_changed,
        defines.input_action.import_blueprint,
        defines.input_action.import_blueprint_string,
        defines.input_action.import_blueprints_filtered,
        defines.input_action.import_permissions_string,
        defines.input_action.instantly_create_space_platform,
        defines.input_action.inventory_split,
        defines.input_action.inventory_transfer,
        defines.input_action.land_at_planet,
        defines.input_action.launch_rocket,
        defines.input_action.lua_shortcut,
        defines.input_action.map_editor_action,
        defines.input_action.market_offer,
        defines.input_action.mod_settings_changed,
        defines.input_action.modify_decider_combinator_condition,
        defines.input_action.modify_decider_combinator_else_output,
        defines.input_action.modify_decider_combinator_output,
        defines.input_action.move_research,
        defines.input_action.open_achievements_gui,
        defines.input_action.open_blueprint_library_gui,
        defines.input_action.open_blueprint_record,
        defines.input_action.open_bonus_gui,
        defines.input_action.open_character_gui,
        defines.input_action.open_current_vehicle_gui,
        defines.input_action.open_equipment,
        defines.input_action.open_global_electric_network_gui,
        defines.input_action.open_gui,
        defines.input_action.open_item,
        defines.input_action.open_logistics_gui,
        defines.input_action.open_mod_item,
        defines.input_action.open_new_platform_button_from_rocket_silo,
        defines.input_action.open_opened_entity_grid,
        defines.input_action.open_parent_of_opened_item,
        defines.input_action.open_production_gui,
        defines.input_action.open_train_gui,
        defines.input_action.open_train_station_gui,
        defines.input_action.open_trains_gui,
        defines.input_action.parametrise_blueprint,
        defines.input_action.paste_entity_settings,
        defines.input_action.pin_alert_group,
        defines.input_action.pin_custom_alert,
        defines.input_action.pin_search_result,
        defines.input_action.pipette,
        defines.input_action.place_equipment,
        defines.input_action.providing_to_other_platforms,
        defines.input_action.quick_bar_pick_slot,
        defines.input_action.quick_bar_set_selected_page,
        defines.input_action.quick_bar_set_slot,
        defines.input_action.reassign_blueprint,
        defines.input_action.redo,
        defines.input_action.remote_view_entity,
        defines.input_action.remote_view_surface,
        defines.input_action.remove_cables,
        defines.input_action.remove_decider_combinator_condition,
        defines.input_action.remove_decider_combinator_else_output,
        defines.input_action.remove_decider_combinator_output,
        defines.input_action.remove_logistic_section,
        defines.input_action.remove_pin,
        defines.input_action.remove_train_interrupt,
        defines.input_action.remove_train_station,
        defines.input_action.rename_interrupt,
        defines.input_action.rename_space_platform,
        defines.input_action.reorder_logistic_section,
        defines.input_action.request_missing_construction_materials,
        defines.input_action.reset_assembling_machine,
        defines.input_action.reverse_select_area,
        defines.input_action.rotate_entity,
        defines.input_action.select_area,
        defines.input_action.select_asteroid_chunk_slot,
        defines.input_action.select_blueprint_entities,
        defines.input_action.select_entity_filter_slot,
        defines.input_action.select_entity_slot,
        defines.input_action.select_item_filter,
        defines.input_action.select_mapper_slot_from,
        defines.input_action.select_mapper_slot_to,
        defines.input_action.select_next_valid_gun,
        defines.input_action.select_tile_slot,
        defines.input_action.send_spidertron,
        defines.input_action.send_stack_to_trash,
        defines.input_action.send_stacks_to_trash,
        defines.input_action.send_train_to_pin_target,
        defines.input_action.set_behavior_mode,
        defines.input_action.set_car_weapons_control,
        defines.input_action.set_cheat_mode_quality,
        defines.input_action.set_circuit_condition,
        defines.input_action.set_circuit_mode_of_operation,
        defines.input_action.set_combinator_description,
        defines.input_action.set_control_behavior_input_networks,
        defines.input_action.set_control_behavior_output_networks,
        defines.input_action.set_copy_color_from_train_stop,
        defines.input_action.set_deconstruction_item_tile_selection_mode,
        defines.input_action.set_deconstruction_item_trees_and_rocks_only,
        defines.input_action.set_entity_color,
        defines.input_action.set_entity_energy_property,
        defines.input_action.set_equipment_energy_property,
        defines.input_action.set_filter,
        defines.input_action.set_ghost_cursor,
        defines.input_action.set_heat_interface_mode,
        defines.input_action.set_heat_interface_temperature,
        defines.input_action.set_infinity_container_filter_item,
        defines.input_action.set_infinity_container_logistic_mode,
        defines.input_action.set_infinity_container_remove_unfiltered_items,
        defines.input_action.set_infinity_pipe_filter,
        defines.input_action.set_inserter_max_stack_size,
        defines.input_action.set_inventory_bar,
        defines.input_action.set_lamp_always_on,
        defines.input_action.set_linked_container_link_i_d,
        defines.input_action.set_logistic_filter_item,
        defines.input_action.set_logistic_network_name,
        defines.input_action.set_logistic_section_active,
        defines.input_action.set_player_color,
        defines.input_action.set_pump_fluid_filter,
        defines.input_action.set_request_from_buffers,
        defines.input_action.set_research_finished_stops_game,
        defines.input_action.set_rocket_silo_send_to_orbit_automated_mode,
        defines.input_action.set_schedule_record_allow_unloading,
        defines.input_action.set_signal,
        defines.input_action.set_splitter_priority,
        defines.input_action.set_spoil_priority,
        defines.input_action.set_train_stop_priority,
        defines.input_action.set_train_stopped,
        defines.input_action.set_trains_limit,
        defines.input_action.set_turret_ignore_unlisted,
        defines.input_action.set_use_inserter_filters,
        defines.input_action.set_vehicle_automatic_targeting_parameters,
        defines.input_action.setup_assembling_machine,
        defines.input_action.setup_blueprint,
        defines.input_action.setup_single_blueprint_record,
        defines.input_action.spawn_item,
        defines.input_action.spectator_change_surface,
        defines.input_action.stack_split,
        defines.input_action.stack_transfer,
        defines.input_action.start_repair,
        defines.input_action.start_research,
        defines.input_action.stop_drag_build,
        defines.input_action.super_forced_select_area,
        defines.input_action.swap_logistic_filter_items,
        defines.input_action.switch_connect_to_logistic_network,
        defines.input_action.switch_constant_combinator_state,
        defines.input_action.switch_inserter_filter_mode_state,
        defines.input_action.switch_loader_filter_mode,
        defines.input_action.switch_mining_drill_filter_mode_state,
        defines.input_action.switch_power_switch_state,
        defines.input_action.take_equipment,
        defines.input_action.toggle_artillery_auto_targeting,
        defines.input_action.toggle_blueprint_snap_to_grid,
        defines.input_action.toggle_deconstruction_item_entity_filter_mode,
        defines.input_action.toggle_deconstruction_item_tile_filter_mode,
        defines.input_action.toggle_driving,
        defines.input_action.toggle_enable_vehicle_logistics_while_moving,
        defines.input_action.toggle_entity_logistic_requests,
        defines.input_action.toggle_equipment_movement_bonus,
        defines.input_action.toggle_map_editor,
        defines.input_action.toggle_personal_logistic_requests,
        defines.input_action.toggle_personal_roboport,
        defines.input_action.toggle_selected_entity,
        defines.input_action.toggle_show_entity_info,
        defines.input_action.toggle_tall_entity_visibility,
        defines.input_action.trash_not_requested_items,
        defines.input_action.undo,
        defines.input_action.upgrade,
        defines.input_action.upgrade_opened_blueprint_by_item,
        defines.input_action.upgrade_opened_blueprint_by_record,
        defines.input_action.use_item,
        defines.input_action.wire_dragging,
    }
    for _, item in pairs(actionList) do
        storage.SM_Store.jailGroup.set_allows_action(item, false)
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
        for _, action in pairs(BLUEPRINT_ACTIONS) do
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

        for _, action in pairs(DEF_GROUP_TOGGLED) do
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
