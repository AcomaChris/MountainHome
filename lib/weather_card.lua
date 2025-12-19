-- Weather card UI component.
-- Displays a weather card that slides in, wiggles, and flips when clicked.

local WeatherCard = {
    -- State
    visible = false,
    revealed = false,
    weather = nil,
    
    -- Animation
    slide_progress = 0,  -- 0 to 1 (slides from bottom to center)
    slide_duration = 0.8,  -- How long slide takes
    wiggle_timer = 0,  -- Timer for wiggle animation
    wiggle_interval = 5.0,  -- Wiggle every 5 seconds
    wiggle_duration = 1.0,  -- Wiggle for 1 second
    wiggle_progress = 0,  -- 0 to 1 during wiggle
    flip_progress = 0,  -- 0 to 1 (card flip animation)
    flip_duration = 0.5,  -- How long flip takes
    
    -- Card dimensions
    card_width = 300,
    card_height = 400,
    
    -- Position (calculated based on screen size)
    target_x = 0,
    target_y = 0,
    start_y = 0,
}

-- Show a weather card
-- @param weather table: Weather data from Weather module
-- @param screen_w number: Screen width
-- @param screen_h number: Screen height
function WeatherCard.show(weather, screen_w, screen_h)
    WeatherCard.weather = weather
    WeatherCard.visible = true
    WeatherCard.revealed = false
    WeatherCard.slide_progress = 0
    WeatherCard.wiggle_timer = 0
    WeatherCard.wiggle_progress = 0
    WeatherCard.flip_progress = 0
    
    -- Calculate target position (center of screen)
    WeatherCard.target_x = (screen_w - WeatherCard.card_width) / 2
    WeatherCard.target_y = (screen_h - WeatherCard.card_height) / 2
    WeatherCard.start_y = screen_h + WeatherCard.card_height  -- Start off-screen bottom
end

-- Hide the weather card
function WeatherCard.hide()
    WeatherCard.visible = false
    WeatherCard.revealed = false
end

-- Reveal the weather (called on click)
function WeatherCard.reveal()
    if not WeatherCard.revealed then
        WeatherCard.revealed = true
        WeatherCard.flip_progress = 0
    end
end

-- Update animation (call from update loop)
-- @param dt number: Delta time
function WeatherCard.update(dt)
    if not WeatherCard.visible then return end
    
    -- Update slide animation
    if WeatherCard.slide_progress < 1.0 then
        WeatherCard.slide_progress = math.min(WeatherCard.slide_progress + dt / WeatherCard.slide_duration, 1.0)
    else
        -- Card is in center, start wiggle timer
        WeatherCard.wiggle_timer = WeatherCard.wiggle_timer + dt
        
        -- Check if it's time to wiggle
        local time_since_last_wiggle = WeatherCard.wiggle_timer % WeatherCard.wiggle_interval
        if time_since_last_wiggle < WeatherCard.wiggle_duration then
            -- Currently wiggling
            WeatherCard.wiggle_progress = time_since_last_wiggle / WeatherCard.wiggle_duration
        else
            WeatherCard.wiggle_progress = 0
        end
    end
    
    -- Update flip animation
    if WeatherCard.revealed and WeatherCard.flip_progress < 1.0 then
        WeatherCard.flip_progress = math.min(WeatherCard.flip_progress + dt / WeatherCard.flip_duration, 1.0)
    end
end

-- Check if a point is within the card bounds
-- @param x number: X coordinate
-- @param y number: Y coordinate
-- @return boolean: True if point is on card
function WeatherCard.contains(x, y)
    if not WeatherCard.visible then return false end
    
    local current_y = WeatherCard.start_y + (WeatherCard.target_y - WeatherCard.start_y) * WeatherCard.slide_progress
    local wiggle_offset = 0
    if WeatherCard.wiggle_progress > 0 then
        -- Wiggle animation: small random offset
        wiggle_offset = math.sin(WeatherCard.wiggle_progress * math.pi * 8) * 10
    end
    
    return x >= WeatherCard.target_x and x <= WeatherCard.target_x + WeatherCard.card_width and
           y >= current_y + wiggle_offset and y <= current_y + wiggle_offset + WeatherCard.card_height
end

