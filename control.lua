local svers = "v039-1-16-2020"
local is_sandbox = false
local probation_score = 30

local ranonce = false
local boot_time = nil

local handler = require("event_handler")
handler.add_lib(require("freeplay"))
handler.add_lib(require("silo-script"))

local regulars = {
    "Estabon",
    "GregorS",
    "Killy71",
    "Mike-_-",
    "Nasphere",
    "POI_780",
    "brftjx",
    "jslannon",
    "lipinkaixin",
    "mueppel",
    "twist.mills",
    "yanivger",
    "A7fie",
    "Aidenkrz",
    "Andro",
    "ArmadaX",
    "AryanCoconut",
    "Avaren",
    "BlackJaBus",
    "Castleboy2000",
    "Corruptarc",
    "DZCM",
    "D_Riv",
    "Daddyrilla",
    "Darsin",
    "Footy",
    "FuzzyOne",
    "GregorS",
    "Merciless210",
    "Moose1301",
    "Nasphere",
    "Rylabs",
    "SmokuNoPico",
    "SpacecatCybran",
    "StevenMatthews",
    "Trent333",
    "VortexBerserker",
    "adee",
    "bazus1",
    "chrisg23",
    "chubbins",
    "funork",
    "literallyjustanegg",
    "luckcolors",
    "mehdi2344",
    "mojosa",
    "nickoe",
    "skymory_24",
    "twist.mills",
    "ytremors",
    "zendesigner",
    "zlema01"
}

local function uptime()
    local results = "Error"

    if boot_time ~= nil then
        local uphours = (game.tick - boot_time) / 60.0 / 60.0 / 60.0
        results = string.format("uptime: %-4.2fh", uphours)
    end

    return results
end

local function sandbox_mode(player)
    if is_sandbox == true and player ~= nil then
        player.cheat_mode = true
        player.surface.always_day = true
        player.force.laboratory_speed_modifier = 1
        player.zoom = 0.1
        player.force.manual_mining_speed_modifier = 1000
        player.force.manual_crafting_speed_modifier = 1000
        player.force.research_all_technologies()

        for name, recipe in pairs(player.force.recipes) do
            recipe.enabled = true
        end

        --Remove character, for godmode
        if (player.character) then
            local temp = player.character
            player.character = nil
            temp.destroy()
        end
    end
end

local function set_perms()
    --Auto set default group permissions
    if game ~= nil then
        local dperms = game.permissions.get_group("Default")

        if dperms ~= nil then
            dperms.set_allows_action(defines.input_action.activate_cut, false)
            dperms.set_allows_action(defines.input_action.add_train_station, false)
            dperms.set_allows_action(defines.input_action.build_terrain, false)
            dperms.set_allows_action(defines.input_action.change_arithmetic_combinator_parameters, false)
            dperms.set_allows_action(defines.input_action.change_decider_combinator_parameters, false)
            dperms.set_allows_action(defines.input_action.change_programmable_speaker_alert_parameters, false)
            dperms.set_allows_action(defines.input_action.change_programmable_speaker_circuit_parameters, false)
            dperms.set_allows_action(defines.input_action.change_programmable_speaker_parameters, false)
            dperms.set_allows_action(defines.input_action.change_train_stop_station, false)
            dperms.set_allows_action(defines.input_action.change_train_wait_condition, false)
            dperms.set_allows_action(defines.input_action.change_train_wait_condition_data, false)
            dperms.set_allows_action(defines.input_action.connect_rolling_stock, false)
            dperms.set_allows_action(defines.input_action.deconstruct, false)
            dperms.set_allows_action(defines.input_action.delete_blueprint_library, false)
            dperms.set_allows_action(defines.input_action.disconnect_rolling_stock, false)
            dperms.set_allows_action(defines.input_action.drag_train_schedule, false)
            dperms.set_allows_action(defines.input_action.drag_train_wait_condition, false)
            dperms.set_allows_action(defines.input_action.launch_rocket, false)
            dperms.set_allows_action(defines.input_action.remove_cables, false)
            dperms.set_allows_action(defines.input_action.remove_train_station, false)
            dperms.set_allows_action(defines.input_action.set_auto_launch_rocket, false)
            dperms.set_allows_action(defines.input_action.set_circuit_condition, false)
            dperms.set_allows_action(defines.input_action.set_circuit_mode_of_operation, false)
            dperms.set_allows_action(defines.input_action.set_logistic_filter_item, false)
            dperms.set_allows_action(defines.input_action.set_logistic_filter_signal, false)
            dperms.set_allows_action(defines.input_action.set_logistic_trash_filter_item, false)
            dperms.set_allows_action(defines.input_action.set_request_from_buffers, false)
            dperms.set_allows_action(defines.input_action.set_signal, false)
            dperms.set_allows_action(defines.input_action.set_train_stopped, false)
        end
    end
