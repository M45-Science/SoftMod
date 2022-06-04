function on_detect_fish(event)
    --Sanity check
    if event and event.player_index then

        local player = game.players[event.player_index]
        if player and player.character then
            local inv = player.character.get_main_inventory()
            if inv then
                local contents = inv.get_contents()
                if contents then
                    for name, count in pairs(contents) do
                        if name == "raw-fish" then
                            player.print("Fish are not allowed in ultimate deathworld.")
                            player.remove_item({ name = "raw-fish", count = count })
                            player.character.damage(25, "enemy")
                        end
                    end
                end
            end
        end
    end
end
