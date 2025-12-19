-- Tile growth system for Mountain Home.
-- Processes natural tile transformations based on weather conditions.
-- Grass grows faster in sunny weather, slower in storms, stops in snow/ice.

local HexMap = require('lib.hex_map')
local HexTiles = require('lib.hex_tiles')
local log = require('lib.logger')

local TileGrowth = {}

-- Process growth for all tiles on the map based on weather
-- @param hex_map_data table: Array of hex data from game state
-- @param weather_effects table: Weather effects {plant_growth_multiplier, ...}
-- @return table: Updated hex_map_data with growth applied
function TileGrowth.process_growth(hex_map_data, weather_effects)
    if not hex_map_data or not weather_effects then
        return hex_map_data or {}
    end
    
    local growth_multiplier = weather_effects.plant_growth_multiplier or 1.0
    
    -- If growth is stopped (multiplier is 0), no growth happens
    if growth_multiplier <= 0 then
        log.info("tile_growth:stopped", { reason = "weather prevents growth", multiplier = growth_multiplier })
        return hex_map_data
    end
    
    -- Growth chance: multiplier > 1.0 means guaranteed growth, < 1.0 means reduced chance
    -- For multipliers > 1.0, we can grow multiple times (e.g., 2.0x = guaranteed growth)
    -- For multipliers < 1.0, it's a chance (e.g., 0.5x = 50% chance)
    local updated_count = 0
    
    for _, hex_data in ipairs(hex_map_data) do
        local tile_id = hex_data.tile_id
        local tile = HexTiles.get(tile_id)
        
        if tile and tile.transforms_to and #tile.transforms_to > 0 then
            -- This tile can transform
            local growth_attempts = math.floor(growth_multiplier)  -- Number of guaranteed growths
            local extra_chance = growth_multiplier - growth_attempts  -- Fractional chance for extra growth
            
            -- Apply guaranteed growths
            for i = 1, growth_attempts do
                local next_tile = tile.transforms_to[1]
                if next_tile then
                    hex_data.tile_id = next_tile
                    tile_id = next_tile  -- Update for next iteration
                    tile = HexTiles.get(next_tile)  -- Get new tile definition
                    updated_count = updated_count + 1
                    
                    -- Check if new tile can also transform
                    if not tile or not tile.transforms_to or #tile.transforms_to == 0 then
                        break  -- Can't grow further
                    end
                else
                    break
                end
            end
            
            -- Apply fractional chance for extra growth (if multiplier > 1.0)
            if extra_chance > 0 and tile and tile.transforms_to and #tile.transforms_to > 0 then
                local roll = love.math.random()
                if roll <= extra_chance then
                    local next_tile = tile.transforms_to[1]
                    if next_tile then
                        hex_data.tile_id = next_tile
                        updated_count = updated_count + 1
                    end
                end
            elseif growth_multiplier < 1.0 then
                -- For multipliers < 1.0, use it as a chance
                local roll = love.math.random()
                if roll <= growth_multiplier then
                    local next_tile = tile.transforms_to[1]
                    if next_tile then
                        hex_data.tile_id = next_tile
                        updated_count = updated_count + 1
                    end
                end
            end
        end
    end
    
    log.info("tile_growth:processed", { 
        total_hexes = #hex_map_data,
        updated = updated_count,
        multiplier = growth_multiplier 
    })
    
    return hex_map_data
end

-- Process growth for a single hex
-- @param hex_index number: Hex index in HexMap
-- @param weather_effects table: Weather effects
-- @return boolean: True if hex was transformed
function TileGrowth.process_hex_growth(hex_index, weather_effects)
    local hex = HexMap.get_hex(hex_index)
    if not hex then
        return false
    end
    
    local tile = HexTiles.get(hex.tile_id)
    if not tile or not tile.transforms_to or #tile.transforms_to == 0 then
        return false
    end
    
    local growth_multiplier = weather_effects.plant_growth_multiplier or 1.0
    if growth_multiplier <= 0 then
        return false
    end
    
    local growth_chance = math.min(1.0, growth_multiplier)
    local roll = love.math.random()
    
    if roll <= growth_chance then
        local next_tile = tile.transforms_to[1]
        if next_tile then
            HexMap.set_tile(hex_index, next_tile)
            return true
        end
    end
    
    return false
end

return TileGrowth

