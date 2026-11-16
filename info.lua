-- Carl Frank Otto III
-- carlotto81@gmail.com
-- GitHub: https://github.com/M45-Science/SoftMod
-- License: MPL 2.0

function INFO_MakeClock(player)
    -- Online button--
    if player.gui.top.reset_clock then
        player.gui.top.reset_clock.destroy()
    end
    if not player.gui.top.reset_clock then
        local rclock = player.gui.top.add {
            type = "button",
            name = "reset_clock",
            style = "red_button",
            tooltip = {"strings.reset_clock_tooltip"},
            visible = false,
        }

        UTIL_DrawMapClock(player)
    end
end

function INFO_MakeButton(player)
    if not (player and player.valid and player.gui and player.gui.top) then
        return
    end
    if player.gui.top.m45_button then
        player.gui.top.m45_button.destroy()
    end
    if not player.gui.top.m45_button then
        local m45_32 = player.gui.top.add {
            type = "sprite-button",
            name = "m45_button",
            sprite = "file/img/buttons/m45-64.png",
            tooltip = {"strings.m45_button_tooltip"}
        }
        m45_32.style.size = { 72, 72 }
        m45_32.style.padding = 0
    end
end

-- Help/Info now uses the same compact panel as the join introduction.
function INFO_InfoWin(player)
    if player and player.valid then ESSENTIALS_Open(player) end
end

function INFO_Clicks(event)
    if not (event and event.element and event.element.valid and event.player_index) then return end
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then return end
    UTIL_ConsolePrint("[ACT] GUI_CLICK: " .. player.name .. ": " .. event.element.name)
    if event.element.name == "m45_button" then
        ESSENTIALS_Toggle(player)
    elseif event.element.name == "reset_clock" then
        if player.gui.top.reset_clock and storage.PData then
            local pdata = storage.PData[player.index]
            if pdata.hideClock and storage.SM_Store.resetDuration ~= "" then
                pdata.hideClock = false
            elseif event.button == defines.mouse_button_type.right and event.control then
                pdata.hideClock = true
            end
        end
        UTIL_DrawMapClock(player)
    end
end

-- Compatibility hooks for the central dispatcher; the new UI has no tabs or editable links.
function INFO_TabChanged() end
function INFO_TextChanged() end
