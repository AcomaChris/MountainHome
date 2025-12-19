-- Simple clickable button for mouse/touch navigation.
-- Usage:
--   local button = UIButton.new("Label", x, y, w, h, on_click)
--   button:draw()
--   button:mousepressed(x, y)
-- Color scheme is minimal programmer art; adjust as needed.

local text_utils = require('lib.text_utils')

local UIButton = {}
UIButton.__index = UIButton

function UIButton.new(label, x, y, w, h, on_click)
    local self = setmetatable({}, UIButton)
    -- Remove semicolons and other unsupported characters from button labels
    self.label = text_utils.clean(label or "")
    self.x = x or 0
    self.y = y or 0
    self.w = w or 160
    self.h = h or 44
    self.on_click = on_click
    self.bg = {0.16, 0.2, 0.26}
    self.fg = {0.9, 0.9, 0.95}
    self.hover_bg = {0.22, 0.27, 0.34}
    return self
end

function UIButton:contains(px, py)
    return px >= self.x and px <= self.x + self.w and py >= self.y and py <= self.y + self.h
end

function UIButton:draw()
    local mx, my = love.mouse.getPosition()
    local is_hover = self:contains(mx, my)
    if is_hover then
        love.graphics.setColor(self.hover_bg)
    else
        love.graphics.setColor(self.bg)
    end
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 6, 6)
    love.graphics.setColor(self.fg)
    love.graphics.printf(self.label, self.x, self.y + (self.h - love.graphics.getFont():getHeight()) / 2, self.w, "center")
end

function UIButton:mousepressed(x, y)
    if self.on_click and self:contains(x, y) then
        -- Call the callback, catching any errors
        local success, err = pcall(self.on_click)
        if not success then
            print("UIButton: Error in on_click callback: " .. tostring(err))
        end
        return true
    end
    return false
end

return UIButton

