-- Hex character system for Mountain Home.
-- Manages characters that move between hexes and say things.

local HexMap = require('lib.hex_map')
local log = require('lib.logger')

local HexCharacters = {
    active_characters = {},  -- Array of active characters on the hex map
}

-- McJaggy messages about living in the mountains
local MCJAGGY_MESSAGES = {
    "THE MOUNTAINS ARE CALLING!",
    "FRESH AIR AND WIDE OPEN SPACES!",
    "NOTHING BEATS MOUNTAIN LIVING!",
    "EVERY DAY IS AN ADVENTURE UP HERE!",
    "THE VIEWS FROM THESE MOUNTAINS ARE INCREDIBLE!",
    "MOUNTAIN LIFE IS THE BEST LIFE!",
    "CAN'T BEAT THE PEACE AND QUIET!",
    "THESE MOUNTAINS ARE MY HOME!",
    "MOUNTAIN AIR IS THE BEST AIR!",
    "LIVING AMONGST NATURE IS AMAZING!",
    "THE MOUNTAINS NEVER GET OLD!",
    "EVERY SEASON BRINGS NEW BEAUTY!",
    "MOUNTAIN LIVING KEEPS YOU STRONG!",
    "THERE'S NOWHERE ELSE I'D RATHER BE!",
    "THE MOUNTAINS TEACH YOU PATIENCE!",
    "MOUNTAIN LIFE IS SIMPLE AND GOOD!",
    "THESE PEAKS ARE MY PLAYGROUND!",
    "MOUNTAIN LIVING IS FREEDOM!",
    "THE WILDS CALL TO MY SOUL!",
    "MOUNTAINS MAKE YOU FEEL ALIVE!",
}

-- Disapproval Meowchi messages about how things could be better
local DISAPPROVAL_MESSAGES = {
    "This hex could use more organization...",
    "The spacing here is all wrong...",
    "This layout is inefficient at best...",
    "Things would be better if arranged differently...",
    "The placement here leaves much to be desired...",
    "This could be optimized so much better...",
    "The design here is... lacking...",
    "There's a better way to do this...",
    "This arrangement is suboptimal...",
    "Things could be so much more efficient...",
    "The organization here is questionable...",
    "This setup needs improvement...",
    "There's room for better planning here...",
    "The structure could be more logical...",
    "This layout lacks proper consideration...",
    "Things would flow better if reorganized...",
    "The placement strategy here is weak...",
    "This could be arranged more thoughtfully...",
    "The design principles are being ignored...",
    "There's a more elegant solution here...",
}

