-- Carl Frank Otto III
-- carlotto81@gmail.com
-- GitHub: https://github.com/M45-Science/SoftMod
-- License: MPL 2.0

local FORCEDEL_BUTTON_NAME = "m45_force_delete_toggle"
local FORCEDEL_SPRITE = "file/img/buttons/force-delete-64.png"
local FORCEDEL_ARMED_SPRITE = "file/img/buttons/force-delete-armed-64.png"

local FORCEDEL_CONFIRM_WINDOW = "m45_force_delete_confirm_window"
local FORCEDEL_CONFIRM_CLOSE = "m45_force_delete_confirm_close"
local FORCEDEL_CONFIRM_CONFIRM = "m45_force_delete_confirm_confirm"
local FORCEDEL_CONFIRM_CANCEL = "m45_force_delete_confirm_cancel"

local function is_armed(player)
    return storage and storage.PData and storage.PData[player.index] and storage.PData[player.index].force_delete_armed
end

local function set_armed(player, armed)
    if not (player and player.valid) then
        return
    end
    STORAGE_EnsureGlobal()
    STORAGE_MakePlayerStorage(player)

    storage.PData[player.index].force_delete_armed = armed and true or false
end

local function clear_pending(player)
    if not (player and player.valid) then
        return
    end
    if not (storage and storage.PData and storage.PData[player.index]) then
        return
    end

    storage.PData[player.index].force_delete_pending_entity = nil
    storage.PData[player.index].force_delete_pending_name = nil
    storage.PData[player.index].force_delete_pending_gps = nil
end

local function set_pending(player, entity)
    if not (player and player.valid and entity and entity.valid) then
        return
    end
    STORAGE_EnsureGlobal()
    STORAGE_MakePlayerStorage(player)

    storage.PData[player.index].force_delete_pending_entity = entity
    storage.PData[player.index].force_delete_pending_name = entity.name
    storage.PData[player.index].force_delete_pending_gps = UTIL_GPSObj(entity)
end

local function destroy_confirm_window(player)
    if not (player and player.valid and player.gui and player.gui.screen) then
        return
    end
    if player.gui.screen[FORCEDEL_CONFIRM_WINDOW] then
        player.gui.screen[FORCEDEL_CONFIRM_WINDOW].destroy()
    end
end

local function open_confirm_window(player, entity)
    if not (player and player.valid and player.admin) then
        return
    end
    if not (entity and entity.valid) then
        return
    end
    if not (player.gui and player.gui.screen) then
        return
    end

    destroy_confirm_window(player)
    set_pending(player, entity)

    local pdata = storage and storage.PData and storage.PData[player.index]
    local name = (pdata and pdata.force_delete_pending_name) or entity.name
    local gps = (pdata and pdata.force_delete_pending_gps) or UTIL_GPSObj(entity)

    local main_flow_def = {
        type = "frame",
        name = FORCEDEL_CONFIRM_WINDOW,
        direction = "vertical"
    }
    local main_flow = player.gui.screen.add(main_flow_def)
    main_flow.style.horizontal_align = "center"
    main_flow.style.vertical_align = "center"
    main_flow.style.minimal_width = 420
    main_flow.style.padding = 4

    local titlebar = main_flow.add {
        type = "flow",
        direction = "horizontal"
    }
    titlebar.drag_target = main_flow
    titlebar.style.horizontal_align = "center"
    titlebar.style.horizontally_stretchable = true

    titlebar.add {
        type = "label",
        style = "frame_title",
        caption = "Force Delete"
    }

    local pusher = titlebar.add {
        type = "empty-widget",
        style = "draggable_space_header"
    }
    pusher.style.vertically_stretchable = true
    pusher.style.horizontally_stretchable = true
    pusher.drag_target = main_flow

    titlebar.add {
        type = "sprite-button",
        name = FORCEDEL_CONFIRM_CLOSE,
        sprite = "utility/close",
        style = "frame_action_button",
        tooltip = "Close"
    }

    local body = main_flow.add {
        type = "flow",
        direction = "vertical"
    }
    body.style.minimal_width = 420
    body.style.horizontal_align = "center"

    body.add {
        type = "label",
        caption = "Delete this entity?"
    }
    body.add {
        type = "label",
        caption = name .. " " .. gps
    }
    local warn = body.add {
        type = "label",
        caption = "This cannot be undone."
    }
    warn.style.font_color = { r = 1, g = 0.3, b = 0.3 }

    local buttons = main_flow.add {
        type = "flow",
        direction = "horizontal"
    }
    buttons.style.horizontally_stretchable = true
    buttons.style.horizontal_align = "center"
    buttons.style.top_padding = 6

    buttons.add {
        type = "button",
        name = FORCEDEL_CONFIRM_CONFIRM,
        caption = "Confirm",
        style = "red_button",
        tooltip = "Force-delete this entity"
    }
    buttons.add {
        type = "button",
        name = FORCEDEL_CONFIRM_CANCEL,
        caption = "Cancel",
        tooltip = "Cancel force-delete"
    }

    main_flow.force_auto_center()
