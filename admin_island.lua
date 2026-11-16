-- A small shared retreat, generated only when an administrator first visits.
local SURFACE_NAME = "admin-island"

local function make_island()
    local existing = game.surfaces[SURFACE_NAME]
    if existing then return existing end

    local surface = game.create_surface(SURFACE_NAME, {
        width = 128, height = 128,
        default_enable_all_autoplace_controls = false,
        autoplace_settings = {
            entity = {treat_missing_as_default = false, settings = {}},
            decorative = {treat_missing_as_default = false, settings = {}},
            tile = {treat_missing_as_default = false, settings = {}}
        }
    })
    surface.request_to_generate_chunks({0, 0}, 2)
    surface.force_generate_chunk_requests()
    surface.daytime = 0
    surface.freeze_daytime = true
    surface.show_clouds = false
    local tiles = {}
    for y = -64, 63 do
        for x = -64, 63 do
            local distance = math.sqrt(x * x + y * y)
            local shore = 37 + 2 * math.sin(x / 7) * math.cos(y / 9)
            local tile = "deepwater"
            if distance < shore + 7 then tile = "water" end
            if distance < shore then tile = "sand-1" end
            if distance < shore - 4 then tile = "grass-1" end
            if distance < 7 or (math.abs(x) < 2 and math.abs(y) < 31)
                or (math.abs(y) < 2 and math.abs(x) < 31) then
                tile = "stone-path"
            end
            if (x - 17)^2 + (y + 15)^2 < 30 then tile = "water" end
            tiles[#tiles + 1] = {name = tile, position = {x, y}}
        end
    end
    surface.set_tiles(tiles)
    for y = -27, 27, 6 do
        for x = -27, 27, 6 do
            if x * x + y * y < 29 * 29 and math.abs(x) > 7 and math.abs(y) > 7 then
                local spec = {name = "tree-04", position = {x, y}}
                if surface.can_place_entity(spec) then surface.create_entity(spec) end
            end
        end
    end
    for _, pos in ipairs({{17, -15}, {-42, 0}, {42, 0}, {0, 42}, {0, -42}}) do
        surface.create_entity{name = "fish", position = pos}
    end
    return surface
end

local function return_from_island(player)
    STORAGE_EnsureGlobal()
    STORAGE_MakePlayerStorage(player)
    local pdata = storage.PData[player.index]
    local saved = pdata.admin_island_return
    local surface = saved and game.surfaces[saved.surface]
    local position = saved and saved.position
    if not (surface and surface.valid) or surface.name == SURFACE_NAME then
        surface = game.surfaces[1]
        position = player.force.get_spawn_position(surface)
    end
    UTIL_ExitRemoteView(player)
    local name = player.character and player.character.name or "character"
    local destination = surface.find_non_colliding_position(name, position, 64, 0.5)
    if destination and player.teleport(destination, surface) then
        pdata.admin_island_return = nil
        UTIL_SmartPrint(player, "Returned from Admin Island.")
        return true
    end
    UTIL_SmartPrint(player, "Could not find a safe return position. Try /admin-island again.")
    return false
end

function ADMIN_ISLAND_CheckAccess(player)
    if player and player.valid and not player.admin and player.physical_surface.name == SURFACE_NAME then
        player.driving = false
        return_from_island(player)
    end
end

CMD_AddCommand("admin-island", "Admins only: visit Admin Island; use again to return.", function(param)
    local player = CMD_GetPlayer(param)
    if not player then
        CMD_RejectConsole("/admin-island can only be used by a player in-game.")
        return
    end
    -- Always allow an occupant to leave, including after losing admin access.
    if player.physical_surface.name == SURFACE_NAME then
        player.driving = false
        return_from_island(player)
        return
    end
    if CMD_ModsOnly(param) then return end
    if param.parameter and param.parameter:match("%S") then
        UTIL_SmartPrint(player, "Use /admin-island without arguments to visit or return.")
        return
    end
    if not player.character or player.driving then
        UTIL_SmartPrint(player, "Leave your vehicle and use this command with a living character.")
        return
    end
    UTIL_ExitRemoteView(player)
    local origin = {surface = player.physical_surface.index,
        position = {x = player.physical_position.x, y = player.physical_position.y}}
    local surface = make_island()
    local destination = surface.find_non_colliding_position(player.character.name, {0, 0}, 16, 0.5)
    if destination and player.teleport(destination, surface) then
        STORAGE_EnsureGlobal()
        STORAGE_MakePlayerStorage(player)
        storage.PData[player.index].admin_island_return = origin
        UTIL_SmartPrint(player, "Welcome to Admin Island! Use /admin-island again to return.")
    else
        UTIL_SmartPrint(player, "Could not find a safe landing on Admin Island.")
    end
end)
