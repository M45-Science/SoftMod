--v037-1-14-2020b
local handler = require("event_handler")
handler.add_lib(require("freeplay"))
handler.add_lib(require("silo-script"))

local regulars = {
    "ytremors",
    "zendesigner",
    "Trent333",
    "luckcolors",
    "skymory_24",
    "SmokuNoPico",
    "Footy",
    "luckcolors",
    "Darsin",
    "Avaren",
    "Aidenkrz",
    "mehdi2344",
    "Rylabs",
    "bazus1",
    "Nasphere",
    "twist.mills",
    "SpacecatCybran",
    "GregorS",
    "nickoe",
    "Moose1301",
    "StevenMatthews",
    "ArmadaX",
    "Daddyrilla",
    "Andro",
    "zlema01",
    "literallyjustanegg",
    "FuzzyOne",
    "adee",
    "BlackJaBus",
    "AryanCoconut",
    "DZCM",
    "chrisg23",
    "A7fie",
    "funork",
    "Corruptarc",
    "chubbins",
    "Castleboy2000",
    "D_Riv",
    "mojosa",
    "VortexBerserker",
    "Merciless210"
}

--Global messages--
local function message_all(message)
    
    for _, player in pairs(game.connected_players) do
        player.print(message)
    end
    print("[MSG] " .. message)

end

--Sort players--
local function sortTime(a, b)
    if ( a == nil or b == nil ) then
        return false
    end

    if ( a.time == nil or b.time == nil ) then
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
                    for _, regular in pairs(regulars) do
                        if (regular == player.name) then
                            if (player.permission_group.name == "Default") then
                                global.trustedgroup.add_player(player)
                                message_all(player.name .. " moved to regulars...")
                                player.print("Welcome back, " .. player.name .. "! Moving you into trusted users group... Have fun!")
                            end
                        end
                    end
                end
            
            else
                if (global.actual_playtime and global.actual_playtime[player.index] and global.actual_playtime[player.index] > (30 * 60 * 60)) then
                    if (player.permission_group ~= nil and player.permission_group.name == "Default") then
                        if (global.trustedgroup.add_player(player) == true) then
                            player.print("(SERVER) You have been actively playing long enough, that the restrictions on your character have been lifted. Have fun, and be nice!")
                            player.print("(SERVER) Discord server: https://discord.gg/Ps2jnm7")
                            message_all(player.name .. " was moved to trusted users.")
                        end
                    end
                end
            end
        end
    end
end

local function show_player (victim)
    local numpeople = 0

    for _, player in pairs(game.connected_players) do
                
        if (player and player.valid and player.connected) then
            numpeople = (numpeople + 1)
            local admintag = " "
            
            if (player.admin) then
                admintag = "  --  (ADMIN)"
            end
            
            if (player.permission_group ~= nil) then
                if (player.permission_group.name == "Default") then
                    admintag = "  --  (NEW)"
                end
            end
            if (player.permission_group ~= nil) then
                if (player.permission_group.name == "Trusted") then
                    admintag = "  --  (MEMBER)"
                end
            end
            
            if (global.actual_playtime and global.actual_playtime[player.index]) then
                    local line = string.format(string.format("%-4d: %-32s Active: %-4.2fm Online: %-4.2fm%s",
                        numpeople, player.name, (global.actual_playtime[player.index] / 60.0 / 60.0), (player.online_time / 60.0 / 60.0), admintag))
                if victim then
                    victim.print(line)
                else
                    print(line)
                end
            end
        end
    
    end
end

--On load, add commands--
script.on_load(function()
	
	--Only add if no commands yet
    if (commands.commands.server_interface == nil) then

        --Online
        commands.add_command("online", "See who is online", function(param)
            if not param.player_index then
                return
            end
            
            local victim = game.players[param.player_index]
			
			--Should be moved into different command
            if (param.parameter == "reveal" and victim.admin) then
                game.forces.player.chart(victim.surface, {lefttop = {x = -2048, y = -2048}, rightbottom = {x = 2048, y = 2048}})
                victim.print("Revealing...")
                return
            end
            if (param.parameter == "rechart" and victim.admin) then
                game.forces.player.clear_chart()
                victim.print("Recharting...")
                return
			end
			--

            if (param.parameter == "active" and victim.admin) then
                if (global.actual_playtime) then
                    
                    local plen = 0
                    local playtime = {}
                    for pos, player in pairs(game.players) do
                        playtime[pos] = {time = global.actual_playtime[player.index], name = game.players[player.index].name}
                        plen = plen + 1
                    end

                    table.sort(playtime, sortTime)
                    
                    --Lets limit number of results
                    for ipos, time in pairs(playtime) do
                        if ( time ~= nil ) then
                            if (time.time ~= nil ) then
                                if ipos > ( plen - 20 ) then
                                    victim.print(string.format("%-4d: %-32s Active: %-4.2fm", ipos, time.name, time.time / 60.0 / 60.0))
                                end
                            end
                        end
                    end
                
                
                end
                return
            end

            show_player(victim)
        
        end)
        
        --Game speed
        commands.add_command("gspeed", "change game speed to <%percent speed>", function(param)
            if not param.player_index then
                return
            end
            local player = game.players[param.player_index]
            
            if (player.admin == false) then
                player.print("Nope.")
                return
            end
            
            if (param.parameter == nil) then
                return
            end
            
            local value = tonumber(param.parameter)
            if (value >= 0.1 and value <= 10.0) then
                game.speed = value
                player.force.character_running_speed_modifier = ((1.0 / value) - 1.0)
                player.print("Game speed: " .. value .. " Walk speed: " .. player.force.character_running_speed_modifier)
                game.print("(System) Game speed set to %" .. (game.speed * 100.00))
            else
                player.print("That doesn't seem like a good idea...")
            end
        
        end)
        
        --Teleport to
        commands.add_command("tto", "teleport to <player>", function(param)
            if not param.player_index then
                return
            end
            local player = game.players[param.player_index]
            
            if (player and player.valid and player.connected and player.character and player.character.valid) then
                
                if (player.admin == false) then
                    player.print("Nope.")
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
        end)
        
        --Teleport x,y
        commands.add_command("tp", "teleport to <x,y>", function(param)
            if not param.player_index then
                return
            end
            local player = game.players[param.player_index]
            
            if (player and player.valid and player.connected and player.character and player.character.valid) then
                
                if (player.admin == false) then
                    player.print("Nope.")
                    return
                end
                
                if param.parameter then
                    local str = param.parameter
                    local xpos = "0.0"
                    local ypos = "0.0"
                    
                    xpos, ypos = str:match("([^,]+),([^,]+)")
                    local position = {x = xpos, y = ypos, }
                    
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
        end)
        
        --Teleport player to me
        commands.add_command("tfrom", "teleport <player> to me", function(param)
            if not param.player_index then
                return
            end
            local player = game.players[param.player_index]
            
            if (player and player.valid and player.connected and player.character and player.character.valid) then
                
                if (player.admin == false) then
                    player.print("Nope.")
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
        
        end)
    
    end
end)

