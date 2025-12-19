-- Trade screen for Mountain Home.
-- Displays monthly trade offers that can be purchased with resources.

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')
local TradeItems = require('data.trade_items')
local TradeOffers = require('data.trade_offers')
local Inventory = require('lib.inventory')
local log = require('lib.logger')
local text_utils = require('lib.text_utils')

local TradeScreen = {
    buttons = {},
    offer_buttons = {},
    offers = {},
    game_data = nil,
}

function TradeScreen.enter(ctx)
    TradeScreen.last_transition = ctx
    
    -- Get game data from context
    -- Screen manager wraps data in ctx.data
    local slot = nil
    if ctx then
        if ctx.data and ctx.data.slot then
            slot = ctx.data.slot
        elseif ctx.data and ctx.data.data and ctx.data.data.slot then
            slot = ctx.data.data.slot
        elseif ctx.slot then
            slot = ctx.slot
        end
    end
    if slot then
        local SaveSystem = require('lib.save_system')
        TradeScreen.game_data = SaveSystem.load_game(slot)
    end
    
    -- Generate or load monthly offers
    if TradeScreen.game_data then
        -- Check if offers exist for current month
        local month_key = "trade_offers_month_" .. (TradeScreen.game_data.month or 1)
        if TradeScreen.game_data[month_key] then
            TradeScreen.offers = TradeScreen.game_data[month_key]
        else
            -- Generate new offers for this month
            TradeScreen.offers = TradeOffers.generate_monthly_offers()
            TradeScreen.game_data[month_key] = TradeScreen.offers
            if slot then
                local SaveSystem = require('lib.save_system')
                SaveSystem.save_game(slot, TradeScreen.game_data)
            end
        end
        
        -- Load inventory from game data
        if TradeScreen.game_data.inventory then
            Inventory.characters = TradeScreen.game_data.inventory.characters or {}
            Inventory.seeds = TradeScreen.game_data.inventory.seeds or {}
            Inventory.tools = TradeScreen.game_data.inventory.tools or {}
            Inventory.buildings = TradeScreen.game_data.inventory.buildings or {}
        end
    else
        TradeScreen.offers = {}
    end
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 220, 44
    
    -- Store slot for later use
    TradeScreen.current_slot = slot
    
    -- Back button
    TradeScreen.back_button = UIButton.new("Back to Game", 20, h - 60, btn_w, btn_h, function()
        -- Save inventory back to game data
        if TradeScreen.game_data and TradeScreen.current_slot then
            TradeScreen.game_data.inventory = {
                characters = Inventory.characters,
                seeds = Inventory.seeds,
                tools = Inventory.tools,
                buildings = Inventory.buildings,
            }
            local SaveSystem = require('lib.save_system')
            SaveSystem.save_game(TradeScreen.current_slot, TradeScreen.game_data)
        end
        bus.emit("trade:back", { from = "trade", slot = TradeScreen.current_slot })
    end)
    
    -- Create offer buttons
    TradeScreen.offer_buttons = {}
    local start_y = 120
    local spacing = 100
    local offer_w = w - 100
    local offer_h = 80
    
    for i, offer in ipairs(TradeScreen.offers) do
        local y = start_y + (i - 1) * spacing
        local item = offer.item
        
        -- Create cost text
        local cost_text = ""
        if item.cost then
            local cost_parts = {}
            for resource, amount in pairs(item.cost) do
                table.insert(cost_parts, resource .. ": " .. amount)
            end
            cost_text = table.concat(cost_parts, ", ")
        end
        
        -- Check if player can afford
        local can_afford = true
        if item.cost and TradeScreen.game_data and TradeScreen.game_data.resources then
            for resource, amount in pairs(item.cost) do
                if (TradeScreen.game_data.resources[resource] or 0) < amount then
                    can_afford = false
                    break
                end
            end
        end
        
        local btn = UIButton.new("", 50, y, offer_w, offer_h, function()
            if can_afford and TradeScreen.game_data then
                -- Deduct costs
                for resource, amount in pairs(item.cost) do
                    TradeScreen.game_data.resources[resource] = (TradeScreen.game_data.resources[resource] or 0) - amount
                end
                
                -- Add to inventory
                Inventory.add(offer.category, offer.id, item)
                
                -- Save game
                if TradeScreen.current_slot then
                    TradeScreen.game_data.inventory = {
                        characters = Inventory.characters,
                        seeds = Inventory.seeds,
                        tools = Inventory.tools,
                        buildings = Inventory.buildings,
                    }
                    local SaveSystem = require('lib.save_system')
                    SaveSystem.save_game(TradeScreen.current_slot, TradeScreen.game_data)
                end
                
                log.info("trade:purchased", { category = offer.category, id = offer.id })
                
                -- Refresh screen to update offers
                local ctx_refresh = { data = { slot = TradeScreen.current_slot } }
                TradeScreen.enter(ctx_refresh)
            end
        end)
        
        -- Store offer data in button
        btn.offer = offer
        btn.can_afford = can_afford
        btn.cost_text = cost_text
        
        -- Color based on affordability
        if not can_afford then
            btn.bg = {0.15, 0.15, 0.15}
            btn.fg = {0.5, 0.5, 0.5}
        end
        
        table.insert(TradeScreen.offer_buttons, btn)
    end
end

function TradeScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.15, 0.12, 0.1)
    
    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Trade", 0, 40, w, "center")
    
    -- Draw resources
    if TradeScreen.game_data and TradeScreen.game_data.resources then
        local res = TradeScreen.game_data.resources
        love.graphics.setColor(0.8, 0.8, 0.9)
        local resource_text = string.format("Wood: %d | Money: %d | Stone: %d | Fruit: %d | Veg: %d | Meat: %d",
            res.wood or 0, res.money or 0, res.stone or 0, res.fruit or 0, res.vegetables or 0, res.meat or 0)
        love.graphics.printf(text_utils.clean(resource_text), 10, 70, w - 20, "left")
    end
    
    -- Draw offers
    for i, btn in ipairs(TradeScreen.offer_buttons) do
        local offer = btn.offer
        if offer then
            local item = offer.item
            local y = btn.y
            
            -- Draw offer card background
            love.graphics.setColor(btn.bg[1], btn.bg[2], btn.bg[3])
            love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 6, 6)
            love.graphics.setColor(0.3, 0.35, 0.4)
            love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 6, 6)
            
            -- Draw item name and description
            love.graphics.setColor(btn.fg[1], btn.fg[2], btn.fg[3])
            love.graphics.printf(item.name, btn.x + 10, y + 10, btn.w - 20, "left")
            love.graphics.setColor(0.7, 0.7, 0.8)
            love.graphics.printf(item.description, btn.x + 10, y + 30, btn.w - 20, "left")
            
            -- Draw cost
            love.graphics.setColor(0.8, 0.7, 0.6)
            love.graphics.printf("Cost: " .. btn.cost_text, btn.x + 10, y + 55, btn.w - 20, "left")
        end
    end
    
    -- Draw back button
    TradeScreen.back_button:draw()
end

function TradeScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- Check offer buttons
    for _, btn in ipairs(TradeScreen.offer_buttons) do
        if btn:mousepressed(x, y) then
            return
        end
    end
    
    -- Check back button
    if TradeScreen.back_button:mousepressed(x, y) then
        return
    end
end

return TradeScreen

