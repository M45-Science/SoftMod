--Carl Frank Otto III
--carlotto81@gmail.com

--Create globals, if needed
function create_myglobals()
  global.svers = "573-1162021-1243-exp"

  if not global.restrict == nil then
    global.restrict = true
  end
  if not global.playeractive then
    global.playeractive = {}
  end
  if not global.active_playtime then
    global.active_playtime = {}
  end
  if not global.blueprint_throttle then
    global.blueprint_throttle = {}
  end

  if not global.patreons then
    global.patreons = {}
  end
  if not global.nitros then
    global.nitros = {}
  end

  if not global.last_speaker_warning then
    global.last_speaker_warning = 1
  end
  if not global.last_decon_warning then
    global.last_decon_warning = 1
  end

  if not global.corpselist then
    global.corpselist = {}
  end
  make_banish_globals()
  if not global.no_fastreplace then
    global.no_fastreplace = false
  end

  if not global.info_shown then
    global.info_shown = {}
  end
end

--Create player globals, if needed
function create_player_globals(player)
  if player and player.valid then
    if global.playeractive and player and player.index then
      if not global.playeractive[player.index] then
        global.playeractive[player.index] = false
      end

      if not global.active_playtime[player.index] then
        global.active_playtime[player.index] = 0
      end

      if not global.blueprint_throttle[player.index] then
        global.blueprint_throttle[player.index] = 0
      end

      if not global.thebanished[player.index] then
        global.thebanished[player.index] = 0
      end
    end
  end
end
