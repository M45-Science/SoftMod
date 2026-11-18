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
        -- Setup removes legacy windows; other tests intentionally omit GUI mocks.
        local guis = {}
        for _, player in pairs(e.game.players) do
            guis[player.index] = player.gui
            player.gui = player.gui or {screen = {}}
        end
        e.RunSetup()
        for _, player in pairs(e.game.players) do player.gui = guis[player.index] end
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

test("player names match case-insensitively without partial matches", function()
    local e = environment()
    local p = e.player("AlIcE")
    assert(e.UTIL_PlayerNamesEqual("ALICE", "alice"))
    assert(not e.UTIL_PlayerNamesEqual(nil, nil))
    assert(not e.UTIL_PlayerNamesEqual("alice", "ali"))
    for _, name in ipairs({"alice", "ALICE", "AlIcE"}) do
        assert(e.UTIL_FindPlayer(name) == p)
    end
    p.connected = false
    assert(e.UTIL_FindPlayer("alice") == p)
    assert(e.UTIL_FindPlayer("ali") == nil and e.UTIL_FindPlayer("missing") == nil)
    assert(e.UTIL_FindPlayer(nil) == nil and e.UTIL_FindPlayer(1) == nil)
    assert(p.name == "AlIcE")
end)

test("ChatWire levels accept database casing and emit canonical player names", function()
    local e = chatwire_env()
    local p = e.player("AlIcE")
    local last_event
    e.CW_EmitEvent = function(event, data) last_event = {event = event, data = data} end
    for _, assignment in ipairs({
        {1, "memGroup"}, {2, "regGroup"}, {3, "vetGroup"},
        {255, "modGroup"}, {2, "regGroup"}, {0, "defGroup"},
    }) do
        last_event = nil
        local level, group = assignment[1], assignment[2]
        local result = e.request_command("player-level", {name = "alice", level = level})
        assert(result.ok, result.error)
        assert(p.permission_group == e.storage.SM_Store[group])
        assert(p.admin == (level == 255))
        if level ~= 255 then assert(e.storage.PData[p.index].level == level) end
        assert(last_event.event == "player-level" and last_event.data.name == "AlIcE" and last_event.data.level == level)
    end
    p.connected = false
    for _, name in ipairs({"alice", "AlIcE", "missing"}) do
        local result = e.request_command("player-level", {name = name, level = 1})
        assert(not result.ok and result.error == "player is not online")
    end
    assert(e.storage.PData[p.index].level == 0)
end)

test("ChatWire whispers and supporter flags accept mixed player-name casing", function()
    local e = chatwire_env()
    local p = e.player("AlIcE")
    local recipient, message
    e.UTIL_SmartPrint = function(player, text) recipient, message = player, text end
    assert(e.request_command("whisper", {name = "ALICE", text = "Hello"}).ok)
    assert(recipient == p and message == "Hello")
    assert(e.request_command("supporter", {name = "alice", patreon = true, nitro = true}).ok)
    assert(e.storage.PData[p.index].patreon and e.storage.PData[p.index].nitro)
end)

test("moderator commands accept mixed player-name casing", function()
    local e = banish_env()
    local p = e.player("AlIcE")
    e.registered.member({parameter = "ALICE"})
    assert(e.storage.PData[p.index].level == 1)
    e.registered.reset({parameter = "alice"})
    assert(e.storage.PData[p.index].level == 0)
    e.registered.jail({parameter = "aLiCe"})
    assert(e.storage.PData[p.index].manual_jail)
    e.registered.unjail({parameter = "ALICE"})
    assert(not e.storage.PData[p.index].manual_jail)
end)

test("reveal supplies valid bounds from console and from a player", function()
    local e = environment()
    e.registered.reveal({name = "reveal", parameter = "1024"})
    assert(e.chart_area.left_top.x == -512 and e.chart_area.right_bottom.y == 512)
    local p = e.player("moderator", true)
    e.registered.reveal({name = "reveal", parameter = "128 [gps=10,20,nauvis]", player_index = p.index})
    assert(e.chart_area.left_top.x == -54 and e.chart_area.right_bottom.y == 84)
end)

