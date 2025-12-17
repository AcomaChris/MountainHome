-- Stub screen for Phase 0: Load Game
-- Placeholder for selecting and loading saved games

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')

local LoadGameScreen = {
    buttons = {},
}

function LoadGameScreen.enter(ctx)
    LoadGameScreen.last_transition = ctx
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 220, 44
    
    LoadGameScreen.buttons = {
        UIButton.new("Back to Menu", (w - btn_w) / 2, h - 80, btn_w, btn_h, function()
            bus.emit("load_game:back", { from = "load_game" })
        end),
    }
end

function LoadGameScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.1, 0.1, 0.15)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Load Game", 0, h * 0.3, w, "center")
    
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.printf("(Placeholder: Save file list coming soon)", 0, h * 0.4, w, "center")
    
    for _, btn in ipairs(LoadGameScreen.buttons) do
        btn:draw()
    end
end

function LoadGameScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    for _, btn in ipairs(LoadGameScreen.buttons) do
        if btn:mousepressed(x, y) then
            return
        end
    end
end

return LoadGameScreen

