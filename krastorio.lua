local krastorio = {}

local machines = {
    {name = "kr-spaceship-reactor", recipe = "steam-engine", offset = {0, 0}},
    {name = "kr-spaceship-research-computer", recipe = "lab", offset = {0, -5}},
    {name = "kr-spaceship-material-fabricator-1", recipe = "assembling-machine-1", offset = {-5, 0}},
    {name = "kr-spaceship-material-fabricator-1", recipe = "assembling-machine-1", offset = {5, 0}},
    {name = "kr-spaceship-material-fabricator-2", recipe = "assembling-machine-1", offset = {-5, 5}},
    {name = "kr-spaceship-material-fabricator-2", recipe = "assembling-machine-1", offset = {5, 5}},
}

local function place(surface, force, name, target, radius)
    if not prototypes.entity[name] then return end

    local position = surface.find_non_colliding_position(name, target, radius, 1)
    if position then
        return surface.create_entity{name = name, position = position, force = force}
    end
end

local function add_salvage(surface, force, anchor)
    local target = {anchor[1] - 10, anchor[2]}
    local cargo = place(surface, force, "crash-site-spaceship", target, 6)
        or place(surface, force, "iron-chest", target, 10)
    if not cargo then return end

    local ship_items = storage.crashed_ship_items or {["firearm-magazine"] = 8}
    local debris_items = storage.crashed_debris_items or {["iron-plate"] = 8}
    for _, items in ipairs({ship_items, debris_items}) do
        for name, count in pairs(items) do
            if prototypes.item[name] then cargo.insert{name = name, count = count} end
        end
    end

    local trees = surface.map_gen_settings.autoplace_controls.trees
    if (not trees or trees.size == 0) and not ship_items.wood and prototypes.item.wood then
        cargo.insert{name = "wood", count = 400}
    end
end

local function place_machines(surface, force, anchor)
    local placed = {}
    for index, machine in ipairs(machines) do
        local target = {anchor[1] + machine.offset[1], anchor[2] + machine.offset[2]}
        local entity = place(surface, force, machine.name, target, 6)
        if not entity then
            for _, partial in ipairs(placed) do partial.destroy() end
            return false
        end
        placed[index] = entity
    end

    -- Krastorio's research handler unlocks these entities as their replacements
    -- become available. Apply its initial protection when creating the site.
    local uses_minable_flag = not script.active_mods.base:match("^2%.0%.")
    for index, entity in ipairs(placed) do
        local machine = machines[index]
        local recipe = force.recipes[machine.recipe]
        local unlocked = recipe and recipe.enabled or false
        if uses_minable_flag then
            entity.minable_flag = unlocked
        else
            entity.minable = unlocked
        end
        entity.destructible = unlocked
    end
    placed[1].operable = false -- Keep the wrecked reactor's controls locked.
    return true
end

local function create_site(surface)
    local force = game.forces.player
    local spawn = force.get_spawn_position(surface)
    local anchors = {{spawn.x - 24, spawn.y}, {spawn.x, spawn.y + 32}}
    for _, anchor in ipairs(anchors) do
        surface.request_to_generate_chunks(anchor, 2)
        surface.force_generate_chunk_requests()
        if place_machines(surface, force, anchor) then
            add_salvage(surface, force, anchor)
            return
        end
    end
    log("M45 SoftMod could not place the Krastorio 2 crash site near spawn.")
end

function krastorio.on_player_created(player)
    if not script.active_mods["Krastorio2"] then return end

    local surface = game.surfaces.nauvis
    if player.index == 1 and surface and not storage.init_ran and not storage.disable_crashsite
        and not storage.SM_Store.krastorio_site_started then
        storage.SM_Store.krastorio_site_started = true
        create_site(surface)
    end

    if prototypes.item["kr-shelter"] then
        player.insert{name = "kr-shelter", count = 1}
    end
    if script.active_mods["aai-industry"] and prototypes.item["medium-electric-pole"] then
        player.insert{name = "medium-electric-pole", count = 10}
    end
end

return krastorio
