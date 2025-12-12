-- Example: Hexagonal Map with Isometric Tiles
-- This demonstrates how to create a hexagonal grid using isometric hex sprites
-- with configurable spacing between tiles

-- ============================================================================
-- CONFIGURATION VARIABLES - Adjust these to change the map appearance
-- ============================================================================

-- Spacing between hex tiles (in pixels)
-- Increase these values to space tiles further apart
-- Decrease to bring them closer together
local HEX_SPACING_X = 32  -- Horizontal spacing between hex centers
local HEX_SPACING_Y = 32  -- Vertical spacing between hex centers

-- Grid size - how many hexes in each direction
local GRID_RADIUS = 5  -- Creates a radius-5 hex grid (11 hexes across at widest)

-- Starting position offset (moves the entire grid)
local OFFSET_X = 400  -- X position of the center hex
local OFFSET_Y = 300  -- Y position of the center hex

-- Hover animation settings
local HOVER_RAISE_AMOUNT = 10  -- X: How many pixels the hex moves up when hovered
local HOVER_SCALE_AMOUNT = 8   -- Y: How many pixels the hex grows/shrinks (added to base size)
local HOVER_ANIMATION_TIME = 1.0  -- Z: Time in seconds for one complete animation cycle
local HOVER_LIGHTEN_AMOUNT = 1.0  -- Lightening intensity (0.0 = no lightening, 1.0 = maximum brightness)
                                    -- Adjust this value to control how bright the hex becomes when hovered

-- Title and font settings
local TITLE_TEXT = "Mountain Home!"  -- Title text to display
local TITLE_FONT_PATH = "The Foregen Rough One.ttf"  -- Path to custom font file (TTF or OTF), or nil to use default font
local TITLE_FONT_SIZE = 48  -- Size of the title font in pixels

-- ============================================================================
-- GAME STATE
-- ============================================================================

local hex_sprite
local hexes = {}  -- Table to store all hex positions

-- Sprite dimensions
local SPRITE_WIDTH = 64
local SPRITE_HEIGHT = 64
local HEX_PLAYABLE_HEIGHT = 22  -- Actual hexagon height from center (44px total)

-- Hover state tracking
local hovered_hex_index = nil  -- Index of the hex currently being hovered (nil if none)
local hover_animation_time = 0  -- Current time in the animation cycle (0 to HOVER_ANIMATION_TIME)

-- Fonts
local title_font = nil  -- Font object for the title (loaded in love.load)
local default_font = nil  -- Default font for debug text (loaded in love.load)

-- ============================================================================
-- HEX COORDINATE FUNCTIONS
-- ============================================================================

-- Convert axial hex coordinates (q, r) to screen pixel coordinates
-- Axial coordinates are simpler than cube coordinates and work well for grids
-- @param q number: Column coordinate (horizontal)
-- @param r number: Row coordinate (diagonal)
-- @return number, number: Screen X and Y pixel positions
function hex_to_pixel(q, r)
    -- For flat-top hexagons, use these formulas
    -- Adjust spacing multipliers to control how far apart hexes are
    local x = HEX_SPACING_X * (q * 1.5)
    local y = HEX_SPACING_Y * (r + q * 0.5)
    
    -- Apply offset to center the grid
    return x + OFFSET_X, y + OFFSET_Y
end

-- Generate all hex coordinates within the grid radius
-- Uses axial coordinate system where each hex has (q, r) coordinates
-- @return table: Array of {q, r} coordinate pairs
function generate_hex_coordinates()
    local coords = {}
    
    -- Generate hexes in a hexagonal pattern
    for q = -GRID_RADIUS, GRID_RADIUS do
        -- Calculate the valid r range for this q to form a hexagon shape
        local r1 = math.max(-GRID_RADIUS, -q - GRID_RADIUS)
        local r2 = math.min(GRID_RADIUS, -q + GRID_RADIUS)
        
        for r = r1, r2 do
            table.insert(coords, {q = q, r = r})
        end
    end
    
    return coords
end

