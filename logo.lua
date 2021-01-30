--Add M45 Logo to spawn area
function dodrawlogo()
    if game.surfaces[1] then
      --Only draw if needed
      if not global.drawlogo then
        --Destroy if already exists
        if global.m45logo then
          rendering.destroy(global.m45logo)
        end
        if global.m45logo_light then
          rendering.destroy(global.m45logo_light)
        end
        if global.m45text then
          rendering.destroy(global.m45text)
        end
        if global.servtext then
          rendering.destroy(global.servtext)
        end
  
        --Get spawn position
        local cpos = {x = 0, y = 0}
        if global.cspawnpos and global.cspawnpos.x then
          cpos = global.cspawnpos
        end
  
        --Find nice clear area for spawn
        local newpos = game.surfaces[1].find_non_colliding_position("crash-site-spaceship", cpos, 1000, 0.1, false)
        --Set spawn position if we found a better spot
        if newpos and newpos.x ~= 0 and newpos.y ~= 0 then
          cpos = newpos
          global.cspawnpos = newpos
        end
  
        --Set drawn flag
        global.drawlogo = true
        global.m45logo =
          rendering.draw_sprite {
          sprite = "file/img/world/m45-pad-v4.png",
          render_layer = "floor",
          target = cpos,
          x_scale = 0.5,
          y_scale = 0.5,
          surface = game.surfaces[1]
        }
        global.m45logo_light =
          rendering.draw_light {
          sprite = "utility/light_medium",
          render_layer = 148,
          target = cpos,
          scale = 8,
          surface = game.surfaces[1],
          minimum_darkness = 0.5
        }
        if not global.servname then
          global.servname = ""
        end
        global.m45text =
          rendering.draw_text {
          text = "M45-Science",
          draw_on_ground = true,
          surface = game.surfaces[1],
          target = {cpos.x + -0.125, cpos.y - 0.75},
          scale = 1.25,
          color = {1, 1, 1},
          alignment = "center",
          scale_with_zoom = false
        }
        global.servtext =
          rendering.draw_text {
          text = global.servname,
          draw_on_ground = true,
          surface = game.surfaces[1],
          target = {cpos.x - 0.125, cpos.y + 2.125},
          scale = 1.0,
          color = {1, 1, 1},
          alignment = "center",
          scale_with_zoom = false
        }
      end
    end
  end