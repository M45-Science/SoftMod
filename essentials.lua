-- One non-modal introduction to the server's tools after a player starts playing.
local PANEL = "m45_essentials"
local DELAY = 8 * 60
local DISCORD_INVITE = "https://discord.gg/rQANzBheVh"
local PATREON_URL = "https://www.patreon.com/m45sci"
local BACK_CAPTION = "[img=utility/backward_arrow] Back"
local PAGE_TITLES = {home = "M45 essentials", membership = "Membership & Voting", discord = "Discord", patreon = "Patreon"}
local activity_events = {
    [defines.events.on_built_entity] = true,
    [defines.events.on_pre_player_mined_item] = true,
    [defines.events.on_marked_for_deconstruction] = true,
    [defines.events.on_player_repaired_entity] = true,
    [defines.events.on_console_chat] = true,
    [defines.events.on_gui_click] = true,
}

local function state(player)
    local pdata = storage.PData and storage.PData[player.index]
    return pdata and pdata.essentials
end

local function close(player)
    local panel = player.gui.screen[PANEL]
    if panel then panel.destroy() end
end

function ESSENTIALS_Join(player)
    close(player)
    storage.PData[player.index].essentials = {waiting = true}
end

function ESSENTIALS_Leave(player)
    close(player)
    local pdata = storage.PData and storage.PData[player.index]
    if pdata then pdata.essentials = nil end
end

function ESSENTIALS_Activity(event)
    local player = event.player_index and game.get_player(event.player_index)
    if not (player and player.valid and player.connected) then return end
    local s = state(player)
    if not (s and s.waiting) then return end
    local walking = event.name == defines.events.on_player_changed_position
        and player.walking_state.walking
    if walking or activity_events[event.name] then
        s.waiting = nil
        s.remaining = DELAY
        s.last_tick = game.tick
    end
end

function ESSENTIALS_Resize(player)
    local panel = player.gui.screen[PANEL]
    if not panel then return end
    local scale = player.display_scale
    local resolution = player.display_resolution
    local height = resolution.height / scale
    local width = math.floor(math.min(640, resolution.width / scale - 24))
    local compact = height < 700
    local card_height = compact and 80 or 88
    local row_gap = compact and 6 or 12
    local estimated_height = panel.tags.page == "membership" and 620 or (3 * (card_height + row_gap) + 140)
    local top = math.max(12, math.min(400, height - estimated_height - 16))
    panel.style.width = width
    panel.body.style.width = width - 24
    panel.body.grid.style.width = width - 24
    panel.body.credits.style.width = width - 24
    for _, container in ipairs({panel.body.membership_page, panel.body.discord_page, panel.body.patreon_page, panel.body.credits}) do
        container.style.width = width - 24
        for _, element in pairs(container.children) do
            if element.type == "label" then
                element.style.maximal_width = width - 24
                element.style.horizontally_squashable = true
            elseif element.type == "textfield" then
                element.style.width = width - 24
            end
        end
    end
    panel.body.membership_page.banish.description.style.maximal_width = width - 108
    panel.body.membership_page.banish.description.style.horizontally_squashable = true
    local rank_width = math.min(104, math.floor((width - 24) / 4))
    for i, label in ipairs(panel.body.membership_page.levels.children) do
        label.style.maximal_width = i % 2 == 1 and rank_width or (width - 36 - rank_width)
        label.style.horizontally_stretchable = i % 2 == 0
        label.style.horizontally_squashable = true
    end
    local column_width = math.floor((width - 36) / 2)
    for _, group in pairs(panel.body.grid.children) do
        if group.type == "frame" then
            group.style.width = column_width
            group.style.height = card_height
            group.style.vertical_align = "top"
            group.style.vertically_stretchable = true
            group.style.padding = compact and 4 or 8
            group.style.bottom_margin = compact and 6 or 12
            for _, element in pairs(group.children) do
                if element.type == "button" then element.style.height = compact and 24 or 28 end
                if element.type == "label" then
                    element.style.font = compact and "default-small" or "default"
                    element.style.maximal_width = column_width - 2 * (compact and 4 or 8)
                    element.style.horizontally_squashable = true
                end
            end
        end
    end
    panel.location = {x = math.max(0, math.floor(resolution.width - (width + 12) * scale)), y = math.floor(top * scale)}
