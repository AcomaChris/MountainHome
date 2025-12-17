-- Placeholder menu screen for Phase 0 navigation prototype.
-- Displays basic text and listens for Enter to continue (emits an event) or Escape to quit.

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')

local MenuScreen = {
    title = "Mountain Home",
    subtitle = "Phase 0 Prototype",
    info = "Click a button to navigate.",
    buttons = {},
}

-- Called when entering the menu
function MenuScreen.enter(ctx)
    -- Store last transition for debugging visibility
    MenuScreen.last_transition = ctx

    -- Layout buttons vertically centered
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 220, 44
    local start_y = h * 0.4
    local btn_spacing = 50
    
    MenuScreen.buttons = {
        UIButton.new("New Game", (w - btn_w) / 2, start_y, btn_w, btn_h, function()
            bus.emit("menu:new_game", { from = "menu" })
        end),
        UIButton.new("Load Game", (w - btn_w) / 2, start_y + btn_spacing, btn_w, btn_h, function()
            bus.emit("menu:load_game", { from = "menu" })
        end),
        UIButton.new("Achievements", (w - btn_w) / 2, start_y + btn_spacing * 2, btn_w, btn_h, function()
            bus.emit("menu:achievements", { from = "menu" })
        end),
        UIButton.new("Options", (w - btn_w) / 2, start_y + btn_spacing * 3, btn_w, btn_h, function()
            bus.emit("menu:options", { from = "menu" })
        end),
        UIButton.new("Cheats", (w - btn_w) / 2, start_y + btn_spacing * 4, btn_w, btn_h, function()
            bus.emit("menu:cheats", { from = "menu" })
        end),
        UIButton.new("Quit", (w - btn_w) / 2, start_y + btn_spacing * 5, btn_w, btn_h, function()
            bus.emit("menu:quit", { from = "menu" })
        end),
    }
end

function MenuScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.1, 0.1, 0.12)

    local y = h * 0.35
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(MenuScreen.title, 0, y, w, "center")

    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.printf(MenuScreen.subtitle, 0, y + 32, w, "center")

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.printf(MenuScreen.info, 0, y + 64, w, "center")

    if MenuScreen.last_transition then
        love.graphics.setColor(0.6, 0.6, 0.8)
        local msg = string.format("from: %s  to: %s", tostring(MenuScreen.last_transition.from), tostring(MenuScreen.last_transition.to))
        love.graphics.printf(msg, 0, y + 96, w, "center")
    end

    for _, btn in ipairs(MenuScreen.buttons) do
        btn:draw()
    end
end

function MenuScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    for _, btn in ipairs(MenuScreen.buttons) do
        if btn:mousepressed(x, y) then
            return
        end
    end
end

return MenuScreen

