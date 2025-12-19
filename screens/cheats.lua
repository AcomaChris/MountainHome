-- Cheats screen for Phase 2: Display discovered cheats
-- Shows toggleable cheats (on/off) and button cheats (one-time actions)
-- Cheats are discovered by typing cheat codes in-game

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')
local cheat_system = require('lib.cheat_system')
local notification = require('lib.notification')
local log = require('lib.logger')
local text_utils = require('lib.text_utils')

local CheatsScreen = {
    buttons = {},
    cheat_buttons = {},
    toggle_buttons = {},
}

function CheatsScreen.enter(ctx)
    CheatsScreen.last_transition = ctx
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 220, 44
    
    -- Back button
    CheatsScreen.back_button = UIButton.new("Back to Menu", 20, h - 60, btn_w, btn_h, function()
        bus.emit("cheats:back", { from = "cheats" })
    end)
    
    -- Refresh cheat list
    CheatsScreen.refresh_cheats()
end

-- Refresh the list of discovered cheats and create UI elements
function CheatsScreen.refresh_cheats()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 280, 50
    local start_y = 120
    local spacing = 60
    
    CheatsScreen.cheat_buttons = {}
    CheatsScreen.toggle_buttons = {}
    
    local discovered = cheat_system.get_discovered()
    
    if #discovered == 0 then
        -- No cheats discovered yet
        return
    end
    
    for i, cheat in ipairs(discovered) do
        local y = start_y + (i - 1) * spacing
        
        if cheat.type == "toggle" then
            -- Toggle cheat - show current state
            local state_text = cheat.state and "ON" or "OFF"
            local label = cheat.name .. " (" .. state_text .. ")"
            local btn = UIButton.new(label, (w - btn_w) / 2, y, btn_w, btn_h, function()
                cheat_system.toggle(cheat.code)
                -- Refresh to get updated state
                CheatsScreen.refresh_cheats()
                -- Get updated cheat data to show correct state
                local updated = cheat_system.get_discovered()
                local new_state = false
                for _, c in ipairs(updated) do
                    if c.code == cheat.code then
                        new_state = c.state
                        break
                    end
                end
                notification.show("Cheat " .. cheat.name .. " " .. (new_state and "enabled" or "disabled"), 2.0, {0.7, 0.9, 0.7})
            end)
            -- Color based on state
            if cheat.state then
                btn.bg = {0.2, 0.4, 0.2}
                btn.hover_bg = {0.25, 0.5, 0.25}
            else
                btn.bg = {0.2, 0.2, 0.2}
                btn.hover_bg = {0.25, 0.25, 0.25}
            end
            table.insert(CheatsScreen.toggle_buttons, btn)
        else
            -- Button cheat - one-time action
            local btn = UIButton.new(cheat.name, (w - btn_w) / 2, y, btn_w, btn_h, function()
                cheat_system.execute(cheat.code)
                notification.show("Cheat " .. cheat.name .. " executed!", 2.0, {0.9, 0.7, 0.3})
            end)
            btn.bg = {0.3, 0.2, 0.2}
            btn.hover_bg = {0.4, 0.25, 0.25}
            table.insert(CheatsScreen.cheat_buttons, btn)
        end
    end
end

function CheatsScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.2, 0.1, 0.1)
    
    -- Title
    love.graphics.setColor(1, 0.8, 0.8)
    love.graphics.printf("Discovered Cheats", 0, 40, w, "center")
    
    local discovered = cheat_system.get_discovered()
    
    if #discovered == 0 then
        -- No cheats discovered
        love.graphics.setColor(0.7, 0.6, 0.6)
        love.graphics.printf(text_utils.clean("No cheats discovered yet."), 0, h * 0.4, w, "center")
        love.graphics.setColor(0.6, 0.5, 0.5)
        love.graphics.printf(text_utils.clean("Type cheat codes in-game to discover them!"), 0, h * 0.45, w, "center")
    else
        -- Draw cheat buttons
        for _, btn in ipairs(CheatsScreen.toggle_buttons) do
            btn:draw()
        end
        for _, btn in ipairs(CheatsScreen.cheat_buttons) do
            btn:draw()
        end
        
        -- Instructions
        love.graphics.setColor(0.7, 0.6, 0.6)
        love.graphics.printf(text_utils.clean("Toggle cheats can be turned on/off. Button cheats execute immediately."), 0, h - 100, w, "center")
    end
    
    -- Back button
    CheatsScreen.back_button:draw()
end

function CheatsScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- Check toggle buttons
    for _, btn in ipairs(CheatsScreen.toggle_buttons) do
        if btn:mousepressed(x, y) then
            return
        end
    end
    
    -- Check button cheats
    for _, btn in ipairs(CheatsScreen.cheat_buttons) do
        if btn:mousepressed(x, y) then
            return
        end
    end
    
    -- Check back button
    if CheatsScreen.back_button:mousepressed(x, y) then
        return
    end
end

return CheatsScreen
