-- Hex map system for Mountain Home.
-- Handles hex coordinate conversion, map generation, and tile management.
-- Based on the hex_map example but integrated into the game system.

local HexTiles = require('lib.hex_tiles')

local HexMap = {
    -- Configuration
    HEX_SPACING_X = 32,
    HEX_SPACING_Y = 24,
    GRID_RADIUS = 5,  -- Creates a radius-5 hex grid
    OFFSET_X = 400,
    OFFSET_Y = 300,
    SPRITE_WIDTH = 64,
    
    -- State
    hexes = {},
    hovered_hex_index = nil,
}

-- Convert axial hex coordinates (q, r) to screen pixel coordinates
-- @param q number: Column coordinate (horizontal)
-- @param r number: Row coordinate (diagonal)
-- @return number, number: Screen X and Y pixel positions
function HexMap.hex_to_pixel(q, r)
    local x = HexMap.HEX_SPACING_X * (q * 1.5)
    local y = HexMap.HEX_SPACING_Y * (r + q * 0.5)
    return x + HexMap.OFFSET_X, y + HexMap.OFFSET_Y
end

-- Generate all hex coordinates within the grid radius
-- @return table: Array of {q, r} coordinate pairs
function HexMap.generate_hex_coordinates()
    local coords = {}
    for q = -HexMap.GRID_RADIUS, HexMap.GRID_RADIUS do
        local r1 = math.max(-HexMap.GRID_RADIUS, -q - HexMap.GRID_RADIUS)
        local r2 = math.min(HexMap.GRID_RADIUS, -q + HexMap.GRID_RADIUS)
        for r = r1, r2 do
            table.insert(coords, {q = q, r = r})
        end
    end
    return coords
end

-- Check if a point (mouse position) is over a hex
-- @param mx number: Mouse X position
-- @param my number: Mouse Y position
-- @param hex table: Hex object with x, y properties
-- @return boolean: True if mouse is over the hex
function HexMap.is_mouse_over_hex(mx, my, hex)
    local dx = mx - hex.x
    local dy = my - hex.y
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance <= HexMap.SPRITE_WIDTH / 2
end

-- Find which hex (if any) the mouse is currently over
-- @param mx number: Mouse X position
-- @param my number: Mouse Y position
-- @return number|nil: Index of hovered hex, or nil if none
function HexMap.find_hovered_hex(mx, my)
    for i = #HexMap.hexes, 1, -1 do
        if HexMap.is_mouse_over_hex(mx, my, HexMap.hexes[i]) then
            return i
        end
    end
    return nil
end

-- Calculate center offset for hex grid based on screen size
-- @param screen_w number: Screen width
-- @param screen_h number: Screen height
-- @param top_margin number: Space at top (for timeline, etc.)
function HexMap.calculate_center_offset(screen_w, screen_h, top_margin)
    top_margin = top_margin or 0
    
    -- Calculate hex grid bounds (without offset)
    local min_x, max_x = math.huge, -math.huge
    local min_y, max_y = math.huge, -math.huge
    
    for q = -HexMap.GRID_RADIUS, HexMap.GRID_RADIUS do
        local r1 = math.max(-HexMap.GRID_RADIUS, -q - HexMap.GRID_RADIUS)
        local r2 = math.min(HexMap.GRID_RADIUS, -q + HexMap.GRID_RADIUS)
        for r = r1, r2 do
            local x = HexMap.HEX_SPACING_X * (q * 1.5)
            local y = HexMap.HEX_SPACING_Y * (r + q * 0.5)
            min_x = math.min(min_x, x)
            max_x = math.max(max_x, x)
            min_y = math.min(min_y, y)
            max_y = math.max(max_y, y)
        end
    end
    
    -- Calculate center offset to center the grid on screen
    local grid_width = max_x - min_x
    local grid_height = max_y - min_y
    HexMap.OFFSET_X = (screen_w - grid_width) / 2 - min_x
    HexMap.OFFSET_Y = top_margin + (screen_h - top_margin - grid_height) / 2 - min_y
end

-- Create a map from tile data
-- @param tile_data table: Array of {q, r, tile_id} for each hex
-- @param screen_w number: Screen width (optional, for centering)
-- @param screen_h number: Screen height (optional, for centering)
-- @param top_margin number: Top margin for UI (optional)
function HexMap.create_from_data(tile_data, screen_w, screen_h, top_margin)
    HexMap.hexes = {}
    
    -- Calculate center offset if screen dimensions provided
    if screen_w and screen_h then
        HexMap.calculate_center_offset(screen_w, screen_h, top_margin)
    end
    
    for _, data in ipairs(tile_data) do
        local x, y = HexMap.hex_to_pixel(data.q, data.r)
        table.insert(HexMap.hexes, {
            q = data.q,
            r = data.r,
            x = x,
            y = y,
            tile_id = data.tile_id or "blank",
        })
    end
    
    -- Sort by Y coordinate for correct rendering order
    table.sort(HexMap.hexes, function(a, b)
        return a.y < b.y
    end)
end

-- Get hex at index
-- @param index number: Hex index
-- @return table or nil: Hex data
function HexMap.get_hex(index)
    return HexMap.hexes[index]
end

-- Set tile type for a hex
-- @param index number: Hex index
-- @param tile_id string: New tile ID
function HexMap.set_tile(index, tile_id)
    if HexMap.hexes[index] then
        HexMap.hexes[index].tile_id = tile_id
    end
end

-- Update hover state (call from update loop)
-- @param mx number: Mouse X
-- @param my number: Mouse Y
function HexMap.update_hover(mx, my)
    HexMap.hovered_hex_index = HexMap.find_hovered_hex(mx, my)
end

return HexMap

