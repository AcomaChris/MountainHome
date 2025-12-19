-- Load Game screen for Phase 2: Save Slot Selection
-- Displays up to 5 save slots with metadata
-- Clicking a slot loads the game and navigates to the game screen

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')
local SaveSystem = require('lib.save_system')
local log = require('lib.logger')

local LoadGameScreen = {
    buttons = {},
    slot_buttons = {},
    saves = {},
}

function LoadGameScreen.enter(ctx)
    LoadGameScreen.last_transition = ctx
    
    -- Refresh save list
    LoadGameScreen.saves = SaveSystem.list_saves()
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 300, 50
    local start_y = 120
    local spacing = 70
    
    -- Back button
    LoadGameScreen.back_button = UIButton.new("Back to Menu", 20, h - 60, 200, 40, function()
        bus.emit("load_game:back", { from = "load_game" })
    end)
    
    -- Create buttons for each save slot
    LoadGameScreen.slot_buttons = {}
    for i = 1, SaveSystem.MAX_SLOTS do
        local slot_data = nil
        -- Find save data for this slot
        for _, save in ipairs(LoadGameScreen.saves) do
            if save.slot == i then
                slot_data = save
                break
            end
        end
        
        local y = start_y + (i - 1) * spacing
        local btn
        
        if slot_data then
            -- Slot has a save - show location and metadata
            local metadata = slot_data.metadata
            local date_str = os.date("%Y-%m-%d", metadata.created_at or 0)
            local label = string.format("Slot %d: %s (%s) - Month %d - %s", 
                i, metadata.location_name or metadata.location, metadata.difficulty, 
                metadata.month or 1, date_str)
            btn = UIButton.new(label, (w - btn_w) / 2, y, btn_w, btn_h, function()
                log.info("load_game:slot_selected", { slot = i, location = metadata.location })
                bus.emit("load_game:load_slot", { slot = i })
            end)
        else
            -- Empty slot
            btn = UIButton.new("Slot " .. i .. ": (Empty)", (w - btn_w) / 2, y, btn_w, btn_h, function()
                -- Empty slot - do nothing or show message
            end)
            -- Make empty slots look disabled
            btn.bg = {0.1, 0.1, 0.12}
            btn.fg = {0.5, 0.5, 0.5}
            btn.hover_bg = {0.1, 0.1, 0.12}
        end
        
        table.insert(LoadGameScreen.slot_buttons, btn)
    end
end

function LoadGameScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.1, 0.1, 0.15)
    
    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Load Game", 0, 40, w, "center")
    
    -- Instructions
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.printf("Select a save slot to continue your homestead", 0, 80, w, "center")
    
    -- Draw slot buttons
    for _, btn in ipairs(LoadGameScreen.slot_buttons) do
        btn:draw()
    end
    
    -- Draw back button
    LoadGameScreen.back_button:draw()
end

function LoadGameScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- Check slot buttons
    for _, btn in ipairs(LoadGameScreen.slot_buttons) do
        if btn:mousepressed(x, y) then
            return
        end
    end
    
    -- Check back button
    if LoadGameScreen.back_button:mousepressed(x, y) then
        return
    end
end

return LoadGameScreen
