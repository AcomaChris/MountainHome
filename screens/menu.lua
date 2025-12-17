-- Placeholder menu screen for Phase 0 navigation prototype.
-- Displays basic text and listens for Enter to continue (emits an event) or Escape to quit.

local bus = require('lib.event_bus')

local MenuScreen = {
    title = "Mountain Home",
    subtitle = "Phase 0 Prototype",
    info = "Press Enter to continue (event only). Press Esc to quit.",
}

-- Called when entering the menu
function MenuScreen.enter(ctx)
    -- Store last transition for debugging visibility
    MenuScreen.last_transition = ctx
end

function MenuScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.1, 0.1, 0.12)

    local y = h * 0.35
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(MenuScreen.title, 0, y, w, "center")

    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.printf(MenuScreen.subtitle, 0, y + 32, w, "center")

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.printf(MenuScreen.info, 0, y + 64, w, "center")

    if MenuScreen.last_transition then
        love.graphics.setColor(0.6, 0.6, 0.8)
        local msg = string.format("from: %s  to: %s", tostring(MenuScreen.last_transition.from), tostring(MenuScreen.last_transition.to))
        love.graphics.printf(msg, 0, y + 96, w, "center")
    end
end

function MenuScreen.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "return" or key == "kpenter" then
        -- Emit an event that can be picked up by other systems/screens later.
        bus.emit("menu:continue", { from = "menu" })
    end
end

return MenuScreen