-- Check if a point (mouse position) is over a hex
-- Uses simple distance check from hex center
-- @param mx number: Mouse X position
-- @param my number: Mouse Y position
-- @param hex table: Hex object with x, y properties
-- @return boolean: True if mouse is over the hex
function is_mouse_over_hex(mx, my, hex)
    -- Calculate distance from mouse to hex center
    local dx = mx - hex.x
    local dy = my - hex.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Check if within hex radius (using half the sprite size as radius)
    return distance <= SPRITE_WIDTH / 2
end

-- Find which hex (if any) the mouse is currently over
-- @param mx number: Mouse X position
-- @param my number: Mouse Y position
-- @return number|nil: Index of hovered hex, or nil if none
function find_hovered_hex(mx, my)
    -- Check hexes in reverse order (top to bottom) so top hexes are checked first
    for i = #hexes, 1, -1 do
        if is_mouse_over_hex(mx, my, hexes[i]) then
            return i
        end
    end
    return nil
end

-- ============================================================================
-- LOVE2D CALLBACKS
-- ============================================================================

-- Called once when the game starts
function love.load()
    -- Set window title
    love.window.setTitle("Hex Map Example")
    
    -- Load default font for debug text (size 12)
    default_font = love.graphics.newFont(12)
    
    -- Load custom font if specified, otherwise use default font
    -- Love2D supports TTF and OTF font formats
    if TITLE_FONT_PATH and TITLE_FONT_PATH ~= "" then
        local success, font = pcall(function()
            return love.graphics.newFont(TITLE_FONT_PATH, TITLE_FONT_SIZE)
        end)
        if success then
            title_font = font
            print("Loaded custom font: " .. TITLE_FONT_PATH)
        else
            print("Warning: Could not load font '" .. TITLE_FONT_PATH .. "', using default font")
            title_font = love.graphics.newFont(TITLE_FONT_SIZE)
        end
    else
        -- Use default font at specified size
        title_font = love.graphics.newFont(TITLE_FONT_SIZE)
    end
    
    -- Load the hex tile sprite
    -- Sprite is copied into this example folder for self-contained example
    hex_sprite = love.graphics.newImage("BasicHexTile.png")
    
    -- Generate all hex coordinates
    local coords = generate_hex_coordinates()
    
    -- Convert coordinates to pixel positions and store
    for _, coord in ipairs(coords) do
        local x, y = hex_to_pixel(coord.q, coord.r)
        table.insert(hexes, {
            q = coord.q,
            r = coord.r,
            x = x,
            y = y
        })
    end
    
    -- Sort hexes by Y coordinate (top to bottom) for correct rendering order
    -- Hexes at the top should be drawn first, so lower Y values come first
    table.sort(hexes, function(a, b)
        return a.y < b.y
    end)
    
    print("Generated " .. #hexes .. " hex tiles")
    print("Adjust HEX_SPACING_X and HEX_SPACING_Y at the top of main.lua to change spacing")
end

-- Called every frame to update game state
-- @param dt number: Delta time (seconds since last frame)
function love.update(dt)
    -- Get mouse position
    local mx, my = love.mouse.getPosition()
    
    -- Check which hex is being hovered
    hovered_hex_index = find_hovered_hex(mx, my)
    
    -- Update animation time if a hex is hovered
    if hovered_hex_index then
        hover_animation_time = hover_animation_time + dt
        -- Loop the animation time back to 0 when it exceeds the cycle time
        if hover_animation_time >= HOVER_ANIMATION_TIME then
            hover_animation_time = hover_animation_time - HOVER_ANIMATION_TIME
        end
    else
        -- Reset animation time when not hovering
        hover_animation_time = 0
    end
end

-- Called every frame to draw graphics
function love.draw()
    -- Draw each hex tile
    for i, hex in ipairs(hexes) do
        local draw_x = hex.x
        local draw_y = hex.y
        local scale = 1.0
        
        -- Apply hover animation if this hex is being hovered
        local lighten_factor = 0.0  -- Default: no lightening
        if i == hovered_hex_index then
            -- Calculate animation progress (0 to 1, looping)
            -- Use sine wave for smooth oscillation
            local progress = hover_animation_time / HOVER_ANIMATION_TIME
            local sine_value = math.sin(progress * math.pi * 2)
            
            -- Convert sine (-1 to 1) to 0 to 1 range for smoother animation
            local normalized = (sine_value + 1) / 2
            
            -- Apply raise effect (move up by HOVER_RAISE_AMOUNT pixels)
            draw_y = draw_y - (normalized * HOVER_RAISE_AMOUNT)
            
            -- Apply scale effect (grow/shrink by HOVER_SCALE_AMOUNT pixels)
            -- Scale is calculated as: base size + animation amount, divided by base size
            local scale_addition = normalized * HOVER_SCALE_AMOUNT
            scale = (SPRITE_WIDTH + scale_addition) / SPRITE_WIDTH
            
            -- Calculate lightening factor (0 to HOVER_LIGHTEN_AMOUNT based on animation)
            -- Lightens as the hex grows, returns to normal as it shrinks
            lighten_factor = normalized * HOVER_LIGHTEN_AMOUNT
        end
        
        -- Draw the sprite centered at the calculated position
        -- Apply scale and offset for centering
        love.graphics.setColor(1, 1, 1, 1)  -- Base color (white)
        love.graphics.draw(
            hex_sprite,
            draw_x,
            draw_y,
            0,  -- rotation
            scale, scale,  -- scale x, scale y
            SPRITE_WIDTH / 2,  -- origin x (center)
            SPRITE_HEIGHT / 2  -- origin y (center)
        )
        
        -- Apply lightening effect by drawing a white overlay with transparency
        -- The lighten_factor controls how much white to blend in
        if lighten_factor > 0 then
            -- Use additive blending to lighten: draw white with alpha based on lighten_factor
            -- This creates a brightening effect that works with any sprite color
            love.graphics.setBlendMode("add")
            love.graphics.setColor(lighten_factor, lighten_factor, lighten_factor, lighten_factor)
            love.graphics.draw(
                hex_sprite,
                draw_x,
                draw_y,
                0,  -- rotation
                scale, scale,  -- scale x, scale y
                SPRITE_WIDTH / 2,  -- origin x (center)
                SPRITE_HEIGHT / 2  -- origin y (center)
            )
            love.graphics.setBlendMode("alpha")  -- Reset to default blending
        end
        
        -- Reset color to white for next hex (or other graphics)
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- Draw title at the top center of the screen
    love.graphics.setFont(title_font)
    love.graphics.setColor(1, 1, 1, 1)  -- White color for title
    local title_width = title_font:getWidth(TITLE_TEXT)
    local screen_width = love.graphics.getWidth()
    local title_x = (screen_width - title_width) / 2  -- Center horizontally
    local title_y = 20  -- Position from top
    love.graphics.print(TITLE_TEXT, title_x, title_y)
    
    -- Draw debug info (optional - shows hex coordinates)
    love.graphics.setColor(1, 1, 1, 0.7)  -- White with transparency
    love.graphics.setFont(default_font)  -- Use default font for debug text
    love.graphics.print("Hex Map Example - " .. #hexes .. " tiles", 10, title_y + TITLE_FONT_SIZE + 20)
    love.graphics.print("Spacing X: " .. HEX_SPACING_X .. " | Spacing Y: " .. HEX_SPACING_Y, 10, title_y + TITLE_FONT_SIZE + 40)
    love.graphics.print("Lighten: " .. HOVER_LIGHTEN_AMOUNT .. " | Raise: " .. HOVER_RAISE_AMOUNT .. " | Scale: " .. HOVER_SCALE_AMOUNT, 10, title_y + TITLE_FONT_SIZE + 60)
    love.graphics.print("Adjust HOVER_* variables in main.lua to customize hover effects", 10, title_y + TITLE_FONT_SIZE + 80)
    love.graphics.setColor(1, 1, 1, 1)  -- Reset to opaque white
end

