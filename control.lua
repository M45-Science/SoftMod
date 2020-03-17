--v0459-3-17-2020_1-47-AM--FIX2

local handler = require("event_handler")
handler.add_lib(require("freeplay"))
handler.add_lib(require("silo-script"))

local coal_mode_recipes = {
    "accumulator",
    "beacon",
    "belt-immunity-equipment",
    "defender-capsule",
    "destroyer-capsule",
    "discharge-defense-equipment",
    "discharge-defense-remote",
    "distractor-capsule",
    "effectivity-module",
    "effectivity-module-2",
    "effectivity-module-3",
    "exoskeleton-equipment",
    "flying-robot-frame",
    "fusion-reactor-equipment",
    "laser-turret",
    "night-vision-equipment",
    "personal-laser-defense-equipment",
    "personal-roboport-equipment",
    "personal-roboport-mk2-equipment",
    "poison-capsule",
    "power-armor",
    "power-armor-mk2",
    "processing-unit",
    "railgun",
    "roboport",
    "rocket-control-unit",
    "rocket-silo",
    "satellite",
    "slowdown-capsule",
    "solar-panel",
    "speed-module",
    "speed-module-2",
    "speed-module-3"
}

local coal_mode_techs = {
    "solar-energy",
    "logistic-robotics",
    "robotics",
    "laser",
    "logistic-system"
}

--Legacy--
local regulars = {
    "Azcrew_",
    "Blitztexen",
    "BloodWolfmann",
    "Candorist",
    "Castleboy2000",
    "Dr.Cube",
    "Fighterxx64",
    "Fondofblack",
    "FoxMayham",
    "Fraanek",
    "Hickory",
    "JerAdams",
    "Mazzeneko",
    "Mr.Plips",
    "R2Boyo25",
    "RoninM3",
    "Starrs",
    "SuicideJunkie",
    "VortexBerserker",
    "Zewex",
    "boeljoet",
    "chrisgamer2902",
    "cubun_2009",
    "dr.robuttnik",
    "enderwolfer",
    "iansuarus",
    "johann_loki",
    "komikoze",
    "luigil101",
    "pakjce",
    "sage307",
    "snekcihc",
    "stety",
    "wampastompa09",
    "zazer4",
    "A7fie",
    "Acid_wars",
    "Aidenkrz",
    "Andro",
    "ArmadaX",
    "AryanCoconut",
    "Avaren",
    "Azcrew_",
    "BlackJaBus",
    "Blitztexen",
    "BloodWolfmann",
    "ButterMeister",
    "Castleboy2000",
    "Corruptarc",
    "DIBBG4MER",
    "DZCM",
    "D_Riv",
    "Daddyrilla",
    "Darsin",
    "Decaliss",
    "Dr.Cube",
    "Estabon",
    "Fighterxx64",
    "Flyrockmaster",
    "Fondofblack",
    "Footy",
    "ForsakenWiz",
    "FoxMayham",
    "Fraanek",
    "FuzzyOne",
    "Gatis",
    "GregorS",
    "Huelsensack",
    "Impregneerspuit",
    "ItsAMeeeLuigi",
    "JerAdams",
    "Jeremykyle",
    "Killy71",
    "Mazzeneko",
    "Merciless210",
    "Micahgee",
    "Mike-_-",
    "Mikel3",
    "Moose1301",
    "Nasphere",
    "Odinoki86",
    "PEEK1995",
    "POI_780",
    "Quinlan",
    "R2Boyo25",
    "Ratuz",
    "Robbie06",
    "RoninM3",
    "Rylabs",
    "SmokuNoPico",
    "SpacecatCybran",
    "Starrs",
    "StevenMatthews",
    "That_Dude",
    "The-Player",
    "Thoren",
    "Trent333",
    "U_Wot",
    "VortexBerserker",
    "Zewex",
    "Zory",
    "adamcode",
    "adee",
    "antuan309",
    "bazus1",
    "bobbythebob12",
    "boeljoet",
    "brftjx",
    "chickenspie",
    "chrisg23",
    "chrisgamer2902",
    "chubbins",
    "clonedlemmings",
    "crystalspider37",
    "cubun_2009",
    "dangerarea",
    "dbt0",
    "dooces",
    "enderwolfer",
    "fluckinnuts",
    "fufexan",
    "funork",
    "haja112",
    "iansuarus",
    "jetboy57",
    "john_zivanovik_f",
    "jslannon",
    "julng",
    "komikoze",
    "lipinkaixin",
    "literallyjustanegg",
    "luckcolors",
    "luigil101",
    "magichobo",
    "mehdi2344",
    "mojosa",
    "mpsv7",
    "mraadx",
    "mueppel",
    "nickoe",
    "pakjce",
    "ruetama",
    "sage307",
    "skymory_24",
    "sm2008",
    "sosofly",
    "sukram72",
    "thanhatam7123",
    "twist.mills",
    "wampastompa09",
    "yanivger",
    "ytremors",
    "zendesigner",
    "zlema01"
}

