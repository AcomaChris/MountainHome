-- Stub screen for Phase 0: Achievements
-- Placeholder for displaying achievements and unlock conditions

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')

local AchievementsScreen = {
    buttons = {},
}

function AchievementsScreen.enter(ctx)
    AchievementsScreen.last_transition = ctx
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 220, 44
    
    AchievementsScreen.buttons = {
        UIButton.new("Back to Menu", (w - btn_w) / 2, h - 80, btn_w, btn_h, function()
            bus.emit("achievements:back", { from = "achievements" })
        end),
    }
end

function AchievementsScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.15, 0.1, 0.15)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Achievements", 0, h * 0.3, w, "center")
    
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.printf("(Placeholder: Achievement list coming soon)", 0, h * 0.4, w, "center")
    
    for _, btn in ipairs(AchievementsScreen.buttons) do
        btn:draw()
    end
end

function AchievementsScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    for _, btn in ipairs(AchievementsScreen.buttons) do
        if btn:mousepressed(x, y) then
            return
        end
    end
end

return AchievementsScreen