end

local function run_once(player)
    if player ~= nil then
        if game ~= nil then
            local pforce = game.forces["player"]

            if pforce ~= nil then
            --disable tech
            --game.forces["player"].technologies["landfill"].enabled = false
            --game.forces["player"].technologies["solar-energy"].enabled = false
            --game.forces["player"].technologies["logistic-robotics"].enabled = false
            --game.forces["player"].technologies["railway"].enabled = false
            end
        end

        player.force.friendly_fire = false --friendly fire
        player.force.research_queue_enabled = true --nice to have
    end
    set_perms()
end

--Is player in regulars list--
local function is_regular(pname)
    for _, regular in pairs(regulars) do
        if (regular == pname) then
            return true
        end
    end
    return false
end

--Smart Print--
local function smart_print(player, message)
    if player then
        player.print(message)
    else
        rcon.print(message)
    end
end

--Global messages--
local function message_all(message)
    for _, player in pairs(game.connected_players) do
        player.print(message)
    end
    print("[MSG] " .. message)
end

--Sort players--
local function sortTime(a, b)
    if (a == nil or b == nil) then
        return false
    end

    if (a.time == nil or b.time == nil) then
        return false
    end

    if (a.time < b.time) then
        return true
    elseif (a.time > b.time) then
        return false
    else
        return nil
    end
end

--Auto permisisons--
local function get_permgroup()
    global.trustedgroup = game.permissions.get_group("Trusted")
    global.admingroup = game.permissions.get_group("Admin")

    if (global.trustedgroup == nil) then
        game.permissions.create_group("Trusted")
    end

    if (global.admingroup == nil) then
        game.permissions.create_group("Admin")
    end

    global.trustedgroup = game.permissions.get_group("Trusted")
    global.admingroup = game.permissions.get_group("Admin")

    for _, player in pairs(game.connected_players) do
        if (player and player.valid and player.connected) then
            if (player.admin) then
                if (player.permission_group ~= nil) then
                    if (player.permission_group.name ~= "Admin") then
                        global.admingroup.add_player(player)
                        message_all(player.name .. " moved to admins...")
                        player.print("Welcome back, " .. player.name .. "! Moving you to admins group... Have fun!")
                    end
                end

                for _, player in pairs(game.connected_players) do
                    if is_regular(player.name) then
                        if (player.permission_group.name == "Default") then
                            global.trustedgroup.add_player(player)
                            message_all(player.name .. " moved to regulars...")
                            player.print("Welcome back, " .. player.name .. "! Moving you into regulars... Have fun!")
                        end
                    end
                end
            else
                if
                    (global.actual_playtime and global.actual_playtime[player.index] and
                        global.actual_playtime[player.index] > (probation_score * 60 * 60))
                 then
                    if (player.permission_group ~= nil and player.permission_group.name == "Default") then
                        if (global.trustedgroup.add_player(player) == true) then
                            message_all(player.name .. " was moved to trusted users.")
                            player.print(
                                "(SERVER) You have been actively playing long enough, that the restrictions on your character have been lifted. Have fun, and be nice!"
                            )
                            player.print("(SERVER) Discord server: https://discord.gg/Ps2jnm7")
                        end
                    end
                end
            end
        end
    end
end

local function show_player(victim)
    local numpeople = 0

    for _, player in pairs(game.connected_players) do
        if (player and player.valid and player.connected) then
            numpeople = (numpeople + 1)
            local utag = " "

            if (player.admin) then
                utag = " (ADMIN)"
            end

            if (player.permission_group ~= nil) then
                if (player.permission_group.name == "Default") then
                    utag = " (NEW)"
                end
            end
            if (player.permission_group ~= nil) then
                if (player.permission_group.name == "Trusted") then
                    utag = " (MEMBER)"
                end
            end
            if is_regular(player.name) then
                utag = " (REGULARS)"
            end

            if (global.actual_playtime and global.actual_playtime[player.index]) then
                smart_print(
                    victim,
                    string.format(
                        "%-3d: %-18s Active: %-4.2fh, Online: %-4.2fh, %s",
                        numpeople,
                        player.name,
                        (global.actual_playtime[player.index] / 60.0 / 60.0 / 60.0),
                        (player.online_time / 60.0 / 60.0 / 60.0),
                        utag
                    )
                )
            end
        end
    end
    if numpeople == 0 then
        smart_print(victim, "No players online.")
    end
