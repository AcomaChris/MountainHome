-- Placeholder intro screen for Phase 0. Shows simple text and returns to menu on any key.

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')

local IntroScreen = {
    title = "Studio Intro",
    info = "Tap the button to return to menu.",
    timer = 0,
    display_time = 0, -- not used yet; placeholder for future timed sequence
    buttons = {},
}

function IntroScreen.enter(ctx)
    IntroScreen.timer = 0
    IntroScreen.last_transition = ctx

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 220, 44
    local y = h * 0.5
    IntroScreen.buttons = {
        UIButton.new("Back to Menu", (w - btn_w) / 2, y, btn_w, btn_h, function()
            bus.emit("intro:done", { from = "intro" })
        end),
    }
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

    for _, btn in ipairs(IntroScreen.buttons) do
        btn:draw()
    end
end

function IntroScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    for _, btn in ipairs(IntroScreen.buttons) do
        if btn:mousepressed(x, y) then
            return
        end
    end
end

return IntroScreen

