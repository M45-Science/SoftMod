-- Carl Frank Otto III
-- carlotto81@gmail.com
-- GitHub: https://github.com/M45-Science/SoftMod
-- License: MPL 2.0

local QUALITY_ALIAS = {
    uncommon = "u",
    rare = "r",
    epic = "e",
    legendary = "l",
}

local QUALITY_FROM_ALIAS = {}
for k, v in pairs(QUALITY_ALIAS) do
    QUALITY_FROM_ALIAS[v] = k
end

local ITEM_ALIAS = {}
local ITEM_FROM_ALIAS = {}

local ITEM_LIST = require("quickbar_v3_items")
local quickbar_v3 = require("quickbar_v3")

local function QUICKBAR_GenerateItemAliases()
    ITEM_ALIAS = {}
    ITEM_FROM_ALIAS = {}
    local function idx_to_alias(i)
        i = i - 1
        local a = math.floor(i / 26)
        local b = i % 26
        return string.char(65 + a) .. string.char(65 + b)
    end
    -- V1/V2 recognize exactly the historical 338 aliases.
    for i = 1, 338 do
        local name = ITEM_LIST[i]
        local alias = idx_to_alias(i)
        ITEM_ALIAS[name] = alias
        ITEM_FROM_ALIAS[alias] = name
    end
end

local QUICKBAR_uses_paged_slots

local function QUICKBAR_UsesPagedSlots()
    if QUICKBAR_uses_paged_slots ~= nil then
        return QUICKBAR_uses_paged_slots
    end

    local ok, active_mods = pcall(function()
        return script.active_mods
    end)
    local base_version = ok and active_mods and active_mods["base"] or nil
    if base_version then
        local major, minor = base_version:match("^(%d+)%.(%d+)")
        major = tonumber(major)
        minor = tonumber(minor)
        QUICKBAR_uses_paged_slots = (major and major > 2) or (major == 2 and minor and minor >= 1)
    else
        QUICKBAR_uses_paged_slots = false
    end

    return QUICKBAR_uses_paged_slots
end

local function QUICKBAR_GetPageSlot(player, index)
    local width = 10
    local ok, quick_bar_width = pcall(function()
        return player.quick_bar_width
    end)
    if ok and type(quick_bar_width) == "number" and quick_bar_width > 0 then
        width = quick_bar_width
    end

    return math.floor((index - 1) / width) + 1, ((index - 1) % width) + 1
end

local function QUICKBAR_GetSlot(player, index)
    if QUICKBAR_UsesPagedSlots() then
        local page_index, slot_index = QUICKBAR_GetPageSlot(player, index)
        return player.get_quick_bar_slot(page_index, slot_index)
    end

    return player.get_quick_bar_slot(index)
end

local function QUICKBAR_SetSlot(player, index, filter)
    if QUICKBAR_UsesPagedSlots() then
        local page_index, slot_index = QUICKBAR_GetPageSlot(player, index)
        player.set_quick_bar_slot(page_index, slot_index, filter)
        return
    end

    player.set_quick_bar_slot(index, filter)
end

local function QUICKBAR_GetItemAndQuality(filter)
    if not filter then
        return nil, nil
    end
    if type(filter) == "string" then
        return filter, nil
    end

    local name = filter.name
    if name ~= nil and type(name) ~= "string" and name.name then
        name = name.name
    end

    local quality = filter.quality
    if quality ~= nil and type(quality) ~= "string" and quality.name then
        quality = quality.name
    end

    return name, quality
end

local function QUICKBAR_GetSlotItemAndQuality(slot)
    if not slot then
        return nil, nil
    end

    if slot.filter then
        return QUICKBAR_GetItemAndQuality(slot.filter)
    end
    if slot.item then
        return QUICKBAR_GetItemAndQuality(slot.item)
    end

    return QUICKBAR_GetItemAndQuality(slot)
end

local function QUICKBAR_MakeSlotFilter(item, quality)
    if QUICKBAR_UsesPagedSlots() then
        local filter = { name = item }
        if quality and quality ~= "normal" then
            filter.quality = quality
        end
        return { type = "filter", filter = filter }
    end

    if quality and quality ~= "normal" then
        return { name = item, quality = quality }
    end
    return item
end

