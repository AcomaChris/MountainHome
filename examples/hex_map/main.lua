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

-- ============================================================================
-- GAME STATE
-- ============================================================================

local hex_sprite
local hexes = {}  -- Table to store all hex positions

-- Sprite dimensions
local SPRITE_WIDTH = 64
local SPRITE_HEIGHT = 64
local HEX_PLAYABLE_HEIGHT = 22  -- Actual hexagon height from center (44px total)

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

-- ============================================================================
-- LOVE2D CALLBACKS
-- ============================================================================

-- Called once when the game starts
function love.load()
    -- Set window title
    love.window.setTitle("Hex Map Example")
    
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
    
    print("Generated " .. #hexes .. " hex tiles")
    print("Adjust HEX_SPACING_X and HEX_SPACING_Y at the top of main.lua to change spacing")
end

-- Called every frame to update game state
-- @param dt number: Delta time (seconds since last frame)
function love.update(dt)
    -- No updates needed for static map
end

-- Called every frame to draw graphics
function love.draw()
    -- Draw each hex tile
    for _, hex in ipairs(hexes) do
        -- Draw the sprite centered at the calculated position
        -- The sprite is 64x64, so we offset by half to center it
        love.graphics.draw(
            hex_sprite,
            hex.x - SPRITE_WIDTH / 2,
            hex.y - SPRITE_HEIGHT / 2
        )
    end
    
    -- Draw debug info (optional - shows hex coordinates)
    love.graphics.setColor(1, 1, 1, 0.7)  -- White with transparency
    local font = love.graphics.getFont()
    love.graphics.print("Hex Map Example - " .. #hexes .. " tiles", 10, 10)
    love.graphics.print("Spacing X: " .. HEX_SPACING_X .. " | Spacing Y: " .. HEX_SPACING_Y, 10, 30)
    love.graphics.print("Adjust HEX_SPACING_X and HEX_SPACING_Y in main.lua to change spacing", 10, 50)
    love.graphics.setColor(1, 1, 1, 1)  -- Reset to opaque white
end

