-- Machine-only protocol between ChatWire and the SoftMod.
-- JSON is deflated/base64 encoded on the wire; every reply/event uses the
-- single [CHATWIRE] tag so ChatWire only needs one parser.

local PROTOCOL_VERSION = 1
local pending_admin_changes = {}

function CW_ConsumeAdminChange(player_index)
    if pending_admin_changes[player_index] then
        pending_admin_changes[player_index] = nil
        return true
    end
    return false
end

function CW_Emit(kind, fields)
    local envelope = fields or {}
    envelope.v = PROTOCOL_VERSION
    envelope.kind = kind
    local encoded = helpers.encode_string(helpers.table_to_json(envelope))
    if encoded then
        print("[CHATWIRE] " .. encoded)
    end
end

function CW_EmitEvent(event_name, data)
    CW_Emit("event", { event = event_name, data = data or {} })
end

function CW_EmitText(event_name, text)
    CW_EmitEvent(event_name, { text = text or "" })
end

local function response(request, ok, data, error_message)
    local envelope = {
        id = request and request.id or nil,
        command = request and request.command or nil,
        ok = ok,
        data = data or {},
    }
    if error_message then
        envelope.error = error_message
    end
    CW_Emit("response", envelope)
end

local function bool_field(data, name)
    return data[name] == nil or type(data[name]) == "boolean"
end

local function string_field(data, name)
    return data[name] == nil or type(data[name]) == "string"
end

local function number_field(data, name)
    return data[name] == nil or type(data[name]) == "number"
end

local function string_array_field(data, name)
    if data[name] == nil then
        return true
    end
    if type(data[name]) ~= "table" then
        return false
    end
    for _, value in pairs(data[name]) do
        if type(value) ~= "string" then
            return false
        end
    end
    return true
end

local function refresh_reset_display()
    for _, player in pairs(game.connected_players) do
        if player.gui and player.gui.screen and player.gui.screen.m45_info_window then
            INFO_InfoWin(player)
        end
        UTIL_DrawMapClock(player)
    end
end

local function apply_config(data)
    if not string_field(data, "server_name") or
        not bool_field(data, "restrict") or
        not bool_field(data, "friendly_fire") or
        not bool_field(data, "one_life") or
        not string_field(data, "reset_duration") or
        not string_field(data, "reset_date") or
        not bool_field(data, "blueprints") or
        not bool_field(data, "cheats") or
        not string_array_field(data, "supporters") or
        not string_array_field(data, "nitro") or
        not number_field(data, "speed") then
        return false, "invalid config field type"
    end
    if data.speed and (data.speed < 0.1 or data.speed > 100.0) then
        return false, "speed must be between 0.1 and 100"
    end

    STORAGE_EnsureGlobal()
    PERMS_EnsureGroups()

    if data.server_name ~= nil and storage.SM_Store.serverName ~= data.server_name then
        storage.SM_Store.serverName = data.server_name
        LOGO_DrawLogo(true)
    end
    if data.restrict ~= nil and storage.SM_Store.restrictNew ~= data.restrict then
        storage.SM_Store.restrictNew = data.restrict
        PERMS_SetPermissions()
    end
    if data.friendly_fire ~= nil then
        game.forces["player"].friendly_fire = data.friendly_fire
    end
    if data.one_life ~= nil and storage.SM_Store.oneLifeMode ~= data.one_life then
        storage.SM_Store.oneLifeMode = data.one_life
        for _, player in ipairs(game.connected_players) do
            ONELIFE_MakeButton(player)
        end
    end
    local reset_changed = false
    if data.reset_duration ~= nil and storage.SM_Store.resetDuration ~= data.reset_duration then
        storage.SM_Store.resetDuration = data.reset_duration
        reset_changed = true
    end
    if data.reset_date ~= nil and storage.SM_Store.resetDate ~= data.reset_date then
        storage.SM_Store.resetDate = data.reset_date
        reset_changed = true
    end
    if reset_changed then
        refresh_reset_display()
    end
    if data.blueprints ~= nil and storage.SM_Store.noBlueprints == data.blueprints then
        storage.SM_Store.noBlueprints = not data.blueprints
        PERMS_SetBlueprintsAllowed(storage.SM_Store.defGroup, data.blueprints)
        PERMS_SetBlueprintsAllowed(storage.SM_Store.memGroup, data.blueprints)
        PERMS_SetBlueprintsAllowed(storage.SM_Store.regGroup, data.blueprints)
        PERMS_SetBlueprintsAllowed(storage.SM_Store.vetGroup, data.blueprints)
        PERMS_SetBlueprintsAllowed(storage.SM_Store.modGroup, data.blueprints)
    end
    if data.cheats ~= nil then
        local cheats_changed = storage.SM_Store.cheats ~= data.cheats
        storage.SM_Store.cheats = data.cheats
        for _, player in ipairs(game.connected_players) do
            player.cheat_mode = data.cheats
        end
        if data.cheats and cheats_changed then
            game.forces["player"].research_all_technologies()
        end
    end
    if data.supporters ~= nil then
        storage.SM_Store.patreonCredits = data.supporters
    end
    if data.nitro ~= nil then
        storage.SM_Store.nitroCredits = data.nitro
    end
    if data.speed ~= nil then
        game.speed = data.speed
        game.forces["player"].character_running_speed_modifier = (1.0 / data.speed) - 1.0
    end
    return true
