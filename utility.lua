--Safe console print
function console_print(message)
  if message then
    print("~" .. message)
  end
end

--Smart/safe Print
function smart_print(player, message)
  if message then
    if player then
      player.print(message)
    else
      rcon.print("~ " .. message)
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

function is_sameobj(obj_a, obj_b)
  --Valid objects?
  if obj_a and obj_b and obj_a.valid and obj_b.valid then
    --Same surface?
    if obj_a.surface.name == obj_b.surface.name then
      --Same name and type?
      if obj_a.object_name == obj_b.object_name and obj_a.type == obj_b.type then
        --Same position?
        if obj_a.position.x == obj_b.position.x and obj_a.position.y == obj_b.position.y then
          return true
        end
      end
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
      if (is_new(victim) and global.thebanished[victim.index] >= 1) or
      (is_member(victim) and global.thebanished[victim.index] >= 2) or
      (is_regular(victim) and global.thebanished[victim.index] >= 2) then
        return true
      end
    end
  end

  return false
end
