--v037-1-2-2020
local util = require("util")
local silo_script = require("silo-script")

local created_items = function()
	return
	{
		["iron-plate"] = 8,
		["wood"] = 1,
		["pistol"] = 1,
		["firearm-magazine"] = 10,
		["burner-mining-drill"] = 1,
		["stone-furnace"] = 1
	}
end

local respawn_items = function()
	return
	{
		["pistol"] = 1,
		["firearm-magazine"] = 10
	}
end

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
	"literallyjustanegg"
}

for k,v in pairs(silo_script.get_events()) do
	script.on_event(k, v)
end

script.on_event(defines.events.on_player_created, function(event)
	local player = game.players[event.player_index]
	util.insert_safe(player, global.created_items)

	local r = global.chart_distance or 200
	player.force.chart(player.surface, {{player.position.x - r, player.position.y - r}, {player.position.x + r, player.position.y + r}})

	if not global.skip_intro then
	if game.is_multiplayer() then
		player.print({"msg-intro"})
	else
		game.show_message_dialog{text = {"msg-intro"}}
	end
  end

  silo_script.on_event(event)
	player.force.friendly_fire = false --friendly fire
	
	if ( not global.actual_playtime ) then
		global.actual_playtime = {}
		global.actual_playtime[0] = 0
	end
	
	--disable tech
	--game.forces["player"].technologies["landfill"].enabled = false
	--game.forces["player"].technologies["solar-energy"].enabled = false
	--game.forces["player"].technologies["logistic-robotics"].enabled = false
	--game.forces["player"].technologies["railway"].enabled = false
	
end)
script.on_event(defines.events.on_player_joined_game, function(event)
	local player = game.players[event.player_index]
	--player.print ( "Disabled tech: landfill" )
	--player.print ( "Disabled tech: landfill, solar, robots, railway, accumulators" )
	--player.print ( "Disabled tech: None, CHEATS ON" )
	--player.print ( "Disabled tech: none" )
	--player.cheat_mode=true
	--player.surface.always_day=true
	--if ( player.character )  then
		--temp = player.character
		--player.character=nil
		--temp.destroy()
	--end

	
end)

script.on_event(defines.events.on_player_respawned, function(event)
	local player = game.players[event.player_index]
	util.insert_safe(player, global.respawn_items)
	silo_script.on_event(event)
end)

script.on_configuration_changed(function(event)
	global.created_items = global.created_items or created_items()
	global.respawn_items = global.respawn_items or respawn_items()
	silo_script.on_configuration_changed(event)
end)

local function sortTime (a, b )
	if (a.time < b.time) then
				 return true
			elseif (a.time > b.time) then
					return false
			else
					return nil
			end
end

