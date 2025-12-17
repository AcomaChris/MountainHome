-- Stub screen for Phase 0: New Game Location Selection
-- Placeholder for selecting starting location on a map

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')

local NewGameLocationScreen = {
    buttons = {},
}

function NewGameLocationScreen.enter(ctx)
    NewGameLocationScreen.last_transition = ctx
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 220, 44
    
    NewGameLocationScreen.buttons = {
        UIButton.new("Back to Menu", (w - btn_w) / 2, h - 80, btn_w, btn_h, function()
            bus.emit("new_game_location:back", { from = "new_game_location" })
        end),
    }
end

function NewGameLocationScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.15, 0.1, 0.1)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("New Game - Location Select", 0, h * 0.3, w, "center")
    
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.printf("(Placeholder: Map selection coming soon)", 0, h * 0.4, w, "center")
    
    for _, btn in ipairs(NewGameLocationScreen.buttons) do
        btn:draw()
    end
end

function NewGameLocationScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    for _, btn in ipairs(NewGameLocationScreen.buttons) do
        if btn:mousepressed(x, y) then
            return
        end
    end
end

return NewGameLocationScreen