--Flag player as currently active
local function set_active(player)
    if (player ~= nil and player.valid and player.connected and player.character and player.character.valid) then
        if (global.active == nil) then
            global.active = {}
        end

        global.active[player.index] = 1
    end
end

--Create user groups if they don't exsist, and create global links to them
local function create_groups()
    global.defaultgroup = game.permissions.get_group("Default")
    global.trustedgroup = game.permissions.get_group("Trusted")
    global.regulargroup = game.permissions.get_group("Regulars")
    global.admingroup = game.permissions.get_group("Admin")

    if (global.defaultgroup == nil) then
        game.permissions.create_group("Default")
    end

    if (global.trustedgroup == nil) then
        game.permissions.create_group("Trusted")
    end

    if (global.regulargroup == nil) then
        game.permissions.create_group("Regulars")
    end

    if (global.admingroup == nil) then
        game.permissions.create_group("Admin")
    end

    global.defaultgroup = game.permissions.get_group("Default")
    global.trustedgroup = game.permissions.get_group("Trusted")
    global.regulargroup = game.permissions.get_group("Regulars")
    global.admingroup = game.permissions.get_group("Admin")
end

--Split strings
local function mysplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

--Coal mode
local function coal_mode()
    local pforce = game.forces["player"]

    if pforce ~= nil then
        if global.coalmode == true then
            for _, gtech in pairs(pforce.technologies) do
                for _, ctech in pairs(coal_mode_techs) do
                    if gtech.name == ctech then
                        pforce.technologies[ctech].enabled = false
                    end
                end
            end

            for _, recipe in pairs(pforce.recipes) do
                for _, crep in pairs(coal_mode_recipes) do
                    if recipe.name == crep then
                        recipe.enabled = false
                    end
                end
            end
        else
            for _, gtech in pairs(pforce.technologies) do
                gtech.enabled = true
            end

            for _, recipe in pairs(pforce.recipes) do
                recipe.enabled = true
            end
        end
    end
end

--Sandbox mode
local function sandbox_mode(player)
    if global.sandboxmode == true and player ~= nil and player.valid then
        player.cheat_mode = true
        player.surface.always_day = true
        player.force.laboratory_speed_modifier = 1
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

--Disable some permissions for new users
local function set_perms()
    --Auto set default group permissions
    local dperms = game.permissions.get_group("Default")

    if dperms ~= nil then
        dperms.set_allows_action(defines.input_action.wire_dragging, false)
        dperms.set_allows_action(defines.input_action.activate_cut, false)
        dperms.set_allows_action(defines.input_action.add_train_station, false)
        dperms.set_allows_action(defines.input_action.build_terrain, false)
        dperms.set_allows_action(defines.input_action.change_arithmetic_combinator_parameters, false)
        dperms.set_allows_action(defines.input_action.change_decider_combinator_parameters, false)
        dperms.set_allows_action(defines.input_action.switch_constant_combinator_state, false)
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

--Set our default settings
local function game_settings(player)
    if game ~= nil then
        if player ~= nil and player.valid and player.force then
            set_perms()
            player.force.friendly_fire = false --friendly fire
            player.force.research_queue_enabled = true --nice to have
        end
    end
end

--Check if player should be considered a regular
local function is_regular(victim)
    if victim ~= nil and victim.valid then
        --If in hard-coded list (legacy)
        for _, regular in pairs(regulars) do
            if (regular == victim.name) then
                return true
            end
        end

        --If in group
        if victim ~= nil and victim.permission_group ~= nil and global.regulargroup ~= nil then
            if victim.permission_group.name == global.regulargroup.name then
                return true
            end
        end

        --If they have enough hours
        if (global.actual_playtime ~= nil and global.actual_playtime[victim.index] ~= nil and global.actual_playtime[victim.index] > (4 * 60 * 60 * 60)) then
            return true
        end
    end

    return false
end

--Check if player should be considered trusted
local function is_trusted(victim)
    --If in group
    if victim ~= nil and victim.permission_group ~= nil and global.trustedgroup ~= nil then
        if victim.permission_group.name == global.trustedgroup.name then
            return true
        end
    end

    --If they have enough hours
    if (global.actual_playtime ~= nil and global.actual_playtime[victim.index] ~= nil and global.actual_playtime[victim.index] > (30 * 60 * 60)) then
        return true
    end

    return false
end

--cprint--
local function cprint(message)
    print("~" .. message)
end

--Smart cprint--
local function smart_print(player, message)
    if player ~= nil and player.valid then
        player.print(message)
    else
        rcon.print("~" .. message)
    end
end

--Global messages--
local function message_all(message)
    for _, player in pairs(game.connected_players) do
        player.print(message)
    end
    print("[MSG] " .. message)
end

--Global messages (players only)--
local function message_allp(message)
    for _, player in pairs(game.connected_players) do
        player.print(message)
    end
end

