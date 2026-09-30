-- Regression tests using isolated Factorio API mocks; no running game required.
-- Run from the repository root: lua5.2 tests/regressions.lua [source-root]
local source_root = (arg[1] or ".") .. "/"
local function noop() end
local function enums()
    return setmetatable({}, {__index = function(t, k) rawset(t, k, k); return k end})
end
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = copy(v) end
    return result
end
local function grid(equipment)
    local result = {valid = true, equipment = copy(equipment or {})}
    result.put = function(def)
        if result.reject == def.name then return nil end
        local eq = {name = def.name, position = copy(def.position), quality = def.quality or "normal", energy = 0}
        result.equipment[#result.equipment + 1] = eq
        return eq
    end
    return result
end
local function stack(def)
    local s = {valid = true, valid_for_read = false}
    if def then
        s.name, s.count, s.quality = def.name, def.count or 1, def.quality or "normal"
        s.valid_for_read = true
        for _, key in ipairs({"blueprint_data", "ammo", "health", "durability", "spoil_tick", "tags"}) do
            s[key] = copy(def[key])
        end
        if def.grid then s.grid = grid(def.grid.equipment)
        elseif def.name == "power-armor" then s.grid = grid(def.equipment) end
    end
    s.clear = function() s.valid_for_read = false; s.count = 0; s.grid = nil; s.blueprint_data = nil end
    s.transfer_stack = function(source)
        if s.read_only or (s.filter and s.filter ~= source.name) then return false end
        if s.valid_for_read and (s.name ~= source.name or s.quality ~= source.quality or s.grid or s.blueprint_data) then
            return false
        end
        local capacity = s.capacity or ((source.grid or source.blueprint_data) and 1 or 100)
        local moved = math.min(source.count, capacity - (s.valid_for_read and s.count or 0))
        if moved <= 0 then return false end
        if not s.valid_for_read then
            local fresh = stack(source)
            for _, key in ipairs({"name", "quality", "grid", "blueprint_data", "ammo", "health", "durability", "spoil_tick", "tags"}) do
                s[key] = fresh[key]
            end
            s.count = 0
            s.valid_for_read = true
        end
        s.count = s.count + moved
        source.count = source.count - moved
        if source.count == 0 then source.clear(); return true end
        return false -- Factorio can partially transfer even when returning false.
    end
    return s
end
local function inventory(size, first)
    local inv = {valid = true}
    for i = 1, size do inv[i] = stack(i == 1 and first or nil) end
    inv.can_insert = function() return true end
    inv.insert = function(def)
        for i = 1, #inv do
            if not inv[i].valid_for_read then inv[i] = stack(def); return def.count or 1 end
        end
        return 0
    end
    inv.get_item_count = function()
        local n = 0
        for i = 1, #inv do if inv[i].valid_for_read then n = n + inv[i].count end end
        return n
    end
    inv.is_empty = function() return inv.get_item_count() == 0 end
    inv.count_empty_stacks = function()
        local n = 0
        for i = 1, #inv do if not inv[i].valid_for_read then n = n + 1 end end
        return n
    end
    inv.get_contents = function()
        local result = {}
        for i = 1, #inv do
            if inv[i].valid_for_read then
                result[#result + 1] = {name = inv[i].name, count = inv[i].count, quality = inv[i].quality}
            end
        end
        return result
    end
    inv.clear = function() for i = 1, #inv do inv[i].clear() end end
    return inv
end
local function environment()
    local e = setmetatable({}, {__index = _G})
    e.storage = {}
    e.defines = {inventory = enums(), input_action = enums(), controllers = enums()}
    e.prototypes = {item = enums(), quality = enums()}
    e.registered = {}
    e.commands = {remove_command = noop, add_command = function(name, _, handler) e.registered[name] = handler end}
    local groups = {}
    local function add_group(name)
        local g = {name = name, valid = true, actions = {}}
        g.add_player = function(p) p.permission_group = g end
        g.remove_player = function(p) if p.permission_group == g then p.permission_group = nil end end
        g.set_allows_action = function(action, value) g.actions[action] = value end
        groups[name] = g
        return g
    end
    local force = {name = "player", get_spawn_position = function() return {x = 0, y = 0} end}
    force.chart = function(_, area)
        e.chart_area = area
        assert(area.left_top and area.right_bottom, "BoundingBox requires left_top and right_bottom")
    end
    local surfaces = {}
    for i, name in ipairs({"nauvis", "jail"}) do
        surfaces[i] = {name = name, valid = true, index = i,
            find_non_colliding_position = function(_, pos) return pos end}
    end
    setmetatable(surfaces, {__index = function(_, key)
        for i = 1, #surfaces do if surfaces[i].name == key then return surfaces[i] end end
    end})
    local players = setmetatable({}, {__index = function(t, name)
        for _, p in pairs(t) do if p.name == name then return p end end
    end})
    e.game = {tick = 100, speed = 1, players = players, connected_players = {}, surfaces = surfaces,
        forces = {player = force}, create_inventory = inventory,
        permissions = {get_group = function(name) return groups[name] end, create_group = add_group}}
    e.load = function(name) return assert(loadfile(source_root .. name .. ".lua", "t", e))() end
    local loaded = {}
    e.require = function(name)
        if not loaded[name] then loaded[name] = e.load(name) or true end
        return loaded[name]
    end
    e.load("storage")
    e.load("utility")
    e.load("perms")
    e.STORAGE_EnsureGlobal()
    e.PERMS_EnsureGroups()
    for _, name in ipairs({"UTIL_SmartPrint", "UTIL_MsgAll", "UTIL_MsgAllSys", "UTIL_ConsolePrint",
        "CW_EmitEvent", "CW_EmitText", "ONLINE_MarkDirty"}) do e[name] = noop end
    e.player = function(name, admin)
        local p = {index = #players + 1, name = name, valid = true, connected = true, admin = admin or false,
            character = {valid = true}, controller_type = e.defines.controllers.character,
            surface = surfaces[1], physical_surface = surfaces[1], position = {x = 0, y = 0}, force = force}
        p.teleport = function(_, surface) p.surface = surface; p.physical_surface = surface; return true end
        p.permission_group = groups.Default
        players[p.index] = p
        e.game.connected_players[#e.game.connected_players + 1] = p
        e.STORAGE_MakePlayerStorage(p)
        return p
    end
    e.load("commands")
    e.setup = function()
        -- Load the real setup function; stub unrelated UI/event module loading.
        local require_module = e.require
        e.require = function(name) if name == "version" then return "review" end; return true end
        e.script = {on_init = noop, on_configuration_changed = noop}
        e.TODO_Init, e.FORCEDEL_MakeButton = noop, noop
        e.storage.SM_OldVersion = "review"
        e.load("control")
        e.require = require_module
        e.RunSetup()
    end
    return e
end
local passed, failed = 0, 0
local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
        print("PASS: " .. name)
    else
        failed = failed + 1
        print("FAIL: " .. name .. ": " .. tostring(err))
    end
end
local function banish_env()
    local e = environment()
    e.load("banish")
    e.UTIL_DumpInv = noop
    return e
end
local function gear_env()
    local e = environment()
    e.load("stash")
    local p = e.player("supporter")
    e.storage.PData[p.index].patreon = true
    local invs = {character_guns = inventory(3), character_ammo = inventory(3), character_armor = inventory(1),
        character_main = inventory(10)}
    p.get_inventory = function(id) return invs[id] end
    return e, p, invs
end
local function chatwire_env()
    local e = environment()
    e.helpers = {decode_string = function(s) return s end, json_to_table = function() return e.request end}
    e.load("chatwire")
    e.CW_Emit = function(kind, data) if kind == "response" then e.response = data end end
    e.request_command = function(command, data)
        e.request = {v = 1, id = "test", command = command, data = data}
        e.registered.chatwire({parameter = "mock-encoded-request"})
        return e.response
    end
    return e
end

test("manual /jail survives /votes and unrelated vote changes", function()
    local e = banish_env()
    local p, caller = e.player("target"), e.player("caller")
    e.registered.jail({name = "jail", parameter = p.name})
    e.registered.votes({player_index = caller.index})
    assert(p.permission_group.name == "Jailed" and p.physical_surface.name == "jail")
    assert(e.storage.PData[p.index].manual_jail and e.UTIL_Is_Banished(p))
    e.storage.SM_Store.votes = {{voter = caller, victim = p, withdrawn = true}}
    e.BANISH_UpdateVotes()
    assert(p.permission_group.name == "Jailed")
end)

test("legacy manual jails survive an in-place upgrade", function()
    local e = banish_env()
    local p = e.player("target")
    e.storage.PData[p.index].manual_jail = nil
    e.storage.PData[p.index].banished = 1000
    e.storage.SM_Store.jailGroup.add_player(p)
    p.surface = e.game.surfaces.jail; p.physical_surface = p.surface
    e.setup()
    e.BANISH_UpdateVotes()
    assert(e.storage.PData[p.index].manual_jail and p.permission_group.name == "Jailed")
end)

test("legacy moderator votes remain withdrawable after upgrade", function()
    local e = banish_env()
    local p, voter = e.player("target"), e.player("moderator", true)
    e.storage.PData[p.index].manual_jail = nil
    e.storage.PData[p.index].banished = 1000
    e.storage.SM_Store.jailGroup.add_player(p)
    e.storage.SM_Store.votes = {{voter = voter, victim = p}}
    e.setup()
    assert(e.storage.PData[p.index].manual_jail == false)
    e.storage.SM_Store.votes[1].withdrawn = true
    e.BANISH_UpdateVotes()
    assert(p.permission_group.name == "Default")
end)

test("unjail overrules every vote and survives subsequent recounts", function()
    local e = banish_env()
    local p, a, b = e.player("target"), e.player("voter-a"), e.player("voter-b")
    e.storage.PData[a.index].level = 2; e.storage.PData[b.index].level = 2
    e.storage.SM_Store.votes = {{voter = a, victim = p}, {voter = b, victim = p}}
    e.registered.jail({name = "jail", parameter = p.name})
    e.registered.unjail({name = "unjail", parameter = p.name})
    for _, vote in ipairs(e.storage.SM_Store.votes) do assert(vote.overruled) end
    e.BANISH_UpdateVotes()
    assert(not e.storage.PData[p.index].manual_jail and not e.UTIL_Is_Banished(p))
end)

test("overrule clear explicitly releases manual and vote jails", function()
    local e = banish_env()
    local p = e.player("target")
    e.registered.jail({name = "jail", parameter = p.name})
    e.registered.overrule({name = "overrule", parameter = "clear"})
    assert(p.permission_group.name == "Default" and not e.UTIL_Is_Banished(p))
end)

test("withdrawing a legacy moderator vote initializes jail state before mutation", function()
    local e = banish_env()
    local p, voter = e.player("target"), e.player("moderator", true)
    e.storage.PData[p.index].manual_jail = nil
    e.storage.PData[p.index].banished = 1000
    e.storage.SM_Store.jailGroup.add_player(p)
    e.storage.SM_Store.votes = {{voter = voter, victim = p}}
    e.registered.unbanish({player_index = voter.index, parameter = p.name})
    assert(e.storage.SM_Store.votes[1].withdrawn and not e.UTIL_Is_Banished(p))
end)

test("overruling a legacy moderator vote initializes jail state before mutation", function()
    local e = banish_env()
    local p, voter = e.player("target"), e.player("moderator", true)
    e.storage.PData[p.index].manual_jail = nil
    e.storage.PData[p.index].banished = 1000
    e.storage.SM_Store.jailGroup.add_player(p)
    e.storage.SM_Store.votes = {{voter = voter, victim = p}}
    e.registered.overrule({name = "overrule", parameter = p.name})
    assert(e.storage.SM_Store.votes[1].overruled and not e.UTIL_Is_Banished(p))
end)

test("unstash with no stash leaves equipped armor untouched", function()
    local e, p, invs = gear_env()
    invs.character_armor[1] = stack({name = "power-armor", equipment = {{name = "exoskeleton-equipment"}}})
    e.registered.unstash({player_index = p.index})
    assert(invs.character_armor[1].valid_for_read and #invs.character_armor[1].grid.equipment == 1)
    assert(invs.character_main.is_empty())
end)

test("unstash with allocated but empty stashes leaves equipment untouched", function()
    local e, p, invs = gear_env()
    invs.character_armor[1] = stack({name = "power-armor", equipment = {{name = "exoskeleton-equipment"}}})
    for _, name in ipairs({"gun_stash", "ammo_stash", "armor_stash"}) do
        e.storage.PData[p.index][name] = inventory(3)
    end
    e.registered.unstash({player_index = p.index})
    assert(#invs.character_armor[1].grid.equipment == 1 and invs.character_main.is_empty())
end)

test("unstash preserves equipment on currently worn armor moved to main", function()
    local e, p, invs = gear_env()
    invs.character_armor[1] = stack({name = "power-armor", equipment = {{name = "exoskeleton-equipment"}}})
    e.storage.PData[p.index].gun_stash = inventory(3, {name = "pistol"})
    e.registered.unstash({player_index = p.index})
    assert(#invs.character_main[1].grid.equipment == 1 and invs.character_guns[1].name == "pistol")
end)

test("stash round-trip preserves armor quality and complete equipment state", function()
    local e, p, invs = gear_env()
    invs.character_armor[1] = stack({name = "power-armor", quality = "legendary", health = 0.4, equipment = {
        {name = "exoskeleton-equipment", quality = "legendary", position = {x = 0, y = 0}, energy = 12, shield = 7}}})
    invs.character_ammo[1] = stack({name = "firearm-magazine", count = 5, ammo = 2, quality = "rare"})
    e.registered.stash({player_index = p.index})
    assert(invs.character_armor.is_empty() and invs.character_ammo.is_empty())
    e.registered.unstash({player_index = p.index})
    local armor, equipment = invs.character_armor[1], invs.character_armor[1].grid.equipment[1]
    assert(armor.quality == "legendary" and armor.health == 0.4)
    assert(equipment.quality == "legendary" and equipment.energy == 12 and equipment.shield == 7)
    assert(invs.character_ammo[1].ammo == 2 and invs.character_ammo[1].count == 5)
    assert(e.storage.PData[p.index].armor_equipment_data == nil)
end)

test("blocked unequip leaves the equipped grid and stash intact", function()
    local e, p, invs = gear_env()
    invs.character_armor[1] = stack({name = "power-armor", equipment = {{name = "exoskeleton-equipment"}}})
    for i = 1, #invs.character_main do invs.character_main[i] = stack({name = "iron-plate", count = 100}) end
    e.storage.PData[p.index].gun_stash = inventory(3, {name = "pistol"})
    e.registered.unstash({player_index = p.index})
    assert(#invs.character_armor[1].grid.equipment == 1)
    assert(e.storage.PData[p.index].gun_stash[1].name == "pistol" and invs.character_guns.is_empty())
end)

test("legacy stashed armor restores equipment before transfer", function()
    local e, p, invs = gear_env()
    e.storage.PData[p.index].armor_stash = inventory(1, {name = "power-armor", quality = "rare"})
    e.storage.PData[p.index].armor_equipment_data = {
        {name = "exoskeleton-equipment", position = {x = 0, y = 0}, energy = 12}}
    e.registered.unstash({player_index = p.index})
    local armor = invs.character_armor[1]
    assert(armor.quality == "rare" and #armor.grid.equipment == 1 and armor.grid.equipment[1].energy == 12)
    assert(e.storage.PData[p.index].armor_equipment_data == nil)
end)

test("legacy equipment restoration failures retain armor and pending data", function()
    local e, p, invs = gear_env()
    local pdata = e.storage.PData[p.index]
    pdata.armor_stash = inventory(1, {name = "power-armor"})
    pdata.armor_equipment_data = {
        {name = "exoskeleton-equipment", position = {x = 0, y = 0}, energy = 12},
        {name = "battery-equipment", position = {x = 2, y = 0}, energy = 20}}
    pdata.armor_stash[1].grid.reject = "battery-equipment"
    e.registered.unstash({player_index = p.index})
    assert(invs.character_armor.is_empty() and #pdata.armor_equipment_data == 1)
    assert(#pdata.armor_stash[1].grid.equipment == 1)
    pdata.armor_stash[1].grid.reject = nil
    e.registered.unstash({player_index = p.index})
    assert(#invs.character_armor[1].grid.equipment == 2 and pdata.armor_equipment_data == nil)
end)

test("partial and blocked stack transfers retain all remaining items", function()
    local e = environment()
    local source, target = inventory(1, {name = "iron-plate", count = 80}), inventory(1)
    target[1].capacity = 30
    local moved, remaining = e.UTIL_TransferInventory(source, target)
    assert(moved and remaining and source[1].count == 50 and target[1].count == 30)
    moved, remaining = e.UTIL_TransferInventory(source, target)
    assert(not moved and remaining and source[1].count == 50)
    target[1].clear(); target[1].filter = "copper-plate"
    moved, remaining = e.UTIL_TransferInventory(source, target)
    assert(not moved and remaining and source[1].count == 50)
end)

test("inventory dumps preserve blueprint contents, armor grids and trash metadata", function()
    local e = environment()
    local p = e.player("target")
    local main = inventory(5, {name = "blueprint", blueprint_data = {entities = {"assembling-machine-3"}}})
    main[2] = stack({name = "power-armor", equipment = {{name = "exoskeleton-equipment", quality = "legendary"}}})
    local trash = inventory(2, {name = "firearm-magazine", count = 5, ammo = 2, quality = "rare"})
    p.get_inventory = function(id) if id == "character_main" then return main elseif id == "character_trash" then return trash end end
    local corpse_inv
    e.game.surfaces[1].create_entity = function(def)
        corpse_inv = inventory(def.inventory_size)
        return {get_inventory = function() return corpse_inv end}
    end
    assert(e.UTIL_DumpInv(p, true) and main.is_empty() and trash.is_empty())
    assert(corpse_inv[1].blueprint_data.entities[1] == "assembling-machine-3")
    assert(corpse_inv[2].grid.equipment[1].quality == "legendary")
    assert(corpse_inv[3].ammo == 2 and corpse_inv[3].quality == "rare")
    assert(e.storage.PData[p.index].cleaned)
end)

test("incomplete dumps leave unmoved items and allow another attempt", function()
    local e = environment()
    local p = e.player("target")
    local main = inventory(1, {name = "iron-plate", count = 80})
    p.get_inventory = function(id) if id == "character_main" then return main end end
    e.game.surfaces[1].create_entity = function()
        local inv = inventory(1); inv[1].capacity = 30
        return {get_inventory = function() return inv end}
    end
    assert(e.UTIL_DumpInv(p, false) and main[1].count == 50 and not e.storage.PData[p.index].cleaned)
    assert(e.UTIL_DumpInv(p, false) and main[1].count == 20)
end)

test("blueprint bans survive setup and repeated ChatWire config repairs drift", function()
    local e = chatwire_env()
    assert(e.request_command("config", {blueprints = false}).ok)
    e.setup()
    for _, key in ipairs({"defGroup", "memGroup", "regGroup", "vetGroup", "modGroup"}) do
        assert(e.storage.SM_Store[key].actions.import_blueprint_string == false)
    end
    e.storage.SM_Store.defGroup.actions.import_blueprint_string = true
    assert(e.request_command("config", {blueprints = false}).ok)
    assert(e.storage.SM_Store.defGroup.actions.import_blueprint_string == false)
end)

test("blueprint and new-user restrictions compose in either setting order", function()
    local e = chatwire_env()
    local defaults = e.storage.SM_Store.defGroup
    assert(e.request_command("config", {restrict = true, blueprints = true}).ok)
    assert(defaults.actions.import_blueprint_string == false and defaults.actions.setup_blueprint == true)
    assert(e.storage.SM_Store.memGroup.actions.import_blueprint_string == true)
    assert(e.request_command("config", {blueprints = false}).ok)
    assert(e.request_command("config", {restrict = false}).ok)
    assert(defaults.actions.import_blueprint_string == false and defaults.actions.setup_blueprint == false)
    assert(defaults.actions.launch_rocket == true)
    assert(e.request_command("config", {blueprints = true}).ok)
    assert(defaults.actions.import_blueprint_string == true and defaults.actions.setup_blueprint == true)
    assert(defaults.actions.deconstruct ~= true)
end)

test("invalid player levels leave admin and pending-change state untouched", function()
    local e = chatwire_env()
    local p = e.player("moderator", true)
    for _, level in ipairs({4, -1, 1.5, 254, 256}) do
        local result = e.request_command("player-level", {name = p.name, level = level})
        assert(not result.ok and result.error == "unsupported player level")
        assert(p.admin and not e.CW_ConsumeAdminChange(p.index))
    end
    assert(e.request_command("player-level", {name = p.name, level = 2}).ok)
    assert(not p.admin and e.CW_ConsumeAdminChange(p.index) and e.storage.PData[p.index].level == 2)
end)

test("reveal supplies valid bounds from console and from a player", function()
    local e = environment()
    e.registered.reveal({name = "reveal", parameter = "1024"})
    assert(e.chart_area.left_top.x == -512 and e.chart_area.right_bottom.y == 512)
    local p = e.player("moderator", true)
    e.registered.reveal({name = "reveal", parameter = "128 [gps=10,20,nauvis]", player_index = p.index})
    assert(e.chart_area.left_top.x == -54 and e.chart_area.right_bottom.y == 84)
end)

test("failed teleport stays queued and succeeds on a later retry", function()
    local e = banish_env()
    local p = e.player("target")
    local teleport = p.teleport
    p.teleport = function() return false end
    e.registered.jail({name = "jail", parameter = p.name})
    assert(p.physical_surface.name == "nauvis" and #e.storage.SM_Store.sendToSurface == 1)
    p.teleport = teleport
    e.BANISH_SendToSurface(p)
    assert(p.physical_surface.name == "jail" and #e.storage.SM_Store.sendToSurface == 0)
end)

test("failed fallback teleports also stay queued", function()
    local e = banish_env()
    local p = e.player("target")
    e.game.surfaces.jail.find_non_colliding_position = function() return nil end
    p.teleport = function() return false end
    e.storage.SM_Store.sendToSurface = {{victim = p, surface = "jail", position = {x = 0, y = 0}}}
    e.BANISH_SendToSurface(p)
    assert(#e.storage.SM_Store.sendToSurface == 1)
    e.storage.SM_Store.sendToSurface[1].position = nil
    e.BANISH_SendToSurface(p)
    assert(#e.storage.SM_Store.sendToSurface == 1)
end)

test("offline release supersedes a pending jail teleport", function()
    local e = banish_env()
    local p = e.player("target")
    p.character = nil
    e.registered.jail({name = "jail", parameter = p.name})
    e.registered.unjail({name = "unjail", parameter = p.name})
    assert(#e.storage.SM_Store.sendToSurface == 1 and e.storage.SM_Store.sendToSurface[1].surface == 1)
    p.character = {valid = true}
    e.BANISH_SendToSurface(p)
    assert(p.physical_surface.name == "nauvis" and #e.storage.SM_Store.sendToSurface == 0)
end)

print(string.format("%d passed; %d failed", passed, failed))
if failed > 0 then os.exit(1) end
