-- Kyle character system for Mountain Home.
-- Spawns Kyle who floats across the screen and says grumpy things.

local log = require('lib.logger')

local KyleCharacter = {
    active = false,
    sprite = nil,
    x = 0,
    y = 0,
    sprite_w = 0,
    sprite_h = 0,
    speed = 100,  -- pixels per second
    start_x = 0,
    end_x = 0,
    screen_middle = 0,
    message = "",
    message_visible = false,
    message_timer = 0,
    message_duration = 4.0,  -- seconds to show message
}

-- Grumpy messages Kyle says when he reaches the middle
local GRUMPY_MESSAGES = {
    "Back in my day, we played games without saves!",
    "Kids these days want everything handed to them...",
    "Real gamers don't need cheats to have fun!",
    "You call that playing? I call it cheating!",
    "In my time, we earned our resources the hard way!",
    "Modern games have made players soft...",
    "Where's the challenge if you just cheat everything?",
    "Back then, we had to work for what we got!",
    "Kids don't know what real gaming is anymore...",
    "You're missing the whole point of the game!",
    "Real players don't need shortcuts!",
    "The journey is the reward, not the destination!",
    "You're robbing yourself of the experience!",
    "Games used to be about skill, not cheats!",
    "Where's your sense of accomplishment?",
    "This generation doesn't understand patience...",
    "You're playing it wrong, I tell you!",
    "Back in the day, we respected the game!",
    "Cheats? More like training wheels for weak players!",
    "The game was meant to be played properly!",
}

-- Spawn Kyle to float across the screen
-- @param screen_w number: Screen width
-- @param screen_h number: Screen height
function KyleCharacter.spawn(screen_w, screen_h)
    -- Load Kyle sprite
    local success, img = pcall(love.graphics.newImage, "assets/Char_Kyle_Idle00.png")
    if not success then
        log.warn("kyle:spawn_failed", { error = "Could not load Kyle sprite" })
        return false
    end
    
    KyleCharacter.sprite = img
    KyleCharacter.sprite_w = img:getWidth()
    KyleCharacter.sprite_h = img:getHeight()
    
    -- Start off-screen to the left, end off-screen to the right
    KyleCharacter.start_x = -KyleCharacter.sprite_w
    KyleCharacter.end_x = screen_w + KyleCharacter.sprite_w
    KyleCharacter.x = KyleCharacter.start_x
    KyleCharacter.y = screen_h * 0.4  -- Float at 40% down the screen
    KyleCharacter.screen_middle = screen_w / 2
    
    -- Select random grumpy message
    KyleCharacter.message = GRUMPY_MESSAGES[love.math.random(1, #GRUMPY_MESSAGES)]
    KyleCharacter.message_visible = false
    KyleCharacter.message_timer = 0
    
    KyleCharacter.active = true
    
    log.info("kyle:spawned", { message = KyleCharacter.message })
    
    return true
end

-- Update Kyle's position and message display
-- @param dt number: Delta time
function KyleCharacter.update(dt)
    if not KyleCharacter.active then
        return
    end
    
    -- Move Kyle from left to right
    KyleCharacter.x = KyleCharacter.x + KyleCharacter.speed * dt
    
    -- Check if Kyle has reached the middle
    if not KyleCharacter.message_visible and KyleCharacter.x >= KyleCharacter.screen_middle - KyleCharacter.sprite_w / 2 then
        KyleCharacter.message_visible = true
        KyleCharacter.message_timer = 0
    end
    
    -- Update message timer
    if KyleCharacter.message_visible then
        KyleCharacter.message_timer = KyleCharacter.message_timer + dt
        if KyleCharacter.message_timer >= KyleCharacter.message_duration then
            KyleCharacter.message_visible = false
        end
    end
    
    -- Despawn when off-screen
    if KyleCharacter.x > KyleCharacter.end_x then
        KyleCharacter.active = false
        KyleCharacter.sprite = nil
    end
end

-- Draw Kyle and his message
function KyleCharacter.draw()
    if not KyleCharacter.active or not KyleCharacter.sprite then
        return
    end
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Draw Kyle with a slight bob animation
    local bob = math.sin(love.timer.getTime() * 3) * 3
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        KyleCharacter.sprite,
        KyleCharacter.x,
        KyleCharacter.y + bob,
        0,
        1, 1,
        KyleCharacter.sprite_w / 2,
        KyleCharacter.sprite_h / 2
    )
    
    -- Draw message bubble when Kyle is at the middle
    if KyleCharacter.message_visible then
        local message_x = KyleCharacter.x
        local message_y = KyleCharacter.y - 60
        
        -- Message bubble background
        local font = love.graphics.getFont()
        local text_w = font:getWidth(KyleCharacter.message)
        local text_h = font:getHeight()
        local padding = 10
        local bubble_w = text_w + padding * 2
        local bubble_h = text_h + padding * 2
        
        love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
        love.graphics.rectangle("fill", message_x - bubble_w / 2, message_y - bubble_h, bubble_w, bubble_h, 6, 6)
        love.graphics.setColor(0.3, 0.3, 0.4, 0.95)
        love.graphics.rectangle("line", message_x - bubble_w / 2, message_y - bubble_h, bubble_w, bubble_h, 6, 6)
        
        -- Message text
        love.graphics.setColor(0.9, 0.7, 0.5)
        love.graphics.printf(
            KyleCharacter.message,
            message_x - bubble_w / 2 + padding,
            message_y - bubble_h + padding,
            text_w,
            "center"
        )
    end
end

-- Check if Kyle is currently active
-- @return boolean: True if Kyle is on screen
function KyleCharacter.is_active()
    return KyleCharacter.active
end

return KyleCharacter

