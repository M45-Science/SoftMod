function make_reset_clock(player)
    --Online button--
    if player.gui.top.reset_clock then
      player.gui.top.reset_clock.destroy()
    end
    if not player.gui.top.reset_clock then
      local rclock =
      player.gui.top.add {
        type = "button",
        name = "reset_clock",
        style = "red_button",
      }
    end
  end