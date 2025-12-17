-- Stub screen for Phase 0: Options
-- Placeholder for game settings and configuration

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')

local OptionsScreen = {
    buttons = {},
}

function OptionsScreen.enter(ctx)
    OptionsScreen.last_transition = ctx
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 220, 44
    
    OptionsScreen.buttons = {
        UIButton.new("Back to Menu", (w - btn_w) / 2, h - 80, btn_w, btn_h, function()
            bus.emit("options:back", { from = "options" })
        end),
    }
end

function OptionsScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.1, 0.15, 0.15)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Options", 0, h * 0.3, w, "center")
    
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.printf("(Placeholder: Settings coming soon)", 0, h * 0.4, w, "center")
    
    for _, btn in ipairs(OptionsScreen.buttons) do
        btn:draw()
    end
end

function OptionsScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    for _, btn in ipairs(OptionsScreen.buttons) do
        if btn:mousepressed(x, y) then
            return
        end
    end
end

return OptionsScreen