script.on_load(function()
	silo_script.on_load()
  
	--dist--
	if ( commands.commands.server_interface == nil ) then

	--ONLINE--
	commands.add_command( "online", "See who is online", function(param)
		if not param then
			return
		end
	
		local numpeople = 0
		local victim = game.players[param.player_index]
		if ( victim == nil ) then
		  return
		end

		if ( param.parameter == "reveal" and victim.admin ) then
  			game.forces.player.chart(victim.surface, {lefttop = {x = -2048, y = -2048}, rightbottom = {x = 2048, y = 2048}})
			victim.print ( "Revealing..." )
			return
		end
		if ( param.parameter == "rechart" and victim.admin ) then
			game.forces.player.clear_chart()
			victim.print ( "Recharting..." )
			return
		end
		--Slow--
		if ( param.parameter == "active" and victim.admin ) then
			if ( global.actual_playtime ) then

				playtime = {}
				for pos, player in pairs(game.players) do
					playtime[pos] = { time = global.actual_playtime[player.index], name = game.players[player.index].name }
				end

				table.sort(playtime, sortTime)

				for ipos, time in pairs(playtime) do
					victim.print( string.format ( "%-4d: %-32s Active: %-4.2fm", ipos, time.name, time.time / 60.0 / 60.0 ) )
				end


			end
			return
		end
	        
		for _, player in pairs(game.connected_players) do
      
			if ( player and player.valid and player.connected and player.character and player.character.valid ) then
				numpeople = (numpeople + 1)
				admintag = " "
		
			if ( player.admin ) then
				admintag = "  --  (ADMIN)"
			end
	
			if ( player.permission_group ~= nil ) then
				if ( player.permission_group.name == "Default" ) then
					admintag = "  --  (NEW)"
				end
			end
			if ( player.permission_group ~= nil ) then
				if ( player.permission_group.name == "Trusted" ) then
					admintag = "  --  (MEMBER)"
				end
			end
        
			if ( global.actual_playtime and global.actual_playtime[player.index] ) then
				victim.print( string.format ( "%-4d: %-32s Active: %-4.2fm Online: %-4.2fm%s",
				numpeople, player.name, ( global.actual_playtime[player.index] / 60.0 / 60.0 ), ( player.online_time / 60.0 / 60.0 ), admintag ) )
			end    
		end
        
	end
	  
end)
  
commands.add_command( "gspeed", "change game speed ( with auto walk speed adjustment )", function(param)
	if not param then
		return
	end
	local player = game.players[param.player_index]
	
	if ( player == nil ) then
		return
	end
    
	if ( player.admin == false ) then
		player.print ( "Nope." )
		return
    end
    
    if ( param.parameter == nil ) then
		return
    end
    
    local value = tonumber ( param.parameter )
	if ( value >= 0.1 and value <= 10.0 ) then
		game.speed = value
		player.force.character_running_speed_modifier = ( (  1.0 / value ) - 1.0 )
		player.print ( "Game speed: " .. value .. " Walk speed: " .. player.force.character_running_speed_modifier )
		game.print ( "(System) Game speed set to %" .. (game.speed * 100.00) )
	else
		player.print ( "That doesn't seem like a good idea..." )
    end  
    
end)
  

commands.add_command( "ctag", "clear speaker map tags", function(param)
	if not param then
		return
	end
    local player = game.players[param.player_index]
    
    if ( player and player.valid and player.connected and player.character and player.character.valid ) then
    
		if ( player.admin == false ) then
			player.print ( "No." )
			return
		end
	  
		x = 0
		--Remove old speakertags
		if ( global.speakerlist ) then
			for _, speaker in pairs(global.speakerlist) do
				if ( speaker.pin and speaker.pin.valid ) then
					speaker.pin.destroy()
					x = x + 1
				end
			end
		end
		global.speakerlist = nil
		player.print (x .. " speaker tags cleared...")
		return
   end
   player.print ( "Error..." )
end)

  
commands.add_command( "tto", "teleport to", function(param)
	if not param then
		return
	end
    local player = game.players[param.player_index]
    
    if ( player and player.valid and player.connected and player.character and player.character.valid ) then
    
		if ( player.admin == false ) then
			player.print ( "No." )
			return
		end
      
		if param.parameter then
			local victim = game.players[param.parameter]
      
			if ( victim and victim.valid ) then
				player.teleport ( { victim.position.x + 1.0, victim.position.y + 1.0 }  )
				player.print ( "Okay." )
				return
			end
		end
     	player.print ( "Error..." )
   end
end)

commands.add_command( "tp", "teleport to x,y", function(param)
	if not param then
		return
	end
    local player = game.players[param.player_index]
    
    if ( player and player.valid and player.connected and player.character and player.character.valid ) then
    
		if ( player.admin == false ) then
			player.print ( "No." )
			return
		end
      
		if param.parameter then
			str=param.parameter
			xpos = "0.0"
			ypos = "0.0"

			xpos, ypos = str:match("([^,]+),([^,]+)")
			position = { x=xpos, y=ypos, }

			if position then
				if position.x and position.y then
					player.teleport ( position )
					player.print ( "Okay." )
				else
					player.print ( "invalid x/y." )
				end
			end
			return
		end
     	player.print ( "Error..." )
   end
end)
  
commands.add_command( "tfrom", "teleport player to me", function(param)
	local player = game.players[param.player_index]
    
	if ( player and player.valid and player.connected and player.character and player.character.valid ) then
    
		if ( player.admin == false ) then
			player.print ( "No." )
			return
		end
      
		if param.parameter then
			local victim = game.players[param.parameter]
      
			if ( victim and victim.valid ) then
				victim.teleport ( { player.position.x + 1.0, player.position.y + 1.0 }   )
				player.print ( "Okay." )
				return
			end
		end
	player.print ( "Error." )
	end
	
end)

end
  --dist--
end)

script.on_init(function()
	global.created_items = created_items()
	global.respawn_items = respawn_items()
	silo_script.on_init()
end)

silo_script.add_remote_interface()
silo_script.add_commands()