local function encode_quickbar(player, limit)
    if not player or not player.valid then
        return
    end

    if not next(ITEM_ALIAS) then QUICKBAR_GenerateItemAliases() end
    local slots, entries = {}, {}
    local legacy_safe = true
    for i = 1, limit and 20 or 100 do
        local name, quality = QUICKBAR_GetSlotItemAndQuality(QUICKBAR_GetSlot(player, i))
        local entry = ""
        if name then
            quality = quality or "normal"
            slots[i] = {name = name, quality = quality}
            -- A literal containing a V2 delimiter or colliding with an alias
            -- cannot be round-tripped in that format.
            if ITEM_FROM_ALIAS[name] or name:find("[,:]") or
                QUALITY_FROM_ALIAS[quality] or quality:find("[,:]") then
                legacy_safe = false
            end
            entry = ITEM_ALIAS[name] or name
            if quality ~= "normal" then entry = entry .. ":" .. (QUALITY_ALIAS[quality] or quality) end
        end
        entries[i] = entry
    end
    local packed = quickbar_v3.encode(slots)
    local payload = "M45-QB2=" .. table.concat(entries, ",") .. ","
    if legacy_safe and #payload <= 10240 then
        local legacy = helpers.encode_string(payload)
        if legacy and #legacy <= 10240 and (not packed or #legacy < #packed) then return legacy end
    end
    if not packed then UTIL_SmartPrint(player, "This quickbar is too large to export.") end
    return packed
end


function ExportQuickbar(player, limit)
    local exchange = encode_quickbar(player, limit)
    if exchange then UTIL_SmartPrint(player, "Quickbar Exported!") end
    return exchange
end

-- Resolve every filter before replacing any slots. QB1 and QB2 both allow a trailing comma.
local function decode_legacy_quickbar(data)
    local ok, decoded = pcall(helpers.decode_string, data)
    if not ok or type(decoded) ~= "string" or #decoded > 10240 then
        return nil, "Could not decode that quickbar string."
    end
    local version, payload = decoded:match("^(M45%-QB[12])=(.*)$")
    if not version then return nil, "Invalid quickbar exchange header." end
    if not next(ITEM_ALIAS) then QUICKBAR_GenerateItemAliases() end
    if payload:sub(-1) ~= "," then payload = payload .. "," end
    local entries, index = {}, 0
    for entry in payload:gmatch("(.-),") do
        index = index + 1
        if index > 100 then return nil, "Quickbar exceeds 100 slots." end
        if entry ~= "" then
            local item, quality = entry, "normal"
            if version == "M45-QB2" then
                local name, q = entry:match("^([^:]+):([^:]+)$")
                if name then item, quality = name, QUALITY_FROM_ALIAS[q] or q end
            end
            item = ITEM_FROM_ALIAS[item] or item
            entries[index] = {name = item, quality = quality}
        end
    end
    return entries
end

