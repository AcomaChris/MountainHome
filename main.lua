-- Mountain Home - Main Game File
-- This is the entry point for the Love2D game engine

-- Called once when the game starts
-- Use this to initialize game state, load assets, etc.
function love.load()
    -- Set up the window title
    love.window.setTitle("Mountain Home")
end

-- Called every frame to update game logic
-- dt is the time elapsed since the last frame (delta time)
function love.update(dt)
    -- No game logic needed yet - just displaying text
end

-- Called every frame to draw graphics to the screen
function love.draw()
    -- Get the window dimensions so we can center the text
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    
    -- Set the text color to white
    love.graphics.setColor(1, 1, 1, 1)  -- RGBA values from 0 to 1
    
    -- Calculate text position to center it on screen
    local text = "Mountain Home"
    local font = love.graphics.getFont()
    local text_width = font:getWidth(text)
    local text_height = font:getHeight(text)
    
    local x = (window_width - text_width) / 2
    local y = (window_height - text_height) / 2
    
    -- Draw the text centered on screen
    love.graphics.print(text, x, y)
end



