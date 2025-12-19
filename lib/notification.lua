-- Notification system for displaying messages that slide in from the top right.
-- Supports multiple notifications stacking vertically.
-- Example:
--   local notify = require('lib.notification')
--   notify.show("Cheat activated!", 3.0) -- Shows for 3 seconds

local text_utils = require('lib.text_utils')

local Notification = {
    notifications = {},
}

-- Show a notification
-- @param message string: The message to display
-- @param duration number: How long to show it (seconds, default 3.0)
-- @param color table: RGB color {r, g, b} (default white)
function Notification.show(message, duration, color)
    duration = duration or 3.0
    color = color or {1, 1, 1}
    
    -- Remove semicolons and other unsupported characters from notification messages
    message = text_utils.clean(message)
    
    local notification = {
        message = message,
        duration = duration,
        time_remaining = duration,
        color = color,
        slide_progress = 0, -- 0 = off screen, 1 = fully visible
        slide_speed = 8.0, -- How fast it slides in/out
    }
    
    table.insert(Notification.notifications, notification)
end

-- Update all notifications (call from love.update)
-- @param dt number: Delta time
function Notification.update(dt)
    for i = #Notification.notifications, 1, -1 do
        local notif = Notification.notifications[i]
        
        -- Update slide animation
        if notif.time_remaining > notif.duration - 0.3 then
            -- Sliding in (first 0.3 seconds)
            notif.slide_progress = math.min(1.0, notif.slide_progress + dt * notif.slide_speed)
        elseif notif.time_remaining < 0.3 then
            -- Sliding out (last 0.3 seconds)
            notif.slide_progress = math.max(0.0, notif.slide_progress - dt * notif.slide_speed)
        else
            -- Fully visible
            notif.slide_progress = 1.0
        end
        
        -- Update timer
        notif.time_remaining = notif.time_remaining - dt
        
        -- Remove expired notifications
        if notif.time_remaining <= 0 then
            table.remove(Notification.notifications, i)
        end
    end
end

-- Draw all notifications (call from love.draw)
function Notification.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local font = love.graphics.getFont()
    local font_height = font:getHeight()
    local padding = 12
    local spacing = 8
    local start_x = w - 350 -- Start from right side
    local start_y = 20
    
    -- Draw notifications from top to bottom
    for i, notif in ipairs(Notification.notifications) do
        local message_width = font:getWidth(notif.message)
        local box_width = math.max(300, message_width + padding * 2)
        local box_height = font_height + padding * 2
        
        -- Calculate position with slide animation
        -- Slide from right (off-screen) to visible position
        local slide_offset = (1.0 - notif.slide_progress) * (box_width + 50)
        local x = start_x - slide_offset
        local y = start_y + (i - 1) * (box_height + spacing)
        
        -- Draw background
        love.graphics.setColor(0.1, 0.1, 0.15, 0.95 * notif.slide_progress)
        love.graphics.rectangle("fill", x, y, box_width, box_height, 6, 6)
        
        -- Draw border
        love.graphics.setColor(0.3, 0.35, 0.4, notif.slide_progress)
        love.graphics.rectangle("line", x, y, box_width, box_height, 6, 6)
        
        -- Draw text
        love.graphics.setColor(notif.color[1], notif.color[2], notif.color[3], notif.slide_progress)
        love.graphics.print(notif.message, x + padding, y + padding)
    end
end

return Notification