test("reveal keeps an omitted size and resolves the explicit GPS surface", function()
    local e = environment()
    local surface = {name = "space-platform 1"}
    e.game.surfaces[3] = surface
    local charted, bounds
    e.game.forces.player.chart = function(s, area) charted, bounds = s, area end
    e.registered.reveal{parameter = "750,-20"}
    assert(bounds.left_top.x == 750 - 512 and bounds.right_bottom.y == -20 + 512,
        "the x coordinate became the reveal size")
    e.registered.reveal{parameter = "128 [gps=12,-20,space-platform 1]"}
    assert(charted == surface and bounds.left_top.x == -52 and bounds.right_bottom.y == 44)
    charted = nil
    e.registered.reveal{parameter = "[gps=12,-20,removed-surface]"}
    assert(not charted, "charted the default surface for an unknown GPS destination")
    e.registered.reveal{parameter = ".,20"}
    assert(not charted, "invalid coordinates should not chart an area")
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

test("new map preview is sent once after ChatWire hello", function()
    local e = chatwire_env()
    e.RunSetup = noop
    assert(e.storage.CW_MapPreviewPending)
    local reads, events = 0, {}
    e.game.get_map_exchange_string = function()
        reads = reads + 1
        return ">>>actual-map-settings-and-seed<<<"
    end
    e.CW_EmitEvent = function(event, data)
        events[#events + 1] = {event = event, data = data}
    end
    assert(e.request_command("hello", {}).ok)
    assert(reads == 1 and #events == 1)
    assert(events[1].event == "map-preview")
    assert(events[1].data.exchange_string == ">>>actual-map-settings-and-seed<<<")
    assert(not e.storage.CW_MapPreviewPending)
    e.STORAGE_EnsureGlobal()
    assert(not e.storage.CW_MapPreviewPending)
    assert(e.request_command("hello", {}).ok)
    assert(reads == 1 and #events == 1)
end)

test("existing maps do not announce a preview on hello", function()
    local e = chatwire_env()
    e.storage.CW_MapPreviewPending = nil
    e.STORAGE_EnsureGlobal()
    e.RunSetup = noop
    e.game.get_map_exchange_string = function() error("must not read existing map") end
    e.CW_EmitEvent = function() error("must not announce existing map") end
    assert(e.request_command("hello", {}).ok)
end)

test("failed map exchange remains pending without breaking hello", function()
    local e = chatwire_env()
    e.RunSetup = noop
    e.storage.CW_MapPreviewPending = true
    e.game.get_map_exchange_string = function() error("not ready") end
    local errors = 0
    e.CW_EmitText = function(event) assert(event == "error"); errors = errors + 1 end
    assert(e.request_command("hello", {}).ok)
    assert(errors == 1 and e.storage.CW_MapPreviewPending)
end)

test("map-preview returns a copyable URL to the requesting player", function()
    local e = chatwire_env()
    local player = e.player("preview-player")
    e.game.get_map_exchange_string = function() return ">>>+//v\r\nYQ==<<<" end
    local recipient, text
    e.UTIL_SmartPrint = function(p, message) recipient, text = p, message end
    e.registered["map-preview"]({player_index = player.index})
    assert(recipient == player and text == "https://mapgen.m45sci.xyz/#m=-__vYQ")
    assert(e.storage.CW_MapPreviewPending) -- manual requests do not consume the announcement
end)

test("map-preview supports console and RCON and handles export errors", function()
    local e = chatwire_env()
    local recipient, text
    e.UTIL_SmartPrint = function(p, message) recipient, text = p, message end
    e.game.get_map_exchange_string = function() return ">>>YWJj<<<" end
    e.registered["map-preview"]({})
    assert(recipient == nil and text == "https://mapgen.m45sci.xyz/#m=YWJj")
    e.game.get_map_exchange_string = function() error("unavailable") end
    e.registered["map-preview"]({})
    assert(text:match("^Map preview unavailable:"))
end)

test("Discord activity notices back off per player and activity while logging each event", function()
    local e = environment()
    e.load("log")
    local player, other = e.player("pilot"), e.player("other")
    local notices, logged = {}, {}
    e.game.print = function() error("routine activity was broadcast in game") end
    e.CW_EmitText = function(event, msg)
        assert(event == "message")
        table.insert(notices, msg)
    end
    e.UTIL_MsgAll = function() error("routine activity was broadcast in game") end
    e.UTIL_ConsolePrint = function(msg) table.insert(logged, msg) end
    e.UTIL_Is_New = function(p) return p == player end
    e.UTIL_Is_Member = function(p) return p == other end
    e.UTIL_Is_Banished = function() return false end
    e.UTIL_IsNatural = function() return false end
    e.UTIL_GPSObj = function(obj) return obj.gps_tag end
    e.UTIL_Area = function() return "[gps=0,0]" end
    local vehicle = {name = "car", gps_tag = "[gps=0,0]"}
    local building = {name = "steel-chest", gps_tag = "[gps=1,2]"}
    local function drive(p, tick)
        e.game.tick = tick
        e.LOG_PlayerDrive({player_index=p.index, entity=vehicle})
    end
    e.storage.PData[player.index].activityNotices = nil -- pre-upgrade save
    drive(player, 100)
    drive(player, 101)
    drive(other, 101)
    local mark = {player_index=player.index, entity=building}
    e.LOG_MarkDecon(mark)
    e.LOG_CancelDecon(mark)
    e.LOG_Decon({player_index=player.index, area={left_top={x=0,y=0},right_bottom={x=2,y=2}},
        surface={find_entities_filtered=function() return {building} end}})
    assert(#notices == 3 and #logged == 6)
    for _,tick in ipairs({400,1000,2200,4600,8200,11800}) do
        local previous = #notices
        drive(player, tick-1)
        drive(player, tick)
        assert(#notices == previous + 1 and notices[#notices] == logged[#logged])
    end
    drive(player, 19000) -- quiet for exactly two game minutes
    drive(player, 19299)
    drive(player, 19300)
    assert(#notices == 11 and #logged == 21)
    e.game.tick = 19301
    e.LOG_MarkedUpgrade(mark)
    e.game.tick = 19302
    e.LOG_CancelUpgrade(mark)
    e.LOG_Flushed({player_index=player.index, entity=building, amount=10, fluid="water"})
    assert(#notices == 14 and #logged == 24)
    e.UTIL_Is_New = function() return false end
    e.game.tick = 40000
    drive(player, 40000)
    e.LOG_MarkDecon(mark)
    assert(#notices == 14 and #logged == 26)
end)

test("depleted drill cleanup stays auditable without activity notices", function()
    local e = environment()
    e.load("log")
    local player = e.player("pilot")
    local notices, logged, resources = {}, {}, 0
    e.UTIL_ConsolePrint = function(msg) logged[#logged + 1] = msg end
    e.UTIL_MsgDiscord = function(msg) notices[#notices + 1] = msg end
    e.UTIL_Is_New = function() return true end
    e.UTIL_Is_Member = function() return false end
    e.UTIL_Is_Banished = function() return false end
    e.UTIL_IsNatural = function() return false end
    e.UTIL_GPSObj = function() return "[gps=1,2]" end
    local area = {{0, 0}, {5, 5}}
    local drill = {type = "mining-drill", name = "electric-mining-drill", mining_area = area,
        -- A nil target alone must never exempt a powerless/blocked live drill.
        surface = {count_entities_filtered = function(filter)
            assert(filter.area == area and filter.type == "resource" and filter.limit == 1)
            return resources
        end}}
    local mark = {player_index = player.index, entity = drill}
    e.LOG_MarkDecon(mark)
    e.LOG_CancelDecon(mark)
    assert(#notices == 0 and #logged == 2)
    assert(logged[1]:find(" decon%-depleted ") and logged[2]:find(" undecon%-depleted "))
    resources = 1
    e.LOG_MarkDecon(mark)
    assert(#notices == 1 and logged[3]:find(" decon electric%-mining%-drill "))
    mark.entity = {type = "container", name = "steel-chest"}
    e.LOG_MarkDecon(mark)
    assert(logged[4]:find(" decon steel%-chest "))
end)

test("asteroid deaths survive save/load and flush once per nonempty interval", function()
    local e = environment()
    e.load("storage")
    e.load("log")
    local lines = {}
    e.UTIL_ConsolePrint = function(line) table.insert(lines, line) end
    local asteroid = {entity = {name = "modded-rock", type = "asteroid"}}
    e.LOG_EntDied(asteroid)
    e.storage = copy(e.storage)
    e.STORAGE_EnsureGlobal()
    e.LOG_EntDied(asteroid)
    e.LOG_EntDied({entity = {name = "character", type = "character"}})
    e.LOG_EntDied({entity = {name = "asteroid-collector", type = "asteroid-collector", gps_tag = "[gps=1,2]"}})
    assert(#lines == 1 and lines[1] == "asteroid-collector died at [gps=1,2]")
    e.LOG_FlushAsteroidDeaths()
    e.LOG_FlushAsteroidDeaths()
    assert(#lines == 2 and lines[2] == "Asteroid deaths this interval: 2")
    e.LOG_EntDied(asteroid)
    e.LOG_FlushAsteroidDeaths()
    assert(#lines == 3 and lines[3] == "Asteroid deaths this interval: 1")
end)

test("flips and rotations both produce activity records", function()
    local e = environment()
    e.load("log")
    local p = e.player("builder")
    local lines = {}
    e.UTIL_ConsolePrint = function(msg) lines[#lines+1] = msg end
    local entity = {name="splitter", gps_tag="[gps=1,2]"}
    e.LOG_Rotated({player_index=p.index, entity=entity, horizontal=false})
    e.LOG_Rotated({player_index=p.index, entity=entity, horizontal=true})
    e.LOG_Rotated({player_index=p.index, entity=entity, previous_direction=0})
    assert(#lines==3 and lines[1]:find(" flipped ") and lines[2]:find(" flipped ") and lines[3]:find(" rotated "))
end)

test("ban recovery announcements reflect the inventory transfer outcome", function()
    local e = environment()
    e.load("log")
    local p = e.player("banned")
    local messages = {}
    e.UTIL_MsgAllSys = function(msg) messages[#messages+1] = msg end
    e.UTIL_DumpInv = function() return false end
    e.LOG_Banned({player_index=p.index})
    assert(#messages==0)
    e.UTIL_DumpInv = function() return true end
    e.storage.PData[p.index].cleaned = false
    e.LOG_Banned({player_index=p.index})
    assert(#messages==1 and messages[1]:find("Remaining items"))
    e.storage.PData[p.index].cleaned = true
    e.LOG_Banned({player_index=p.index})
    assert(#messages==2 and messages[2]:find("so they can be recovered"))
end)

local function quickbar_gui_element(parent, spec)
    local node = {valid = true, parent = parent, name = spec.name, style = {}, text = spec.text, caption = spec.caption, enabled = true}
    node.add = function(child)
        local added = quickbar_gui_element(node, child)
        if child.name then node[child.name] = added end
        return added
    end
    node.destroy = function() node.valid = false; parent[node.name] = nil end
    node.focus, node.select_all, node.force_auto_center = noop, noop, noop
    return node
end

local function click_quickbar(e, p, button)
    e.QUICKBAR_Clicks{element = button, player_index = p.index}
end

local function overwrite_button(player, confirm)
    local actions = assert(player.gui.screen.qb_overwrite).actions
    return confirm and actions.qb_confirm_overwrite or actions.qb_keep_toolbar
end

test("V1 and V2 imports and the published V3 vector use the same quickbar paths", function()
    local e = chatwire_env()
    e.load("quickbar")
    local p = e.player("Alice")
    p.gui = {screen = quickbar_gui_element(nil, {})}
    local bar = {}
    p.set_quick_bar_slot = function(i, filter) bar[i] = filter end
    p.get_quick_bar_slot = function(i) return bar[i] end
    e.helpers.encode_string = function(value) return value end
    e.prototypes.item = {["transport-belt"] = true, inserter = true}
    e.prototypes.quality = {normal = true, legendary = true}
    e.UTIL_SmartPrint = noop

    assert(e.ImportQuickbar(p, "M45-QB1=transport-belt,,inserter"))
    assert(bar[1] == "transport-belt" and not bar[2] and bar[3] == "inserter")
    assert(not e.ImportQuickbar(p, "M45-QB2=MB,FN:l,"))
    assert(bar[3] == "inserter")
    click_quickbar(e, p, overwrite_button(p, false))
    assert(not p.gui.screen.qb_overwrite and bar[3] == "inserter")
    assert(not e.ImportQuickbar(p, "M45-QB2=MB,FN:l,"))
    click_quickbar(e, p, overwrite_button(p, true))
    assert(e.ExportQuickbar(p) == "Q3:BA0VrE" and not bar[3])
    bar = {}
    assert(e.ImportQuickbar(p, "Q3:BA0VrE"))
    assert(bar[1] == "transport-belt" and bar[2].name == "inserter" and bar[2].quality == "legendary")
    for _, bad in ipairs({"Q3:", "Q3:BA0Vr", "Q3:BA0VrEA", "Q3:!!", "Q3:AB", "Q3:_A"}) do
        assert(not e.ImportQuickbar(p, bad))
        assert(e.ExportQuickbar(p) == "Q3:BA0VrE")
    end
    assert(not e.ImportQuickbar(p, "Q3:AA") and bar[1])
    click_quickbar(e, p, overwrite_button(p, true))
    assert(next(bar) == nil)
end)

test("V3 compact modes preserve repeated items, strided slots and sparse quality exceptions", function()
    local e = chatwire_env()
    local codec = e.require("quickbar_v3")
    local catalog = e.require("quickbar_v3_items")
    local function check(slots, expected)
        assert(codec.encode(slots) == expected)
        local decoded = assert(codec.decode(expected))
        for i = 1, 100 do
            if slots[i] then
                assert(decoded[i].name == slots[i].name and decoded[i].quality == slots[i].quality)
            else
                assert(not decoded[i])
            end
        end
    end
    local repeated, strided, distinct, mixed = {}, {}, {}, {}
    local qualities = {"normal", "uncommon", "rare", "epic", "legendary", "quality-unknown"}
    for i = 0, 99 do
        repeated[i + 1] = {name = "transport-belt", quality = "epic"}
        if i % 10 == 2 then strided[i + 1] = {name = "rail", quality = "normal"} end
        distinct[i + 1] = {name = catalog[i + 1], quality = i == 17 and "rare" or "normal"}
        if (i * 37 % 101) % 3 == 0 then
            mixed[i + 1] = {name = catalog[i + 1], quality = qualities[i % 6 + 1]}
        end
    end
    check(repeated, "Q3:yCBOVg")
    check(strided, "Q3:FIJKA6Q")
    check(distinct, "Q3:yB" .. string.rep("A", 138) .. "w7JQ")
    check(mixed, "Q3:RZi_L8vy_L8vxeLxfgAgACVKSwQgKu4Bng0T3vs2hF7PhDTRVNcVWaBtsBKncxnWudrhsTXuo62tN1Izd-g")
end)

test("V3 preserves modded items and qualities, sparse and limited exports, and V2 name collisions", function()
    local e = chatwire_env()
    e.load("quickbar")
    local p = e.player("Alice")
    p.gui = {screen = quickbar_gui_element(nil, {})}
    local bar = {[100] = {name = "example-belt", quality = "example-quality"}}
    p.set_quick_bar_slot = function(i, filter) bar[i] = filter end
    p.get_quick_bar_slot = function(i) return bar[i] end
    e.helpers.encode_string = function(value) return value end
    local notice
    e.UTIL_SmartPrint = function(_, text) notice = text end
    local export = "Q3:A8AnBYyvDC2uDYylrEytjoF7K8MLa4NjKWuLqwtjS6PJVmg"
    assert(e.ExportQuickbar(p) == export and e.ExportQuickbar(p, true) == "Q3:AA")
    e.prototypes.item = {["example-belt"] = true, AA = true}
    e.prototypes.quality = {normal = true, ["example-quality"] = true, r = true}
    bar = {}
    assert(e.ImportQuickbar(p, export))
    assert(bar[100].name == "example-belt" and bar[100].quality == "example-quality")
    e.prototypes.quality["example-quality"] = nil
    assert(not e.ImportQuickbar(p, export) and bar[100])
    click_quickbar(e, p, overwrite_button(p, true))
    assert(not bar[100] and notice:find("example%-belt:example%-quality"))
    e.helpers.encode_string = function() return "short" end
    bar[50] = {name = "AA", quality = "r"}
    local escaped = e.ExportQuickbar(p)
    bar = {}
    assert(escaped:sub(1,3) == "Q3:" and e.ImportQuickbar(p, escaped))
    assert(bar[50].name == "AA" and bar[50].quality == "r")
    bar[50] = "transport-belt"
    assert(e.ExportQuickbar(p) == "short")
end)

test("Default is requested once for a new player and never overwrites an existing map player on join", function()
    local e = chatwire_env()
    e.load("quickbar")
    local p = e.player("Alice")
    p.gui = {screen = {}}
    e.prototypes.item = {["iron-plate"] = true}
    e.prototypes.quality = {normal = true}
    local slots = {}
    p.get_quick_bar_slot = function(i) return slots[i] end
    p.set_quick_bar_slot = function(i, filter) slots[i] = filter end
    local request
    e.CW_EmitEvent = function(_, data) request = data end
    e.storage.SM_Store.quickbar_presets = true
    local pdata = e.storage.PData[p.index]
    e.QUICKBAR_CheckAccess(p)
    assert(not request.first_join)
    pdata.qb_first_join = true
    e.QUICKBAR_CheckAccess(p)
    assert(request.first_join)
    local result = {id = request.id, name = "Alice", allowed = true, labels = {}, exchange = "M45-QB2=iron-plate,"}
    assert(e.request_command("quickbar-result", result).ok)
    assert(slots[1] == "iron-plate" and not pdata.qb_first_join)
    slots[1] = "copper-plate"
    assert(e.request_command("quickbar-result", result).ok and slots[1] == "copper-plate")
    e.QUICKBAR_CheckAccess(p)
    assert(not request.first_join)
    result.id = request.id
    assert(e.request_command("quickbar-result", result).ok and slots[1] == "copper-plate")
end)

test("incompatible Default and denied or stale replies preserve current quickbar", function()
    local e = chatwire_env()
    e.load("quickbar")
    local p = e.player("Alice")
    p.gui = {screen = {}}
    p.get_quick_bar_slot = function() return nil end
    p.set_quick_bar_slot = function() error("unexpected quickbar modification") end
    e.prototypes.item, e.prototypes.quality = {}, {normal = true}
    e.storage.SM_Store.quickbar_presets = true
    local pdata = e.storage.PData[p.index]
    pdata.qb_first_join = true
    e.QUICKBAR_CheckAccess(p)
    local id = pdata.qb_pending.id
    local result = {id = id, name = "Alice", allowed = true, exchange = "M45-QB2=unavailable,"}
    assert(e.request_command("quickbar-result", result).ok and not pdata.qb_first_join)
    pdata.qb_first_join = true
    e.QUICKBAR_CheckAccess(p)
    assert(e.request_command("quickbar-result", result).ok and pdata.qb_first_join)
    result.id, result.allowed = pdata.qb_pending.id, false
    assert(e.request_command("quickbar-result", result).ok and not pdata.qb_allowed)
end)

test("first-join Default preserves shortcuts added while the access request was in flight", function()
    local e = chatwire_env()
    e.load("quickbar")
    local p = e.player("Alice")
    p.gui = {screen = {}}
    local bar = {}
    p.get_quick_bar_slot = function(i) return bar[i] end
    p.set_quick_bar_slot = function() error("overwrote a first-join toolbar") end
    e.storage.SM_Store.quickbar_presets = true
    local pdata = e.storage.PData[p.index]
    pdata.qb_first_join = true
    e.QUICKBAR_CheckAccess(p)
    bar[100] = "rail"
    local notice
    e.UTIL_SmartPrint = function(_, text) notice = text end
    e.QUICKBAR_Result{name = p.name, id = pdata.qb_pending.id, allowed = true, exchange = "Q3:BA0VrE"}
    assert(not pdata.qb_first_join and notice:find("load it manually", 1, true) and bar[100] == "rail")
end)

test("global loads check only writable positions and Clear requires its own confirmation", function()
    local e = chatwire_env()
    e.load("quickbar")
    local p = e.player("Alice")
    local screen = quickbar_gui_element(nil, {})
    p.gui = {screen = screen}
    local section = screen.add{name = "quickbar_manager"}.add{name = "qb_preset_section"}
    local row = section.add{name = "qb_public"}
    row.add{name = "choice"}.selected_index = 1
    row.add{name = "qb_public_load"}
    row.add{name = "qb_clear_toolbar"}
    e.prototypes.item = {["transport-belt"] = true}
    local bar = {[2] = "personal", [98] = "rail"}
    p.get_quick_bar_slot = function(i) return bar[i] end
    p.set_quick_bar_slot = function(i, value) bar[i] = value end
    click_quickbar(e, p, row.qb_public_load)
    assert(bar[1] == "transport-belt" and bar[2] == "personal" and not screen.qb_overwrite)
    bar[1] = "inserter"
    click_quickbar(e, p, row.qb_public_load)
    assert(screen.qb_overwrite and bar[1] == "inserter")
    click_quickbar(e, p, overwrite_button(p, true))
    assert(bar[1] == "transport-belt" and bar[98] == "rail")
    click_quickbar(e, p, row.qb_clear_toolbar)
    click_quickbar(e, p, overwrite_button(p, false))
    assert(bar[98] == "rail")
    click_quickbar(e, p, row.qb_clear_toolbar)
    click_quickbar(e, p, overwrite_button(p, true))
    assert(next(bar) == nil)
    click_quickbar(e, p, row.qb_clear_toolbar)
    assert(not screen.qb_overwrite)
end)

test("personal overwrite confirmation checks the current grant and exact saved layout", function()
    local e = chatwire_env()
    e.load("quickbar")
    local p = e.player("Alice")
    local screen = quickbar_gui_element(nil, {})
    p.gui = {screen = screen}
    local section = screen.add{name = "quickbar_manager"}.add{name = "qb_preset_section"}
    section.add{name = "access_note"}
    local row = section.add{name = "qb_presets"}
    for _, name in ipairs({"slot", "load", "store", "qb_rename"}) do row.add{name = name} end
    row.slot.selected_index = 2
    local bar = {[100] = "rail"}
    p.get_quick_bar_slot = function(i) return bar[i] end
    p.set_quick_bar_slot = function(i, value) bar[i] = value end
    e.storage.SM_Store.quickbar_presets = true
    local pdata = e.storage.PData[p.index]
    pdata.qb_allowed = true
    e.prototypes.item = {rail = true}
    local function reply(allowed, layout)
        e.QUICKBAR_Result{name = p.name, id = pdata.qb_pending.id, allowed = allowed,
            labels = {"", ""}, exchange = layout}
    end
    local partial = "M45-QB2=rail,,missing,"
    click_quickbar(e, p, row.load)
    reply(true, partial)
    assert(screen.qb_overwrite.actions.qb_confirm_overwrite.caption == "Load compatible slots")
    click_quickbar(e, p, overwrite_button(p, true))
    reply(true, "Q3:AA") -- A different saved layout requires fresh confirmation.
    assert(screen.qb_overwrite and bar[100])
    click_quickbar(e, p, overwrite_button(p, true))
    reply(false, nil)
    assert(not screen.qb_overwrite and bar[100])
    pdata.qb_allowed, row.slot.selected_index = true, 2
    click_quickbar(e, p, row.load)
    reply(true, partial)
    click_quickbar(e, p, overwrite_button(p, true))
    reply(true, partial)
    assert(not screen.qb_overwrite and bar[1] == "rail" and not bar[100])
end)

test("personal preset selector uses the granted slot count and clamps selection after downgrade", function()
    local e = chatwire_env()
    e.load("quickbar")
    local player = e.player("Alice")
    local row = {slot = {selected_index = 3}, load = {}, store = {}, qb_rename = {}}
    player.gui = {screen = {quickbar_manager = {qb_preset_section = {qb_presets = row, access_note = {}}}}}
    e.storage.SM_Store.quickbar_presets = true
    local pdata = e.storage.PData[player.index]
    local function grant(labels)
        pdata.qb_pending = {id = 1, action = "access"}
        e.QUICKBAR_Result({name = "Alice", id = 1, allowed = true, labels = labels})
    end
    grant({"", "", "", "", "", "", "", "", "", "Oil"})
    assert(#row.slot.items == 10 and row.slot.items[10] == "10. Oil")
    assert(row.slot.items[1] == "Default" and row.slot.selected_index == 3 and row.qb_rename.enabled)
    row.slot.selected_index = 1
    grant({"Old default name", "", ""})
    assert(row.slot.items[1] == "Default" and not row.qb_rename.enabled)
    row.slot.selected_index = 10
    grant({"", "", "Rails", "", "Oil"})
    assert(#row.slot.items == 5 and row.slot.selected_index == 5 and row.slot.items[5] == "5. Oil")
    grant({"", "", "", "Rails"})
    assert(#row.slot.items == 4 and row.slot.selected_index == 4 and row.slot.items[4] == "4. Rails")
    grant({"", "Rails"})
    assert(#row.slot.items == 2 and row.slot.selected_index == 2 and row.slot.items[2] == "2. Rails")
    local labels = {}
    for i = 1, 16 do labels[i] = "" end
    labels[16] = "Space"
    grant(labels)
    assert(#row.slot.items == 16 and row.slot.items[16] == "16. Space")
    grant({"", "", "", "", "", "", "", "Oil"})
    assert(#row.slot.items == 8 and row.slot.items[8] == "8. Oil")
    grant({"", "[img=utility/close]", "[Rail]", "Café 火箭 👨‍👩‍👧"})
    assert(row.slot.items[2] == "Preset 2" and row.slot.items[3] == "3. [Rail]")
    assert(row.slot.items[4] == "4. Café 火箭 👨‍👩‍👧")
end)

test("renaming a personal preset opens an editor and only Save submits the selected slot", function()
    local e = chatwire_env()
    e.load("quickbar")
    local player = e.player("Alice")
    local screen = quickbar_gui_element(nil, {})
    player.gui = {screen = screen}
    local manager = screen.add{name = "quickbar_manager"}
    local section = manager.add{name = "qb_preset_section"}
    section.add{name = "access_note"}
    local row = section.add{name = "qb_presets"}
    for _, name in ipairs({"slot", "load", "store", "qb_rename"}) do row.add{name = name} end
    local pdata = e.storage.PData[player.index]
    pdata.qb_labels, pdata.qb_allowed = {"", "Rails", ""}, true
    e.storage.SM_Store.quickbar_presets = true
    local sent
    e.CW_EmitEvent = function(_, data) sent = data end
    local function click(button) e.QUICKBAR_Clicks{element = button, player_index = player.index} end
    row.slot.selected_index = 1
    click(row.qb_rename)
    assert(not screen.qb_rename_dialog)
    row.slot.selected_index = 2
    click(row.qb_rename)
    local dialog = screen.qb_rename_dialog
    assert(dialog.slot_name.text == "Rails" and not manager.visible)
    dialog.slot_name.text = "Discarded"
    click(dialog.actions.qb_rename_cancel)
    assert(not sent and manager.visible and not screen.qb_rename_dialog)
    click(row.qb_rename)
    dialog = screen.qb_rename_dialog
    assert(dialog.slot_name.text == "Rails")
    for _, label in ipairs({"[img=utility/close]", "[font=x]x[/font]", "[.color]", "[img=unfinished"}) do
        dialog.slot_name.text = label
        click(dialog.actions.qb_rename_save)
        assert(not sent and not pdata.qb_pending and dialog.actions.qb_rename_save.enabled)
    end
    dialog.slot_name.text = "Oil"
    click(dialog.actions.qb_rename_save)
    assert(sent.action == "rename" and sent.slot == 2 and sent.label == "Oil" and not sent.exchange)
    e.QUICKBAR_Result{name = player.name, id = sent.id, allowed = true, error = "Try again"}
    assert(dialog.valid and dialog.slot_name.text == "Oil" and dialog.actions.qb_rename_save.enabled)
    local previous_id = sent.id
    click(dialog.actions.qb_rename_save)
    assert(sent.id == previous_id and dialog.actions.qb_rename_save.enabled and not pdata.qb_pending)
    e.game.tick = e.game.tick + 60
    click(dialog.actions.qb_rename_save)
    assert(sent.id ~= previous_id and not dialog.actions.qb_rename_save.enabled)
    e.QUICKBAR_Result{name = player.name, id = sent.id, allowed = true, labels = {"", "Oil", ""}}
    assert(manager.visible and not screen.qb_rename_dialog and row.slot.items[2] == "2. Oil")
end)

test("quickbar Store blocks per-frame clicks before encoding and sending for one second", function()
    local e = chatwire_env()
    e.load("quickbar")
    e.storage.SM_Store.quickbar_presets = true
    local sent, encoded, notices = 0, 0, 0
    e.CW_EmitEvent = function() sent = sent + 1 end
    e.helpers.encode_string = function(value) encoded = encoded + 1; return value end
    e.UTIL_SmartPrint = function() notices = notices + 1 end
    local function setup(name)
        local player = e.player(name)
        player.get_quick_bar_slot = function() return nil end
        local row = {slot = {selected_index = 1}}
        row.store = {valid = true, name = "store", parent = row}
        row.load = {valid = true, name = "load", parent = row}
        player.gui = {screen = {quickbar_manager = {qb_preset_section = {qb_presets = row}}}}
        e.storage.PData[player.index].qb_allowed = true
        return function(button) e.QUICKBAR_Clicks{element = row[button], player_index = player.index} end
    end
    local click = setup("Alice")
    e.game.tick = 100
    click("store")
    local pending_id = e.storage.PData[1].qb_pending.id
    for tick = 101, 159 do
        e.game.tick = tick
        click("store")
    end
    assert(sent == 1 and encoded == 1 and notices == 1)
    assert(e.storage.PData[1].qb_pending.id == pending_id)
    -- Cooldowns are local to each player; loading is unrestricted.
    local other_click = setup("Bob")
    other_click("store")
    click("load")
    assert(sent == 3 and encoded == 2)
    e.game.tick = 160
    click("store")
    assert(sent == 4 and encoded == 3)
end)

test("Store skips unchanged confirmed and pending saves but retries failures and refreshed slots", function()
    local e = chatwire_env()
    e.load("quickbar")
    e.storage.SM_Store.quickbar_presets = true
    local player = e.player("Alice")
    local item = "iron-plate"
    player.get_quick_bar_slot = function(index) if index == 1 then return item end end
    e.helpers.encode_string = function(value) return value end
    local row = {slot = {selected_index = 1}, qb_rename = {}}
    row.store = {valid = true, name = "store", parent = row}
    row.load = {valid = true, name = "load", parent = row}
    player.gui = {screen = {quickbar_manager = {qb_preset_section = {qb_presets = row, access_note = {}}}}}
    local pdata = e.storage.PData[player.index]
    pdata.qb_allowed = true
    local sent, request = 0
    e.CW_EmitEvent = function(_, data) sent = sent + 1; request = data end
    local function click(button)
        e.game.tick = e.game.tick + 60
        e.QUICKBAR_Clicks{element = row[button], player_index = player.index}
    end
    local function reply(error)
        e.QUICKBAR_Result{name = player.name, id = request.id, allowed = true,
            labels = {"", "", "", ""}, error = error}
    end
    click("store")
    assert(sent == 1)
    local first_id = request.id
    e.QUICKBAR_Result{name = player.name, id = first_id, allowed = true, pending = true}
    assert(pdata.qb_pending.id == first_id and pdata.qb_pending.saving_notified)
    click("store") -- identical request still in flight
    assert(sent == 1 and pdata.qb_pending.id == first_id)
    reply()
    click("store") -- confirmed identical save
    assert(sent == 1 and not pdata.qb_pending)
    item = "copper-plate"
    click("store")
    assert(sent == 2)
    reply("Save failed")
    click("store") -- failures never become confirmed snapshots
    assert(sent == 3)
    reply()
    click("store")
    assert(sent == 3)
    row.slot.selected_index = 2
    click("store") -- identical toolbar, different destination
    assert(sent == 4 and request.slot == 2)
    reply()
    click("store")
    assert(sent == 4)
    e.QUICKBAR_CheckAccess(player) -- opening/refreshing the manager invalidates snapshots
    assert(sent == 5)
    reply()
    click("store")
    assert(sent == 6)
    reply()
    click("load") -- a slot may have changed on another map
    assert(sent == 7)
    reply()
    click("store")
    assert(sent == 8)
    reply()
    item = "iron-plate"
    click("store")
    assert(sent == 9)
    local stale_id = request.id
    item = "copper-plate" -- return to the old saved toolbar while a different write is pending
    click("store")
    assert(sent == 10 and request.id ~= stale_id)
    e.QUICKBAR_Result{name = player.name, id = stale_id, allowed = true, labels = {"", "", "", ""}}
    assert(pdata.qb_pending.id == request.id)
end)

test("players cannot submit system ChatWire commands or forge preset replies", function()
    local e = chatwire_env()
    local player = e.player("Alice")
    local message
    e.UTIL_SmartPrint = function(p, text) assert(p == player); message = text end
    e.helpers.decode_string = function() error("player input reached system-command decoder") end
    e.registered.chatwire{player_index = player.index, parameter = "forged-preset-reply"}
    assert(message == "That command is for system use only.")
    assert(not e.response)
end)

test("queued cleanup skips removed objects and protects neighboring buildings", function()
    local e = environment()
    local dispatch
    e.defines.events = enums()
    e.script = {on_nth_tick = noop, on_event = function(_, callback) dispatch = callback end}
    e.load("event")
    local deleted, message = {}, nil
    local force = {valid = true, name = "team", is_chunk_charted = function() return false end}
    local surface = {valid = true, name = "nauvis"}
    surface.get_chunks = function()
        local chunks = {{x = 0, y = 0}, {x = 10, y = 0}}
        local i = 0
        return function() i = i + 1; return chunks[i] end
    end
    surface.count_entities_filtered = function(filter)
        assert(filter.limit == 1 and filter.force[1] == "player" and filter.force[2] == "team")
        -- A building in the southeast neighboring chunk.
        local area = filter.area
        return area.left_top.x <= 40 and area.left_top.y <= 40
            and area.right_bottom.x > 40 and area.right_bottom.y > 40 and 1 or 0
    end
    surface.delete_chunk = function(chunk) deleted[#deleted + 1] = chunk.x end
    e.UTIL_MsgAll = function(text) message = text end
    local queue = {
        {delay = 0, surface = {valid = false}, force = force},
        {delay = 0, surface = surface, force = {valid = false}},
        {delay = 0, surface = surface, force = force, victim = {valid = false}},
    }
    e.storage.SM_Store.purge_tasks = queue
    for i = 1, 3 do dispatch{name = e.defines.events.on_tick} end
    assert(#queue == 0 and #deleted == 1 and deleted[1] == 10)
    assert(message:match("^System deleted 1 "))
end)

test("one-life spectators can click other controls without a death notice", function()
    local e = environment()
    local player = e.player("Spectator")
    player.character = nil
    e.storage.SM_Store.oneLifeMode = true
    e.load("onelife")
    local message
    e.UTIL_SmartPrint = function(_, text) message = text end
    local event = {player_index = player.index, element = {valid = true, name = "m45_button"}}
    e.ONELIFE_Clicks(event)
    assert(message == nil)
    event.element.name = "spec_button"
    e.ONELIFE_Clicks(event)
    assert(message == "You are already dead!")
end)

print(string.format("%d passed; %d failed", passed, failed))
if failed > 0 then os.exit(1) end
