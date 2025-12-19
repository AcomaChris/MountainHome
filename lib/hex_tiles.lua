-- Hex tile definitions for Mountain Home.
-- Defines tile types, their properties, images, and transformation rules.
-- Extensible system for adding new tile types and behaviors.

local HexTiles = {
    -- Tile type definitions
    tiles = {},
    
    -- Sprite storage
    sprites = {},
    quads = {},
}

-- Sprite dimensions
HexTiles.SPRITE_WIDTH = 64
HexTiles.SPRITE_HEIGHT = 64

-- Register a hex tile type
-- @param id string: Unique tile ID (e.g., "grass_cut")
-- @param data table: Tile properties {
--   name: Display name,
--   sprite_path: Path to sprite image,
--   quad_x, quad_y: Position in sprite sheet (if using sheet),
--   actions: Array of {name, cost, result_tile} actions available,
--   transforms_to: Array of tiles this can transform into over time,
--   resources: Resources produced when interacted with,
--   description: Tooltip description
-- }
function HexTiles.register(id, data)
    assert(type(id) == "string" and id ~= "", "id must be non-empty string")
    assert(type(data) == "table", "data must be a table")
    
    HexTiles.tiles[id] = {
        id = id,
        name = data.name or id,
        sprite_path = data.sprite_path,
        quad_x = data.quad_x,
        quad_y = data.quad_y,
        actions = data.actions or {},
        transforms_to = data.transforms_to or {},
        resources = data.resources or {},
        description = data.description or "",
    }
end

-- Load all tile sprites (call after registering all tiles)
function HexTiles.load_sprites()
    for id, tile in pairs(HexTiles.tiles) do
        if tile.sprite_path then
            -- Load sprite if not already loaded
            if not HexTiles.sprites[tile.sprite_path] then
                local success, sprite = pcall(love.graphics.newImage, tile.sprite_path)
                if success then
                    HexTiles.sprites[tile.sprite_path] = sprite
                else
                    print("Warning: Could not load sprite: " .. tile.sprite_path)
                end
            end
            
            -- Create quad if sprite sheet coordinates are provided
            if tile.quad_x and tile.quad_y and HexTiles.sprites[tile.sprite_path] then
                local sprite = HexTiles.sprites[tile.sprite_path]
                local quad_key = tile.sprite_path .. "_" .. tile.quad_x .. "_" .. tile.quad_y
                if not HexTiles.quads[quad_key] then
                    HexTiles.quads[quad_key] = love.graphics.newQuad(
                        tile.quad_x,
                        tile.quad_y,
                        HexTiles.SPRITE_WIDTH,
                        HexTiles.SPRITE_HEIGHT,
                        sprite:getWidth(),
                        sprite:getHeight()
                    )
                end
            end
        end
    end
end

-- Get tile definition by ID
-- @param id string: Tile ID
-- @return table or nil: Tile definition
function HexTiles.get(id)
    return HexTiles.tiles[id]
end

-- Get sprite for a tile
-- @param tile_id string: Tile ID
-- @return Image or nil: Sprite image
function HexTiles.get_sprite(tile_id)
    local tile = HexTiles.get(tile_id)
    if tile and tile.sprite_path then
        return HexTiles.sprites[tile.sprite_path]
    end
    return nil
end

-- Get quad for a tile (if using sprite sheet)
-- @param tile_id string: Tile ID
-- @return Quad or nil: Sprite quad
function HexTiles.get_quad(tile_id)
    local tile = HexTiles.get(tile_id)
    if tile and tile.sprite_path and tile.quad_x and tile.quad_y then
        local quad_key = tile.sprite_path .. "_" .. tile.quad_x .. "_" .. tile.quad_y
        return HexTiles.quads[quad_key]
    end
    return nil
end

-- Initialize default tile types
function HexTiles.init_defaults()
    -- Blank/base tile
    HexTiles.register("blank", {
        name = "Empty",
        sprite_path = "RAW/Sprites/BasicHexTile.png",
        description = "Empty land ready for development",
    })
    
    -- Grass tiles (using sprite sheet)
    HexTiles.register("grass_cut", {
        name = "Cut Grass",
        sprite_path = "examples/hex_map/Grass_Tile_Medium.png",
        quad_x = 0,
        quad_y = 0,
        description = "Freshly cut grass",
        actions = {
            {name = "Let Grow", cost = 0, result_tile = "grass_long"},
        },
        transforms_to = {"grass_long"},
    })
    
    HexTiles.register("grass_long", {
        name = "Long Grass",
        sprite_path = "examples/hex_map/Grass_Tile_Medium.png",
        quad_x = 64,
        quad_y = 0,
        description = "Long grass",
        actions = {
            {name = "Cut Grass", cost = 1, result_tile = "grass_cut", resources = {wood = 1}},
            {name = "Let Overgrow", cost = 0, result_tile = "grass_overgrown"},
        },
        transforms_to = {"grass_overgrown"},
    })
    
    HexTiles.register("grass_overgrown", {
        name = "Overgrown",
        sprite_path = "examples/hex_map/Grass_Tile_Medium.png",
        quad_x = 128,
        quad_y = 0,
        description = "Overgrown grass and weeds",
        actions = {
            {name = "Clear", cost = 2, result_tile = "grass_cut", resources = {wood = 2}},
        },
    })
    
    -- Load sprites after registration
    HexTiles.load_sprites()
end

return HexTiles

