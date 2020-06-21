local alert_type_names = {
    "none",
    "entity_destroyed",
    "entity_under_attack",
    "not_enough_construction_robots",
    "no_material_for_construction",
    "not_enough_repair_packs",
    "turret_fire",
    "mod_custom",
    "no_storage",
    "train_out_of_fuel",
    "fluid_mixing",
    "error"
}
--Get alert data
for _, player in pairs(game.connected_players) do
    local alerts_a = player.get_alerts {}

    for a, alerts_b in pairs(alerts_a) do
        for b, alerts_c in pairs(alerts_b) do
            for c, alerts_d in pairs(alerts_c) do
                if alerts_d ~= nil and alerts_d ~= {} then
                    local target_name = "none"
                    local entity_name = "none"
                    local proto_name = "none"
                    local health = "none"
                    if alerts_d.target and alerts_d.target ~= nil and alerts_d.target ~= {} then
                        if
                            alerts_d.target.shooting_target and alerts_d.target.shooting_target ~= nil and
                                alerts_d.target.shooting_target ~= {}
                         then
                            target_name = alerts_d.target.shooting_target.name
                            health = alerts_d.target.health
                        end
                        if alerts_d.prototype and alerts_d.prototype ~= nil and alerts_d.prototype ~= {} then
                            proto_name = alerts_d.prototype.name
                        end

                        entity_name = alerts_d.target.name
                    end

                    if entity_name == "none" and b == defines.alert_type.entity_destroyed then
                        game.print("Item destroyed!")
                    end
                    if entity_name ~= "none" and b == defines.alert_type.entity_under_attack then
                        game.print(
                            entity_name ..
                                " is under attack, at " ..
                                    alerts_d.position.x .. ", " .. alerts_d.position.y .. "!"
                        )
                    end
                    if b > 99999 then
                        print(
                            "alert: surface:" ..
                                game.surfaces[a].name ..
                                    " type:" ..
                                        alert_type_names[b + 1] ..
                                            " number:" ..
                                                c ..
                                                    " position:" ..
                                                        dump(alerts_d.position) ..
                                                            " tick:" ..
                                                                alerts_d.tick ..
                                                                    " entity: " ..
                                                                        entity_name ..
                                                                            " health: " ..
                                                                                health ..
                                                                                    " target:" ..
                                                                                        target_name ..
                                                                                            " prototype:" ..
                                                                                                proto_name ..
                                                                                                    "\n"
                        )
                    end
                end
            end
        end
    end