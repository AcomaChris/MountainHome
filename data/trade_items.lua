-- Trade item definitions for Mountain Home.
-- Editable data file for balancing trades without coding.
-- Items include characters, seeds, tools, and buildings.

local TradeItems = {
    -- Character definitions
    characters = {
        mcjaggy = {
            id = "mcjaggy",
            name = "McJaggy",
            sprite_path = "RAW/Sprites/Char_McJaggy_Idle00.png",
            description = "A helpful companion who provides +2 Action Points per month",
            cost = {
                money = 200,
                meat = 5,
            },
            ability = {
                type = "action_points",
                value = 2,
            },
            upkeep = {
                meat = 1,  -- Requires 1 meat per month or leaves
            },
        },
        dmeowchi = {
            id = "dmeowchi",
            name = "Disapproval Meowchi",
            sprite_path = "RAW/Sprites/Char_DMeowchi_Idle00.png",
            description = "A grumpy cat that reduces action costs by 1 (minimum 1)",
            cost = {
                money = 150,
                vegetables = 3,
            },
            ability = {
                type = "cost_reduction",
                value = 1,
            },
            upkeep = {
                vegetables = 1,  -- Requires 1 vegetable per month or leaves
            },
        },
    },
    
    -- Seed/plant definitions
    seeds = {
        berry_bush = {
            id = "berry_bush",
            name = "Berry Bush Seeds",
            description = "Plant to grow berry bushes that produce fruit",
            cost = {
                money = 50,
            },
            plantable_on = {"grass_cut", "blank"},  -- Can plant on these tile types
            grows_to = "berry_bush_tile",  -- Tile type it becomes
            produces = {
                fruit = 2,  -- Produces 2 fruit per month when mature
            },
        },
        vegetable_garden = {
            id = "vegetable_garden",
            name = "Vegetable Seeds",
            description = "Plant to grow vegetables",
            cost = {
                money = 40,
            },
            plantable_on = {"grass_cut", "blank"},
            grows_to = "vegetable_garden_tile",
            produces = {
                vegetables = 3,
            },
        },
    },
    
    -- Tool definitions
    tools = {
        sharp_axe = {
            id = "sharp_axe",
            name = "Sharp Axe",
            description = "Reduces wood harvesting costs by 1 AP",
            cost = {
                money = 100,
                wood = 5,
            },
            effect = {
                type = "cost_modifier",
                action_type = "harvest_wood",
                modifier = -1,
            },
        },
        sturdy_shovel = {
            id = "sturdy_shovel",
            name = "Sturdy Shovel",
            description = "Reduces land clearing costs by 1 AP",
            cost = {
                money = 80,
                stone = 3,
            },
            effect = {
                type = "cost_modifier",
                action_type = "clear_land",
                modifier = -1,
            },
        },
    },
    
    -- Building definitions
    buildings = {
        storage_shed = {
            id = "storage_shed",
            name = "Storage Shed",
            description = "Increases resource storage capacity",
            cost = {
                money = 150,
                wood = 10,
            },
            sprite_path = "RAW/Sprites/BasicHexTile.png",  -- Placeholder
            radius = 1,  -- Affects hexes within 1 tile
            bonus = {
                type = "storage",
                value = 50,
            },
        },
        workshop = {
            id = "workshop",
            name = "Workshop",
            description = "Reduces building costs by 10% in nearby hexes",
            cost = {
                money = 200,
                wood = 15,
                stone = 5,
            },
            sprite_path = "RAW/Sprites/BasicHexTile.png",  -- Placeholder
            radius = 2,
            bonus = {
                type = "cost_reduction",
                value = 0.1,  -- 10% reduction
            },
        },
    },
}

-- Get all trade items of a type
-- @param category string: "characters", "seeds", "tools", or "buildings"
-- @return table: Array of items
function TradeItems.get_category(category)
    return TradeItems[category] or {}
end

-- Get a specific item by ID
-- @param category string: Item category
-- @param id string: Item ID
-- @return table or nil: Item data
function TradeItems.get(category, id)
    local category_items = TradeItems[category]
    if category_items then
        return category_items[id]
    end
    return nil
end

-- Get all items as a flat list for trade offers
-- @return table: Array of {category, id, item_data}
function TradeItems.get_all()
    local all = {}
    for category, items in pairs(TradeItems) do
        if type(items) == "table" and category ~= "get_category" and category ~= "get" and category ~= "get_all" then
            for id, item in pairs(items) do
                if type(item) == "table" and item.id then
                    table.insert(all, {
                        category = category,
                        id = id,
                        item = item,
                    })
                end
            end
        end
    end
    return all
end

return TradeItems