remote.add_interface("freeplay",
{
  get_created_items = function()
    return global.created_items
  end,
  set_created_items = function(map)
    global.created_items = map
  end,
  get_respawn_items = function()
    return global.respawn_items
  end,
  set_respawn_items = function(map)
    global.respawn_items = map
  end,
  set_skip_intro = function(bool)
    global.skip_intro = bool
  end,
  set_chart_distance = function(value)
    global.chart_distance = tonumber(value)
  end
})


--Auto permisisons--
function get_permgroup()

    global.trustedgroup = game.permissions.get_group("Trusted")
    global.admingroup = game.permissions.get_group("Admin")
    
	if ( global.trustedgroup == nil ) then
		game.permissions.create_group("Trusted")
    end
    
    if ( global.admingroup == nil ) then
		game.permissions.create_group("Admin" )
    end
    
    global.trustedgroup = game.permissions.get_group("Trusted")
    global.admingroup = game.permissions.get_group("Admin")

    for _, player in pairs(game.connected_players) do
    if ( player and player.valid and player.connected and player.character and player.character.valid ) then
    
      if (player.admin) then
        if (player.permission_group ~= nil ) then
          if (player.permission_group.name ~= "Admin") then
            global.admingroup.add_player(player)
            message_debug ( player.name .. " moved to admins..." )
	    player.print("Welcome back, " .. player.name .. "! Moving you to admins group... Have fun!" )
          end
        end
		
        for _, player in pairs(game.connected_players) do
	for _, regular in pairs(regulars) do
	  if ( regular == player.name ) then
			if (player.permission_group.name == "Default" ) then
				global.trustedgroup.add_player(player)
				message_debug ( player.name .. " moved to regulars..." )
				player.print ( "Welcome back, " .. player.name .. "! Moving you into trusted users group... Have fun!" )
			end
	  end
	end
	end
        
      else
        if ( global.actual_playtime and global.actual_playtime[player.index] and global.actual_playtime[player.index] > ( 30 * 60 * 60 ) ) then
          if ( player.permission_group ~= nil and player.permission_group.name == "Default" ) then
            if ( global.trustedgroup.add_player( player ) == true ) then
			  player.print ( "(SERVER) You have now been playing long enough, that the new-user restrictions on your character have been lifted... Have fun, and be nice!" )
			  player.print ( "(SERVER) Discord server: Link on page at: http://BHMM.NET/" )
              message_debug ( player.name .. " was moved to trusted users." )
            end
          end
        end
        
      end
  end
  end
end

script.on_event(defines.events.on_built_entity, function(event)
	local player = game.players[event.player_index]
	local created_entity = event.created_entity
	local surface = created_entity.surface

	if ( not global.actual_playtime ) then
		global.actual_playtime = {}
		global.actual_playtime[0] = 0
	end

	if ( global.actual_playtime and global.actual_playtime[player.index] ) then
		global.actual_playtime[player.index] = global.actual_playtime[player.index] + 1
	else
		global.actual_playtime[player.index] = 0.0
	end

	if player and created_entity and surface then
		if created_entity.name == "programmable-speaker" then
			message = (player.name .. " placed speaker: " .. math.floor(created_entity.position.x) .. "," .. math.floor(created_entity.position.y) )
			message_debug(message)

			if ( not global.speakerlist ) then
				global.speakerlist = { pin = {}, speaker = {}, tick = {}, pos = {}, }
			end

			local chartTag = {position=created_entity.position, icon={type="item",name="programmable-speaker"}, text=label}
			qtag = player.force.add_chart_tag ( player.surface, chartTag )
		
			table.insert(global.speakerlist, { pin = qtag, speaker = created_entity, tick = game.tick, pos = created_entity.position })
		end
	end
	
end)

--Console chat can activate this
script.on_event(defines.events.on_console_chat, function(event)
	if ( event and event.player_index ) then
		local player = game.players[event.player_index]

		if ( not global.actual_playtime ) then
			global.actual_playtime = {}
			global.actual_playtime[0] = 0
		end

		if ( player and player.valid ) then

			if ( global.actual_playtime and global.actual_playtime[player.index] ) then
				global.actual_playtime[player.index] = global.actual_playtime[player.index] + 1
			else	
				global.actual_playtime[player.index] = 0.0
			end
		end
	end
end)

