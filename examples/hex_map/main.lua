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
local HEX_SPACING_Y = 24  -- Vertical spacing between hex centers

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

-- Tile type probabilities (must sum to 1.0)
-- These control how likely each tile type is to appear when generating the map
local TILE_PROBABILITIES = {
    blank = 0.2,        -- 20% chance for blank tiles
    short_grass = 0.4,  -- 40% chance for short grass
    long_grass = 0.3,   -- 30% chance for long grass
    overgrown = 0.1     -- 10% chance for overgrown grass
}

-- ============================================================================
-- TILE TYPE DEFINITIONS
-- ============================================================================

-- Tile type constants for easy reference
local TILE_TYPES = {
    BLANK = "blank",
    SHORT_GRASS = "short_grass",
    LONG_GRASS = "long_grass",
    OVERGROWN = "overgrown"
}

-- ============================================================================
-- GAME STATE
-- ============================================================================

local blank_sprite  -- The original BasicHexTile.png sprite
local grass_sprite  -- The Grass_Tile_Medium.png sprite sheet
local grass_quads = {}  -- Quads for each grass tile type (short, long, overgrown)
local hexes = {}  -- Table to store all hex positions

-- Sprite dimensions
local SPRITE_WIDTH = 64
local SPRITE_HEIGHT = 64
local HEX_PLAYABLE_HEIGHT = 22  -- Actual hexagon height from center (44px total)

-- Hover state tracking
local hovered_hex_index = nil  -- Index of the hex currently being hovered (nil if none)
local hover_animation_time = 0  -- Current time in the animation cycle (0 to HOVER_ANIMATION_TIME)
local game_timer = 0  -- Elapsed time since game start

-- Fonts
local title_font = nil  -- Font object for the title (loaded in love.load)
local default_font = nil  -- Default font for debug text (loaded in love.load)

-- Character state (McJaggy)
local char1_sprite = nil
local char1_w = 0
local char1_h = 0
local char1_pos = { x = 0, y = 0 }
local char1_hex_index = nil  -- Index of hex character is on/heading to
local char1_start_pos = nil
local char1_move_elapsed = 0
local char1_move_duration = 0
local char1_move_cooldown = 0
local char1_moving = false
local char1_vibrating = false
local char1_vibrate_timer = 0
local char1_vibrate_duration = 2.0
local char1_spawn_delay = 1.0
local char1_pop_progress = 0
local char1_pop_duration = 0.4
local char1_visible = false

-- Character state (DMeowchi)
local char2_sprite = nil
local char2_w = 0
local char2_h = 0
local char2_pos = { x = 0, y = 0 }
local char2_hex_index = nil  -- Index of hex character is on/heading to
local char2_start_pos = nil
local char2_move_elapsed = 0
local char2_move_duration = 0
local char2_move_cooldown = 0
local char2_moving = false
local char2_vibrating = false
local char2_vibrate_timer = 0
local char2_vibrate_duration = 2.0
local char2_spawn_delay = 1.5
local char2_pop_progress = 0
local char2_pop_duration = 0.4
local char2_visible = false

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

-- Get a random hex index from the hexes array
-- @return number: Random hex index
function get_random_hex_index()
    return love.math.random(1, #hexes)
end

-- Randomly select a tile type based on configured probabilities
-- Uses weighted random selection: each tile type has a probability weight
-- @return string: The selected tile type name
function select_random_tile_type()
    -- Generate random number between 0 and 1
    local roll = math.random()
    
    -- Cumulative probability tracking
    local cumulative = 0.0
    
    -- Check each tile type in a specific order to ensure consistent behavior
    -- This creates a weighted random distribution based on probabilities
    local tile_order = {TILE_TYPES.BLANK, TILE_TYPES.SHORT_GRASS, TILE_TYPES.LONG_GRASS, TILE_TYPES.OVERGROWN}
    for _, tile_type in ipairs(tile_order) do
        local probability = TILE_PROBABILITIES[tile_type]
        if probability then
            cumulative = cumulative + probability
            if roll <= cumulative then
                return tile_type
            end
        end
    end
    
    -- Fallback to blank if probabilities don't sum to 1.0 (shouldn't happen)
    return TILE_TYPES.BLANK
end

-- ============================================================================
-- LOVE2D CALLBACKS
-- ============================================================================

