-- Stub screen for Phase 0: Quit Confirmation
-- Placeholder for quit confirmation dialog

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')

local QuitScreen = {
    buttons = {},
}

function QuitScreen.enter(ctx)
    QuitScreen.last_transition = ctx
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 180, 44
    local btn_spacing = 20
    
    QuitScreen.buttons = {
        UIButton.new("Yes, Quit", (w - btn_w * 2 - btn_spacing) / 2, h * 0.55, btn_w, btn_h, function()
            love.event.quit()
        end),
        UIButton.new("Cancel", (w + btn_spacing) / 2, h * 0.55, btn_w, btn_h, function()
            bus.emit("quit:cancel", { from = "quit" })
        end),
    }
end

function QuitScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.12, 0.08, 0.08)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Quit Game?", 0, h * 0.35, w, "center")
    
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.printf("Are you sure you want to quit?", 0, h * 0.45, w, "center")
    
    for _, btn in ipairs(QuitScreen.buttons) do
        btn:draw()
    end
end

function QuitScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    for _, btn in ipairs(QuitScreen.buttons) do
        if btn:mousepressed(x, y) then
            return
        end
    end
end

return QuitScreen