--EVENTS--

--Player created
script.on_event(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]

    player.force.friendly_fire = false --friendly fire
    player.force.research_queue_enabled = true --nice to have

    --disable tech
    --game.forces["player"].technologies["landfill"].enabled = false
    --game.forces["player"].technologies["solar-energy"].enabled = false
    --game.forces["player"].technologies["logistic-robotics"].enabled = false
	--game.forces["player"].technologies["railway"].enabled = false
	
    player.print("(SERVER) Discord server: https://discord.gg/Ps2jnm7")
    player.print("(SERVER) You are currently a new player on this map, and some options will be disabled for you.")
end)

--Player Login
--script.on_event(defines.events.on_player_joined_game, function(event)
    --local player = game.players[event.player_index]
    --player.print ( "Disabled tech: landfill" )
    --player.print ( "Disabled tech: landfill, solar, robots, railway, accumulators" )
    --player.print ( "Disabled tech: none" )
    --player.print ( "Disabled tech: None, CHEATS ON" )

    --player.cheat_mode = true
	--player.surface.always_day = true
	--for name, recipe in pairs(player.force.recipes) do recipe.enabled = true end
	--player.force.laboratory_speed_modifier=1
	--player.zoom=0.1
	--player.force.manual_mining_speed_modifier=1000
	--player.force.manual_crafting_speed_modifier=1000
	--player.force.research_all_technologies()
      
    --if (player.character) then
        --temp = player.character
        --player.character = nil
        --temp.destroy()
    --end
--end)

script.on_event(defines.events.on_built_entity, function(event)
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
	
	if (game.tick - global.last_speaker_warning >= 300 ) then
		if player and created_entity then
        	if created_entity.name == "programmable-speaker" then
				message_all(player.name .. " placed speaker: " .. math.floor(created_entity.position.x) .. "," .. math.floor(created_entity.position.y))
				global.last_speaker_warning = game.tick
	        end
		end
	end

end)

--Deconstuction planner warning
script.on_event(defines.events.on_player_deconstructed_area, function(event)
    local player = game.players[event.player_index]
    local area = event.area
    
	if (not global.last_decon_warning) then
		global.last_decon_warning = 0
	end
	
	if (game.tick - global.last_decon_warning >= 300 ) then
	    message_all(player.name .. " is using the deconstruction planner: " .. math.floor(area.left_top.x) .. "," .. math.floor(area.left_top.y) .. " to " .. math.floor(area.right_bottom .x) .. "," .. math.floor(area.right_bottom .y) )
		global.last_decon_warning = game.tick
	end

end)



script.on_event(defines.events.on_pre_player_mined_item, function(event)
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
end)

script.on_event(defines.events.on_player_changed_position, function(event)
    local player = game.players[event.player_index]
    
    if (not global.actual_playtime) then
        global.actual_playtime = {}
        global.actual_playtime[0] = 0
    end
    
    if (global.actual_playtime and global.actual_playtime[player.index]) then
        global.actual_playtime[player.index] = global.actual_playtime[player.index] + (6.67)--Estimate...
    else
        global.actual_playtime[player.index] = 0.0
    end
end)

--Corpse Marker
script.on_event(defines.events.on_pre_player_died, function(event)
    if (not global.corpselist) then
        global.corpselist = {tag = {}, tick = {}, }
    end
    
    local player = game.players[event.player_index]
    local centerPosition = player.position
    local label = "Corpse of: " .. player.name .. " " .. math.floor(player.position.x) .. "," .. math.floor(player.position.y)
    local chartTag = {position = centerPosition, icon = nil, text = label}
    local qtag = player.force.add_chart_tag(player.surface, chartTag)
    
    table.insert(global.corpselist, {tag = qtag, tick = game.tick, })
end)

--Tick loop--
--Keep to minimum--
script.on_event(defines.events.on_tick, function(event)
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
                local chartTag = {position = {0, 0}, icon = {type = "item", name = "programmable-speaker"}, text = label}
                global.servertag = game.forces['player'].add_chart_tag(game.surfaces["nauvis"], chartTag)
            end
            
            get_permgroup()
            global.last_s_tick = game.tick
        
        end

end)

