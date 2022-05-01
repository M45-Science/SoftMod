--Carl Frank Otto III
--carlotto81@gmail.com

--Add M45 Logo to spawn area
function dodrawlogo()
  local msurf = game.surfaces["nauvis"]
  if msurf then
    --Only draw if needed
    if not global.drawlogo then
      --Destroy if already exists
      if global.m45logo then
        rendering.destroy(global.m45logo)
      end
      if global.m45logo_light then
        rendering.destroy(global.m45logo_light)
      end
      if global.servtext then
        rendering.destroy(global.servtext)
      end

      --Get spawn position
      local cpos = get_default_spawn()

      --Find nice clear area for spawn
      local newpos = msurf.find_non_colliding_position("crash-site-spaceship", cpos, 4096, 1, false)
      --Set spawn position if we found a better spot
      if newpos then
        cpos = newpos
        local pforce = game.forces["player"]
        if pforce then
          pforce.set_spawn_position(cpos, msurf)
        else
          console_print("dodrawlogo: Player force not found.")
        end
      end

      --Set drawn flag
      global.drawlogo = true
      global.m45logo =
        rendering.draw_sprite {
        sprite = "file/img/world/m45-pad-v5.png",
        render_layer = "floor",
        target = cpos,
        x_scale = 0.5,
        y_scale = 0.5,
        surface = msurf
      }
      global.m45logo_light =
        rendering.draw_light {
        sprite = "utility/light_medium",
        render_layer = 148,
        target = cpos,
        scale = 8,
        surface = msurf,
        minimum_darkness = 0.5
      }
      if not global.servname then
        global.servname = ""
      end
      global.servtext =
        rendering.draw_text {
        text = global.servname,
        draw_on_ground = true,
        surface = msurf,
        target = {cpos.x - 0.125, cpos.y + 2.125},
        scale = 1.0,
        color = {1, 1, 1},
        alignment = "center",
        scale_with_zoom = false
      }
    end
  end
end