end

--On load, add commands--
script.on_load(
    function()

        boot_time = game.tick --Set boot time here

        --Only add if no commands yet
        if (commands.commands.server_interface == nil) then
            --Status
            commands.add_command(
                "stat",
                "Shows server stats",
                function(param)
                    local victim = nil
                    local is_admin = true

                    if param.player_index then
                        victim = game.players[param.player_index]
                        if victim.admin == false then
                            is_admin = false
                        end
                    end

                    if is_admin then
                        local utime = uptime()
                        if utime ~= nil then
                            local sandstr = "Error"

                            if is_sandbox == true then
                                sandstr = "yes"
                            else
                                sandstr = "no"
                            end

                            local buf = string.format("Sandbox: " .. sandstr .. ", uptime: " .. utime)
                            smart_print(victim, buf)
                        end
                    else
                        smart_print(victim, "Admins only.")
                    end
                end
            )

            --Reveal map
            commands.add_command(
                "reveal",
                "reveal (optional) <x> units of map. Default: 1024, max 4096",
                function(param)
                    local is_admin = true
                    local victim = nil

                    if param.player_index then
                        victim = game.players[param.player_index]
                        if victim.admin == false then
                            is_admin = false
                        end
                    end

                    if (is_admin) then
                        local surface = game.surfaces["nauvis"]
                        local pforce = game.forces["player"]
                        local size = 1024

                        if param.parameter then
                            local rsize = tonumber(param.parameter)

                            --limits
                            if rsize > 0 then
                                if rsize < 128 then
                                    rsize = 128
                                else
                                    if rsize > 4096 then
                                        rsize = 4096
                                    end
                                    size = rsize
                                end
                            end

                            if surface ~= nil and pforce ~= nil then
                                pforce.chart(
                                    surface,
                                    {lefttop = {x = -size, y = -size}, rightbottom = {x = size, y = size}}
                                )
                                local sstr = string.format("%04.0f", size)
                                smart_print(victim, "Revealing " .. sstr .. "x" .. sstr .. " tiles")
                            else
                                smart_print(
                                    victim,
                                    "Either couldn't find surface nauvis, or couldn't find force player."
                                )
                            end
                        end
                    else
                        smart_print(victim, "Admins only.")
                    end
                end
            )

            --Rechart map
            commands.add_command(
                "rechart",
                "rechart: resets fog of war",
                function(param)
                    local is_admin = true
                    local victim = nil

                    if param.player_index then
                        victim = game.players[param.player_index]
                        if victim.admin == false then
                            is_admin = false
                        end
                    end

                    if (is_admin) then
                        local pforce = game.forces["player"]

                        if pforce ~= nil then
                            pforce.clear_chart()
                            smart_print(victim, "Recharting map...")
                        else
                            smart_print(victim, "Couldn't find force: player")
                        end
                    else
                        smart_print(victim, "Admins only.")
                    end
                end
            )

            --Online
            commands.add_command(
                "online",
                "See who is online!",
                function(param)
                    local victim = nil
                    local is_admin = true

                    if param.player_index then
                        victim = game.players[param.player_index]
                        if victim.admin == false then
                            is_admin = false
                        end
                    end

                    if (param.parameter == "active" and is_admin) then
                        if (global.actual_playtime) then
                            local plen = 0
                            local playtime = {}
                            for pos, player in pairs(game.players) do
                                playtime[pos] = {
                                    time = global.actual_playtime[player.index],
                                    name = game.players[player.index].name
                                }
                                plen = plen + 1
                            end

                            table.sort(playtime, sortTime)

                            --Lets limit number of results
                            for ipos, time in pairs(playtime) do
                                if (time ~= nil) then
                                    if (time.time ~= nil) then
                                        if ipos > (plen - 20) then
                                            smart_print(
                                                victim,
                                                string.format(
                                                    "%-4d: %-32s Active: %-4.2fm",
                                                    ipos,
                                                    time.name,
                                                    time.time / 60.0 / 60.0
                                                )
                                            )
                                        end
                                    end
                                end
                            end
                        end
                        return
                    end

                    show_player(victim)
                end
            )

            --Game speed
            commands.add_command(
                "gspeed",
                "change game speed. Default: 1.0, min 0.1, max 10.0",
                function(param)
                    local player = nil
                    local isadmin = true

                    if param.player_index then
                        player = game.players[param.player_index]
                    end

                    if (player ~= nil) then
                        if (player.admin == false) then
                            isadmin = false
                        end
                    end

                    if (isadmin == false) then
                        smart_print(player, "Admins only..")
                        return
                    end

                    if (param.parameter == nil) then
                        smart_print(player, "But what speed? 0.1 to 10")
                        return
                    end

                    local value = tonumber(param.parameter)
                    if (value >= 0.1 and value <= 10.0) then
                        game.speed = value

                        local pforce = game.forces["player"]

                        if pforce ~= nil then
                            game.forces["player"].character_running_speed_modifier = ((1.0 / value) - 1.0)
                            smart_print(
                                player,
                                "Game speed: " ..
                                    value .. " Walk speed: " .. game.forces["player"].character_running_speed_modifier
                            )
                            message_all("Game speed set to %" .. (game.speed * 100.00))
                        else
                            smart_print(player, "Force: Player doesn't seem to exsist.")
                        end
                    else
                        smart_print(player, "That doesn't seem like a good idea...")
                    end
                end
            )

            --Teleport to
            commands.add_command(
                "tto",
                "teleport to <player>",
                function(param)
                    if not param.player_index then
                        return
                    end
                    local player = game.players[param.player_index]

                    if (player and player.valid and player.connected and player.character and player.character.valid) then
                        if (player.admin == false) then
                            player.print("Admins only.")
                            return
                        end

                        if param.parameter then
                            local victim = game.players[param.parameter]

                            if (victim and victim.valid) then
                                player.teleport({victim.position.x + 1.0, victim.position.y + 1.0})
                                player.print("Okay.")
                                return
                            end
                        end
                        player.print("Error...")
                    end
                end
            )

            --Teleport x,y
            commands.add_command(
                "tp",
                "teleport to <x,y>",
                function(param)
                    if not param.player_index then
                        return
                    end
                    local player = game.players[param.player_index]

                    if (player and player.valid and player.connected and player.character and player.character.valid) then
                        if (player.admin == false) then
                            player.print("Admins only.")
                            return
                        end

                        if param.parameter then
                            local str = param.parameter
                            local xpos = "0.0"
                            local ypos = "0.0"

                            xpos, ypos = str:match("([^,]+),([^,]+)")
                            local position = {x = xpos, y = ypos}

                            if position then
                                if position.x and position.y then
                                    player.teleport(position)
                                    player.print("Okay.")
                                else
                                    player.print("invalid x/y.")
                                end
                            end
                            return
                        end
                        player.print("Error...")
                    end
                end
            )

            --Teleport player to me
            commands.add_command(
                "tfrom",
                "teleport <player> to me",
                function(param)
                    if not param.player_index then
                        return
                    end
                    local player = game.players[param.player_index]

                    if (player and player.valid and player.connected and player.character and player.character.valid) then
                        if (player.admin == false) then
                            player.print("Admins only.")
                            return
                        end

                        if param.parameter then
                            local victim = game.players[param.parameter]

                            if (victim and victim.valid) then
                                victim.teleport({player.position.x + 1.0, player.position.y + 1.0})
                                player.print("Okay.")
                                return
                            end
                        end
                        player.print("Error.")
                    end
                end
            )
        end
    end
)

