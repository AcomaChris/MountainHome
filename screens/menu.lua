-- Placeholder menu screen for Phase 0 navigation prototype.
-- Displays basic text and listens for Enter to continue (emits an event) or Escape to quit.

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')

local MenuScreen = {
    title = "Mountain Home",
    subtitle = "Phase 0 Prototype",
    info = "Click a button to navigate.",
    buttons = {},
    title_font = nil,
    title_letters = {},
    wave_speed = 3.0, -- Speed of the wave animation
    wave_amplitude = 8, -- How much each letter bobs up and down
}

-- Called when entering the menu
function MenuScreen.enter(ctx)
    -- Store last transition for debugging visibility
    MenuScreen.last_transition = ctx

    -- Load large font for title (size 48 for big letters)
    MenuScreen.title_font = love.graphics.newFont("assets/star-crush.regular.ttf", 48)
    
    -- Split title into individual letters for animation
    MenuScreen.title_letters = {}
    for i = 1, #MenuScreen.title do
        local char = MenuScreen.title:sub(i, i)
        if char ~= " " then
            table.insert(MenuScreen.title_letters, {
                char = char,
                phase = (i - 1) * 0.3, -- Stagger each letter's wave phase
            })
        else
            -- Spaces are represented as nil to skip during drawing
            table.insert(MenuScreen.title_letters, nil)
        end
    end

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

    -- Draw animated title with wave effect
    local title_y = h * 0.2
    local time = love.timer.getTime()
    
    -- Save current font and set title font
    local default_font = love.graphics.getFont()
    love.graphics.setFont(MenuScreen.title_font)
    
    -- Calculate total width of title to center it
    local total_width = 0
    local char_widths = {}
    for i, letter_data in ipairs(MenuScreen.title_letters) do
        if letter_data then
            local char_width = MenuScreen.title_font:getWidth(letter_data.char)
            char_widths[i] = char_width
            total_width = total_width + char_width
        else
            -- Space character
            char_widths[i] = MenuScreen.title_font:getWidth(" ")
            total_width = total_width + char_widths[i]
        end
    end
    
    -- Draw each letter with wave animation
    local current_x = (w - total_width) / 2
    love.graphics.setColor(1, 1, 1)
    
    for i, letter_data in ipairs(MenuScreen.title_letters) do
        if letter_data then
            -- Calculate wave offset for this letter
            local wave_offset = math.sin(time * MenuScreen.wave_speed + letter_data.phase) * MenuScreen.wave_amplitude
            local letter_y = title_y + wave_offset
            
            -- Draw the letter
            love.graphics.print(letter_data.char, current_x, letter_y)
        end
        -- Move to next character position (including spaces)
        current_x = current_x + char_widths[i]
    end
    
    -- Restore default font
    love.graphics.setFont(default_font)

    -- Draw subtitle and info below animated title
    local subtitle_y = title_y + 70
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.printf(MenuScreen.subtitle, 0, subtitle_y, w, "center")

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.printf(MenuScreen.info, 0, subtitle_y + 32, w, "center")

    if MenuScreen.last_transition then
        love.graphics.setColor(0.6, 0.6, 0.8)
        local msg = string.format("from: %s  to: %s", tostring(MenuScreen.last_transition.from), tostring(MenuScreen.last_transition.to))
        love.graphics.printf(msg, 0, subtitle_y + 64, w, "center")
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