--Global messages-- (discord only)
local function message_alld(message)
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
    --Cleaned up 1-2020
    for _, player in pairs(game.connected_players) do
        if (player ~= nil and player.valid) then
            --Handle nil permissions, for mod compatability
            if (player.permission_group ~= nil and global.defaultgroup ~= nil and global.trustedgroup ~= nil and global.regulargroup ~= nil and global.admingroup ~= nil) then
                --Only move from default groups, for mod compatability
                if (player.permission_group.name == global.defaultgroup.name or player.permission_group.name == global.trustedgroup.name or player.permission_group.name == global.regulargroup.name) then
                    if player.permission_group.name == global.defaultgroup.name then
                        if (global.actual_playtime ~= nil and player.index ~= nil and global.actual_playtime[player.index] ~= nil and global.actual_playtime[player.index] > (30 * 60 * 60)) then
                            if (player.permission_group.name ~= global.trustedgroup.name) then
                                global.trustedgroup.add_player(player)
                                message_all(player.name .. " was moved to trusted users.")
                                player.print("[color=0.25,1,1](@ChatWire)[/color] [color=1,0.75,0]You have been actively playing enough, that the restrictions on your character have been lifted.[/color]")
                                player.print("[color=0.25,1,1](@ChatWire)[/color] [color=1,0.75,0]You now have access to our -Discord Members- role![/color]")
                                player.print("[color=0.25,1,1](@ChatWire)[/color] [color=1,0.75,0]Check out our Discord server, the link can be copied from the text in the top-left of your screen (select with mouse, control-c).[/color]")
                            end
                        end
                    elseif player.permission_group.name == global.defaultgroup.name or player.permission_group.name == global.trustedgroup.name then
                        if (global.actual_playtime ~= nil and global.actual_playtime[player.index] ~= nil and global.actual_playtime[player.index] > (4 * 60 * 60 * 60)) then
                            if (player.permission_group.name ~= global.regulargroup.name) then
                                global.regulargroup.add_player(player)
                                message_all(player.name .. " was moved to regulars.")
                                player.print("[color=0.25,1,1](@ChatWire)[/color] [color=1,0.75,0]You have been actively playing enough, that you have been promoted to The Regulars group![/color]")
                                player.print("[color=0.25,1,1](@ChatWire)[/color] [color=1,0.75,0]You now have access to our -Discord Regulars- role, and can get access to regulars-only Factorio servers and channels.[/color]")
                                player.print("[color=0.25,1,1](@ChatWire)[/color] [color=1,0.75,0]Check out our Discord server, the link can be copied from the text in the top-left of your screen (select with mouse, control-c).[/color]")
                            end
                        end
                    end
                end
            end
        end
    end
end

local function show_players(victim)
    local numpeople = 0

    --Cleaned up 1-2020
    for _, player in pairs(game.connected_players) do
        if (player ~= nil and player.valid) then
            numpeople = (numpeople + 1)
            local utag = "(error)"

            if player.permission_group ~= nil then
                local gname = player.permission_group.name
                if gname == "Default" then
                    gname = "NEW"
                end

                utag = gname
            else
                utag = "(none)"
            end

            if (global.actual_playtime ~= nil and player.index ~= nil and global.actual_playtime[player.index] ~= nil) then
                smart_print(victim, string.format("%-3d: %-18s Activity: %-4.3f, Online: %-4.3fh, (%s)", numpeople, player.name, (global.actual_playtime[player.index] / 60.0 / 60.0 / 60.0), (player.online_time / 60.0 / 60.0 / 60.0), utag))
            end
        end
    end
    if numpeople == 0 then
        smart_print(victim, "No players online.")
    end
end