--EVENTS--

--Player created
script.on_event(
    defines.events.on_player_created,
    function(event)
        local player = game.players[event.player_index]

        --Show players online, send help messages
        show_player(player)

        if ranonce == false then
            ranonce = true
            run_once(player)
        end
    end
)

--Player Login
script.on_event(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.players[event.player_index]

        sandbox_mode(player)
    end
)

--Build stuff
script.on_event(
    defines.events.on_built_entity,
    function(event)
        local player = game.players[event.player_index]
        local created_entity = event.created_entity

        if (not global.actual_playtime) then
            global.actual_playtime = {}
            global.actual_playtime[0] = 0
        end

        if (global.actual_playtime and global.actual_playtime[player.index]) then
            global.actual_playtime[player.index] = global.actual_playtime[player.index] + 1
        else
            global.actual_playtime[player.index] = 0.0
        end

        if (not global.last_speaker_warning) then
            global.last_speaker_warning = 0
        end

        if (game.tick - global.last_speaker_warning >= 300) then
            if player and created_entity then
                if is_regular(player.name) == false and player.admin == false then --Dont bother with regulars/admins
                    if created_entity.name == "programmable-speaker" then
                        message_all(
                            player.name ..
                                " placed speaker: " ..
                                    math.floor(created_entity.position.x) ..
                                        "," .. math.floor(created_entity.position.y)
                        )
                        global.last_speaker_warning = game.tick
                    end
                end
            end
        end
    end
)