end

function CW_OnlineSnapshot()
    local players = {}
    if storage.SM_Store.playerList then
        for _, target in ipairs(storage.SM_Store.playerList) do
            if target and target.victim and target.victim.connected then
                table.insert(players, {
                    name = target.victim.name,
                    score_ticks = target.score or 0,
                    time_ticks = target.time or 0,
                    type = target.type or "none",
                    afk = target.afk or "",
                })
            end
        end
    end
    return { count = #players, players = players }
end

function CW_EmitOnline()
    CW_EmitEvent("online", CW_OnlineSnapshot())
end

local function set_player_level(data)
    if type(data.name) ~= "string" or data.name == "" or type(data.level) ~= "number" then
        return false, "name and numeric level are required"
    end
    local player = game.players[data.name]
    if not (player and player.connected) then
        return false, "player is not online"
    end
    if data.level < 255 and player.admin then
        pending_admin_changes[player.index] = true
        player.admin = false
    end
    if data.level == 0 then
        PERMS_MakeNew(nil, player)
    elseif data.level == 1 then
        PERMS_MakeMember(nil, player)
    elseif data.level == 2 then
        PERMS_MakeRegular(nil, player)
    elseif data.level == 3 then
        PERMS_MakeVeteran(nil, player)
    elseif data.level == 255 then
        if not player.admin then
            pending_admin_changes[player.index] = true
            player.admin = true
        end
        if storage.SM_Store.modGroup then
            storage.SM_Store.modGroup.add_player(player)
        end
        CW_EmitEvent("player-level", { name = player.name, level = 255 })
        ONLINE_MarkDirty()
    else
        return false, "unsupported player level"
    end
    return true
end

local function set_supporter(data)
    if type(data.name) ~= "string" then
        return false, "name is required"
    end
    if (data.patreon ~= nil and type(data.patreon) ~= "boolean") or
        (data.nitro ~= nil and type(data.nitro) ~= "boolean") then
        return false, "supporter flags must be boolean"
    end
    local player = game.players[data.name]
    if not (player and player.connected and storage.PData[player.index]) then
        return false, "player is not online"
    end
    if data.patreon ~= nil then
        storage.PData[player.index].patreon = data.patreon == true
        if data.patreon then
            player.tag = "(supporter)"
        end
    end
    if data.nitro ~= nil then
        storage.PData[player.index].nitro = data.nitro == true
    end
    ONLINE_MarkDirty()
    return true
end

local handlers = {
    hello = function()
        RunSetup()
        return true, { softmod_version = storage.SM_Version or SM_VERSION or "?" }
    end,
    status = function()
        return true, {
            tick = game.tick,
            speed = game.speed,
            paused = game.tick_paused,
            connected_players = #game.connected_players,
        }
    end,
    config = function(data)
        local ok, err = apply_config(data)
        return ok, {}, err
    end,
    online = function()
        ONLINE_UpdatePlayerList(false)
        return true, CW_OnlineSnapshot()
    end,
    chat = function(data)
        if type(data.text) ~= "string" then
            return false, {}, "text is required"
        end
        UTIL_MsgPlayers(data.text)
        return true, {}
    end,
    whisper = function(data)
        if type(data.name) ~= "string" or type(data.text) ~= "string" then
            return false, {}, "name and text are required"
        end
        local player = game.players[data.name]
        if not (player and player.connected) then
            return false, {}, "player is not online"
        end
        UTIL_SmartPrint(player, data.text)
        return true, {}
    end,
    ["player-level"] = function(data)
        local ok, err = set_player_level(data)
        return ok, {}, err
    end,
    supporter = function(data)
        local ok, err = set_supporter(data)
        return ok, {}, err
    end,
}

local function handle_chatwire(param)
    if param and param.player_index then
        UTIL_SmartPrint(game.players[param.player_index], "That command is for system use only.")
        return
    end
    if not param or type(param.parameter) ~= "string" or param.parameter == "" then
        response(nil, false, {}, "encoded request required")
        return
    end

    local decoded_ok, decoded = pcall(helpers.decode_string, param.parameter)
    if not decoded_ok or type(decoded) ~= "string" then
        response(nil, false, {}, "invalid encoded request")
        return
    end
    local parsed, request = pcall(helpers.json_to_table, decoded)
    if not parsed or type(request) ~= "table" then
        response(nil, false, {}, "invalid JSON request")
        return
    end
    if request.v ~= PROTOCOL_VERSION then
        response(request, false, {}, "unsupported protocol version")
        return
    end
    if type(request.command) ~= "string" or not handlers[request.command] then
        response(request, false, {}, "unknown command")
        return
    end
    local data = request.data
    if data == nil then
        data = {}
    elseif type(data) ~= "table" then
        response(request, false, {}, "data must be an object")
        return
    end

    local ran, ok, result, err = pcall(handlers[request.command], data)
    if not ran then
        response(request, false, {}, "handler failed: " .. tostring(ok))
        return
    end
    response(request, ok == true, result or {}, err)
end

commands.remove_command("chatwire")
commands.add_command("chatwire", "System use only.", handle_chatwire)
