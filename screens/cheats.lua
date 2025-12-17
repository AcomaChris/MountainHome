-- Stub screen for Phase 0: Cheats
-- Placeholder for cheat code activation and toggles (secret screen)

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')

local CheatsScreen = {
    buttons = {},
}

function CheatsScreen.enter(ctx)
    CheatsScreen.last_transition = ctx
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 220, 44
    
    CheatsScreen.buttons = {
        UIButton.new("Back to Menu", (w - btn_w) / 2, h - 80, btn_w, btn_h, function()
            bus.emit("cheats:back", { from = "cheats" })
        end),
    }
end

function CheatsScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.2, 0.1, 0.1)
    
    love.graphics.setColor(1, 0.8, 0.8)
    love.graphics.printf("Cheats (Secret Screen)", 0, h * 0.3, w, "center")
    
    love.graphics.setColor(0.9, 0.7, 0.7)
    love.graphics.printf("(Placeholder: Cheat toggles coming in Phase 3)", 0, h * 0.4, w, "center")
    
    for _, btn in ipairs(CheatsScreen.buttons) do
        btn:draw()
    end
end

function CheatsScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    for _, btn in ipairs(CheatsScreen.buttons) do
        if btn:mousepressed(x, y) then
            return
        end
    end
end

return CheatsScreen