end

local function draw_button(player)
    if not (player and player.valid and player.gui and player.gui.top) then
        return
    end

    if not player.admin then
        if player.gui.top[FORCEDEL_BUTTON_NAME] then
            player.gui.top[FORCEDEL_BUTTON_NAME].destroy()
        end
        return
    end

    local button = player.gui.top[FORCEDEL_BUTTON_NAME]
    if not button then
        button = player.gui.top.add {
            type = "sprite-button",
            name = FORCEDEL_BUTTON_NAME,
            sprite = FORCEDEL_SPRITE,
            tooltip = "Force delete (admin): arm, click entity, confirm"
        }
        button.style.size = { 72, 72 }
    end

    button.style.size = {72, 72}
    button.style.padding = 0

    local armed = is_armed(player) and true or false
    button.sprite = armed and FORCEDEL_ARMED_SPRITE or FORCEDEL_SPRITE
    button.tooltip = armed and "ARMED: click an entity to force-delete it. Click here to disarm."
        or "Force delete (admin): click to arm, then click an entity to confirm deletion."
    button.toggled = armed
end

function FORCEDEL_MakeButton(player)
    draw_button(player)
end

function FORCEDEL_Clicks(event)
    if not (event and event.element and event.element.valid and event.player_index) then
        return
    end
    local ename = event.element.name
    if ename ~= FORCEDEL_BUTTON_NAME and ename ~= FORCEDEL_CONFIRM_CLOSE and ename ~= FORCEDEL_CONFIRM_CANCEL and
        ename ~= FORCEDEL_CONFIRM_CONFIRM then
        return
    end

    local player = game.players[event.player_index]
    if not (player and player.valid) then
        return
    end

    if ename == FORCEDEL_BUTTON_NAME then
        if not player.admin then
            return
        end

        local armed = is_armed(player)
        destroy_confirm_window(player)
        clear_pending(player)
        set_armed(player, not armed)
        draw_button(player)
        return
    end

    if not player.admin then
        return
    end

    if ename == FORCEDEL_CONFIRM_CLOSE or ename == FORCEDEL_CONFIRM_CANCEL then
        destroy_confirm_window(player)
        clear_pending(player)
        set_armed(player, false)
        draw_button(player)
        return
    end

    if ename == FORCEDEL_CONFIRM_CONFIRM then
        STORAGE_EnsureGlobal()
        STORAGE_MakePlayerStorage(player)
        local entity = storage.PData[player.index].force_delete_pending_entity

        destroy_confirm_window(player)
        clear_pending(player)

        if not (entity and entity.valid) then
            set_armed(player, false)
            draw_button(player)
            UTIL_SmartPrint(player, "[FORCE-DELETE] Target no longer exists.")
            return
        end

        local gps = UTIL_GPSObj(entity)
        local name = entity.name

        set_armed(player, false)
        draw_button(player)
        entity.destroy { raise_destroy = true }
        UTIL_SmartPrint(player, "[FORCE-DELETE] " .. name .. " " .. gps)
        return
    end
end

function FORCEDEL_OnGuiOpened(event)
    if not (event and event.player_index) then
        return
    end

    local player = game.players[event.player_index]
    if not (player and player.valid and player.admin) then
        return
    end

    if not is_armed(player) then
        return
    end

    if event.gui_type ~= defines.gui_type.entity then
        return
    end

    local entity = event.entity
    if entity and entity.valid then
        if player.opened == entity then
            player.opened = nil
        end

        set_armed(player, false)
        draw_button(player)
        open_confirm_window(player, entity)
    end
end
