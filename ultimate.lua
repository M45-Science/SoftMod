--No magic healing fish
function on_detect_fish(event)
    --Sanity check
    if event and event.player_index then
        local player = game.players[event.player_index]
        if player and player.character then
            local inv = player.character.get_main_inventory()
            if inv then

                --Get inv contents
                local contents = inv.get_contents()
                if contents then
                    for name, count in pairs(contents) do
                        if name == "raw-fish" then
                            --NO FISH FOR YOU
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

--If you die, thats it!
function one_life_to_live(event)
    if event and event.player_index then

        local player = game.players[event.player_index]
        if player and player.character then

            --Make sure the jail is built
            if game.surfaces["hell"] == nil then
                local my_map_gen_settings = {
                    width = 100,
                    height = 100,
                    default_enable_all_autoplace_controls = false,
                    property_expression_names = { cliffiness = 0 },
                    autoplace_settings = {
                        tile = {
                            settings = {
                                ["sand-1"] = {
                                    frequency = "normal",
                                    size = "normal",
                                    richness = "normal"
                                }
                            }
                        }
                    },
                    starting_area = "none"
                }
                game.create_surface("hell", my_map_gen_settings)
            end

            --Make sure the list is set up
            if not global.send_to_surface then
                global.send_to_surface = {}
              end
        
            --Better luck next time!
            table.insert(global.send_to_surface, { victim = player, surface = "hell", position = { 0, 0 } })
        end
    end
end
