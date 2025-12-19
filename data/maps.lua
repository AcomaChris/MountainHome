-- Map data for each location in Mountain Home.
-- Defines starting hex tile configurations for each of the 6 locations.
-- Easy to edit - just modify the tile_id values in the hex_data arrays.

local Maps = {
    -- Map data for each location
    maps = {},
}

-- Register a map for a location
-- @param location_id string: Location ID (e.g., "revelstoke")
-- @param hex_data table: Array of {q, r, tile_id} for each hex
function Maps.register(location_id, hex_data)
    Maps.maps[location_id] = hex_data
end

-- Get map data for a location
-- @param location_id string: Location ID
-- @return table or nil: Map hex data
function Maps.get(location_id)
    return Maps.maps[location_id]
end

-- Initialize default maps (can be replaced with data files later)
function Maps.init_defaults()
    -- Generate a simple default map for all locations
    -- In the future, these can be loaded from JSON files or customized per location
    local function generate_default_map()
        local coords = {}
        for q = -5, 5 do
            local r1 = math.max(-5, -q - 5)
            local r2 = math.min(5, -q + 5)
            for r = r1, r2 do
                -- Random tile distribution (can be customized per location)
                local roll = love.math.random()
                local tile_id = "blank"
                if roll < 0.2 then
                    tile_id = "grass_cut"
                elseif roll < 0.5 then
                    tile_id = "grass_long"
                elseif roll < 0.7 then
                    tile_id = "grass_overgrown"
                end
                table.insert(coords, {q = q, r = r, tile_id = tile_id})
            end
        end
        return coords
    end
    
    -- Create default maps for all 6 locations
    local locations = {"revelstoke", "invermere", "radium_hot_springs", "golden", "jasper", "kananaskis_village"}
    for _, loc_id in ipairs(locations) do
        Maps.register(loc_id, generate_default_map())
    end
end

return Maps