-- Create a new character on the hex map
-- @param sprite_path string: Path to sprite image
-- @param name string: Character name
-- @param messages table: Array of messages
-- @param speed number: Movement speed (hexes per second)
-- @param message_interval number: Time between messages (seconds)
function HexCharacters.spawn(sprite_path, name, messages, speed, message_interval)
    -- Check if character already exists
    if HexCharacters.is_active(name) then
        return false
    end
    
    -- Only spawn if we're on the game screen and hex map exists
    local screen_manager = require('lib.screen_manager')
    if screen_manager.current_name() ~= "game" then
        return false
    end
    
    if #HexMap.hexes == 0 then
        return false
    end
    
    -- Load sprite
    local success, sprite = pcall(love.graphics.newImage, sprite_path)
    if not success then
        log.warn("hex_characters:spawn_failed", { name = name, error = "Could not load sprite" })
        return false
    end
    
    -- Pick random starting hex
    local start_hex_index = love.math.random(1, #HexMap.hexes)
    local start_hex = HexMap.get_hex(start_hex_index)
    if not start_hex then
        return false
    end
    
    local character = {
        sprite = sprite,
        sprite_w = sprite:getWidth(),
        sprite_h = sprite:getHeight(),
        name = name,
        messages = messages,
        speed = speed,  -- hexes per second
        message_interval = message_interval or 3.0,
        current_hex_index = start_hex_index,
        target_hex_index = nil,
        x = start_hex.x,
        y = start_hex.y,
        start_x = start_hex.x,
        start_y = start_hex.y,
        target_x = start_hex.x,
        target_y = start_hex.y,
        move_progress = 1.0,  -- 1.0 = at target
        move_duration = 1.0,
        move_timer = 0,
        message_timer = 0,
        current_message = "",
        message_visible = false,
        message_duration = 3.0,
    }
    
    table.insert(HexCharacters.active_characters, character)
    
    log.info("hex_characters:spawned", { name = name, hex_index = start_hex_index })
    
    return true
end

-- Get neighbors of a hex (simplified - just pick random hex)
-- @param hex_index number: Current hex index
-- @return number or nil: Random neighbor hex index
local function get_random_neighbor_hex(hex_index)
    if #HexMap.hexes == 0 then
        return nil
    end
    
    -- For simplicity, just pick a random hex (could be improved to find actual neighbors)
    local attempts = 0
    while attempts < 10 do
        local random_index = love.math.random(1, #HexMap.hexes)
        if random_index ~= hex_index then
            return random_index
        end
        attempts = attempts + 1
    end
    
    -- Fallback: just return a different random hex
    if #HexMap.hexes > 1 then
        local new_index = love.math.random(1, #HexMap.hexes)
        if new_index == hex_index then
            new_index = (new_index % #HexMap.hexes) + 1
        end
        return new_index
    end
    
    return nil
end

-- Update all active characters
-- @param dt number: Delta time
function HexCharacters.update(dt)
    if #HexMap.hexes == 0 then
        return
    end
    
    for i = #HexCharacters.active_characters, 1, -1 do
        local char = HexCharacters.active_characters[i]
        
        -- Update movement
        if char.move_progress >= 1.0 then
            -- At target, pick new target
            char.current_hex_index = char.target_hex_index or char.current_hex_index
            local new_target = get_random_neighbor_hex(char.current_hex_index)
            
            if new_target then
                local target_hex = HexMap.get_hex(new_target)
                if target_hex then
                    char.target_hex_index = new_target
                    char.start_x = char.x
                    char.start_y = char.y
                    char.target_x = target_hex.x
                    char.target_y = target_hex.y
                    char.move_progress = 0.0
                    
                    -- Calculate move duration based on speed (speed is in hexes per second)
                    local dx = char.target_x - char.start_x
                    local dy = char.target_y - char.start_y
                    local distance = math.sqrt(dx * dx + dy * dy)
                    -- Convert speed to pixels per second (rough estimate: 1 hex = ~64 pixels)
                    char.move_duration = distance / (char.speed * 64)
                    if char.move_duration < 0.1 then
                        char.move_duration = 0.1
                    end
                end
            end
        else
            -- Moving to target - lerp from start to target
            char.move_progress = char.move_progress + dt / char.move_duration
            if char.move_progress > 1.0 then
                char.move_progress = 1.0
                char.x = char.target_x
                char.y = char.target_y
            else
                -- Lerp position
                char.x = char.start_x + (char.target_x - char.start_x) * char.move_progress
                char.y = char.start_y + (char.target_y - char.start_y) * char.move_progress
            end
        end
        
        -- Update message timer
        char.message_timer = char.message_timer + dt
        if char.message_timer >= char.message_interval then
            -- Show a random message
            char.current_message = char.messages[love.math.random(1, #char.messages)]
            char.message_visible = true
            char.message_timer = 0
        end
        
        -- Update message visibility
        if char.message_visible then
            char.message_duration = char.message_duration - dt
            if char.message_duration <= 0 then
                char.message_visible = false
                char.message_duration = 3.0  -- Reset duration
            end
        end
    end
end

-- Draw all active characters
function HexCharacters.draw()
    for _, char in ipairs(HexCharacters.active_characters) do
        if char.sprite then
            -- Bob animation
            local bob = math.sin(love.timer.getTime() * 5) * 2
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(
                char.sprite,
                char.x,
                char.y + bob,
                0,
                1, 1,
                char.sprite_w / 2,
                char.sprite_h / 2
            )
            
            -- Draw message bubble if visible
            if char.message_visible and char.current_message ~= "" then
                local message_x = char.x
                local message_y = char.y - 50
                
                local font = love.graphics.getFont()
                local text_w = font:getWidth(char.current_message)
                local text_h = font:getHeight()
                local padding = 10
                local bubble_w = text_w + padding * 2
                local bubble_h = text_h + padding * 2
                
                -- Message bubble background
                love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
                love.graphics.rectangle("fill", message_x - bubble_w / 2, message_y - bubble_h, bubble_w, bubble_h, 6, 6)
                love.graphics.setColor(0.3, 0.3, 0.4, 0.95)
                love.graphics.rectangle("line", message_x - bubble_w / 2, message_y - bubble_h, bubble_w, bubble_h, 6, 6)
                
                -- Message text (different colors for different characters)
                if char.name == "McJaggy" then
                    love.graphics.setColor(0.9, 0.8, 0.5)  -- Yellow for shouting
                else
                    love.graphics.setColor(0.7, 0.6, 0.8)  -- Purple for disapproval
                end
                love.graphics.printf(
                    char.current_message,
                    message_x - bubble_w / 2 + padding,
                    message_y - bubble_h + padding,
                    text_w,
                    "center"
                )
            end
        end
    end
end

-- Remove a character by name
-- @param name string: Character name to remove
function HexCharacters.remove(name)
    for i = #HexCharacters.active_characters, 1, -1 do
        if HexCharacters.active_characters[i].name == name then
            table.remove(HexCharacters.active_characters, i)
            log.info("hex_characters:removed", { name = name })
            return true
        end
    end
    return false
end

-- Check if a character is active
-- @param name string: Character name
-- @return boolean: True if character is active
function HexCharacters.is_active(name)
    for _, char in ipairs(HexCharacters.active_characters) do
        if char.name == name then
            return true
        end
    end
    return false
end

-- Clear all characters
function HexCharacters.clear()
    HexCharacters.active_characters = {}
end

return HexCharacters

