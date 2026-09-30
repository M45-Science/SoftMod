-- Stash-related command registrations

function STASH_AddStashCommands()
    CMD_AddCommand("stash", "Donator-only: Stash current weapons, ammo and armor.",
        function(param)
            if not param or not param.player_index then
                CMD_RejectConsole("The console can't use /stash.")
                return
            end
            local player = game.players[param.player_index]

            if not is_player_valid(player) then
                if player and player.valid then
                    player.print("You must be alive, connected, and controlling a character to use this command.")
                end
                return
            end

            if not UTIL_Is_Supporter(player) and not player.admin then
                UTIL_SmartPrint(player, "This command is only for supporters.")
                return
            end

            if not storage.PData then storage.PData = {} end
            if not storage.PData[player.index] then storage.PData[player.index] = {} end

            local can_stash_guns = ensure_empty_stash(player.index, "gun_stash", 3)
            local can_stash_ammo = ensure_empty_stash(player.index, "ammo_stash", 3)
            local can_stash_armor = ensure_empty_stash(player.index, "armor_stash", 1)

            if not (can_stash_guns and can_stash_ammo and can_stash_armor) then
                UTIL_SmartPrint(player, "You already have stashed equipment. Unstash before stashing again.")
                return
            end

            local gun_inventory = player.get_inventory(defines.inventory.character_guns)
            local ammo_inventory = player.get_inventory(defines.inventory.character_ammo)

            local gun_stashed, gun_stash_full = stash_inventory(gun_inventory, storage.PData[player.index].gun_stash)
            local ammo_stashed, ammo_stash_full = stash_inventory(ammo_inventory, storage.PData[player.index].ammo_stash)
            local armor_stashed, armor_stash_full = stash_armor(player)

            local stashed_anything = gun_stashed or ammo_stashed or armor_stashed
            local stash_full = gun_stash_full or ammo_stash_full or armor_stash_full

            if stashed_anything then
                UTIL_SmartPrint(player, "Your guns, ammo, and armor have been successfully stashed!")
                if stash_full then
                    UTIL_SmartPrint(player, "Some items could not be stashed due to insufficient space.")
                end
            else
                if stash_full then
                    UTIL_SmartPrint(player, "No space to stash your equipment.")
                else
                    UTIL_SmartPrint(player, "You had no guns, ammo, or armor to stash.")
                end
            end
        end
    )

    CMD_AddCommand("unstash", "Donator-only: Unstash weapons, ammo and armor.",
        function(param)
            if not param or not param.player_index then
                CMD_RejectConsole("The console can't use /unstash.")
                return
            end
            local player = game.players[param.player_index]

            if not is_player_valid(player) then
                if player and player.valid then
                    player.print("You must be alive, connected, and controlling a character to use this command.")
                end
                return
            end

            if not UTIL_Is_Supporter(player) and not player.admin then
                UTIL_SmartPrint(player, "This command is only for supporters.")
                return
            end

            if not storage.PData or not storage.PData[player.index] then
                return
            end

            local gun_stash = storage.PData[player.index].gun_stash
            local ammo_stash = storage.PData[player.index].ammo_stash
            local armor_stash = storage.PData[player.index].armor_stash
            if is_inventory_empty(gun_stash) and is_inventory_empty(ammo_stash) and is_inventory_empty(armor_stash) then
                UTIL_SmartPrint(player, "No stashed equipment found to unstash.")
                return
            end

            local gun_inventory = player.get_inventory(defines.inventory.character_guns)
            local ammo_inventory = player.get_inventory(defines.inventory.character_ammo)
            local armor_inventory = player.get_inventory(defines.inventory.character_armor)
            local main_inventory = player.get_inventory(defines.inventory.character_main)

            -- Attempt to clear the player's gun/ammo/armor slots by moving their current gear into main inventory if possible
            move_items_to_inventory_or_leave(gun_inventory, main_inventory)
            move_items_to_inventory_or_leave(ammo_inventory, main_inventory)
            move_items_to_inventory_or_leave(armor_inventory, main_inventory)

            -- Now check if empty after attempting to unequip
            if not is_inventory_empty(gun_inventory) or not is_inventory_empty(ammo_inventory) or not is_inventory_empty(armor_inventory) then
                UTIL_SmartPrint(player, "You must remove all your current guns, ammo, and armor before unstashing.")
                return
            end

            local guns_unstashed, guns_full = unstash_inventory(gun_stash, gun_inventory)
            local ammo_unstashed, ammo_full = unstash_inventory(ammo_stash, ammo_inventory)
            local armor_unstashed, armor_full = unstash_armor(player)

            local unstashed_anything = guns_unstashed or ammo_unstashed or armor_unstashed
            local player_inventory_full = guns_full or ammo_full or armor_full

            if unstashed_anything then
                UTIL_SmartPrint(player, "Your stashed guns, ammo, and armor have been successfully unstashed!")
                if player_inventory_full then
                    UTIL_SmartPrint(player, "Some items could not be unstashed due to insufficient space.")
                end
            elseif player_inventory_full then
                UTIL_SmartPrint(player, "No stashed items could be moved. Check inventory space and saved equipment.")
            else
                UTIL_SmartPrint(player, "Your stash is empty!")
            end
        end
    )
end
