-- Example: Buttons and Fonts in Love2D
-- This demonstrates how to create interactive buttons and use custom fonts

-- Button table to store button properties
local buttons = {}

-- Font variables
local default_font
local button_font

-- Colors for button states
local COLOR_NORMAL = {0.3, 0.5, 0.8, 1.0}      -- Blue
local COLOR_HOVER = {0.4, 0.6, 0.9, 1.0}       -- Lighter blue
local COLOR_CLICKED = {0.2, 0.4, 0.7, 1.0}     -- Darker blue
local COLOR_TEXT = {1.0, 1.0, 1.0, 1.0}        -- White

-- Click counter to show button interaction
local click_count = 0

-- Function to create a button
-- @param x number: X position of button
-- @param y number: Y position of button
-- @param width number: Button width
-- @param height number: Button height
-- @param text string: Text to display on button
-- @return table: Button object
function create_button(x, y, width, height, text)
    local button = {
        x = x,
        y = y,
        width = width,
        height = height,
        text = text,
        is_hovered = false,
        is_clicked = false
    }
    table.insert(buttons, button)
    return button
end

-- Check if a point (mx, my) is inside a button
-- @param button table: Button object to check
-- @param mx number: Mouse X position
-- @param my number: Mouse Y position
-- @return boolean: True if point is inside button
function is_point_in_button(button, mx, my)
    return mx >= button.x and mx <= button.x + button.width and
           my >= button.y and my <= button.y + button.height
end

-- Love2D callback: Called once when the game starts
function love.load()
    -- Load a custom font (Love2D includes a default font if file not found)
    -- You can use love.graphics.newFont("path/to/font.ttf", size) for custom fonts
    -- Here we'll use Love2D's built-in font system
    button_font = love.graphics.newFont(24)  -- 24 pixel font
    default_font = love.graphics.getFont()   -- Get default font (12px)
    
    -- Create some example buttons
    create_button(100, 100, 200, 50, "Click Me!")
    create_button(100, 200, 200, 50, "Another Button")
    create_button(100, 300, 200, 50, "Reset Counter")
end

-- Love2D callback: Called every frame to update game state
-- @param dt number: Delta time (seconds since last frame)
function love.update(dt)
    local mx, my = love.mouse.getPosition()
    
    -- Update button hover states
    for _, button in ipairs(buttons) do
        button.is_hovered = is_point_in_button(button, mx, my)
    end
end

-- Love2D callback: Called every frame to draw graphics
function love.draw()
    -- Set the default font for general text
    love.graphics.setFont(default_font)
    
    -- Draw title text at the top
    love.graphics.print("Button and Font Example", 100, 30)
    love.graphics.print("Clicks: " .. click_count, 100, 50)
    
    -- Draw each button
    for _, button in ipairs(buttons) do
        -- Determine button color based on state
        local color = COLOR_NORMAL
        if button.is_clicked then
            color = COLOR_CLICKED
        elseif button.is_hovered then
            color = COLOR_HOVER
        end
        
        -- Draw button rectangle
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
        
        -- Draw button border
        love.graphics.setColor(0, 0, 0, 1)  -- Black border
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
        
        -- Draw button text (centered)
        love.graphics.setFont(button_font)
        love.graphics.setColor(COLOR_TEXT)
        
        -- Calculate text position to center it in the button
        local text_width = button_font:getWidth(button.text)
        local text_height = button_font:getHeight()
        local text_x = button.x + (button.width - text_width) / 2
        local text_y = button.y + (button.height - text_height) / 2
        
        love.graphics.print(button.text, text_x, text_y)
    end
    
    -- Reset color to white for any other drawing
    love.graphics.setColor(1, 1, 1, 1)
end

-- Love2D callback: Called when mouse button is pressed
-- @param x number: Mouse X position
-- @param y number: Mouse Y position
-- @param button number: Mouse button (1=left, 2=right, 3=middle)
function love.mousepressed(x, y, button)
    if button == 1 then  -- Left mouse button
        for _, btn in ipairs(buttons) do
            if is_point_in_button(btn, x, y) then
                btn.is_clicked = true
                
                -- Handle button actions
                if btn.text == "Click Me!" then
                    click_count = click_count + 1
                elseif btn.text == "Another Button" then
                    click_count = click_count + 2
                elseif btn.text == "Reset Counter" then
                    click_count = 0
                end
            end
        end
    end
end

-- Love2D callback: Called when mouse button is released
-- @param x number: Mouse X position
-- @param y number: Mouse Y position
-- @param button number: Mouse button (1=left, 2=right, 3=middle)
function love.mousereleased(x, y, button)
    if button == 1 then  -- Left mouse button
        for _, btn in ipairs(buttons) do
            btn.is_clicked = false
        end
    end
end