end

local function fill_credits(group)
    group.clear()
    local title = group.add{type = "label", caption = "Thanks to our supporters", style = "bold_label"}
    title.style.single_line = false
    title.style.horizontally_stretchable = true
    local names, seen = {}, {}
    for _, name in ipairs(storage.SM_Store.patreonCredits or {}) do
        if name ~= "" and not seen[string.lower(name)] then
            names[#names + 1] = name
            seen[string.lower(name)] = true
        end
    end
    table.sort(names, function(a, b) return string.lower(a) < string.lower(b) end)
    if #names > 0 then
        local label = group.add{type = "label", name = "names", caption = table.concat(names, ", ")}
        label.style.single_line = false
        label.style.horizontally_stretchable = true
        label.style.rich_text_setting = defines.rich_text_setting.disabled
        label.style.font_color = {r = 0.85, g = 0.72, b = 1}
    end
end

function ESSENTIALS_RefreshCredits(player)
    local panel = player.gui.screen[PANEL]
    if panel then fill_credits(panel.body.credits) end
end

local function show(player)
    close(player)
    local panel = player.gui.screen.add{type = "frame", name = PANEL, direction = "vertical"}
    local titlebar = panel.add{type = "flow", name = "titlebar", direction = "horizontal"}
    titlebar.style.horizontally_stretchable = true
    titlebar.style.vertical_align = "center"
    titlebar.drag_target = panel
    local logo = titlebar.add{type = "sprite", name = "logo", sprite = "file/img/info-win/m45-128.png"}
    logo.style.size = {28, 28}
    logo.style.stretch_image_to_widget_size = true
    titlebar.add{type = "label", name = "title", caption = "M45 essentials", style = "frame_title"}
    local drag = titlebar.add{type = "empty-widget", style = "draggable_space_header"}
    drag.style.horizontally_stretchable = true
    drag.style.height = 24
    drag.drag_target = panel
    local body = panel.add{type = "flow", name = "body", direction = "vertical"}
    local grid = body.add{type = "table", name = "grid", column_count = 2}
    grid.style.horizontal_spacing = 12
    grid.style.vertical_spacing = 0
    grid.style.vertical_align = "top"
    local function section(button, title, description)
        local group = grid.add{type = "frame", name = button .. "_section",
            direction = "vertical", style = "inside_shallow_frame_with_padding"}
        group.style.horizontally_stretchable = true
        group.style.padding = 8
        group.style.bottom_margin = 12
        local action = group.add{type = "button", name = button, caption = title}
        action.style.horizontally_stretchable = true
        action.style.horizontal_align = "left"
        local text = group.add{type = "label", caption = description}
        text.style.top_margin = 4
        text.style.single_line = false
        text.style.horizontally_stretchable = true
        return group
    end
    section("essentials_membership", "[virtual-signal=signal-info] Membership", "Your score, levels, banish, and map voting.")
    section("essentials_players", "[img=utility/side_menu_players_icon] Players", "See who's online and open player actions.")
    section("essentials_todo", "[img=utility/list_view] To-do", "See what the team is working on.")
    section("essentials_toolbar", "[item=blueprint-book] Toolbar Manager", "Save and reuse your toolbar across maps.")
    section("essentials_discord", "[img=utility/side_menu_players_icon] Discord", "Community, help, and server news.")
    section("essentials_patreon", "[item=production-science-pack] Patreon", "Help keep the M45 servers running.")
    local credits = body.add{type = "flow", name = "credits", direction = "vertical"}
    credits.style.horizontally_stretchable = true
    fill_credits(credits)

    local function new_page(name)
        local page = body.add{type = "flow", name = name .. "_page", direction = "vertical"}
        page.style.horizontally_stretchable = true
        page.style.vertical_spacing = 8
        page.visible = false
        return page
    end
    local function paragraph(page, text, name)
        local label = page.add{type = "label", name = name, caption = text}
        label.style.single_line = false
        label.style.horizontally_stretchable = true
        return label
    end
    local membership = new_page("membership")
    paragraph(membership, "", "status").style.font = "default-bold"
    paragraph(membership, "Membership is automatic and free. Earn activity score by performing game actions; AFK time does not count. Score resets each map, but earned levels carry across maps.")
    local levels = membership.add{type = "table", name = "levels", column_count = 2}
    levels.style.horizontal_spacing = 12
    levels.style.vertical_spacing = 8
    local function rank(name, text)
        paragraph(levels, "[font=default-bold]" .. name .. "[/font]")
        paragraph(levels, text)
    end
    rank("1 · New", "Start here. Some actions are restricted.")
    rank("2 · Member", "Score 30: restrictions lift; 2 personal toolbar presets.")
    rank("3 · Regular", "Score 240: Banish and Map Vote unlock; 4 presets.")
    rank("4 · Veteran", "Regular + 72 hours of tracked playtime: double map vote; 8 presets.")
    paragraph(membership, "[font=default-bold]Banish · Regulars and above[/font]")
    local banish = membership.add{type = "flow", name = "banish", direction = "horizontal"}
    banish.style.horizontal_spacing = 12
    banish.style.vertical_align = "center"
    local players = banish.add{type = "sprite-button", name = "essentials_membership_players", sprite = "file/img/buttons/online-64.png", tooltip = "Open Players"}
    players.style.size = {72, 72}
    players.style.padding = 0
    paragraph(banish, "Open Players, select the player, enter a reason under Banish Player, then click VOTE TO BANISH. Successful votes move the player to confinement off-map; the votes needed depend on their level.", "description")
    paragraph(membership, "[font=default-bold]Map Vote · Regular Discord role or above[/font]\nIn this server's Discord chat, use /vote-map to start fresh, rewind to a save, or skip a scheduled reset. A choice needs 2 vote points; Veterans, supporters, and moderators count as 2.")
    paragraph(membership, "Use /register on Discord to link your Factorio account for Discord roles and voting. Supporters and admins can have 16 personal toolbar presets; membership does not require payment.")
    membership.add{type = "button", name = "essentials_membership_discord", caption = "[img=utility/side_menu_players_icon] Discord"}
    local discord = new_page("discord")
    discord.add{type = "sprite", sprite = "file/img/info-win/discord-64.png"}
    paragraph(discord, "Join the M45 community for chat, help, server news, and map voting.")
    local invite = discord.add{type = "textfield", name = "invite", text = DISCORD_INVITE}
    invite.read_only = true
    paragraph(discord, "Copy this invite with Ctrl+C, then open it in your browser or Discord.")
    local patreon = new_page("patreon")
    patreon.add{type = "sprite", sprite = "file/img/info-win/patreon-64.png"}
    paragraph(patreon, "Support M45's servers and community through Patreon. Supporting is optional; membership and levels are earned by playing.")
    local support_url = patreon.add{type = "textfield", name = "invite", text = PATREON_URL}
    support_url.read_only = true
    paragraph(patreon, "Copy this link with Ctrl+C, then open it in your browser to see the available support options.")
    local actions = panel.add{type = "flow", name = "actions", direction = "horizontal"}
    actions.style.horizontally_stretchable = true
    actions.add{type = "button", name = "essentials_help", caption = BACK_CAPTION, visible = false}
    local spacer = actions.add{type = "empty-widget"}
    spacer.style.horizontally_stretchable = true
    actions.add{type = "button", name = "essentials_close", caption = "[img=utility/check_mark] Got it"}
    ESSENTIALS_Resize(player)
    -- Do not set player.opened, focus a field, or center the panel.
end

-- Manual Help/Info access never consumes the shared reminder cooldown.
function ESSENTIALS_Open(player)
    STORAGE_EnsureGlobal()
    STORAGE_MakePlayerStorage(player)
    local old = player.gui.screen.m45_info_window
    if old then old.destroy() end
    local welcome = player.gui.screen.member_welcome
    if welcome then welcome.destroy() end
    storage.PData[player.index].essentials = {}
    show(player)
end

function ESSENTIALS_Toggle(player)
    if player.gui.screen[PANEL] then close(player) else ESSENTIALS_Open(player) end
end

function ESSENTIALS_Result(data)
    if type(data.name) ~= "string" then return end
    local player = UTIL_FindPlayer(data.name)
    if not (player and player.connected) then return end
    local s = state(player)
    if not (s and s.pending and s.pending == data.id) then return end
    s.pending = nil
    if data.allowed == true then
        s.ready = true
    end
end

local function busy(player)
    if player.opened ~= nil or not player.character then return true end
    for _, name in ipairs({"m45_info_window", "m45_todo", "quickbar_manager", "quickbar_exchange", "qb_rename_dialog", "qb_overwrite"}) do
        local window = player.gui.screen[name]
        if window and window.visible then return true end
    end
    return false
end

function ESSENTIALS_Tick()
    for _, player in pairs(game.connected_players) do
        local s = state(player)
        if s then
            if s.remaining then
                s.remaining = s.remaining - (game.tick - s.last_tick) / game.speed
                s.last_tick = game.tick
                if s.remaining <= 0 and storage.SM_Store.tool_hints and not busy(player) then
                    s.remaining = nil
                    storage.SM_Store.tool_hint_sequence = (storage.SM_Store.tool_hint_sequence or 0) + 1
                    s.pending = storage.SM_Store.tool_hint_sequence
                    CW_EmitEvent("tool-hint", {name = player.name, id = s.pending})
                end
            end
            if s.ready and not busy(player) then
                s.ready = nil
                show(player)
            end
        end
    end
end

local function open_page(player, page)
    local panel = player.gui.screen[PANEL]
    local tags = panel.tags
    local history = tags.history or {}
    if not page then
        page = table.remove(history) or "home"
    else
        history[#history + 1] = tags.page or "home"
    end
    for _, child in pairs(panel.body.children) do
        child.visible = page == "home" and (child.name == "grid" or child.name == "credits")
            or child.name == page .. "_page"
    end
    panel.tags = {page = page, history = history}
    panel.titlebar.title.caption = PAGE_TITLES[page]
    panel.actions.essentials_help.visible = page ~= "home"
    if page == "membership" then
        local pdata = storage.PData[player.index]
        local rank = player.admin and "Admin" or ({[0] = "New", "Member", "Regular", "Veteran"})[pdata.level or 0] or "New"
        panel.body.membership_page.status.caption = "Your level: " .. rank .. "   |   Activity score on this map: " .. math.floor((pdata.score or 0) / 3600)
    elseif page == "discord" or page == "patreon" then
        local field = panel.body[page .. "_page"].invite
        field.focus()
        field.select_all()
    end
end

function ESSENTIALS_OpenMembership(player)
    ESSENTIALS_Open(player)
    open_page(player, "membership")
    ESSENTIALS_Resize(player)
end

-- Reuse the Discord page for entry points outside the essentials panel.
function ESSENTIALS_OpenDiscord(player)
    ESSENTIALS_Open(player)
    open_page(player, "discord")
    ESSENTIALS_Resize(player)
end

function ESSENTIALS_Click(event)
    if not (event.element and event.element.valid) then return end
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then return end
    local panel = player.gui.screen[PANEL]
    if not panel then return end
    local element = event.element
    local parent = element
    while parent and parent ~= panel do parent = parent.parent end
    if not parent then return end
    local action = element.name
    if action == "essentials_close" then
        close(player)
    elseif action == "essentials_membership" then
        open_page(player, "membership")
    elseif action == "essentials_players" or action == "essentials_membership_players" then
        close(player)
        ONLINE_Window(player)
    elseif action == "essentials_discord" or action == "essentials_membership_discord" then
        open_page(player, "discord")
    elseif action == "essentials_patreon" then
        open_page(player, "patreon")
    elseif action == "essentials_todo" then
        close(player)
        TODO_MakeWindow(player)
    elseif action == "essentials_toolbar" then
        close(player)
        QUICKBAR_OpenManager(player)
    elseif action == "essentials_help" then
        open_page(player)
    end
    if player.gui.screen[PANEL] then ESSENTIALS_Resize(player) end
end

script.on_nth_tick(30, ESSENTIALS_Tick)
