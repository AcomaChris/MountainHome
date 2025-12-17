-- Placeholder intro screen for Phase 0. Shows simple text and returns to menu on any key.

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')

local IntroScreen = {
    title = "Studio Intro",
    info = "Tap the button to return to menu.",
    timer = 0,
    display_time = 0, -- not used yet; placeholder for future timed sequence
    buttons = {},
    sprite = nil,
    sprite_w = 0,
    sprite_h = 0,
    spawn_delay = 1.0,
    pop_duration = 0.4,
    pop_progress = 0,
    visible = false,
    pos = { x = 0, y = 0 },
    target = nil,
    start_pos = nil,
    move_elapsed = 0,
    move_duration = 0,
    move_cooldown = 0,
    moving = false,
}

function IntroScreen.enter(ctx)
    IntroScreen.timer = 0
    IntroScreen.last_transition = ctx
    IntroScreen.visible = false
    IntroScreen.pop_progress = 0
    IntroScreen.move_elapsed = 0
    IntroScreen.move_duration = 0
    IntroScreen.moving = false
    IntroScreen.move_cooldown = love.math.random(3, 8)

    if not IntroScreen.sprite then
        IntroScreen.sprite = love.graphics.newImage("RAW/Sprites/Char_McJaggy_Idle00.png")
        IntroScreen.sprite_w = IntroScreen.sprite:getWidth()
        IntroScreen.sprite_h = IntroScreen.sprite:getHeight()
    end

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 220, 44
    local y = h * 0.5
    IntroScreen.buttons = {
        UIButton.new("Back to Menu", (w - btn_w) / 2, y, btn_w, btn_h, function()
            bus.emit("intro:done", { from = "intro" })
        end),
    }

    -- Start McJaggy at center before first move
    IntroScreen.pos.x = w * 0.5
    IntroScreen.pos.y = h * 0.4
end

function IntroScreen.update(dt)
    IntroScreen.timer = IntroScreen.timer + dt
    -- Handle delayed spawn with pop-in scale animation
    if not IntroScreen.visible and IntroScreen.timer >= IntroScreen.spawn_delay then
        IntroScreen.visible = true
        IntroScreen.pop_progress = 0
    end
    if IntroScreen.visible and IntroScreen.pop_progress < IntroScreen.pop_duration then
        IntroScreen.pop_progress = math.min(IntroScreen.pop_progress + dt, IntroScreen.pop_duration)
    end

    -- Random movement every 3-8 seconds with easing and bobbing
    if IntroScreen.visible then
        IntroScreen.move_cooldown = IntroScreen.move_cooldown - dt
        if IntroScreen.move_cooldown <= 0 and not IntroScreen.moving then
            local w, h = love.graphics.getWidth(), love.graphics.getHeight()
            local pad = 80
            IntroScreen.start_pos = { x = IntroScreen.pos.x, y = IntroScreen.pos.y }
            IntroScreen.target = {
                x = love.math.random(pad, w - pad),
                y = love.math.random(pad, h - pad * 1.5)
            }
            IntroScreen.move_duration = 0.9
            IntroScreen.move_elapsed = 0
            IntroScreen.moving = true
            IntroScreen.move_cooldown = love.math.random(3, 8)
        end

        if IntroScreen.moving then
            IntroScreen.move_elapsed = IntroScreen.move_elapsed + dt
            local t = math.min(IntroScreen.move_elapsed / IntroScreen.move_duration, 1)
            local eased = 1 - (1 - t) * (1 - t) -- ease-out quad
            IntroScreen.pos.x = IntroScreen.start_pos.x + (IntroScreen.target.x - IntroScreen.start_pos.x) * eased
            IntroScreen.pos.y = IntroScreen.start_pos.y + (IntroScreen.target.y - IntroScreen.start_pos.y) * eased
            if t >= 1 then
                IntroScreen.moving = false
                IntroScreen.pos.x = IntroScreen.target.x
                IntroScreen.pos.y = IntroScreen.target.y
            end
        end
    end
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

    -- Draw McJaggy with pop-in scale and bobbing bounce
    if IntroScreen.visible and IntroScreen.sprite then
        local base_scale = IntroScreen.pop_progress / IntroScreen.pop_duration
        local scale = math.max(0, math.min(base_scale, 1))
        local bob = math.sin(love.timer.getTime() * 9) * 6
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            IntroScreen.sprite,
            IntroScreen.pos.x,
            IntroScreen.pos.y + bob,
            0,
            scale,
            scale,
            IntroScreen.sprite_w / 2,
            IntroScreen.sprite_h / 2
        )
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