-- Called once when the game starts
function love.load()
    -- Set window size to 1280x720
    love.window.setMode(1280, 720)
    
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
    
    -- Load the blank tile sprite (original BasicHexTile.png)
    blank_sprite = love.graphics.newImage("BasicHexTile.png")
    
    -- Load the grass sprite sheet (Grass_Tile_Medium.png with 3 tiles side by side)
    grass_sprite = love.graphics.newImage("Grass_Tile_Medium.png")
    
    -- Create quads for each grass tile type from the sprite sheet
    -- The sprite sheet has 3 tiles: short grass (left), long grass (middle), overgrown (right)
    -- Each tile is 64x64 pixels, arranged horizontally
    grass_quads[TILE_TYPES.SHORT_GRASS] = love.graphics.newQuad(0, 0, SPRITE_WIDTH, SPRITE_HEIGHT, grass_sprite:getWidth(), grass_sprite:getHeight())
    grass_quads[TILE_TYPES.LONG_GRASS] = love.graphics.newQuad(64, 0, SPRITE_WIDTH, SPRITE_HEIGHT, grass_sprite:getWidth(), grass_sprite:getHeight())
    grass_quads[TILE_TYPES.OVERGROWN] = love.graphics.newQuad(128, 0, SPRITE_WIDTH, SPRITE_HEIGHT, grass_sprite:getWidth(), grass_sprite:getHeight())
    
    -- Initialize random seed for tile generation
    math.randomseed(os.time())
    
    -- Generate all hex coordinates
    local coords = generate_hex_coordinates()
    
    -- Convert coordinates to pixel positions and assign random tile types
    for _, coord in ipairs(coords) do
        local x, y = hex_to_pixel(coord.q, coord.r)
        local tile_type = select_random_tile_type()
        table.insert(hexes, {
            q = coord.q,
            r = coord.r,
            x = x,
            y = y,
            tile_type = tile_type  -- Store which tile type this hex uses
        })
    end
    
    -- Sort hexes by Y coordinate (top to bottom) for correct rendering order
    -- Hexes at the top should be drawn first, so lower Y values come first
    table.sort(hexes, function(a, b)
        return a.y < b.y
    end)
    
    print("Generated " .. #hexes .. " hex tiles")
    print("Adjust HEX_SPACING_X and HEX_SPACING_Y at the top of main.lua to change spacing")
    
    -- Load character sprites
    char1_sprite = love.graphics.newImage("Char_McJaggy_Idle00.png")
    char1_w = char1_sprite:getWidth()
    char1_h = char1_sprite:getHeight()
    
    char2_sprite = love.graphics.newImage("Char_DMeowchi_Idle00.png")
    char2_w = char2_sprite:getWidth()
    char2_h = char2_sprite:getHeight()
    
    -- Initialize character positions to random hex centers
    char1_hex_index = get_random_hex_index()
    char1_pos.x = hexes[char1_hex_index].x
    char1_pos.y = hexes[char1_hex_index].y
    char1_move_cooldown = love.math.random(3, 8)
    
    char2_hex_index = get_random_hex_index()
    char2_pos.x = hexes[char2_hex_index].x
    char2_pos.y = hexes[char2_hex_index].y
    char2_move_cooldown = love.math.random(3, 8)
    
    -- Reset character animation states
    char1_visible = false
    char1_pop_progress = 0
    char1_vibrating = false
    char1_vibrate_timer = 0
    char1_moving = false
    
    char2_visible = false
    char2_pop_progress = 0
    char2_vibrating = false
    char2_vibrate_timer = 0
    char2_moving = false
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
    
    -- Update game timer
    game_timer = game_timer + dt
    
    -- Handle delayed spawn with pop-in scale animation for McJaggy
    if not char1_visible and game_timer >= char1_spawn_delay then
        char1_visible = true
        char1_pop_progress = 0
    end
    if char1_visible and char1_pop_progress < char1_pop_duration then
        char1_pop_progress = math.min(char1_pop_progress + dt, char1_pop_duration)
    end
    
    -- Handle delayed spawn with pop-in scale animation for DMeowchi
    if not char2_visible and game_timer >= char2_spawn_delay then
        char2_visible = true
        char2_pop_progress = 0
    end
    if char2_visible and char2_pop_progress < char2_pop_duration then
        char2_pop_progress = math.min(char2_pop_progress + dt, char2_pop_duration)
    end
    
    -- Handle vibration timer for McJaggy
    if char1_vibrating then
        char1_vibrate_timer = char1_vibrate_timer - dt
        if char1_vibrate_timer <= 0 then
            char1_vibrating = false
        end
    end
    
    -- Random movement between hexes for McJaggy
    -- When vibrating, move every 0.3-0.8 seconds instead
    if char1_visible then
        char1_move_cooldown = char1_move_cooldown - dt
        local cooldown_min, cooldown_max = 3, 8
        if char1_vibrating then
            cooldown_min, cooldown_max = 0.3, 0.8
        end
        
        if char1_move_cooldown <= 0 and not char1_moving then
            -- Select a random hex to move to
            local target_hex_index = get_random_hex_index()
            local target_hex = hexes[target_hex_index]
            
            char1_start_pos = { x = char1_pos.x, y = char1_pos.y }
            char1_move_duration = char1_vibrating and 0.4 or 0.9
            char1_move_elapsed = 0
            char1_moving = true
            char1_hex_index = target_hex_index
            char1_move_cooldown = love.math.random(cooldown_min, cooldown_max)
        end
        
        if char1_moving then
            char1_move_elapsed = char1_move_elapsed + dt
            local t = math.min(char1_move_elapsed / char1_move_duration, 1)
            local eased = 1 - (1 - t) * (1 - t)  -- ease-out quad
            
            local target_hex = hexes[char1_hex_index]
            char1_pos.x = char1_start_pos.x + (target_hex.x - char1_start_pos.x) * eased
            char1_pos.y = char1_start_pos.y + (target_hex.y - char1_start_pos.y) * eased
            
            if t >= 1 then
                char1_moving = false
                char1_pos.x = target_hex.x
                char1_pos.y = target_hex.y
            end
        end
    end
    
    -- Handle vibration timer for DMeowchi
    if char2_vibrating then
        char2_vibrate_timer = char2_vibrate_timer - dt
        if char2_vibrate_timer <= 0 then
            char2_vibrating = false
        end
    end
    
    -- Random movement between hexes for DMeowchi
    -- When vibrating, move every 0.3-0.8 seconds instead
    if char2_visible then
        char2_move_cooldown = char2_move_cooldown - dt
        local cooldown_min2, cooldown_max2 = 3, 8
        if char2_vibrating then
            cooldown_min2, cooldown_max2 = 0.3, 0.8
        end
        
        if char2_move_cooldown <= 0 and not char2_moving then
            -- Select a random hex to move to
            local target_hex_index = get_random_hex_index()
            local target_hex = hexes[target_hex_index]
            
            char2_start_pos = { x = char2_pos.x, y = char2_pos.y }
            char2_move_duration = char2_vibrating and 0.4 or 0.9
            char2_move_elapsed = 0
            char2_moving = true
            char2_hex_index = target_hex_index
            char2_move_cooldown = love.math.random(cooldown_min2, cooldown_max2)
        end
        
        if char2_moving then
            char2_move_elapsed = char2_move_elapsed + dt
            local t = math.min(char2_move_elapsed / char2_move_duration, 1)
            local eased = 1 - (1 - t) * (1 - t)  -- ease-out quad
            
            local target_hex = hexes[char2_hex_index]
            char2_pos.x = char2_start_pos.x + (target_hex.x - char2_start_pos.x) * eased
            char2_pos.y = char2_start_pos.y + (target_hex.y - char2_start_pos.y) * eased
            
            if t >= 1 then
                char2_moving = false
                char2_pos.x = target_hex.x
                char2_pos.y = target_hex.y
            end
        end
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
        
        -- Select the correct sprite and quad based on tile type
        local sprite_to_draw = blank_sprite
        local quad_to_draw = nil
        
        if hex.tile_type == TILE_TYPES.BLANK then
            sprite_to_draw = blank_sprite
            quad_to_draw = nil
        elseif hex.tile_type == TILE_TYPES.SHORT_GRASS or 
               hex.tile_type == TILE_TYPES.LONG_GRASS or 
               hex.tile_type == TILE_TYPES.OVERGROWN then
            sprite_to_draw = grass_sprite
            quad_to_draw = grass_quads[hex.tile_type]
        end
        
        -- Draw the sprite centered at the calculated position
        -- Apply scale and offset for centering
        love.graphics.setColor(1, 1, 1, 1)  -- Base color (white)
        if quad_to_draw then
            -- Draw using quad for grass tiles
            love.graphics.draw(
                sprite_to_draw,
                quad_to_draw,
                draw_x,
                draw_y,
                0,  -- rotation
                scale, scale,  -- scale x, scale y
                SPRITE_WIDTH / 2,  -- origin x (center)
                SPRITE_HEIGHT / 2  -- origin y (center)
            )
        else
            -- Draw without quad for blank tiles
            love.graphics.draw(
                sprite_to_draw,
                draw_x,
                draw_y,
                0,  -- rotation
                scale, scale,  -- scale x, scale y
                SPRITE_WIDTH / 2,  -- origin x (center)
                SPRITE_HEIGHT / 2  -- origin y (center)
            )
        end
        
        -- Apply lightening effect by drawing a white overlay with transparency
        -- The lighten_factor controls how much white to blend in
        if lighten_factor > 0 then
            -- Use additive blending to lighten: draw white with alpha based on lighten_factor
            -- This creates a brightening effect that works with any sprite color
            love.graphics.setBlendMode("add")
            love.graphics.setColor(lighten_factor, lighten_factor, lighten_factor, lighten_factor)
            if quad_to_draw then
                love.graphics.draw(
                    sprite_to_draw,
                    quad_to_draw,
                    draw_x,
                    draw_y,
                    0,  -- rotation
                    scale, scale,  -- scale x, scale y
                    SPRITE_WIDTH / 2,  -- origin x (center)
                    SPRITE_HEIGHT / 2  -- origin y (center)
                )
            else
                love.graphics.draw(
                    sprite_to_draw,
                    draw_x,
                    draw_y,
                    0,  -- rotation
                    scale, scale,  -- scale x, scale y
                    SPRITE_WIDTH / 2,  -- origin x (center)
                    SPRITE_HEIGHT / 2  -- origin y (center)
                )
            end
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
    love.graphics.print("Tile Probabilities - Blank: " .. (TILE_PROBABILITIES.blank * 100) .. "% | Short: " .. (TILE_PROBABILITIES.short_grass * 100) .. "% | Long: " .. (TILE_PROBABILITIES.long_grass * 100) .. "% | Overgrown: " .. (TILE_PROBABILITIES.overgrown * 100) .. "%", 10, title_y + TITLE_FONT_SIZE + 80)
    love.graphics.print("Adjust HOVER_* and TILE_PROBABILITIES in main.lua to customize", 10, title_y + TITLE_FONT_SIZE + 100)
    love.graphics.setColor(1, 1, 1, 1)  -- Reset to opaque white
    
    -- Draw characters last so they appear on top of hex tiles
    -- Draw McJaggy with pop-in scale and bobbing bounce
    if char1_visible and char1_sprite then
        local base_scale = char1_pop_progress / char1_pop_duration
        local scale = math.max(0, math.min(base_scale, 1))
        local bob = math.sin(love.timer.getTime() * 9) * 6
        
        -- Add fast vibration when clicked
        local vibrate_x, vibrate_y = 0, 0
        if char1_vibrating then
            local vibrate_intensity = 8
            vibrate_x = (love.math.random() - 0.5) * vibrate_intensity
            vibrate_y = (love.math.random() - 0.5) * vibrate_intensity
        end
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            char1_sprite,
            char1_pos.x + vibrate_x,
            char1_pos.y + bob + vibrate_y,
            0,
            scale,
            scale,
            char1_w / 2,
            char1_h / 2
        )
    end
    
    -- Draw DMeowchi with pop-in scale and bobbing bounce
    if char2_visible and char2_sprite then
        local base_scale2 = char2_pop_progress / char2_pop_duration
        local scale2 = math.max(0, math.min(base_scale2, 1))
        local bob2 = math.sin(love.timer.getTime() * 7 + 1.5) * 6  -- Slightly different bob timing
        
        -- Add fast vibration when clicked
        local vibrate_x2, vibrate_y2 = 0, 0
        if char2_vibrating then
            local vibrate_intensity2 = 8
            vibrate_x2 = (love.math.random() - 0.5) * vibrate_intensity2
            vibrate_y2 = (love.math.random() - 0.5) * vibrate_intensity2
        end
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            char2_sprite,
            char2_pos.x + vibrate_x2,
            char2_pos.y + bob2 + vibrate_y2,
            0,
            scale2,
            scale2,
            char2_w / 2,
            char2_h / 2
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

function love.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- Check if clicked on McJaggy
    if char1_visible and char1_sprite then
        local base_scale = char1_pop_progress / char1_pop_duration
        local scale = math.max(0, math.min(base_scale, 1))
        local bob = math.sin(love.timer.getTime() * 9) * 6
        local sprite_y = char1_pos.y + bob
        
        if is_click_on_sprite(x, y, char1_pos.x, sprite_y, char1_w, char1_h, scale) then
            char1_vibrating = true
            char1_vibrate_timer = char1_vibrate_duration
            char1_move_cooldown = 0  -- Trigger immediate movement
            return
        end
    end
    
    -- Check if clicked on DMeowchi
    if char2_visible and char2_sprite then
        local base_scale2 = char2_pop_progress / char2_pop_duration
        local scale2 = math.max(0, math.min(base_scale2, 1))
        local bob2 = math.sin(love.timer.getTime() * 7 + 1.5) * 6
        local sprite_y2 = char2_pos.y + bob2
        
        if is_click_on_sprite(x, y, char2_pos.x, sprite_y2, char2_w, char2_h, scale2) then
            char2_vibrating = true
            char2_vibrate_timer = char2_vibrate_duration
            char2_move_cooldown = 0  -- Trigger immediate movement
            return
        end
    end
end

