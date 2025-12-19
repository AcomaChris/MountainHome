-- Inventory system for Mountain Home.
-- Tracks items the player has purchased (characters, seeds, tools, buildings).
-- Items can be placed/used on hex tiles.

local Inventory = {
    -- Inventory storage
    characters = {},  -- Array of {id, data}
    seeds = {},       -- Array of {id, count, data}
    tools = {},       -- Array of {id, data}
    buildings = {},   -- Array of {id, count, data}
}

-- Add an item to inventory
-- @param category string: Item category
-- @param item_id string: Item ID
-- @param item_data table: Item data from TradeItems
function Inventory.add(category, item_id, item_data)
    if category == "characters" then
        table.insert(Inventory.characters, {id = item_id, data = item_data})
    elseif category == "seeds" then
        -- Check if already in inventory
        local found = false
        for _, seed in ipairs(Inventory.seeds) do
            if seed.id == item_id then
                seed.count = seed.count + 1
                found = true
                break
            end
        end
        if not found then
            table.insert(Inventory.seeds, {id = item_id, count = 1, data = item_data})
        end
    elseif category == "tools" then
        table.insert(Inventory.tools, {id = item_id, data = item_data})
    elseif category == "buildings" then
        local found = false
        for _, building in ipairs(Inventory.buildings) do
            if building.id == item_id then
                building.count = building.count + 1
                found = true
                break
            end
        end
        if not found then
            table.insert(Inventory.buildings, {id = item_id, count = 1, data = item_data})
        end
    end
end

-- Remove an item from inventory (for consumables like seeds)
-- @param category string: Item category
-- @param item_id string: Item ID
-- @return boolean: True if removed
function Inventory.remove(category, item_id)
    if category == "seeds" then
        for i, seed in ipairs(Inventory.seeds) do
            if seed.id == item_id then
                seed.count = seed.count - 1
                if seed.count <= 0 then
                    table.remove(Inventory.seeds, i)
                end
                return true
            end
        end
    elseif category == "buildings" then
        for i, building in ipairs(Inventory.buildings) do
            if building.id == item_id then
                building.count = building.count - 1
                if building.count <= 0 then
                    table.remove(Inventory.buildings, i)
                end
                return true
            end
        end
    end
    return false
end

-- Get inventory items
-- @param category string: Item category (optional, nil for all)
-- @return table: Inventory items
function Inventory.get(category)
    if category then
        return Inventory[category] or {}
    else
        return {
            characters = Inventory.characters,
            seeds = Inventory.seeds,
            tools = Inventory.tools,
            buildings = Inventory.buildings,
        }
    end
end

-- Check if player has an item
-- @param category string: Item category
-- @param item_id string: Item ID
-- @return boolean: True if has item
function Inventory.has(category, item_id)
    local items = Inventory.get(category)
    for _, item in ipairs(items) do
        if item.id == item_id then
            if item.count then
                return item.count > 0
            else
                return true
            end
        end
    end
    return false
end

-- Clear inventory (for new game)
function Inventory.clear()
    Inventory.characters = {}
    Inventory.seeds = {}
    Inventory.tools = {}
    Inventory.buildings = {}
end

return Inventory

