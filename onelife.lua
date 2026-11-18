-- Carl Frank Otto III
-- carlotto81@gmail.com
-- GitHub: https://github.com/M45-Science/SoftMod
-- License: MPL 2.0
-- Safe console print

function ONELIFE_IsRevivable(player)
    return player
       and player.valid
       and player.controller_type == defines.controllers.spectator
       and (not player.character or not player.character.valid)
end

function ONELIFE_Main(event)
    if not storage.SM_Store.oneLifeMode then
        return
    end

    if not event or not event.player_index then
        return
    end
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    if UTIL_Is_Banished(player) then
        return
    end

    -- PlanetPicker mod: it can temporarily put players on an "empty_void" surface (planet selection / limbo) and
    -- relies on controlling player state. Don't teleport them out or change controller types from SoftMod while there.
    local surface = player.surface
    if surface and surface.valid and surface.name == "empty_void" then
        return
    end

    -- Only switch controller modes when the player is actually in character control.
    if player.controller_type ~= defines.controllers.character then
        return
    end
    local character = player.character
    if not (character and character.valid) then
        return
    end

    player.set_controller { type = defines.controllers.spectator }
    UTIL_SmartPrint(player, "Game over! you are now a spectator.")
    ONLINE_MarkDirty()

    -- Stop player states, or they will continue forever
    character.walking_state = {
        walking = false,
        direction = defines.direction.south
    }
    character.riding_state = {
        acceleration = defines.riding.acceleration.braking,
        direction = defines.riding.direction.straight
    }
    character.shooting_state = {
        state = defines.shooting.not_shooting,
        position = character.position
    }
    character.mining_state = {
        mining = false
    }
    character.picking_state = false
    character.repair_state = {
        repairing = false,
        position = character.position
    }
end

function ONELIFE_Clicks(event)
    if not storage.SM_Store.oneLifeMode then
        return
    end

    if not (event and event.player_index and event.element and event.element.valid and event.element.name == "spec_button") then
        return
    end
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end
    if STORAGE_EnsureGlobal then
        STORAGE_EnsureGlobal()
    end
    if STORAGE_MakePlayerStorage then
        STORAGE_MakePlayerStorage(player)
    end
    if UTIL_Is_Banished(player) then
        return
    end
    if not player.character or not player.character.valid then
        UTIL_SmartPrint(player, "You are already dead!")
        return
    end
    if not (storage and storage.PData and storage.PData[player.index]) then
        return
    end
    -- Otherwise confirm
    if storage.PData[player.index].permDeath then
        if storage.PData[player.index].permDeath >= 2 then
            storage.PData[player.index].permDeath = 0
            player.character.die("player")
            ONELIFE_Main(event)
            return
        elseif storage.PData[player.index].permDeath < 2 then
            UTIL_SmartPrintColor(player,
                "[color=red](NO UNDO, PERM-DEATH) -- click " .. 2 - storage.PData[player.index].permDeath ..
                " more times to confirm.[/color]")
        end

        storage.PData[player.index].permDeath = storage.PData[player.index].permDeath + 1
    end
end

function ONELIFE_MakeButton(player)
    if not (player and player.valid and player.gui and player.gui.top) then
        return
    end
    if not (player.surface and player.surface.valid) then
        return
    end
    if player.gui.top.spec_button then
        player.gui.top.spec_button.destroy()
    end

    if storage.SM_Store.oneLifeMode == false then
        if ONELIFE_IsRevivable(player) then
            -- PlanetPicker mod uses an "empty_void" surface for planet selection / limbo; do not teleport players out
            -- of it or change their controller type here, since PlanetPicker expects to manage that transition itself.
            local surface = player.surface
            if surface and surface.valid and surface.name == "empty_void" then
                UTIL_SmartPrint(player, "Can't revive while on PlanetPicker's 'empty_void' surface; finish selecting a planet first.")
                return
            end

            local position = surface.find_non_colliding_position("character", player.position, 1024, 1, false) or
                surface.find_non_colliding_position("character", { x = 0, y = 0 }, 1024, 1, false) or { x = 0, y = 0 }
            player.teleport(position, surface)
            local character = surface.create_entity({ name = "character", position = position, force = player.force })
            if not (character and character.valid) then
                return
            end
            player.set_controller {
                type = defines.controllers.character,
                character = character
            }
            UTIL_SmartPrint(player, "You have been revived!")
            ONLINE_MarkDirty()
        end
        return
    end
    if storage.SM_Store.oneLifeMode == true then
        if not player.gui.top.spec_button then
            local m45_32 = player.gui.top.add {
                type = "sprite-button",
                name = "spec_button",
                sprite = "file/img/buttons/spectate.png",
                tooltip = "Kills you forever to become spectator (NO UNDO)"
            }
            m45_32.style.size = { 64, 64 }
        end
    end
end