--Deconstuction planner warning
script.on_event(
    defines.events.on_player_deconstructed_area,
    function(event)
        local player = game.players[event.player_index]
        local area = event.area

        if (not global.last_decon_warning) then
            global.last_decon_warning = 0
        end

        if (game.tick - global.last_decon_warning >= 300) then
            if is_regular(player.name) == false and player.admin == false then --Dont bother with regulars/admins
                message_all(
                    player.name ..
                        " is using the deconstruction planner: " ..
                            math.floor(area.left_top.x) ..
                                "," ..
                                    math.floor(area.left_top.y) ..
                                        " to " ..
                                            math.floor(area.right_bottom.x) .. "," .. math.floor(area.right_bottom.y)
                )
            end
            global.last_decon_warning = game.tick
        end
    end
)

--Mined item
script.on_event(
    defines.events.on_pre_player_mined_item,
    function(event)
        local player = game.players[event.player_index]

        if (not global.actual_playtime) then
            global.actual_playtime = {}
            global.actual_playtime[0] = 0
        end

        if (global.actual_playtime and global.actual_playtime[player.index]) then
            global.actual_playtime[player.index] = global.actual_playtime[player.index] + 1
        else
            global.actual_playtime[player.index] = 0.0
        end
    end
)

--Walking/Driving
script.on_event(
    defines.events.on_player_changed_position,
    function(event)
        local player = game.players[event.player_index]

        if (not global.actual_playtime) then
            global.actual_playtime = {}
            global.actual_playtime[0] = 0
        end

        if (global.actual_playtime and global.actual_playtime[player.index]) then
            --Estimate...
            global.actual_playtime[player.index] = global.actual_playtime[player.index] + (6.67)
        else
            global.actual_playtime[player.index] = 0.0
        end
    end
)

--Corpse Marker
script.on_event(
    defines.events.on_pre_player_died,
    function(event)
        if (not global.corpselist) then
            global.corpselist = {tag = {}, tick = {}}
        end

        local player = game.players[event.player_index]
        local centerPosition = player.position
        local label =
            "Corpse of: " .. player.name .. " " .. math.floor(player.position.x) .. "," .. math.floor(player.position.y)
        local chartTag = {position = centerPosition, icon = nil, text = label}
        local qtag = player.force.add_chart_tag(player.surface, chartTag)

        table.insert(global.corpselist, {tag = qtag, tick = game.tick})
    end
)

--Tick loop--
--Keep to minimum--
script.on_event(
    defines.events.on_tick,
    function(event)
        local toremove
        if (not global.last_s_tick) then
            global.last_s_tick = 0
        end

        if (game.tick - global.last_s_tick >= 600) then
            --Remove old corpse tags
            if (global.corpselist) then
                for _, corpse in pairs(global.corpselist) do
                    if (corpse.tick and (corpse.tick + (15 * 60 * 60)) < game.tick) then
                        if (corpse.tag and corpse.tag.valid) then
                            corpse.tag.destroy()
                        end
                        toremove = corpse
                    end
                end
            end
            if (toremove) then
                toremove.tag = nil
                toremove.tick = nil
                toremove = nil
            end

            if (global.servertag and not global.servertag.valid) then
                global.servertag = nil
            end
            if (global.servertag and global.servertag.valid) then
                global.servertag.destroy()
                global.servertag = nil
            end
            if (not global.servertag) then
                local label = "discord.gg/Ps2jnm7"
                local chartTag = {
                    position = {0, 0},
                    icon = {type = "item", name = "programmable-speaker"},
                    text = label
                }
                global.servertag = game.forces["player"].add_chart_tag(game.surfaces["nauvis"], chartTag)
            end

            get_permgroup()
            global.last_s_tick = game.tick
        end
    end
)