-- Draw the weather card (call from draw loop)
function WeatherCard.draw()
    if not WeatherCard.visible then return end
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Calculate current position with slide animation
    local current_y = WeatherCard.start_y + (WeatherCard.target_y - WeatherCard.start_y) * WeatherCard.slide_progress
    
    -- Add wiggle offset
    local wiggle_offset = 0
    if WeatherCard.slide_progress >= 1.0 and WeatherCard.wiggle_progress > 0 then
        wiggle_offset = math.sin(WeatherCard.wiggle_progress * math.pi * 8) * 10
    end
    
    local card_x = WeatherCard.target_x
    local card_y = current_y + wiggle_offset
    
    -- Draw card background
    if WeatherCard.revealed and WeatherCard.flip_progress < 1.0 then
        -- During flip: show both sides with rotation
        local flip_angle = WeatherCard.flip_progress * math.pi
        
        -- Back side (fading out)
        if WeatherCard.flip_progress < 0.5 then
            local back_alpha = 1.0 - (WeatherCard.flip_progress * 2)
            love.graphics.setColor(0.2, 0.3, 0.5, back_alpha)
            love.graphics.rectangle("fill", card_x, card_y, WeatherCard.card_width, WeatherCard.card_height, 12, 12)
            love.graphics.setColor(0.4, 0.5, 0.7, back_alpha)
            love.graphics.rectangle("line", card_x, card_y, WeatherCard.card_width, WeatherCard.card_height, 12, 12)
            
            -- Draw question mark on back
            love.graphics.setColor(1, 1, 1, back_alpha)
            love.graphics.printf("?", card_x, card_y + WeatherCard.card_height / 2 - 30, WeatherCard.card_width, "center")
        end
        
        -- Front side (fading in)
        if WeatherCard.flip_progress >= 0.5 then
            local front_alpha = (WeatherCard.flip_progress - 0.5) * 2
            love.graphics.setColor(0.9, 0.9, 0.8, front_alpha)
            love.graphics.rectangle("fill", card_x, card_y, WeatherCard.card_width, WeatherCard.card_height, 12, 12)
            love.graphics.setColor(0.6, 0.6, 0.5, front_alpha)
            love.graphics.rectangle("line", card_x, card_y, WeatherCard.card_width, WeatherCard.card_height, 12, 12)
            
            -- Draw weather info
            if WeatherCard.weather then
                love.graphics.setColor(0.2, 0.2, 0.2, front_alpha)
                love.graphics.printf(WeatherCard.weather.name, card_x + 20, card_y + 40, WeatherCard.card_width - 40, "center")
                love.graphics.setColor(0.4, 0.4, 0.4, front_alpha)
                love.graphics.printf(WeatherCard.weather.description, card_x + 20, card_y + 100, WeatherCard.card_width - 40, "center")
            end
        end
    elseif WeatherCard.revealed then
        -- Fully revealed: show front
        love.graphics.setColor(0.9, 0.9, 0.8)
        love.graphics.rectangle("fill", card_x, card_y, WeatherCard.card_width, WeatherCard.card_height, 12, 12)
        love.graphics.setColor(0.6, 0.6, 0.5)
        love.graphics.rectangle("line", card_x, card_y, WeatherCard.card_width, WeatherCard.card_height, 12, 12)
        
        -- Draw weather info
        if WeatherCard.weather then
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.printf(WeatherCard.weather.name, card_x + 20, card_y + 40, WeatherCard.card_width - 40, "center")
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.printf(WeatherCard.weather.description, card_x + 20, card_y + 100, WeatherCard.card_width - 40, "center")
        end
    else
        -- Face down: show back
        love.graphics.setColor(0.2, 0.3, 0.5)
        love.graphics.rectangle("fill", card_x, card_y, WeatherCard.card_width, WeatherCard.card_height, 12, 12)
        love.graphics.setColor(0.4, 0.5, 0.7)
        love.graphics.rectangle("line", card_x, card_y, WeatherCard.card_width, WeatherCard.card_height, 12, 12)
        
        -- Draw question mark on back
        love.graphics.setColor(1, 1, 1)
        local font = love.graphics.getFont()
        local font_size = font:getHeight()
        love.graphics.printf("?", card_x, card_y + WeatherCard.card_height / 2 - font_size / 2, WeatherCard.card_width, "center")
    end
end

return WeatherCard