script.on_event(defines.events.on_pre_player_mined_item, function(event)
	local player = game.players[event.player_index]
	local mined_entity = event.entity

	if ( not global.actual_playtime ) then
		global.actual_playtime = {}
		global.actual_playtime[0] = 0
	end

	if ( global.actual_playtime and global.actual_playtime[player.index] ) then
		global.actual_playtime[player.index] = global.actual_playtime[player.index] + 1
	else
		global.actual_playtime[player.index] = 0.0
	end

	if player and mined_entity then
		if mined_entity.name == "programmable-speaker" then

		end
	end
end)

script.on_event(defines.events.on_player_changed_position, function(event)
	local player = game.players[event.player_index]

	if ( not global.actual_playtime ) then
		global.actual_playtime = {}
		global.actual_playtime[0] = 0
	end
	
	if ( global.actual_playtime and global.actual_playtime[player.index] ) then
		global.actual_playtime[player.index] = global.actual_playtime[player.index] + ( 6.67 ) --Estimate... 
	else
		global.actual_playtime[player.index] = 0.0
	end
end)

--Corpse Marker
script.on_event(defines.events.on_pre_player_died, function(event)
	if ( not global.corpselist ) then
		global.corpselist = { tag = {}, tick = {}, }
	end  

	local player = game.players[event.player_index]
	local centerPosition = player.position
	local label = "Corpse of: " .. player.name .. " " .. math.floor(player.position.x) .. "," .. math.floor(player.position.y)
	local chartTag = {position=centerPosition, icon=signalID, text=label}
	qtag = player.force.add_chart_tag ( player.surface, chartTag )

	table.insert(global.corpselist, { tag = qtag, tick = game.tick, }  )
end)

--Tick loop--
--Keep to minimum--
script.on_event(defines.events.on_tick, function(event)

if ( not global.last_s_tick ) then
	global.last_s_tick = 0
end

if (game.tick - global.last_s_tick >= 600 ) then
	toremove = -1
	x = 1
	--Remove old corpse tags
	if ( global.corpselist ) then
		for _, corpse in pairs(global.corpselist) do
			if ( corpse.tick and ( corpse.tick + (15 * 60 * 60) ) < game.tick ) then
				if ( corpse.tag and corpse.tag.valid ) then
	  				corpse.tag.destroy()
				--else
					--message_debug("Corpse map tag was no longer there!")
				end
				toremove = x
				break
			end
			x = x + 1
		end
	end
	if ( toremove >= 0 and global.corpselist) then
			table.remove(global.corpselist, toremove)
	end

	--Remove old speakertags
	toremove = -1
	x = 1
	if ( global.speakerlist ) then
		for _, speaker in pairs(global.speakerlist) do

			--If the speaker isn't there anymore, remove the tag
			if ( not speaker.speaker ) then
				if ( speaker.pin and speaker.pin.valid ) then
					--message_debug ("Speaker was nil.")
					speaker.pin.destroy()
				end
				toremove = x
				break
			end
			--If the speaker isn't valid anymore, remove the tag
			if ( speaker.speaker ) then
				if ( not speaker.speaker.valid ) then 
					if ( speaker.pin and speaker.pin.valid ) then
						--message_debug ("Speaker was invalid.")
						speaker.pin.destroy()
					end
					toremove = x
					break
				end
			end
			x = x + 1
		end
	end
	if ( toremove >= 0 and global.speakerlist ) then
		table.remove(global.speakerlist, toremove)
		--message_debug("Corpse tag removed")
	end

	
	if ( global.servertag and not global.servertag.valid ) then
			global.servertag = nil
	end
	if ( global.servertag and global.servertag.valid ) then
		global.servertag.destroy()
		global.servertag = nil
        end
	if ( not global.servertag ) then
		local label = "Discord: BHMM.NET"
		local chartTag = {position={0,0}, icon={type="item",name="programmable-speaker"}, text=label}
		global.servertag = game.forces['player'].add_chart_tag ( game.surfaces["nauvis"], chartTag )
	end

	get_permgroup()
	global.last_s_tick = game.tick
	
end

end)

--Debug messages--
function message_debug(message)

  for _, player in pairs(game.connected_players) do

    if (player.admin) then
	  player.print( "(INFO) " .. message)
	  print(message)
      return
    end
	
  end

end

--global messages--
function message_all(message)

	for _, player in pairs(game.connected_players) do

		player.print( message)
		print(message)
		return
	  
	end
  
  end

