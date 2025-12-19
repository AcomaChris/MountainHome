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
    background_images = {}, -- Array of loaded images
    current_image_index = 1, -- Which image is currently showing
    image_animations = {}, -- Animation state for each image
    image_start_x = 0, -- Starting X position for images
    image_move_distance = 20, -- How far images move to the left
    fade_duration = 1.5, -- How long fade in/out takes (seconds)
    move_duration = 3.0, -- How long the move animation takes (seconds)
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

    -- Load background images
    MenuScreen.background_images = {}
    local image_paths = {
        "assets/TitleImages/MountainBackground01.png",
        "assets/TitleImages/MountainBackground02.png",
        "assets/TitleImages/MountainBackground03.png",
        "assets/TitleImages/MountainBackground04.png",
    }
    
    for _, path in ipairs(image_paths) do
        local success, img = pcall(love.graphics.newImage, path)
        if success then
            table.insert(MenuScreen.background_images, img)
        end
    end
    
    -- Initialize animation states for each image
    MenuScreen.image_animations = {}
    for i = 1, #MenuScreen.background_images do
        MenuScreen.image_animations[i] = {
            fade_progress = 0, -- 0 to 1 (fade in), then 1 to 0 (fade out)
            move_progress = 0, -- 0 to 1 (how far through the move)
            phase = "fade_in", -- "fade_in", "moving", "fade_out"
            timer = 0,
        }
    end
    
    -- Set starting image
    MenuScreen.current_image_index = 1
    if #MenuScreen.image_animations > 0 then
        MenuScreen.image_animations[1].phase = "fade_in"
    end

    -- Layout buttons vertically on the left side
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 220, 44
    local left_margin = 80  -- Left margin for buttons
    local start_y = h * 0.4
    local btn_spacing = 50
    
    -- Calculate image area (right side)
    MenuScreen.image_start_x = w * 0.5  -- Images start at middle of screen
    MenuScreen.image_area_width = w * 0.5 - 40  -- Right half minus margin
    MenuScreen.image_y = 0  -- Will be calculated in draw
    
    MenuScreen.buttons = {
        UIButton.new("New Game", left_margin, start_y, btn_w, btn_h, function()
            bus.emit("menu:new_game", { from = "menu" })
        end),
        UIButton.new("Load Game", left_margin, start_y + btn_spacing, btn_w, btn_h, function()
            bus.emit("menu:load_game", { from = "menu" })
        end),
        UIButton.new("Achievements", left_margin, start_y + btn_spacing * 2, btn_w, btn_h, function()
            bus.emit("menu:achievements", { from = "menu" })
        end),
        UIButton.new("Options", left_margin, start_y + btn_spacing * 3, btn_w, btn_h, function()
            bus.emit("menu:options", { from = "menu" })
        end),
        UIButton.new("Cheats", left_margin, start_y + btn_spacing * 4, btn_w, btn_h, function()
            bus.emit("menu:cheats", { from = "menu" })
        end),
        UIButton.new("Quit", left_margin, start_y + btn_spacing * 5, btn_w, btn_h, function()
            bus.emit("menu:quit", { from = "menu" })
        end),
    }
end

function MenuScreen.update(dt)
    if #MenuScreen.image_animations == 0 then
        return
    end
    
    local anim = MenuScreen.image_animations[MenuScreen.current_image_index]
    if not anim then
        return
    end
    
    anim.timer = anim.timer + dt
    
    if anim.phase == "fade_in" then
        -- Fade in
        anim.fade_progress = math.min(1.0, anim.timer / MenuScreen.fade_duration)
        if anim.fade_progress >= 1.0 then
            anim.phase = "moving"
            anim.timer = 0
        end
    elseif anim.phase == "moving" then
        -- Move 20 pixels to the left
        anim.move_progress = math.min(1.0, anim.timer / MenuScreen.move_duration)
        if anim.move_progress >= 1.0 then
            anim.phase = "fade_out"
            anim.timer = 0
        end
    elseif anim.phase == "fade_out" then
        -- Fade out
        anim.fade_progress = math.max(0.0, 1.0 - (anim.timer / MenuScreen.fade_duration))
        if anim.fade_progress <= 0.0 then
            -- Move to next image
            MenuScreen.current_image_index = (MenuScreen.current_image_index % #MenuScreen.background_images) + 1
            local next_anim = MenuScreen.image_animations[MenuScreen.current_image_index]
            if next_anim then
                next_anim.phase = "fade_in"
                next_anim.timer = 0
                next_anim.fade_progress = 0
                next_anim.move_progress = 0
            end
        end
    end
end

function MenuScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.1, 0.1, 0.12)

    -- Draw background images on the right side
    if #MenuScreen.background_images > 0 and MenuScreen.current_image_index then
        local img = MenuScreen.background_images[MenuScreen.current_image_index]
        local anim = MenuScreen.image_animations[MenuScreen.current_image_index]
        
        if img and anim then
            -- Calculate position (starts at image_start_x, moves left by move_distance)
            local current_x = MenuScreen.image_start_x - (anim.move_progress * MenuScreen.image_move_distance)
            local img_w = img:getWidth()
            local img_h = img:getHeight()
            
            -- Scale image to fit the right side area (maintain aspect ratio)
            local target_height = h * 0.8
            local scale = target_height / img_h
            local scaled_width = img_w * scale
            local scaled_height = img_h * scale
            
            -- Center vertically
            local img_y = (h - scaled_height) / 2
            
            -- Draw with fade
            love.graphics.setColor(1, 1, 1, anim.fade_progress)
            love.graphics.draw(img, current_x, img_y, 0, scale, scale)
        end
    end

    -- Draw animated title with wave effect (on the left)
    local title_y = h * 0.2
    local time = love.timer.getTime()
    
    -- Save current font and set title font
    local default_font = love.graphics.getFont()
    love.graphics.setFont(MenuScreen.title_font)
    
    -- Calculate total width of title
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
    
    -- Draw each letter with wave animation (aligned to left)
    local left_margin = 80
    local current_x = left_margin
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

    -- Draw subtitle and info below animated title (on the left)
    local subtitle_y = title_y + 70
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.printf(MenuScreen.subtitle, left_margin, subtitle_y, w * 0.4, "left")

    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.printf(MenuScreen.info, left_margin, subtitle_y + 32, w * 0.4, "left")

    if MenuScreen.last_transition then
        love.graphics.setColor(0.6, 0.6, 0.8)
        local msg = string.format("from: %s  to: %s", tostring(MenuScreen.last_transition.from), tostring(MenuScreen.last_transition.to))
        love.graphics.printf(msg, left_margin, subtitle_y + 64, w * 0.4, "left")
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