local function decode_quickbar(data)
    if type(data) ~= "string" or #data > 10240 then return nil, "Invalid quickbar string size." end
    local decode = data:sub(1, 3) == "Q3:" and quickbar_v3.decode or decode_legacy_quickbar
    local entries, err = decode(data)
    if not entries then return nil, err end
    if not prototypes or not prototypes.item or not prototypes.quality then
        return nil, "Item and quality prototypes are unavailable."
    end
    local slots, missing = {}, {}
    for i = 1, 100 do
        local entry = entries[i]
        if entry then
            local item, quality = entry.name, entry.quality
            if prototypes.item[item] and prototypes.quality[quality] then
                slots[i] = QUICKBAR_MakeSlotFilter(item, quality)
            else
                missing[#missing + 1] = item .. (quality ~= "normal" and ":" .. quality or "")
            end
        end
    end
    return slots, missing
end

local function apply_quickbar(player, slots)
    for i = 1, 100 do QUICKBAR_SetSlot(player, i, slots[i]) end
end

local function make_window(player, name, title)
    local main_flow = player.gui.screen.add {
        type = "frame", name = name, direction = "vertical"
    }
    main_flow.style.horizontal_align = "center"
    main_flow.style.vertical_align = "center"
    main_flow.force_auto_center()

    -- Title Bar--
    local info_titlebar = main_flow.add {
        type = "flow",
        direction = "horizontal"
    }
    info_titlebar.drag_target = main_flow
    info_titlebar.style.horizontal_align = "center"
    info_titlebar.style.horizontally_stretchable = true

    info_titlebar.add {
        type = "label",
        name = "qb_title",
        style = "frame_title",
        caption = title
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
        name = "qb_exchange_close",
        sprite = "utility/close",
        style = "frame_action_button",
        tooltip = "Close this window"
    }

    main_flow.style.padding = 4
    return main_flow
end

-- A global preset only writes the positions for which this map has an item.
-- Full imports, personal presets and Clear write all 100 positions.
local function toolbar_occupied(player, target_slots)
    for i = 1, 100 do
        if (not target_slots or target_slots[i]) and QUICKBAR_GetSlot(player, i) ~= nil then return true end
    end
    return false
end

local function close_overwrite(player)
    local screen = player.gui.screen
    local dialog = screen.qb_overwrite
    if not dialog then return end
    dialog.destroy()
    if screen.quickbar_exchange then
        screen.quickbar_exchange.visible = true
    elseif screen.quickbar_manager then
        screen.quickbar_manager.visible = true
    end
end

local function warn_overwrite(player, tags, message, confirm_caption)
    local screen = player.gui.screen
    close_overwrite(player)
    local dialog = make_window(player, "qb_overwrite", "Change current toolbar?")
    dialog.tags = tags
    dialog.add{type = "label", caption = message}
    local actions = dialog.add{type = "flow", name = "actions", direction = "horizontal"}
    actions.add{type = "button", name = "qb_keep_toolbar", caption = "Cancel"}
    actions.add{type = "button", name = "qb_confirm_overwrite", caption = confirm_caption, style = "red_button"}
    if screen.quickbar_manager then screen.quickbar_manager.visible = false end
    if screen.quickbar_exchange then screen.quickbar_exchange.visible = false end
end

local function import_quickbar(player, data, confirmed)
    if not player or not player.valid or not data or data == "" then return false end
    local slots, missing = decode_quickbar(data)
    if not slots then
        UTIL_SmartPrint(player, missing)
        return false
    end
    if not confirmed and toolbar_occupied(player) then
        local message = "Replace all 100 slots with the imported toolbar?"
        if #missing > 0 then message = message .. "\n" .. #missing .. " unavailable shortcuts will be empty." end
        warn_overwrite(player, {action = "import", exchange = data}, message, "Replace toolbar")
        return false
    end
    apply_quickbar(player, slots)
    if #missing > 0 then
        UTIL_SmartPrint(player, "Quickbar Import: Invalid items/qualities skipped: " .. table.concat(missing, ", "))
    else
        UTIL_SmartPrint(player, "Quickbar imported!")
    end
    return true
end

function ImportQuickbar(player, data)
    return import_quickbar(player, data, false)
end

local function preset_label_has_markup(label)
    return type(label) == "string" and (string.find(label, "%[[^%]]*=") or
        string.find(label, "%[[/%.]color%]") or string.find(label, "%[[/%.]font%]")) ~= nil
end

local preset_save_interval = 60 -- one game second
-- Session-only snapshots, populated only after ChatWire confirms a store.
-- Reopening the manager or loading a slot discards the relevant snapshot.
local saved_preset_exchanges = {}

local function preset_request(player, action, slot, label, confirmed_exchange)
    local pdata = storage.PData[player.index]
    if not storage.SM_Store.quickbar_presets or not pdata then return false end
    if preset_label_has_markup(label) then
        UTIL_SmartPrint(player, "Preset names cannot contain rich-text tags.")
        return false
    end
    if action == "store" or action == "rename" then
        if pdata.qb_next_save_tick and game.tick < pdata.qb_next_save_tick then
            if not pdata.qb_save_warned then
                UTIL_SmartPrint(player, "Please wait one second before saving another quickbar preset.")
                pdata.qb_save_warned = true
            end
            return false
        end
        pdata.qb_next_save_tick = game.tick + preset_save_interval
        pdata.qb_save_warned = nil
    end
    local request = {name = player.name, action = action, slot = slot, admin = player.admin}
    if action == "access" then
        saved_preset_exchanges[player.index] = nil
    elseif action == "load" then
        local saved = saved_preset_exchanges[player.index]
        if saved then saved[slot] = nil end
    elseif action == "store" then
        request.exchange = encode_quickbar(player, false)
        if not request.exchange then return false end
        local saved = saved_preset_exchanges[player.index]
        if saved and saved[slot] == request.exchange then
            UTIL_SmartPrint(player, "Quickbar unchanged; already saved in this slot.")
            return false
        end
        local pending = pdata.qb_pending
        if pending and pending.action == "store" and pending.slot == slot and pending.exchange == request.exchange then
            UTIL_SmartPrint(player, "This quickbar is already being saved.")
            return false
        end
        -- A new write makes the previous snapshot obsolete immediately, even
        -- before its reply arrives (the player may change back while waiting).
        if saved then saved[slot] = nil end
    end
    request.label = label
    request.first_join = action == "access" and pdata.qb_first_join == true
    storage.SM_Store.qb_sequence = (storage.SM_Store.qb_sequence or 0) + 1
    request.id = storage.SM_Store.qb_sequence
    pdata.qb_pending = {id = request.id, action = action, slot = slot, first_join = request.first_join,
        exchange = request.exchange,
        confirmed_exchange = confirmed_exchange}
    CW_EmitEvent("quickbar-preset", request)
    return true
end

function QUICKBAR_CheckAccess(player)
    preset_request(player, "access")
end

-- Each public layout fills the first 60 positions; the remaining shortcuts stay personal.
local public_presets = {
    {
        name = "Starter base",
        items = {
            "transport-belt", "underground-belt", "splitter", "inserter", "small-electric-pole",
            "assembling-machine-1", "electric-mining-drill", "stone-furnace", "wooden-chest", "repair-pack",
            "burner-mining-drill", "burner-inserter", "long-handed-inserter", "pipe", "pipe-to-ground",
            "offshore-pump", "boiler", "steam-engine", "lab", "gun-turret",
            -- Power and lighting.
            "medium-electric-pole", "big-electric-pole", "small-lamp", "power-switch", "copper-wire",
            "solar-panel", "accumulator", "substation", "radar", "lightning-rod",
            -- Construction and terrain.
            "iron-chest", "steel-chest", "steel-furnace", "assembling-machine-2", "storage-tank",
            "stone-brick", "concrete", "hazard-concrete", "landfill", "cliff-explosives",
            -- Transport and basic oil.
            "fast-transport-belt", "fast-underground-belt", "fast-splitter", "fast-inserter", "bulk-inserter",
            "pump", "pumpjack", "oil-refinery", "chemical-plant", "car",
            -- Defense and building tools.
            "stone-wall", "gate", "firearm-magazine", "piercing-rounds-magazine", "grenade",
            "blueprint", "blueprint-book", "deconstruction-planner", "upgrade-planner", "copy-paste-tool"
        }
    },
    {
        name = "Factory and oil",
        items = {
            "fast-transport-belt", "fast-underground-belt", "fast-splitter", "fast-inserter", "medium-electric-pole",
            "assembling-machine-2", "electric-mining-drill", "steel-furnace", "steel-chest", "repair-pack",
            "pipe", "pipe-to-ground", "pump", "storage-tank", "pumpjack",
            "oil-refinery", "chemical-plant", "long-handed-inserter", "bulk-inserter", "substation",
            -- High-throughput production.
            "express-transport-belt", "express-underground-belt", "express-splitter", "stack-inserter", "assembling-machine-3",
            "electric-furnace", "beacon", "speed-module-3", "productivity-module-3", "efficiency-module-3",
            -- Logistics and construction.
            "roboport", "construction-robot", "logistic-robot", "passive-provider-chest", "requester-chest",
            "storage-chest", "buffer-chest", "active-provider-chest", "radar", "small-lamp",
            -- Power generation and distribution.
            "big-electric-pole", "solar-panel", "accumulator", "nuclear-reactor", "heat-pipe",
            "heat-exchanger", "steam-turbine", "offshore-pump", "boiler", "steam-engine",
            -- Circuit control and building tools.
            "red-wire", "green-wire", "constant-combinator", "arithmetic-combinator", "decider-combinator",
            "programmable-speaker", "blueprint", "blueprint-book", "deconstruction-planner", "upgrade-planner"
        }
    },
    {
        name = "Rail outpost",
        items = {
            "rail", "rail-chain-signal", "rail-signal", "train-stop", "big-electric-pole",
            "locomotive", "cargo-wagon", "fluid-wagon", "radar", "repair-pack",
            "fast-transport-belt", "fast-underground-belt", "fast-splitter", "bulk-inserter", "medium-electric-pole",
            "electric-mining-drill", "steel-chest", "pump", "storage-tank", "pipe-to-ground",
            -- Elevated rail and train supplies.
            "rail-ramp", "rail-support", "artillery-wagon", "artillery-shell", "artillery-targeting-remote",
            "coal", "solid-fuel", "rocket-fuel", "nuclear-fuel", "small-lamp",
            -- Mining and high-throughput loading.
            "big-mining-drill", "express-transport-belt", "express-underground-belt", "express-splitter", "stack-inserter",
            "inserter", "fast-inserter", "long-handed-inserter", "wooden-chest", "iron-chest",
            -- Outpost defense.
            "stone-wall", "gate", "gun-turret", "laser-turret", "flamethrower-turret",
            "piercing-rounds-magazine", "uranium-rounds-magazine", "land-mine", "artillery-turret", "cliff-explosives",
            -- Remote construction and station control.
            "roboport", "construction-robot", "storage-chest", "passive-provider-chest", "requester-chest",
            "constant-combinator", "decider-combinator", "red-wire", "green-wire", "blueprint-book"
        }
    }
}

local function load_public_preset(player, element, confirmed)
    local window = player.gui.screen.quickbar_manager
    local section = window and window.qb_preset_section
    local row = section and section.qb_public
    if not row or element ~= row.qb_public_load then return end
    local preset = public_presets[row.choice.selected_index]
    if not preset then return end
    QUICKBAR_ClearString(player)
    local slots, loaded = {}, 0
    for i, item in ipairs(preset.items) do
        if prototypes.item[item] then
            slots[i] = QUICKBAR_MakeSlotFilter(item, "normal")
            loaded = loaded + 1
        end
    end
    if not confirmed and toolbar_occupied(player, slots) then
        warn_overwrite(player, {action = "public", index = row.choice.selected_index},
            preset.name .. " will replace shortcuts in the first 60 slots.", "Load preset")
        return
    end
    for i = 1, #preset.items do
        if slots[i] then QUICKBAR_SetSlot(player, i, slots[i]) end
    end
    UTIL_SmartPrint(player, preset.name .. ": loaded " .. loaded .. " of " .. #preset.items .. " shortcuts.")
end

local function preset_row(player)
    local window = player.gui.screen.quickbar_manager
    local section = window and window.qb_preset_section
    return section and section.qb_presets
end

local function select_preset(row)
    row.qb_rename.enabled = row.slot.enabled and row.slot.selected_index > 1
    row.load.caption = "Load"
end

local function refresh_presets(player, pdata)
    local window = player.gui.screen.quickbar_manager
    local section = window and window.qb_preset_section
    if not section then return end
    local allowed = storage.SM_Store.quickbar_presets == true and pdata.qb_allowed == true
    section.access_note.visible = not allowed
    local row = section.qb_presets
    local selected = row and row.slot.selected_index or 1
    if not row then
        row = section.add{type = "flow", name = "qb_presets", direction = "horizontal"}
        row.add{type = "drop-down", name = "slot", tooltip = "Default loads into an empty toolbar on your first visit to each map."}
        row.add{type = "button", name = "load", caption = "Load", tooltip = "Replace your quickbar with this preset."}
        row.add{type = "button", name = "store", caption = "Store", tooltip = "Store your current quickbar in this slot."}
    end
    if not row.qb_rename then
        row.add{type = "button", name = "qb_rename", caption = "Rename", tooltip = "Rename the selected personal preset."}
    end
    -- Older saves can contain an open manager with the previous inline editor.
    if row.preset_name then row.preset_name.destroy() end
    row.slot.enabled, row.load.enabled, row.store.enabled = allowed, allowed, allowed
    local labels = {"Default"}
    local count = allowed and math.max(1, #(pdata.qb_labels or {})) or 2
    for i = 2, count do
        local label = pdata.qb_labels and pdata.qb_labels[i]
        if preset_label_has_markup(label) then label = nil end
        labels[i] = label and label ~= "" and (i .. ". " .. label) or ("Preset " .. i)
    end
    row.slot.items = labels
    row.slot.selected_index = math.min(selected, count)
    select_preset(row)
end

function QUICKBAR_SelectPreset(event)
    local player = game.get_player(event.player_index)
    local row = preset_row(player)
    if row and event.element == row.slot then
        storage.PData[player.index].qb_pending = nil
        select_preset(row)
    end
end

local function close_rename(player)
    local screen = player.gui.screen
    if screen.qb_rename_dialog then screen.qb_rename_dialog.destroy() end
    if screen.quickbar_manager then screen.quickbar_manager.visible = true end
end

function QUICKBAR_Result(data)
    local player = UTIL_FindPlayer(data.name)
    if not (player and player.connected) then return end
    local pdata = storage.PData[player.index]
    local pending = pdata and pdata.qb_pending
    if not pending or pending.id ~= data.id then return end
    if data.pending == true then
        if not pending.saving_notified then
            UTIL_SmartPrint(player, "Saving quickbar preset...")
            pending.saving_notified = true
        end
        return
    end
    pdata.qb_pending = nil
    pdata.qb_allowed = data.allowed == true
    if not pdata.qb_allowed then
        saved_preset_exchanges[player.index] = nil
    elseif pending.action == "store" then
        saved_preset_exchanges[player.index] = saved_preset_exchanges[player.index] or {}
        saved_preset_exchanges[player.index][pending.slot] = not data.error and pending.exchange or nil
    end
    if not data.error then pdata.qb_labels = data.labels or {} end
    if pending.first_join and not data.error then pdata.qb_first_join = nil end
    local warning = player.gui.screen.qb_overwrite
    if not pdata.qb_allowed and warning and warning.tags.action == "personal" then close_overwrite(player) end
    if pending.action == "load" and not preset_row(player) then return end
    refresh_presets(player, pdata)
    local dialog = player.gui.screen.qb_rename_dialog
    if dialog then
        if not pdata.qb_allowed or dialog.tags.slot > #pdata.qb_labels then
            close_rename(player)
        elseif pending.action == "rename" and dialog.tags.slot == pending.slot then
            if data.error then
                dialog.actions.qb_rename_save.enabled = true
                dialog.slot_name.focus()
            else
                close_rename(player)
            end
        end
    end
    if not pdata.qb_allowed then
        if pending.action ~= "access" then UTIL_SmartPrint(player, "Preset access is unavailable.") end
        return
    end
    if data.error then UTIL_SmartPrint(player, data.error); return end
    if pending.action == "rename" or pending.action == "store" then
        UTIL_SmartPrint(player, pending.action == "rename" and "Preset name saved." or "Quickbar stored.")
        return
    end
    if pending.action == "access" and not pending.first_join then return end
    if not data.exchange then
        if pending.action == "load" then UTIL_SmartPrint(player, "This preset is empty.") end
        return
    end
    local slots, missing = decode_quickbar(data.exchange)
    if not slots then UTIL_SmartPrint(player, missing); return end
    if data.exchange ~= pending.confirmed_exchange then
        local occupied = toolbar_occupied(player)
        if occupied or #missing > 0 then
            local message = occupied and "Loading this preset will replace your current toolbar." or ""
            if #missing > 0 then
                if occupied then message = message .. "\n" end
                message = message .. #missing .. " slots use unavailable items or qualities and will be empty."
            end
            if pending.first_join then
                UTIL_SmartPrint(player, "Default was not loaded. Open Quickbar Manager to load it manually. " ..
                    (occupied and "Your toolbar already has shortcuts." or message))
            else
                warn_overwrite(player, {action = "personal", slot = pending.slot, exchange = data.exchange},
                    message, #missing > 0 and "Load compatible slots" or "Replace toolbar")
            end
            return
        end
    end
    apply_quickbar(player, slots)
    UTIL_SmartPrint(player, pending.first_join and "Default quickbar loaded." or "Quickbar loaded.")
end

function QUICKBAR_MakeExchangeButton(player)
    QUICKBAR_ClearString(player)

    if not (player and player.valid and player.gui and player.gui.top) then
        return
    end
    if player.gui.top.qb_exchange_button then
        player.gui.top.qb_exchange_button.destroy()
    end
    if not player.gui.top.qb_exchange_button then
        local ex_button = player.gui.top.add {
            type = "sprite-button",
            name = "qb_exchange_button",
            sprite = "file/img/buttons/exchange-64.png",
            tooltip = "Open M45 Quickbar Manager."
        }
        ex_button.style.size = { 64, 64 }
        ex_button.style.padding = 0
    end
end

local function click_preset(player, element)
    local row = preset_row(player)
    if not row or element.parent ~= row then return end
    local pdata = storage.PData[player.index]
    if not pdata.qb_allowed then return end
    local slot = row.slot.selected_index
    if element == row.store then
        preset_request(player, "store", slot)
    elseif element == row.load then
        preset_request(player, "load", slot)
    elseif element == row.qb_rename and slot > 1 then
        local screen = player.gui.screen
        if screen.qb_rename_dialog then return end
        local dialog = make_window(player, "qb_rename_dialog", "Rename preset " .. slot)
        dialog.tags = {slot = slot}
        local field = dialog.add{type = "textfield", name = "slot_name",
            text = pdata.qb_labels[slot] or "", tooltip = "Up to 32 characters, without rich-text tags. Leave blank to reset the name."}
        local actions = dialog.add{type = "flow", name = "actions", direction = "horizontal"}
        actions.add{type = "button", name = "qb_rename_cancel", caption = "Cancel"}
        actions.add{type = "button", name = "qb_rename_save", caption = "Save", style = "confirm_button"}
        screen.quickbar_manager.visible = false
        field.focus()
        field.select_all()
    end
end

local function open_manager(player)
    local manager = make_window(player, "quickbar_manager", "M45 Quickbar Manager")
    local section = manager.add {
        type = "frame", name = "qb_preset_section", direction = "vertical",
        style = "inside_shallow_frame_with_padding", caption = "Quickbar presets"
    }
    section.style.horizontally_stretchable = true
    section.add{type = "label", caption = "Global presets", style = "bold_label"}
    local public = section.add{type = "flow", name = "qb_public", direction = "horizontal"}
    local names = {}
    for i, preset in ipairs(public_presets) do names[i] = i .. ". " .. preset.name end
    public.add{type = "drop-down", name = "choice", items = names, selected_index = 1}
    public.add{type = "button", name = "qb_public_load", caption = "Load",
        tooltip = "Replace the first 60 shortcuts (6 standard rows). The last 40 stay personal. Items unavailable on this map are skipped."}
    public.add{type = "button", name = "qb_clear_toolbar", caption = "Clear toolbar",
        tooltip = "Clear all 100 quickbar shortcuts. Saved presets are kept."}
    section.add{type = "line", direction = "horizontal"}
    section.add{type = "label", caption = "Personal presets", style = "bold_label"}
    section.add{type = "label", caption = "On your first visit to each map, Default loads automatically if your toolbar is empty."}
    section.add{type = "label", name = "access_note", caption = "Available to Members, Regulars, Veterans, supporters, and admins."}
    refresh_presets(player, storage.PData[player.index])
    manager.add{type = "button", name = "qb_open_exchange", caption = "Import / export string"}
    QUICKBAR_CheckAccess(player)
end

function QUICKBAR_MakeExchangeWindow(player, exportMode)
    if not (player and player.valid and player.gui and player.gui.screen) then return end
    local screen = player.gui.screen
    if screen.quickbar_exchange then screen.quickbar_exchange.destroy() end
    if screen.quickbar_manager then screen.quickbar_manager.visible = false end
    QUICKBAR_ClearString(player)
    local main_flow = make_window(player, "quickbar_exchange", "M45 Quickbar Exchange String")
    local mframe = main_flow.add {
        type = "frame", name = "qb_exchange_section", direction = "vertical",
        style = "inside_shallow_frame_with_padding"
    }
    mframe.style.horizontally_stretchable = true

    local qbes = ""
    if exportMode then
        qbes = ExportQuickbar(player, false) or ""
    end
    mframe.add {
        type = "text-box",
        name = "quickbar_string",
        text = qbes,
        tooltip = "COPY: Click text then Control-C\nPASTE: Click text then Control-V",
    }
    mframe.quickbar_string.style.minimal_width = 500
    mframe.quickbar_string.style.minimal_height = 50

    local bframe = mframe.add {
        type = "flow",
        direction = "horizontal"
    }
    bframe.add {
        type = "button",
        caption = "Import",
        style = "green_button",
        name = "import_qb",
        tooltip = "Import a new quickbar."
    }
    local pusher = bframe.add {
        type = "empty-widget",
    }
    pusher.style.vertically_stretchable = true
    pusher.style.horizontally_stretchable = true
    bframe.add {
        type = "button",
        caption = "Export",
        style = "red_button",
        name = "export_qb",
        tooltip = "Export current quickbars."
    }
    bframe.add{type = "button", name = "qb_exchange_back", caption = "Back to presets"}
    mframe.quickbar_string.focus()
    if exportMode then mframe.quickbar_string.select_all() end
end

local function back_to_presets(player)
    local screen = player.gui.screen
    screen.quickbar_exchange.destroy()
    if screen.quickbar_manager then
        screen.quickbar_manager.visible = true
    else
        open_manager(player)
    end
end

local function clear_toolbar(player, confirmed)
    QUICKBAR_ClearString(player)
    if not confirmed and toolbar_occupied(player) then
        warn_overwrite(player, {action = "clear"}, "Clear all 100 shortcuts from your current toolbar?", "Clear toolbar")
        return
    end
    apply_quickbar(player, {})
    UTIL_SmartPrint(player, "Toolbar cleared.")
end

local function confirm_overwrite(player, tags)
    local screen = player.gui.screen
    if tags.action == "import" then
        if import_quickbar(player, tags.exchange, true) and screen.quickbar_exchange then back_to_presets(player) end
    elseif tags.action == "clear" then
        clear_toolbar(player, true)
    elseif tags.action == "public" and screen.quickbar_manager then
        local row = screen.quickbar_manager.qb_preset_section.qb_public
        if row.choice.selected_index == tags.index then load_public_preset(player, row.qb_public_load, true) end
    elseif tags.action == "personal" then
        local row = preset_row(player)
        if row and row.slot.selected_index == tags.slot then
            -- Recheck entitlement and bind confirmation to the exact exchange shown.
            preset_request(player, "load", tags.slot, nil, tags.exchange)
        end
    end
end

function QUICKBAR_Clicks(event)
    if event and event.element and event.element.valid and event.player_index then
        local player = game.players[event.player_index]

        if player and player.valid and event.element.name then
            local screen = player.gui.screen
            local action = event.element.name
            local overwrite = screen.qb_overwrite
            if overwrite then
                if event.element == overwrite.actions.qb_confirm_overwrite then
                    local tags = overwrite.tags
                    close_overwrite(player)
                    confirm_overwrite(player, tags)
                elseif event.element == overwrite.actions.qb_keep_toolbar or action == "qb_exchange_close"
                    or action == "qb_exchange_button" then
                    close_overwrite(player)
                end
                return
            end
            if event.element.name == "qb_public_load" then
                load_public_preset(player, event.element)
            elseif event.element.name == "qb_clear_toolbar" then
                local window = player.gui.screen.quickbar_manager
                local section = window and window.qb_preset_section
                local row = section and section.qb_public
                if row and event.element == row.qb_clear_toolbar then
                    clear_toolbar(player, false)
                end
            elseif event.element.name == "load" or event.element.name == "store" or event.element.name == "qb_rename" then
                click_preset(player, event.element)
            elseif event.element.name == "quickbar_string" then
                event.element.select_all()
            end

            local dialog = screen.qb_rename_dialog
            if dialog and (action == "qb_rename_cancel" or action == "qb_exchange_close") then
                close_rename(player)
            elseif dialog and action == "qb_rename_save" and event.element == dialog.actions.qb_rename_save then
                if event.element.enabled then
                    if preset_request(player, "rename", dialog.tags.slot, dialog.slot_name.text) then
                        event.element.enabled = false
                    end
                end
            elseif action == "qb_exchange_button" or action == "qb_exchange_close" then
                if dialog then close_rename(player) end
                local was_open = screen.quickbar_manager or screen.quickbar_exchange
                if screen.quickbar_exchange then screen.quickbar_exchange.destroy() end
                if screen.quickbar_manager then screen.quickbar_manager.destroy() end
                QUICKBAR_ClearString(player)
                if not was_open and action == "qb_exchange_button" then open_manager(player) end
            elseif action == "qb_open_exchange" and screen.quickbar_manager then
                QUICKBAR_MakeExchangeWindow(player, false)
            elseif action == "qb_exchange_back" and screen.quickbar_exchange then
                back_to_presets(player)
            elseif action == "export_qb" and screen.quickbar_exchange then
                QUICKBAR_MakeExchangeWindow(player, true)
            elseif action == "import_qb" and screen.quickbar_exchange then
                local section = screen.quickbar_exchange.qb_exchange_section
                if section and ImportQuickbar(player, section.quickbar_string.text) then
                    back_to_presets(player)
                end
            end
        end
    end
end

function QUICKBAR_ClearString(player)
    if not player or not player.valid then
        return
    end
    if player.gui then close_overwrite(player) end
    local pdata = storage.PData and storage.PData[player.index]
    if pdata then
        if pdata.qb_pending and pdata.qb_pending.action == "load" then pdata.qb_pending = nil end
    end
end
