-- Placeholder intro screen for Phase 0. Shows simple text and returns to menu on any key.

local bus = require('lib.event_bus')

local IntroScreen = {
    title = "Studio Intro",
    info = "Press any key to return to menu.",
    timer = 0,
    display_time = 0, -- not used yet; placeholder for future timed sequence
}

function IntroScreen.enter(ctx)
    IntroScreen.timer = 0
    IntroScreen.last_transition = ctx
end

function IntroScreen.update(dt)
    IntroScreen.timer = IntroScreen.timer + dt
end

function IntroScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.08, 0.09, 0.11)

    local y = h * 0.4
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.printf(IntroScreen.title, 0, y, w, "center")

    love.graphics.setColor(0.7, 0.9, 0.8)
    love.graphics.printf(IntroScreen.info, 0, y + 32, w, "center")

    if IntroScreen.last_transition then
        love.graphics.setColor(0.6, 0.7, 0.9)
        local msg = string.format("from: %s  to: %s", tostring(IntroScreen.last_transition.from), tostring(IntroScreen.last_transition.to))
        love.graphics.printf(msg, 0, y + 64, w, "center")
    end
end

function IntroScreen.keypressed()
    -- Emit event to go back to menu
    bus.emit("intro:done", { from = "intro" })
end

return IntroScreen

