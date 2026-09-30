function is_player_valid(player)
    return player
       and player.valid
       and player.connected
       and player.character
       and player.character.valid
       and player.controller_type == defines.controllers.character
end

function is_inventory_empty(inventory)
    if not inventory then return true end
    return inventory.get_item_count() == 0
end

function ensure_empty_stash(player_index, stash_name, size)
    if storage.PData[player_index][stash_name] then
        return storage.PData[player_index][stash_name].is_empty()
    end
    storage.PData[player_index][stash_name] = game.create_inventory(size)
    return true
end

function stash_inventory(source_inv, stash_inv)
    return UTIL_TransferInventory(source_inv, stash_inv)
end

function unstash_inventory(stash_inv, target_inv)
    return UTIL_TransferInventory(stash_inv, target_inv)
end

function stash_armor(player)
    local armor_inventory = player.get_inventory(defines.inventory.character_armor)
    local pdata = storage.PData[player.index]
    local moved, remaining = UTIL_TransferInventory(armor_inventory, pdata.armor_stash)
    if moved then
        -- New stashes retain the actual equipment grid inside the armor stack.
        pdata.armor_equipment_data = nil
    end
    return moved, remaining
end

local function restore_legacy_armor_equipment(player)
    local pdata = storage.PData[player.index]
    if not pdata.armor_equipment_data then
        return true
    end
    local armor = pdata.armor_stash and pdata.armor_stash[1]
    if not armor or not armor.valid_for_read or not armor.grid then
        return false
    end

    -- Older saves stored a bare armor stack and serialized its equipment separately.
    -- Restore that data into the stash before transferring it to the player.
    local remaining = {}
    for _, data in ipairs(pdata.armor_equipment_data) do
        local ok, equipment = pcall(armor.grid.put, {
            name = data.name,
            position = data.position,
            quality = data.quality or "normal"
        })
        if ok and equipment then
            equipment.energy = data.energy or 0
        else
            remaining[#remaining + 1] = data
        end
    end
    if #remaining > 0 then
        pdata.armor_equipment_data = remaining
        UTIL_SmartPrint(player, "Unable to restore some legacy stashed equipment; your armor remains stashed.")
        return false
    end
    pdata.armor_equipment_data = nil
    return true
end

function unstash_armor(player)
    local pdata = storage.PData[player.index]
    if is_inventory_empty(pdata.armor_stash) then
        return false, false
    end
    if not restore_legacy_armor_equipment(player) then
        return false, true
    end
    local armor_inventory = player.get_inventory(defines.inventory.character_armor)
    return UTIL_TransferInventory(pdata.armor_stash, armor_inventory)
end

function move_items_to_inventory_or_leave(source_inv, target_inv)
    return UTIL_TransferInventory(source_inv, target_inv)
end
