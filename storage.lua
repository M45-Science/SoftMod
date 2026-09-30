-- Carl Frank Otto III
-- carlotto81@gmail.com
-- GitHub: https://github.com/M45-Science/SoftMod
-- License: MPL 2.0
local function ensure_global_tables()
    if not storage.PData then
        storage.PData = {}
    end
    if not storage.SM_Store then
        storage.SM_Store = {}
    end

    if not storage.SM_Store.resetDuration then
        storage.SM_Store.resetDuration = ""
    end
    if not storage.SM_Store.purge_tasks then
        storage.SM_Store.purge_tasks = {}
    end

    if not storage.SM_Store.restrictNew then
        storage.SM_Store.restrictNew = false
    end

    if not storage.SM_Store.patreonCredits then
        storage.SM_Store.patreonCredits = {}
    end
    if not storage.SM_Store.nitroCredits then
        storage.SM_Store.nitroCredits = {}
    end

    if not storage.SM_Store.votes then
        storage.SM_Store.votes = {}
    end
    if not storage.SM_Store.sendToSurface then
        storage.SM_Store.sendToSurface = {}
    end

    if not storage.SM_Store.noBlueprints then
        storage.SM_Store.noBlueprints = false
    end
    if not storage.SM_Store.oneLifeMode then
        storage.SM_Store.oneLifeMode = false
    end
    if not storage.SM_Store.cheats then
        storage.SM_Store.cheats = false
    end

    if not storage.SM_Store.onlineCache then
        storage.SM_Store.onlineCache = ""
    end
    if not storage.SM_Store.pcount then
        storage.SM_Store.pcount = 0
    end
    if not storage.SM_Store.tcount then
        storage.SM_Store.tcount = 0
    end
    if not storage.SM_Store.playerList then
        storage.SM_Store.playerList = {}
    end
    if storage.SM_Store.online_dirty == nil then
        storage.SM_Store.online_dirty = true
    end

    if not storage.SM_Store.redrawLogo then
        storage.SM_Store.redrawLogo = true
    end
    if not storage.SM_Store.serverName then
        storage.SM_Store.serverName = ""
    end

    if not storage.SM_Store.tickDiv then
        storage.SM_Store.tickDiv = 0
    end

    if storage.SM_Store.perms_static_applied == nil then
        storage.SM_Store.perms_static_applied = false
    end
end

function STORAGE_EnsureGlobal()
    ensure_global_tables()
end

function STORAGE_EnsureAllPlayers()
    local player_indices = {}
    for player_index, _ in pairs(game.players) do
        table.insert(player_indices, player_index)
    end
    table.sort(player_indices)
    for _, player_index in ipairs(player_indices) do
        local victim = game.players[player_index]
        STORAGE_MakePlayerStorage(victim)
    end
end

-- Create storage, if needed
function STORAGE_CreateGlobal()
    STORAGE_EnsureGlobal()
    STORAGE_EnsureAllPlayers()
end

-- Create player storage, if needed
function STORAGE_MakePlayerStorage(player)
    if not storage.PData then
        storage.PData = {}
    end
    if not storage.PData[player.index] then
        storage.PData[player.index] = {}
    end
    --score
    if not storage.PData[player.index].active then
        storage.PData[player.index].active = false
    end
    if not storage.PData[player.index].moving then
        storage.PData[player.index].moving = false
    end
    if not storage.PData[player.index].score then
        storage.PData[player.index].score = 0
    end
    if not storage.PData[player.index].lastOnline then
        storage.PData[player.index].lastOnline = game.tick
    end

    --prefs
    if not storage.PData[player.index].hideClock then
        storage.PData[player.index].hideClock = false
    end

    --state
    if storage.PData[player.index].manual_jail == nil then
        -- Legacy /jail used 1000 points, also used by an active moderator vote.
        local manual_jail = storage.PData[player.index].banished == 1000
        if manual_jail and storage.SM_Store and storage.SM_Store.votes then
            for _, vote in ipairs(storage.SM_Store.votes) do
                if vote.victim == player and vote.voter and vote.voter.valid and vote.voter.admin
                    and not vote.withdrawn and not vote.overruled then
                    manual_jail = false
                    break
                end
            end
        end
        storage.PData[player.index].manual_jail = manual_jail
    end
    if not storage.PData[player.index].cleaned then
        storage.PData[player.index].cleaned = false
    end
    if not storage.PData[player.index].patreon then
        storage.PData[player.index].patreon = false
    end
    if not storage.PData[player.index].nitro then
        storage.PData[player.index].nitro = false
    end

    --throttle
    if not storage.PData[player.index].regAttempts then
        storage.PData[player.index].regAttempts = 0
    end
    if not storage.PData[player.index].lastWarned then
        storage.PData[player.index].lastWarned = 0
    end
    if not storage.PData[player.index].reports then
        storage.PData[player.index].reports = 0
    end
    if not storage.PData[player.index].permDeath then
        storage.PData[player.index].permDeath = 0
    end

    --online menu
    if not storage.PData[player.index].onlineBrief then
        storage.PData[player.index].onlineBrief = false
    end
    if not storage.PData[player.index].onlineShowOffline then
        storage.PData[player.index].onlineShowOffline = false
    end

    if not storage.PData[player.index].level then
        storage.PData[player.index].level = 0
    end

    --promotion throttle
    if not storage.PData[player.index].nextPromoTick then
        storage.PData[player.index].nextPromoTick = 0
    end
    if not storage.PData[player.index].lastPromoScore then
        storage.PData[player.index].lastPromoScore = 0
    end

    --ui state
    if not storage.PData[player.index].info_tab_index then
        storage.PData[player.index].info_tab_index = 1
    end

    --admin tools
    if storage.PData[player.index].force_delete_armed == nil then
        storage.PData[player.index].force_delete_armed = false
    end
end
