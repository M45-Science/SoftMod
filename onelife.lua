function doOnelife(event)
    if not event or not event.player_index then
        return
    end
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    player.set_controller {
        type = defines.controllers.spectator
    }
    smart_print(player, "Game over! you are now a spectator.")
    update_player_list()

    player.close_map()

    if not player.character or not player.character.valid then
        return
    end
    local character = player.character
    -- Stop player states, just in case
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

function onelife_clickhandler(event)
    if not event or not event.player_index then
        return
    end
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end
    if not player.character or not player.character.valid then
        smart_print("You are already dead!")
        return
    end
    if event.element and event.element.valid and event.element.name == "spec_button" then

        -- Init global if needed
        if not global.spec_confirm then
            global.spec_confirm = {}
        end
        -- Create player entry if needed
        if not global.spec_confirm[player.index] then
            global.spec_confirm[player.index] = 0
        end
        -- Otherwise confirm
        if global.spec_confirm and player.index and global.spec_confirm[player.index] then

            if global.spec_confirm[player.index] >= 2 then
                global.spec_confirm[player.index] = nil
                player.character.die("player")
                doOnelife(event)
                return
            elseif global.spec_confirm[player.index] < 2 then
                smart_print(player,
                    "[color=red](NO UNDO, PERM-DEATH) -- click " .. 2 - global.spec_confirm[player.index] ..
                        " more times to confirm.[/color]")
                smart_print(player,
                    "[color=white](NO UNDO, PERM-DEATH) -- click " .. 2 - global.spec_confirm[player.index] ..
                        " more times to confirm.[/color]")
                smart_print(player,
                    "[color=black](NO UNDO, PERM-DEATH) -- click " .. 2 - global.spec_confirm[player.index] ..
                        " more times to confirm.[/color]")
            end

            global.spec_confirm[player.index] = global.spec_confirm[player.index] + 1
        end
    end
end

function make_onelife_button(player)
    if player.gui.top.spec_button then
        player.gui.top.spec_button.destroy()
    end
    if not player.gui.top.spec_button then
        local m45_32 = player.gui.top.add {
            type = "sprite-button",
            name = "spec_button",
            sprite = "file/img/buttons/spectate.png",
            tooltip = "Kills you forever to become spectator (NO UNDO)"
        }
        m45_32.style.size = {64, 64}
    end
end
