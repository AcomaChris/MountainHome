-- Intro screen with logo animation and character spawning.
-- Logo flips in from center, grows, and transitions to full color.
-- Characters spawn after logo animation completes.
-- Clicking at any time fades out to menu.

local bus = require('lib.event_bus')
local log = require('lib.logger')

local IntroScreen = {
    timer = 0,
    
    -- Logo animation
    logo_sprite = nil,
    logo_w = 0,
    logo_h = 0,
    logo_scale = 0.1,  -- Start very small
    logo_color = {0, 0, 0},  -- Start black
    logo_flip_progress = 0,  -- 0 to 1, cycles for flip animation
    logo_flip_speed = 3.0,  -- Flips per second
    logo_scale_target = 1.0,  -- Target scale
    logo_color_target = {1, 1, 1},  -- Target color (full color)
    logo_animation_duration = 2.0,  -- How long the logo animation takes
    logo_animation_progress = 0,  -- 0 to 1, overall animation progress
    logo_complete = false,
    
    -- Fade out
    fade_out_progress = 0,  -- 0 to 1
    fade_out_duration = 0.5,  -- Fade out duration in seconds
    fading_out = false,
    
    -- Character spawning (delayed until logo is complete)
    -- McJaggy sprite
    sprite = nil,
    sprite_w = 0,
    sprite_h = 0,
    spawn_delay = 0.5,  -- Delay after logo completes
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
    vibrate_duration = 2.0,
    -- DMeowchi sprite
    sprite2 = nil,
    sprite2_w = 0,
    sprite2_h = 0,
    spawn_delay2 = 1.0,
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
    vibrate_duration2 = 2.0,
}

function IntroScreen.enter(ctx)
    IntroScreen.timer = 0
    IntroScreen.last_transition = ctx
    
    -- Reset logo animation
    IntroScreen.logo_scale = 0.1
    IntroScreen.logo_color = {0, 0, 0}
    IntroScreen.logo_flip_progress = 0
    IntroScreen.logo_animation_progress = 0
    IntroScreen.logo_complete = false
    
    -- Reset fade out
    IntroScreen.fade_out_progress = 0
    IntroScreen.fading_out = false
    
    -- Reset characters
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

    -- Load logo sprite
    if not IntroScreen.logo_sprite then
        local success, sprite = pcall(love.graphics.newImage, "assets/IntroLogo.png")
        if success then
            IntroScreen.logo_sprite = sprite
            IntroScreen.logo_w = sprite:getWidth()
            IntroScreen.logo_h = sprite:getHeight()
        else
            log.info("intro:logo_load_failed", { error = tostring(sprite) })
        end
    end

    -- Load character sprites
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
    
    -- Handle fade out
    if IntroScreen.fading_out then
        IntroScreen.fade_out_progress = math.min(IntroScreen.fade_out_progress + dt / IntroScreen.fade_out_duration, 1.0)
        if IntroScreen.fade_out_progress >= 1.0 then
            bus.emit("intro:done", { from = "intro" })
            return
        end
    end
    
    -- Logo animation
    if not IntroScreen.logo_complete and IntroScreen.logo_sprite then
        -- Update flip progress (cycles 0 to 1 repeatedly)
        IntroScreen.logo_flip_progress = IntroScreen.logo_flip_progress + dt * IntroScreen.logo_flip_speed
        if IntroScreen.logo_flip_progress >= 1.0 then
            IntroScreen.logo_flip_progress = IntroScreen.logo_flip_progress - 1.0
        end
        
        -- Update overall animation progress
        IntroScreen.logo_animation_progress = math.min(IntroScreen.logo_animation_progress + dt / IntroScreen.logo_animation_duration, 1.0)
        
        -- Lerp scale from 0.1 to 1.0
        IntroScreen.logo_scale = 0.1 + (IntroScreen.logo_scale_target - 0.1) * IntroScreen.logo_animation_progress
        
        -- Lerp color from black to full color
        IntroScreen.logo_color[1] = 0 + (IntroScreen.logo_color_target[1] - 0) * IntroScreen.logo_animation_progress
        IntroScreen.logo_color[2] = 0 + (IntroScreen.logo_color_target[2] - 0) * IntroScreen.logo_animation_progress
        IntroScreen.logo_color[3] = 0 + (IntroScreen.logo_color_target[3] - 0) * IntroScreen.logo_animation_progress
        
        -- Check if animation is complete
        if IntroScreen.logo_animation_progress >= 1.0 then
            IntroScreen.logo_complete = true
            IntroScreen.logo_scale = IntroScreen.logo_scale_target
            IntroScreen.logo_color = {IntroScreen.logo_color_target[1], IntroScreen.logo_color_target[2], IntroScreen.logo_color_target[3]}
            log.info("intro:logo_complete")
        end
    end
    
    -- Character spawning (only after logo is complete)
    if IntroScreen.logo_complete then
        local character_timer = IntroScreen.timer - IntroScreen.logo_animation_duration
        
        -- Handle delayed spawn with pop-in scale animation for McJaggy
        if not IntroScreen.visible and character_timer >= IntroScreen.spawn_delay then
            IntroScreen.visible = true
            IntroScreen.pop_progress = 0
            log.info("character:spawn", { character="McJaggy", x=IntroScreen.pos.x, y=IntroScreen.pos.y })
        end
        if IntroScreen.visible and IntroScreen.pop_progress < IntroScreen.pop_duration then
            IntroScreen.pop_progress = math.min(IntroScreen.pop_progress + dt, IntroScreen.pop_duration)
        end
        
        -- Handle delayed spawn with pop-in scale animation for DMeowchi
        if not IntroScreen.visible2 and character_timer >= IntroScreen.spawn_delay2 then
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
                IntroScreen.move_duration = IntroScreen.vibrating and 0.4 or 0.9
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
                IntroScreen.move_duration2 = IntroScreen.vibrating2 and 0.4 or 0.9
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
end

function IntroScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Start with black screen
    love.graphics.clear(0, 0, 0)
    
    -- Draw logo if loaded
    if IntroScreen.logo_sprite then
        local center_x = w / 2
        local center_y = h / 2
        
        -- Calculate flip scale (vertical flip animation)
        -- Flip progress goes 0 -> 1, we want it to flip at 0.5
        local flip_scale_y = 1.0
        if IntroScreen.logo_flip_progress < 0.5 then
            -- First half: scale down to 0 (flip in)
            flip_scale_y = 1.0 - (IntroScreen.logo_flip_progress * 2)
        else
            -- Second half: scale up from 0 (flip out)
            flip_scale_y = (IntroScreen.logo_flip_progress - 0.5) * 2
        end
        
        -- Apply color and scale
        love.graphics.setColor(IntroScreen.logo_color[1], IntroScreen.logo_color[2], IntroScreen.logo_color[3])
        
        -- Draw with flip animation and scale lerp
        love.graphics.draw(
            IntroScreen.logo_sprite,
            center_x,
            center_y,
            0,  -- rotation
            IntroScreen.logo_scale,  -- scale x
            IntroScreen.logo_scale * flip_scale_y,  -- scale y (with flip)
            IntroScreen.logo_w / 2,  -- origin x
            IntroScreen.logo_h / 2   -- origin y
        )
    end
    
    -- Draw characters (only if logo is complete)
    if IntroScreen.logo_complete then
        -- Draw McJaggy with pop-in scale and bobbing bounce
        if IntroScreen.visible and IntroScreen.sprite then
            local base_scale = IntroScreen.pop_progress / IntroScreen.pop_duration
            local scale = math.max(0, math.min(base_scale, 1))
            local bob = math.sin(love.timer.getTime() * 9) * 6
            
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
            local bob2 = math.sin(love.timer.getTime() * 7 + 1.5) * 6
            
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
    
    -- Draw fade out overlay
    if IntroScreen.fading_out then
        local alpha = IntroScreen.fade_out_progress
        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end
end

function IntroScreen.keypressed(key, scancode, isrepeat)
    -- Start fade out on any key press
    if not IntroScreen.fading_out then
        IntroScreen.fading_out = true
        log.info("intro:fade_out_started", { trigger = "key", key = key })
    end
end

function IntroScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- Start fade out on any mouse click
    if not IntroScreen.fading_out then
        IntroScreen.fading_out = true
        log.info("intro:fade_out_started", { trigger = "mouse", x = x, y = y })
    end
end

return IntroScreen