--Custom commands
script.on_load(
    function()
        --Only add if no commands yet
        if (commands.commands.server_interface == nil) then
            --register command
            commands.add_command(
                "register",
                "<code>",
                function(param)
                    local player
                    if param.player_index then
                        local player = game.players[param.player_index]

                        if param.parameter ~= nil and player ~= nil and player.valid then
                            local ptype = "Error"

                            if player.admin then
                                ptype = "admin"
                            elseif is_regular(player) then
                                ptype = "regular"
                            elseif is_trusted(player) then
                                ptype = "trusted"
                            else
                                ptype = "normal"
                            end

                            print("[ACCESS] " .. ptype .. " " .. player.name .. " " .. param.parameter)
                            smart_print(player, "Access code sent, check discord!")
                            return
                        end
                        smart_print(player, "You need to specify an access code!")
                        return
                    end
                    smart_print(nil, "I don't think the console needs to use this command...")
                end
            )

            --server chat
            commands.add_command(
                "cchat",
                "<message here>",
                function(param)
                    if param.player_index ~= nil then
                        local player = game.players[param.player_index]
                        smart_print(player, "This command is for console use only.")
                        return
                    end

                    if param.parameter ~= nil then
                        message_allp(param.parameter)
                    end
                end
            )

            --Set player color
            commands.add_command(
                "pcolor",
                "<player> <color>",
                function(param)
                    local player

                    if param.player_index ~= nil then
                        player = game.players[param.player_index]
                        if player ~= nil and player.valid and player.admin == false then
                            smart_print(player, "Admins only.")
                            return
                        end
                    end

                    if param.parameter ~= nil then
                        local args = mysplit(param.parameter, " ")

                        if args[1] and args[2] then
                            local victim = game.players[args[1]]
                            local xytable = mysplit(args[2], ",")
                            if victim ~= nil and victim.valid then
                                if xytable[1] ~= nil and xytable[2] ~= nil and xytable[3] ~= nil then
                                    if (victim ~= nil and victim.valid) then
                                        if xytable ~= nil then
                                            local argr = xytable[1]
                                            local argg = xytable[2]
                                            local argb = xytable[3]
                                            victim.color = {argr, argg, argb, 1.0}
                                            victim.chat_color = {argr, argg, argb, 1.0}
                                            smart_print(player, "Color set.")
                                            return
                                        end
                                    else
                                        smart_print(player, "Player not found.")
                                        return
                                    end
                                end
                            end
                        end
                    end
                    smart_print(player, "Invalid argument, systax pcolor <player> <r,g,b>")
                end
            )

            --Reset user
            commands.add_command(
                "reset",
                "<player> -- sets user to 0",
                function(param)
                    local is_admin = true
                    local player

                    if param.player_index ~= nil then
                        player = game.players[param.player_index]
                        if player ~= nil and player.valid and player.admin == false then
                            is_admin = false
                            smart_print(player, "Admins only.")
                            return
                        end
                    end

                    if param.parameter then
                        local victim = game.players[param.parameter]

                        if (victim ~= nil and victim.valid) then
                            --Lame, but works
                            if global.actual_playtime ~= nil then
                                if global.actual_playtime[victim.index] == nil then
                                    global.actual_playtime[victim.index] = 1
                                end
                                if global.actual_playtime[victim.index] > 0 then
                                    global.actual_playtime[victim.index] = 0
                                    smart_print(player, "Player set to 0.")
                                    return
                                end
                                smart_print(player, "Player was already reset.")
                                return
                            end
                        end
                    end
                    smart_print(player, "Error.")
                end
            )

            --Trust user
            commands.add_command(
                "trust",
                "<player> -- sets user to trusted",
                function(param)
                    local is_admin = true
                    local player

                    if param.player_index ~= nil then
                        player = game.players[param.player_index]
                        if player ~= nil and player.valid and player.admin == false then
                            is_admin = false
                            smart_print(player, "Admins only.")
                            return
                        end
                    end

                    if param.parameter ~= nil then
                        local victim = game.players[param.parameter]

                        if (victim ~= nil and victim.valid) then
                            --Lame, but works
                            if global.actual_playtime ~= nil then
                                if global.actual_playtime[victim.index] == nil then
                                    global.actual_playtime[victim.index] = 1
                                end
                                if global.actual_playtime[victim.index] < (30 * 60 * 60) then
                                    global.actual_playtime[victim.index] = (30 * 60 * 60) + 1
                                    smart_print(player, "Player set to trusted.")
                                    return
                                end
                                smart_print(player, "Player was already trusted.")
                                return
                            end
                        end
                    end
                    smart_print(player, "Error.")
                end
            )

            --Set user to regular
            commands.add_command(
                "regular",
                "<player> -- sets user to regular status",
                function(param)
                    local is_admin = true
                    local player

                    if param.player_index ~= nil then
                        player = game.players[param.player_index]
                        if player ~= nil and player.valid and player.admin == false then
                            is_admin = false
                            smart_print(player, "Admins only.")
                            return
                        end
                    end

                    if param.parameter then
                        local victim = game.players[param.parameter]

                        if (victim ~= nil and victim.valid) then
                            --Lame, but works
                            if global.actual_playtime ~= nil then
                                if global.actual_playtime[victim.index] == nil then
                                    global.actual_playtime[victim.index] = 1
                                end
                                if global.actual_playtime[victim.index] < (4 * 60 * 60 * 60) then
                                    global.actual_playtime[victim.index] = (4 * 60 * 60 * 60) + 1
                                    smart_print(player, "Player set to regular.")
                                    return
                                end
                                smart_print(player, "Player was already a regular.")

                                return
                            end
                        end
                    end
                    smart_print(player, "Error.")
                end
            )

            --Change game mode
            commands.add_command(
                "mode",
                "<mode>, options: sandbox, coal.",
                function(param)
                    local is_admin = true
                    local victim

                    if param.player_index ~= nil then
                        victim = game.players[param.player_index]
                        if victim ~= nil and victim.valid and victim.admin == false then
                            is_admin = false
                        end
                    end

                    if is_admin then
                        if param.parameter == "sandbox" then
                            if global.sandboxmode == true then
                                global.sandboxmode = nil
                                smart_print(victim, "Sandbox mode disabled.")
                            else
                                global.sandboxmode = true
                                sandbox_mode(victim)
                                smart_print(victim, "Sandbox mode enabled.")
                            end
                        elseif param.parameter == "coal" then
                            if global.coalmode == true then
                                global.coalmode = nil
                                smart_print(victim, "Coal mode disabled.")
                            else
                                global.coalmode = true
                                coal_mode()
                                smart_print(victim, "Coal mode enabled.")
                            end
                        else
                            smart_print(victim, "Valid modes: sandbox, coal")
                        end
                    else
                        smart_print(victim, "Admins only.")
                    end
                end
            )
            --Change default spawn point
            commands.add_command(
                "cspawn",
                "<x,y> -- Changes default spawn location, if no <x,y> then where you currently stand.",
                function(param)
                    local is_admin = true
                    local victim
                    local new_pos_x = 0.0
                    local new_pos_y = 0.0

                    if param.player_index ~= nil then
                        victim = game.players[param.player_index]

                        if victim ~= nil and victim.valid and victim.admin == false then
                            is_admin = false
                        else
                            new_pos_x = victim.position.x
                            new_pos_y = victim.position.y
                        end
                    end

                    if is_admin then
                        local psurface = game.surfaces["nauvis"]
                        local pforce = game.forces["player"]

                        if victim ~= nil and victim.valid then
                            pforce = victim.force
                            psurface = victim.surface
                        end

                        if param.parameter ~= nil then
                            local xytable = mysplit(param.parameter, ",")
                            if xytable then
                                local argx = xytable[1]
                                local argy = xytable[2]
                                new_pos_x = argx
                                new_pos_y = argy
                            else
                                smart_print(victim, "Invalid argument.")
                                return
                            end
                        end

                        if pforce ~= nil and psurface ~= nil then
                            pforce.set_spawn_position({new_pos_x, new_pos_y}, psurface)
                            smart_print(victim, string.format("New spawn point set: %d,%d", math.floor(new_pos_x), math.floor(new_pos_y)))
                            smart_print(victim, string.format("Surface: %s, Force: %s", psurface.name, pforce.name))
                            global.cspawnpos = {new_pos_x, new_pos_y}
                        else
                            smart_print(victim, "Couldn't find force or surface...")
                        end
                    else
                        smart_print(victim, "Admins only.")
                    end
                end
            )

            --Reveal map
            commands.add_command(
                "reveal",
                "<size> -- <x> units of map. Default: 1024, max 4096",
                function(param)
                    local is_admin = true
                    local victim

                    if param.player_index ~= nil then
                        victim = game.players[param.player_index]
                        if victim ~= nil and victim.valid and victim.admin == false then
                            is_admin = false
                        end
                    end

                    if (is_admin) then
                        local psurface = game.surfaces["nauvis"]
                        local pforce = game.forces["player"]
                        local size = 1024

                        if param.parameter ~= nil then
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
                        end

                        if psurface ~= nil and pforce ~= nil then
                            pforce.chart(psurface, {lefttop = {x = -size, y = -size}, rightbottom = {x = size, y = size}})
                            local sstr = string.format("%-4.0f", size)
                            smart_print(victim, "Revealing " .. sstr .. "x" .. sstr .. " tiles")
                        else
                            smart_print(victim, "Either couldn't find surface nauvis, or couldn't find force player.")
                        end
                    else
                        smart_print(victim, "Admins only.")
                    end
                end
            )

            --Rechart map
            commands.add_command(
                "rechart",
                "resets fog of war",
                function(param)
                    local is_admin = true
                    local victim

                    if param.player_index ~= nil then
                        victim = game.players[param.player_index]
                        if victim ~= nil and victim.valid and victim.admin == false then
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
                    local victim
                    local is_admin = true

                    if param.player_index ~= nil then
                        victim = game.players[param.player_index]
                        if victim ~= nil and victim.valid and victim.admin == false then
                            is_admin = false
                        end
                    end

                    if (param.parameter == "active" and is_admin) then
                        if (global.actual_playtime ~= nil) then
                            local plen = 0
                            local playtime = {}
                            for pos, player in pairs(game.players) do
                                if player ~= nil and player.valid then
                                    if global.actual_playtime[player.index] ~= nil then
                                        playtime[pos] = {
                                            time = global.actual_playtime[player.index],
                                            name = player.name
                                        }
                                        plen = plen + 1
                                    end
                                end
                            end

                            table.sort(playtime, sortTime)

                            --Lets limit number of results
                            for ipos, time in pairs(playtime) do
                                if (time ~= nil) then
                                    if (time.time ~= nil) then
                                        if ipos > (plen - 20) then
                                            smart_print(victim, string.format("%-4d: %-32s Active: %-4.2fm", ipos, time.name, time.time / 60.0 / 60.0))
                                        end
                                    end
                                end
                            end
                        end
                        return
                    end

                    show_players(victim)
                end
            )

            --Game speed
            commands.add_command(
                "gspeed",
                "<x.x> -- Changes game speed. Default: 1.0, min 0.1, max 10.0",
                function(param)
                    local player
                    local isadmin = true

                    if param.player_index ~= nil then
                        player = game.players[param.player_index]
                    end

                    if (player ~= nil and player.valid) then
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
                            smart_print(player, "Game speed: " .. value .. " Walk speed: " .. game.forces["player"].character_running_speed_modifier)
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
                "<player> -- teleport to <player>",
                function(param)
                    if param.player_index == nil then
                        smart_print(nil, "You want me to teleport a remote console somewhere???")
                        return
                    end
                    local player = game.players[param.player_index]

                    if (player ~= nil and player.valid and player.connected and player.character and player.character.valid) then
                        if (player.admin == false) then
                            player.print("Admins only.")
                            return
                        end

                        if param.parameter ~= nil then
                            local victim = game.players[param.parameter]

                            if (victim ~= nil and victim.valid) then
                                local newpos = victim.surface.find_non_colliding_position("character", victim.position, 15, 0.01, false)
                                if (newpos ~= nil) then
                                    player.teleport(newpos, victim.surface)
                                    player.print("Okay.")
                                else
                                    player.print("Area full.")
                                end
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
                "<x,y> -- teleport to <x,y>",
                function(param)
                    if param.player_index == nil then
                        smart_print(nil, "You want me to teleport a remote console somewhere???")
                        return
                    end
                    local player = game.players[param.player_index]

                    if (player ~= nil and player.valid and player.connected and player.character and player.character.valid) then
                        if (player.admin == false) then
                            player.print("Admins only.")
                            return
                        end

                        if param.parameter ~= nil then
                            local str = param.parameter
                            local xpos = "0.0"
                            local ypos = "0.0"

                            xpos, ypos = str:match("([^,]+),([^,]+)")
                            local position = {x = xpos, y = ypos}

                            if position ~= nil then
                                if position.x ~= nil and position.y ~= nil then
                                    local newpos = player.surface.find_non_colliding_position("character", position, 15, 0.01, false)
                                    if (newpos ~= nil) then
                                        player.teleport(newpos, player.surface)
                                        player.print("Okay.")
                                    else
                                        player.print("Area full.")
                                    end
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
                "<player> -- teleport <player> to me",
                function(param)
                    if not param.player_index then
                        smart_print(nil, "You want me to teleport a remote console somewhere???")
                        return
                    end
                    local player = game.players[param.player_index]

                    if (player ~= nil and player.valid and player.connected and player.character and player.character.valid) then
                        if (player.admin == false) then
                            player.print("Admins only.")
                            return
                        end

                        if param.parameter ~= nil then
                            local victim = game.players[param.parameter]

                            if (victim ~= nil and victim.valid) then
                                local newpos = player.surface.find_non_colliding_position("character", player.position, 15, 0.01, false)
                                if (newpos ~= nil) then
                                    victim.teleport(newpos, player.surface)
                                    player.print("Okay.")
                                else
                                    player.print("Area full.")
                                end
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
--Command logging
script.on_event(
    defines.events.on_console_command,
    function(event)
        local command = ""
        local args = ""

        if event.command ~= nil then
            command = event.command
        end

        if event.parameters ~= nil then
            args = event.parameters
        end

        if event.player_index ~= nil then
            local player = game.players[event.player_index]
            if player ~= nil and player.valid then
                print(string.format("[CMD] NAME: %s, COMMAND: %s, ARGS: %s", player.name, command, args))
            end
        elseif command ~= "time" and command ~= "p" and command ~= "w" and command ~= "server-save" then --Ignore spammy console commands
            print(string.format("[CMD] NAME: NONE, COMMAND: %s, ARGS: %s", command, args))
        end
    end
)

--Player connected
script.on_event(
    defines.events.on_player_joined_game,
    function(event)
        if event ~= nil and event.player_index then
            local player = game.players[event.player_index]

            if player ~= nil and player.valid then
                create_groups()
                sandbox_mode(player)

                --Discord Info--
                if player.gui.top.discord == nil then
                    player.gui.top.add {type = "textfield", name = "discord"}
                    player.gui.top.discord.text = "discord.gg/Ps2jnm7"
                    player.gui.top.discord.tooltip = "select with mouse, and control-c to copy!"
                end

                --Moved here to reduce on_tick
                if global.defaultgroup ~= nil and global.regulargroup ~= nil and global.trustedgroup ~= nil then
                    if player.admin then
                        global.admingroup.add_player(player)
                    elseif is_regular(player) then
                        global.regulargroup.add_player(player)
                    elseif is_trusted(player) then
                        global.trustedgroup.add_player(player)
                    end
                end
            end
        end
    end
)

--New player created
script.on_event(
    defines.events.on_player_created,
    function(event)
        if event ~= nil and event.player_index then
            local player = game.players[event.player_index]

            if player ~= nil and player.valid then
                message_all(player.name .. " is a new character!")
                create_groups()
                sandbox_mode(player)
                game_settings(player)
                smart_print(player, "To see online players, chat /online")
                show_players(player)
            end
        end
    end
)

--ACTIVITY EVENTS
--Build stuff
script.on_event(
    defines.events.on_built_entity,
    function(event)
        if event ~= nil and event.player_index and event.created_entity then
            local player = game.players[event.player_index]
            local created_entity = event.created_entity

            if player ~= nil and player.valid and created_entity and created_entity.valid then
                if global.last_speaker_warning == nil then
                    global.last_speaker_warning = 1
                end

                if (game.tick - global.last_speaker_warning >= 300) then
                    if is_regular(player) == false and player.admin == false then --Dont bother with regulars/admins
                        if created_entity.name == "programmable-speaker" then
                            message_all(player.name .. " placed speaker: " .. math.floor(created_entity.position.x) .. "," .. math.floor(created_entity.position.y))
                            global.last_speaker_warning = game.tick
                        end
                    end
                end
                set_active(player)
            end
        end
    end
)

--Deconstuction planner warning
script.on_event(
    defines.events.on_player_deconstructed_area,
    function(event)
        if event ~= nil and event.player_index and event.area then
            local player = game.players[event.player_index]
            local area = event.area

            if player ~= nil and player.valid and area and area.left_top and area.right_bottom then
                set_active(player)

                if global.last_decon == nil then
                    global.last_decon = 1
                end

                if (game.tick - global.last_decon >= 600 and area.left_top.x ~= nil and area.left_top.y ~= nil and area.right_bottom.x ~= nil and area.right_bottom.y ~= nil) then
                    if is_regular(player) == false and player.admin == false then --Dont bother with regulars/admins
                        message_all(player.name .. " is using the deconstruction planner: " .. math.floor(area.left_top.x) .. "," .. math.floor(area.left_top.y) .. " to " .. math.floor(area.right_bottom.x) .. "," .. math.floor(area.right_bottom.y))
                    end
                    global.last_decon = game.tick
                end
            end
        end
    end
)

--Mined item or corpse
script.on_event(
    defines.events.on_pre_player_mined_item,
    function(event)
        if (global.corpselist == nil) then
            global.corpselist = {tag = {}, tick = {}, pos = {}, name = {}}
        end

        if event ~= nil and event.entity and event.player_index then
            local player = game.players[event.player_index]
            local obj = event.entity

            if player ~= nil and player.valid and obj and obj.valid and obj.name and obj.position then
                cprint(player.name .. " mined " .. obj.name .. " at " .. obj.position.x .. "," .. obj.position.y)
                set_active(player)

                if obj.name == "character-corpse" then
                    --Remove old corpse tags
                    if (global.corpselist ~= nil) then
                        for x, corpse in pairs(global.corpselist) do
                            if (corpse ~= nil and corpse.pos ~= nil and orpse.pos.x ~= nil and corpse.pos.x ~= nil == obj.position.x ~= nil and corpse.pos.y ~= nil == obj.position.y ~= nil) then
                                if corpse.name ~= nil and player.name ~= nil and corpse.name == player.name then
                                    message_all(player.name .. " recovered their corpse at: " .. math.floor(corpse.pos.x) .. "," .. math.floor(corpse.pos.y))
                                else
                                    message_all(player.name .. " picked up " .. corpse.name .. "'s corpse at: " .. math.floor(corpse.pos.x) .. "," .. math.floor(corpse.pos.y))
                                end
                                if corpse.tag ~= nil and corpse.tag.valid then
                                    corpse.tag.destroy()
                                end
                                if corpse.tick ~= nil then
                                    cprint("Tag removed: Tick: " .. corpse.tick)
                                end
                                table.remove(global.corpselist, x)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
)

--Player inventory
script.on_event(
    defines.events.on_player_main_inventory_changed,
    function(event)
        local player = game.players[event.player_index]
        set_active(player)
    end
)

--Mine tiles
script.on_event(
    defines.events.on_player_mined_tile,
    function(event)
        local player = game.players[event.player_index]

        set_active(player)
    end
)

--Repair entity
script.on_event(
    defines.events.on_player_repaired_entity,
    function(event)
        local player = game.players[event.player_index]

        set_active(player)
    end
)

--Rotate entity
script.on_event(
    defines.events.on_player_rotated_entity,
    function(event)
        local player = game.players[event.player_index]

        set_active(player)
    end
)

--Fast transfer
script.on_event(
    defines.events.on_player_fast_transferred,
    function(event)
        local player = game.players[event.player_index]

        set_active(player)
    end
)

--Shooting
script.on_event(
    defines.input_action.change_shooting_state,
    function(event)
        local player = game.players[event.player_index]

        set_active(player)
    end
)

--Chatting
script.on_event(
    defines.events.on_console_chat,
    function(event)
        --Can be triggered by console, so check for nil
        if event.player_index then
            local player = game.players[event.player_index]

            set_active(player)
        end
    end
)

--End Activity

--Walking/Driving
script.on_event(
    defines.events.on_player_changed_position,
    function(event)
        if event and event.player_index then
            local player = game.players[event.player_index]

            --Only count if actually walking...
            if player ~= nil and player.valid and player.walking_state then
                local walking_state = player.walking_state.walking

                if walking_state == true then
                    set_active(player)
                end
            end
        end
    end
)

--OTHER EVENTS
--Corpse Marker
script.on_event(
    defines.events.on_pre_player_died,
    function(event)
        if (global.corpselist == nil) then
            global.corpselist = {tag = {}, tick = {}, pos = {}, name = {}}
        end

        if event ~= nil and event.player_index ~= nil then
            local player = game.players[event.player_index]

            if player ~= nil and player.valid and player.character and player.position and player.surface then
                local ppos = player.position
                local label = "Corpse of: " .. player.name .. " " .. math.floor(ppos.x) .. "," .. math.floor(ppos.y)
                local chartTag = {position = ppos, icon = "", text = label}
                local qtag = player.force.add_chart_tag(player.surface, chartTag)

                table.insert(global.corpselist, {tag = qtag, tick = game.tick, pos = ppos, name = player.name})

                --Log to discord
                message_all(player.name .. " died at " .. math.floor(player.position.x) .. "," .. math.floor(player.position.y))
            end
        end
    end
)

--Research Finished
script.on_event(
    defines.events.on_research_finished,
    function(event)
        if event and event.reseatch then
            local tech = event.research
            local wscript = event.by_script

            --Disable mining/rotating once we get far enough along.. do this fairly late
            if tech ~= nil and tech.name and tech.name == "logistics-3" and wscript == false then
                local dperms = game.permissions.get_group("Default")
                if dperms then
                    message_all("Automatically disabling rotating and mining/deleting objects for new users... due to technology level.")
                    dperms.set_allows_action(defines.input_action.begin_mining, false)
                    dperms.set_allows_action(defines.input_action.rotate_entity, false)
                end
            end

            --Log to discord
            if wscript == false then
                message_alld("Research " .. tech.name .. " completed.")
            end
        end
    end
)

script.on_nth_tick(
    300, --5 seconds--
    function(event)
        --Repair discord info--
        for _, player in pairs(game.connected_players) do
            if player ~= nil and player.valid and player.gui and player.gui.top and player.gui.top.discord then
                player.gui.top.discord.text = "discord.gg/Ps2jnm7"
            end
        end

        --Remove old corpse tags--
        if (global.corpselist ~= nil) then
            for x, corpse in pairs(global.corpselist) do
                if corpse ~= nil and coprse.tick ~= nil and corpse.name ~= nil then
                    if (corpse.tick ~= nil and (corpse.tick + (15 * 60 * 60)) < game.tick) then
                        if (corpse.tag ~= nil and corpse.tag.valid) then
                            corpse.tag.destroy()
                        end
                        message_all(corpse.name .. "'s corpse has decomposed...")
                        table.remove(global.corpselist, x)
                        break
                    end
                end
            end
        end

        --Spawn marker--
        if (global.servertag ~= nil and global.servertag.valid) then
            global.servertag.destroy()
            global.servertag = nil
        end
        if (global.servertag ~= nil and not global.servertag.valid) then
            global.servertag = nil
        end
        if (global.servertag == nil) then
            local label = "Spawn Area"
            local xpos = 0
            local ypos = 0

            if global.cspawnpos ~= nil then
                xpos = global.cspawnpos[1]
                ypos = global.cspawnpos[2]
            end

            local chartTag = {
                position = {xpos, ypos},
                icon = {type = "item", name = "heavy-armor"},
                text = label
            }
            local pforce = game.forces["player"]
            local psurface = game.surfaces["nauvis"]

            if pforce ~= nil and psurface ~= nil and chartTag ~= nil then
                global.servertag = pforce.add_chart_tag(psurface, chartTag)
            end
        end

        --Check permissions
        get_permgroup()
    end
)

--Idle Detection--
script.on_nth_tick(
    7200, --2 minutes
    function(event)
        --Init global.actual_playtime
        if (global.actual_playtime == nil) then
            global.actual_playtime = {}
        end

        --Init global.active
        if (global.active == nil) then
            global.active = {}
        end

        --Cycle all connected players, increment active play time.
        for _, player in pairs(game.connected_players) do
            if global.active ~= nil and player ~= nil and player.valid and player.index ~= nil then
                if global.active[player.index] ~= nil then
                    if global.active[player.index] == 1 then
                        global.active[player.index] = 0 --Turn back off

                        if global.actual_playtime ~= nil and global.actual_playtime[player.index] ~= nil then
                            --Must be same as interval
                            global.actual_playtime[player.index] = global.actual_playtime[player.index] + 7200
                        else
                            --INIT
                            global.actual_playtime[player.index] = 0
                        end
                    end
                else
                    --INIT
                    global.active[player.index] = 0
                end
            end
        end
    end
)
