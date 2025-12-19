-- Item placement system for Mountain Home.
-- Handles placing inventory items (seeds, buildings) on hex tiles.
-- Validates placement rules and updates hex map.

local ItemPlacement = {
    selected_item = nil,  -- Currently selected inventory item for placement
    selected_category = nil,
}

-- Select an item for placement
-- @param category string: Item category ("seeds", "buildings")
-- @param item_id string: Item ID
function ItemPlacement.select(category, item_id)
    local Inventory = require('lib.inventory')
    local TradeItems = require('data.trade_items')
    
    -- Check if item is in inventory
    if Inventory.has(category, item_id) then
        local item = TradeItems.get(category, item_id)
        if item then
            ItemPlacement.selected_item = item
            ItemPlacement.selected_category = category
            return true
        end
    end
    return false
end

-- Clear selection
function ItemPlacement.clear()
    ItemPlacement.selected_item = nil
    ItemPlacement.selected_category = nil
end

-- Check if an item can be placed on a hex
-- @param hex_index number: Hex index
-- @param item table: Item data
-- @return boolean: True if can place
function ItemPlacement.can_place_on(hex_index, item)
    local HexMap = require('lib.hex_map')
    local hex = HexMap.get_hex(hex_index)
    if not hex then return false end
    
    if ItemPlacement.selected_category == "seeds" then
        -- Seeds can be placed on specific tile types
        if item.plantable_on then
            for _, tile_type in ipairs(item.plantable_on) do
                if hex.tile_id == tile_type then
                    return true
                end
            end
        end
    elseif ItemPlacement.selected_category == "buildings" then
        -- Buildings can be placed on cleared land
        if hex.tile_id == "blank" or hex.tile_id == "grass_cut" then
            return true
        end
    end
    
    return false
end

-- Place an item on a hex
-- @param hex_index number: Hex index
-- @return boolean: True if placed successfully
function ItemPlacement.place(hex_index)
    if not ItemPlacement.selected_item or not ItemPlacement.selected_category then
        return false
    end
    
    local HexMap = require('lib.hex_map')
    local Inventory = require('lib.inventory')
    
    -- Check if can place
    if not ItemPlacement.can_place_on(hex_index, ItemPlacement.selected_item) then
        return false
    end
    
    -- Place the item
    if ItemPlacement.selected_category == "seeds" then
        -- Transform hex to the plant tile
        if ItemPlacement.selected_item.grows_to then
            HexMap.set_tile(hex_index, ItemPlacement.selected_item.grows_to)
            -- Remove from inventory
            Inventory.remove("seeds", ItemPlacement.selected_item.id)
            return true
        end
    elseif ItemPlacement.selected_category == "buildings" then
        -- Place building (for now, just mark the hex)
        -- TODO: Store building data on hex
        HexMap.set_tile(hex_index, "building_" .. ItemPlacement.selected_item.id)
        Inventory.remove("buildings", ItemPlacement.selected_item.id)
        return true
    end
    
    return false
end

return ItemPlacement

