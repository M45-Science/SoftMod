-- Native Factorio test scenario. Copy admin_island.lua alongside this file.
local handler
function CMD_AddCommand(_, _, callback) handler = callback end
function CMD_GetPlayer(param) return param.player_index and game.get_player(param.player_index) end
function CMD_RejectConsole(message) storage.last_message = message end
function UTIL_SmartPrint(_, message) storage.last_message = message end
function UTIL_ExitRemoteView(player)
    if player.controller_type == defines.controllers.remote then player.exit_remote_view() end
end
function STORAGE_EnsureGlobal() storage.PData = storage.PData or {} end
function STORAGE_MakePlayerStorage(player)
    storage.PData[player.index] = storage.PData[player.index] or {}
end
function CMD_ModsOnly(param) return not game.get_player(param.player_index).admin end
require "admin_island"

script.on_event(defines.events.on_tick, function()
    local player = game.get_player(1)
    assert(player and player.character)
    local function visit() handler{player_index = player.index} end
    assert(not game.surfaces["admin-island"], "surface created before first visit")
    handler{}
    assert(storage.last_message:find("in%-game"))
    player.admin = false
    visit()
    assert(not game.surfaces["admin-island"], "non-admin created surface")
    player.admin = true
    local original = player.physical_surface
    original.request_to_generate_chunks({0, 0}, 1)
    original.force_generate_chunk_requests()
    local home = original.find_non_colliding_position("character", {0, 0}, 100, 0.5)
    assert(home and player.teleport(home, original))
    visit()
    local island = game.surfaces["admin-island"]
    assert(island and player.physical_surface == island)
    assert(island.freeze_daytime and island.darkness == 0, "island should stay sunny")
    assert(island.get_tile(0, 0).name == "stone-path")
    assert(island.get_tile(20, 10).name == "grass-1")
    assert(island.get_tile(17, -15).name == "water")
    assert(island.get_tile(60, 60).name == "deepwater")
    assert(island.count_entities_filtered{type = "tree"} > 0)
    assert(island.count_entities_filtered{type = "fish"} > 0)
    assert(island.count_entities_filtered{force = "enemy"} == 0)
    visit()
    assert(player.physical_surface == original)
    assert(not storage.PData[player.index].admin_island_return)
    assert(math.abs(player.physical_position.x - home.x) < 2)
    -- Reuse the surface and preserve changes between visits.
    island.set_tiles{{name = "concrete", position = {0, 0}}}
    visit()
    assert(game.surfaces["admin-island"].index == island.index)
    assert(island.get_tile(0, 0).name == "concrete")
    player.admin = false
    ADMIN_ISLAND_CheckAccess(player)
    assert(player.physical_surface == original, "demoted admin stayed on island")
    assert(player.teleport({0, 0}, island))
    ADMIN_ISLAND_CheckAccess(player)
    assert(player.physical_surface == original, "unauthorized visitor stayed on island")
    player.admin = true
    visit()
    storage.PData[player.index].admin_island_return.surface = 999999
    visit()
    assert(player.physical_surface == original, "deleted return surface did not fall back")
    log("ADMIN ISLAND TEST PASSED")
    script.finish_test(true)
end)
