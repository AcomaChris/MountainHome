-- Stub screen for Phase 0: Main Game Screen
-- Placeholder for the actual gameplay

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')

local GameScreen = {
    buttons = {},
}

function GameScreen.enter(ctx)
    GameScreen.last_transition = ctx
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 220, 44
    
    GameScreen.buttons = {
        UIButton.new("Back to Menu", (w - btn_w) / 2, h - 80, btn_w, btn_h, function()
            bus.emit("game:back", { from = "game" })
        end),
    }
end

function GameScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.1, 0.15, 0.1)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Game Screen", 0, h * 0.3, w, "center")
    
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.printf("(Placeholder: Hex grid and gameplay coming in Phase 2)", 0, h * 0.4, w, "center")
    
    for _, btn in ipairs(GameScreen.buttons) do
        btn:draw()
    end
end

function GameScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    for _, btn in ipairs(GameScreen.buttons) do
        if btn:mousepressed(x, y) then
            return
        end
    end
end

return GameScreen

