-- Placeholder intro screen for Phase 0. Shows simple text and returns to menu on any key.

local bus = require('lib.event_bus')
local log = require('lib.logger')

local IntroScreen = {
    title = "Studio Intro",
    info = "Press any key or click to continue",
    timer = 0,
    display_time = 0, -- not used yet; placeholder for future timed sequence
    -- McJaggy sprite
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
    vibrating = false,
    vibrate_timer = 0,
    vibrate_duration = 2.0, -- How long vibration lasts
    -- DMeowchi sprite
    sprite2 = nil,
    sprite2_w = 0,
    sprite2_h = 0,
    spawn_delay2 = 1.5,
    pop_progress2 = 0,
    visible2 = false,
    pos2 = { x = 0, y = 0 },
    target2 = nil,
    start_pos2 = nil,
    move_elapsed2 = 0,
    move_duration2 = 0,
    move_cooldown2 = 0,
    moving2 = false,
    vibrating2 = false,
    vibrate_timer2 = 0,
    vibrate_duration2 = 2.0, -- How long vibration lasts
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
    
    IntroScreen.visible2 = false
    IntroScreen.pop_progress2 = 0
    IntroScreen.move_elapsed2 = 0
    IntroScreen.move_duration2 = 0
    IntroScreen.moving2 = false
    IntroScreen.move_cooldown2 = love.math.random(3, 8)
    
    IntroScreen.vibrating = false
    IntroScreen.vibrate_timer = 0
    IntroScreen.vibrating2 = false
    IntroScreen.vibrate_timer2 = 0

    if not IntroScreen.sprite then
        IntroScreen.sprite = love.graphics.newImage("RAW/Sprites/Char_McJaggy_Idle00.png")
        IntroScreen.sprite_w = IntroScreen.sprite:getWidth()
        IntroScreen.sprite_h = IntroScreen.sprite:getHeight()
    end
    
    if not IntroScreen.sprite2 then
        IntroScreen.sprite2 = love.graphics.newImage("RAW/Sprites/Char_DMeowchi_Idle00.png")
        IntroScreen.sprite2_w = IntroScreen.sprite2:getWidth()
        IntroScreen.sprite2_h = IntroScreen.sprite2:getHeight()
    end

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    -- Start McJaggy at center-left
    IntroScreen.pos.x = w * 0.4
    IntroScreen.pos.y = h * 0.4
    
    -- Start DMeowchi at center-right
    IntroScreen.pos2.x = w * 0.6
    IntroScreen.pos2.y = h * 0.4
end

function IntroScreen.update(dt)
    IntroScreen.timer = IntroScreen.timer + dt
    
    -- Handle delayed spawn with pop-in scale animation for McJaggy
    if not IntroScreen.visible and IntroScreen.timer >= IntroScreen.spawn_delay then
        IntroScreen.visible = true
        IntroScreen.pop_progress = 0
        log.info("character:spawn", { character="McJaggy", x=IntroScreen.pos.x, y=IntroScreen.pos.y })
    end
    if IntroScreen.visible and IntroScreen.pop_progress < IntroScreen.pop_duration then
        IntroScreen.pop_progress = math.min(IntroScreen.pop_progress + dt, IntroScreen.pop_duration)
    end
    
    -- Handle delayed spawn with pop-in scale animation for DMeowchi
    if not IntroScreen.visible2 and IntroScreen.timer >= IntroScreen.spawn_delay2 then
        IntroScreen.visible2 = true
        IntroScreen.pop_progress2 = 0
        log.info("character:spawn", { character="DMeowchi", x=IntroScreen.pos2.x, y=IntroScreen.pos2.y })
    end
    if IntroScreen.visible2 and IntroScreen.pop_progress2 < IntroScreen.pop_duration then
        IntroScreen.pop_progress2 = math.min(IntroScreen.pop_progress2 + dt, IntroScreen.pop_duration)
    end

    -- Handle vibration timer for McJaggy
    if IntroScreen.vibrating then
        IntroScreen.vibrate_timer = IntroScreen.vibrate_timer - dt
        if IntroScreen.vibrate_timer <= 0 then
            IntroScreen.vibrating = false
            log.info("character:vibrate_stop", { character="McJaggy", x=IntroScreen.pos.x, y=IntroScreen.pos.y })
        end
    end
    
    -- Random movement every 3-8 seconds with easing and bobbing for McJaggy
    -- When vibrating, move every 0.3-0.8 seconds instead
    if IntroScreen.visible then
        IntroScreen.move_cooldown = IntroScreen.move_cooldown - dt
        local cooldown_min, cooldown_max = 3, 8
        if IntroScreen.vibrating then
            cooldown_min, cooldown_max = 0.3, 0.8
        end
        
        if IntroScreen.move_cooldown <= 0 and not IntroScreen.moving then
            local w, h = love.graphics.getWidth(), love.graphics.getHeight()
            local pad = 80
            IntroScreen.start_pos = { x = IntroScreen.pos.x, y = IntroScreen.pos.y }
            IntroScreen.target = {
                x = love.math.random(pad, w - pad),
                y = love.math.random(pad, h - pad * 1.5)
            }
            IntroScreen.move_duration = IntroScreen.vibrating and 0.4 or 0.9 -- Faster when vibrating
            IntroScreen.move_elapsed = 0
            IntroScreen.moving = true
            IntroScreen.move_cooldown = love.math.random(cooldown_min, cooldown_max)
            log.info("character:move", { character="McJaggy", from_x=IntroScreen.start_pos.x, from_y=IntroScreen.start_pos.y, to_x=IntroScreen.target.x, to_y=IntroScreen.target.y })
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
    
    -- Handle vibration timer for DMeowchi
    if IntroScreen.vibrating2 then
        IntroScreen.vibrate_timer2 = IntroScreen.vibrate_timer2 - dt
        if IntroScreen.vibrate_timer2 <= 0 then
            IntroScreen.vibrating2 = false
            log.info("character:vibrate_stop", { character="DMeowchi", x=IntroScreen.pos2.x, y=IntroScreen.pos2.y })
        end
    end
    
    -- Random movement every 3-8 seconds with easing and bobbing for DMeowchi
    -- When vibrating, move every 0.3-0.8 seconds instead
    if IntroScreen.visible2 then
        IntroScreen.move_cooldown2 = IntroScreen.move_cooldown2 - dt
        local cooldown_min2, cooldown_max2 = 3, 8
        if IntroScreen.vibrating2 then
            cooldown_min2, cooldown_max2 = 0.3, 0.8
        end
        
        if IntroScreen.move_cooldown2 <= 0 and not IntroScreen.moving2 then
            local w, h = love.graphics.getWidth(), love.graphics.getHeight()
            local pad = 80
            IntroScreen.start_pos2 = { x = IntroScreen.pos2.x, y = IntroScreen.pos2.y }
            IntroScreen.target2 = {
                x = love.math.random(pad, w - pad),
                y = love.math.random(pad, h - pad * 1.5)
            }
            IntroScreen.move_duration2 = IntroScreen.vibrating2 and 0.4 or 0.9 -- Faster when vibrating
            IntroScreen.move_elapsed2 = 0
            IntroScreen.moving2 = true
            IntroScreen.move_cooldown2 = love.math.random(cooldown_min2, cooldown_max2)
            log.info("character:move", { character="DMeowchi", from_x=IntroScreen.start_pos2.x, from_y=IntroScreen.start_pos2.y, to_x=IntroScreen.target2.x, to_y=IntroScreen.target2.y })
        end

        if IntroScreen.moving2 then
            IntroScreen.move_elapsed2 = IntroScreen.move_elapsed2 + dt
            local t = math.min(IntroScreen.move_elapsed2 / IntroScreen.move_duration2, 1)
            local eased = 1 - (1 - t) * (1 - t) -- ease-out quad
            IntroScreen.pos2.x = IntroScreen.start_pos2.x + (IntroScreen.target2.x - IntroScreen.start_pos2.x) * eased
            IntroScreen.pos2.y = IntroScreen.start_pos2.y + (IntroScreen.target2.y - IntroScreen.start_pos2.y) * eased
            if t >= 1 then
                IntroScreen.moving2 = false
                IntroScreen.pos2.x = IntroScreen.target2.x
                IntroScreen.pos2.y = IntroScreen.target2.y
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

    -- Draw McJaggy with pop-in scale and bobbing bounce
    if IntroScreen.visible and IntroScreen.sprite then
        local base_scale = IntroScreen.pop_progress / IntroScreen.pop_duration
        local scale = math.max(0, math.min(base_scale, 1))
        local bob = math.sin(love.timer.getTime() * 9) * 6
        
        -- Add fast vibration when clicked
        local vibrate_x, vibrate_y = 0, 0
        if IntroScreen.vibrating then
            local vibrate_intensity = 8
            vibrate_x = (love.math.random() - 0.5) * vibrate_intensity
            vibrate_y = (love.math.random() - 0.5) * vibrate_intensity
        end
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            IntroScreen.sprite,
            IntroScreen.pos.x + vibrate_x,
            IntroScreen.pos.y + bob + vibrate_y,
            0,
            scale,
            scale,
            IntroScreen.sprite_w / 2,
            IntroScreen.sprite_h / 2
        )
    end
    
    -- Draw DMeowchi with pop-in scale and bobbing bounce
    if IntroScreen.visible2 and IntroScreen.sprite2 then
        local base_scale2 = IntroScreen.pop_progress2 / IntroScreen.pop_duration
        local scale2 = math.max(0, math.min(base_scale2, 1))
        local bob2 = math.sin(love.timer.getTime() * 7 + 1.5) * 6 -- Slightly different bob timing
        
        -- Add fast vibration when clicked
        local vibrate_x2, vibrate_y2 = 0, 0
        if IntroScreen.vibrating2 then
            local vibrate_intensity2 = 8
            vibrate_x2 = (love.math.random() - 0.5) * vibrate_intensity2
            vibrate_y2 = (love.math.random() - 0.5) * vibrate_intensity2
        end
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            IntroScreen.sprite2,
            IntroScreen.pos2.x + vibrate_x2,
            IntroScreen.pos2.y + bob2 + vibrate_y2,
            0,
            scale2,
            scale2,
            IntroScreen.sprite2_w / 2,
            IntroScreen.sprite2_h / 2
        )
    end
end

-- Check if a point is within sprite bounds
-- @param click_x number
-- @param click_y number
-- @param sprite_x number (center x)
-- @param sprite_y number (center y)
-- @param sprite_w number
-- @param sprite_h number
-- @param scale number
-- @return boolean
local function is_click_on_sprite(click_x, click_y, sprite_x, sprite_y, sprite_w, sprite_h, scale)
    local half_w = (sprite_w * scale) / 2
    local half_h = (sprite_h * scale) / 2
    return click_x >= sprite_x - half_w and click_x <= sprite_x + half_w and
           click_y >= sprite_y - half_h and click_y <= sprite_y + half_h
end

function IntroScreen.keypressed(key, scancode, isrepeat)
    -- Progress to menu on any key press
    bus.emit("intro:done", { from = "intro" })
end

function IntroScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- Progress to menu on any mouse click
    bus.emit("intro:done", { from = "intro" })
end

return IntroScreen

