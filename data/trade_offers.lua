-- Trade offer generation system.
-- Creates random trade offers that refresh monthly.
-- Editable probabilities and offer counts.

local TradeOffers = {
    -- Configuration
    OFFERS_PER_MONTH = 4,  -- Number of trade offers shown each month
    
    -- Probability weights for each category (higher = more likely)
    category_weights = {
        characters = 0.2,  -- 20% chance
        seeds = 0.3,       -- 30% chance
        tools = 0.3,       -- 30% chance
        buildings = 0.2,   -- 20% chance
    },
}

-- Generate random trade offers for the month
-- @return table: Array of trade offers {category, id, item, cost}
function TradeOffers.generate_monthly_offers()
    local TradeItems = require('data.trade_items')
    local offers = {}
    
    -- Calculate total weight
    local total_weight = 0
    for _, weight in pairs(TradeOffers.category_weights) do
        total_weight = total_weight + weight
    end
    
    -- Generate offers
    for i = 1, TradeOffers.OFFERS_PER_MONTH do
        -- Select category based on weights
        local roll = love.math.random() * total_weight
        local cumulative = 0
        local selected_category = nil
        
        for category, weight in pairs(TradeOffers.category_weights) do
            cumulative = cumulative + weight
            if roll <= cumulative then
                selected_category = category
                break
            end
        end
        
        -- Select random item from category
        if selected_category then
            local category_items = TradeItems.get_category(selected_category)
            local item_list = {}
            for id, item in pairs(category_items) do
                table.insert(item_list, {id = id, item = item})
            end
            
            if #item_list > 0 then
                local selected = item_list[love.math.random(1, #item_list)]
                table.insert(offers, {
                    category = selected_category,
                    id = selected.id,
                    item = selected.item,
                })
            end
        end
    end
    
    return offers
end

return TradeOffers

