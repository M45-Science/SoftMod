--Carl Frank Otto III
--carlotto81@gmail.com
--GitHub: https://github.com/Distortions81/M45-SoftMod
--License: MPL 2.0

--Safe console print
function console_print(message)
  if message then
    print(message)
  end
end

--Smart/safe Print
function smart_print(player, message)
  if message then
    if player then
      player.print(message)
    else
      rcon.print(message)
    end
  end
end

--Global messages (game/discord)
function message_all(message)
  if message then
    game.print(message)
    print("[MSG] " .. message)
  end
end

--System messages (game/discord)
function gsysmsg(message)
  if message then
    game.print("[color=orange](SYSTEM)[/color] [color=red]" .. message .. "[/color]")
    print("[MSG] " .. message)
  end
end

--Global messages (game only)
function message_allp(message)
  if message then
    game.print(message)
  end
end

--Global messages (discord only)
function message_alld(message)
  if message then
    print("[MSG] " .. message)
  end
end

--Calculate distance between two points
function dist_to(pos_a, pos_b)
  if pos_a and pos_b and pos_a.x and pos_a.y and pos_b.x and pos_b.y then
    local axbx = pos_a.x - pos_b.x
    local ayby = pos_a.y - pos_b.y
    return (axbx * axbx + ayby * ayby) ^ 0.5
  else
    return 10000000
  end
end

--Show players online to a player
function show_players(victim)
  local buf = ""
  local count = 0

  --For console use
  if not victim then
    buf = "[ONLINE] "
    if global.player_list then
      for i, target in pairs(global.player_list) do
        if target and target.victim and target.victim.connected then
          buf = buf .. target.victim.name ..  "," .. target.score .. ","..target.time..","..target.type..";"
        end
      end
    end

    print(buf)
    return
  end

  if global.player_list then
    for i, target in pairs(global.player_list) do
      if target and target.victim and target.victim.connected then
        buf = buf .. string.format("~%16s: - Score: %d - Online: %dm - (%s)\n", target.victim.name, math.floor(target.score / 60 / 60), math.floor(target.time / 60 / 60), target.type)
      end
    end
  end

  --No one is online
  if not global.player_count or global.player_count == 0 then
    smart_print(victim, "No players online.")
  else
    smart_print(victim, "Players Online: " .. global.player_count .. "\n" .. buf)
  end
end

--Split strings
function mysplit(inputstr, sep)
  if inputstr and sep and inputstr ~= "" then
    local t = {}
    local x = 0

    --Handle nil/empty strings
    if not sep or not inputstr then
      return t
    end
    if sep == "" or inputstr == "" then
      return t
    end

    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
      x = x + 1
      if x > 100 then --Max 100 args
        break
      end

      table.insert(t, str)
    end
    return t
  end
  return {""}
end

--Quickly turn tables into strings
function dump(o)
  if type(o) == "table" then
    local s = "{ "
    for k, v in pairs(o) do
      if type(k) ~= "number" then
        k = '"' .. k .. '"'
      end
      s = s .. "[" .. k .. "] = " .. dump(v) .. ","
    end
    return s .. "} "
  else
    return tostring(o)
  end
end

--Cut off extra precision
function round(number, precision)
  local fmtStr = string.format("%%0.%sf", precision)
  number = string.format(fmtStr, number)
  return number
end


--Check if player is flagged patreon
function is_patreon(victim)
  if victim and victim.valid then
    if not global.patreons then
      global.patreons = {}
    end
    if global.patreons and global.patreons[victim.index] then
      return global.patreons[victim.index]
    else
      global.patreons[victim.index] = false
      return false
    end
  end

  return false
end

--Check if player is flagged nitro
function is_nitro(victim)
  if victim and victim.valid then
    if not global.nitros then
      global.nitros = {}
    end
    if global.nitros and global.nitros[victim.index] then
      return global.nitros[victim.index]
    else
      global.nitros[victim.index] = false
      return false
    end
  end

  return false
end

--permissions system
--Check if player should be considered a regular
function is_regular(victim)
  if victim and victim.valid and not victim.admin then
    --If in group
    if victim.permission_group and global.regularsgroup then
      if victim.permission_group.name == global.regularsgroup.name or victim.permission_group.name == global.regularsgroup.name .. "_satellite" then
        return true
      end
    end
  end

  return false
end

--Check if player should be considered a member
function is_member(victim)
  if victim and victim.valid and not victim.admin then
    --If in group
    if victim.permission_group and global.membersgroup then
      if victim.permission_group.name == global.membersgroup.name or victim.permission_group.name == global.membersgroup.name .. "_satellite" then
        return true
      end
    end
  end

  return false
end

--Check if player should be considered new
function is_new(victim)
  if victim and victim.valid and not victim.admin then
    if is_member(victim) == false and is_regular(victim) == false then
      return true
    end
  end

  return false
end

--Check if player should be considered banished
function is_banished(victim)
  if victim and victim.valid and not victim.admin then
    --Admins can not be marked as banished
    if victim.admin then
      return false
    elseif global.thebanished and global.thebanished[victim.index] then
      if (is_new(victim) and global.thebanished[victim.index] >= 1) or (is_member(victim) and global.thebanished[victim.index] >= 2) or (is_regular(victim) and global.thebanished[victim.index] >= 2) then
        return true
      end
    end
  end

  return false
end

function send_to_default_spawn(victim)
  if victim and victim.valid and victim.character then
    local nsurf = game.surfaces["nauvis"] --Find default surface

    if nsurf then
      local pforce = victim.force
      local spawnpos = {0, 0}
      if pforce then
        spawnpos = pforce.get_spawn_position(nsurf)
      else
        console_print("send_to_default_spawn: victim does not have a valid force.")
      end
      local newpos = nsurf.find_non_colliding_position("character", spawnpos, 4096, 1, false)
      if newpos then
        victim.teleport(newpos, nsurf)
      else
        victim.teleport({0, 0}, nsurf)
      end
    else
      console_print("send_to_default_spawn: The surface nauvis does not exist, could not teleport victim.")
    end
  else
    console_print("send_to_default_spawn: victim invalid or dead")
  end
end

function send_to_surface_spawn(victim)
  if victim and victim.valid and victim.character then
    local nsurf = victim.surface
    if nsurf then
      local pforce = victim.force
      local spawnpos = {0, 0}
      if pforce then
        spawnpos = pforce.get_spawn_position(nsurf)
      else
        console_print("send_to_surface_spawn: victim force invalid")
      end
      local newpos = nsurf.find_non_colliding_position("character", spawnpos, 4096, 1, false)
      if newpos then
        victim.teleport(newpos, nsurf)
      else
        victim.teleport({0, 0}, nsurf)
      end
    else
      console_print("send_to_surface_spawn: The surface does not exist, could not teleport victim.")
    end
  else
    console_print("send_to_surface_spawn: victim invalid or dead")
  end
end

function get_default_spawn()
  local nsurf = game.surfaces["nauvis"]
  if nsurf then
    local pforce = game.forces["player"]
    if pforce then
      local spawnpos = pforce.get_spawn_position(nsurf)
      return spawnpos
    else
      console_print("get_default_spawn: Couldn't find force 'player'")
      return {0, 0}
    end
  else
    console_print("get_default_spawn: Couldn't find default surface nauvis.")
    return {0, 0}
  end
end
