-- Cheat system that tracks key presses and activates cheats when codes are typed.
-- Tracks the last 30 key presses and checks for cheat code patterns.
-- Supports two cheat types: "toggle" (on/off state) and "button" (one-time action).
-- Example:
--   local cheat = require('lib.cheat_system')
--   cheat.register("nosaves", "No Saves", "button", function() ... end)
--   cheat.register("godmode", "God Mode", "toggle", function(enabled) ... end)
--   cheat.on_keypressed(key) -- Call this from love.keypressed

local bus = require('lib.event_bus')
local log = require('lib.logger')
local json = require('lunajson')

local CheatSystem = {
    KEY_HISTORY_SIZE = 30,
    key_history = {},
    cheats = {},
    discovered_cheats = {}, -- Set of discovered cheat codes
    toggle_states = {}, -- Current state of toggle cheats { code = true/false }
    DISCOVERED_FILE = "saved/cheats.json",
}

-- Load discovered cheats and toggle states from file
local function load_discovered()
    local info = love.filesystem.getInfo(CheatSystem.DISCOVERED_FILE)
    if info then
        local contents = love.filesystem.read(CheatSystem.DISCOVERED_FILE)
        if contents then
            local ok, data = pcall(json.decode, contents)
            if ok and data then
                CheatSystem.discovered_cheats = data.discovered or {}
                CheatSystem.toggle_states = data.toggles or {}
            end
        end
    end
end

-- Save discovered cheats and toggle states to file
local function save_discovered()
    love.filesystem.createDirectory("saved")
    local data = {
        discovered = CheatSystem.discovered_cheats,
        toggles = CheatSystem.toggle_states,
    }
    local json_data = json.encode(data)
    love.filesystem.write(CheatSystem.DISCOVERED_FILE, json_data)
end

-- Initialize cheat system (call once at startup)
function CheatSystem.init()
    load_discovered()
end

-- Register a cheat code
-- @param code string: The key sequence to type (e.g., "nosaves")
-- @param name string: Display name for the cheat
-- @param cheat_type string: "toggle" or "button"
-- @param callback function: Function to call when cheat is activated
--   For toggle: callback(enabled) where enabled is boolean
--   For button: callback() - executes immediately
function CheatSystem.register(code, name, cheat_type, callback)
    assert(type(code) == "string" and code ~= "", "code must be non-empty string")
    assert(type(name) == "string" and name ~= "", "name must be non-empty string")
    assert(cheat_type == "toggle" or cheat_type == "button", "cheat_type must be 'toggle' or 'button'")
    assert(type(callback) == "function", "callback must be a function")
    
    CheatSystem.cheats[code] = {
        name = name,
        type = cheat_type,
        callback = callback,
    }
    
    -- Initialize toggle state if it's a toggle cheat
    if cheat_type == "toggle" and CheatSystem.toggle_states[code] == nil then
        CheatSystem.toggle_states[code] = false
    end
    
    log.info("cheat:registered", { code = code, name = name, type = cheat_type })
end

-- Mark a cheat as discovered
-- @param code string: Cheat code
local function mark_discovered(code)
    if not CheatSystem.discovered_cheats[code] then
        CheatSystem.discovered_cheats[code] = true
        save_discovered()
        log.info("cheat:discovered", { code = code })
    end
end

-- Check if a cheat is discovered
-- @param code string: Cheat code
-- @return boolean: True if discovered
function CheatSystem.is_discovered(code)
    return CheatSystem.discovered_cheats[code] == true
end

-- Get all discovered cheats
-- @return table: Array of { code, name, type, state } for discovered cheats
function CheatSystem.get_discovered()
    local discovered = {}
    for code, _ in pairs(CheatSystem.discovered_cheats) do
        local cheat_data = CheatSystem.cheats[code]
        if cheat_data then
            table.insert(discovered, {
                code = code,
                name = cheat_data.name,
                type = cheat_data.type,
                state = CheatSystem.toggle_states[code],
            })
        end
    end
    -- Sort by name for consistent display
    table.sort(discovered, function(a, b) return a.name < b.name end)
    return discovered
end

-- Toggle a toggle cheat on/off
-- @param code string: Cheat code
function CheatSystem.toggle(code)
    local cheat_data = CheatSystem.cheats[code]
    if not cheat_data or cheat_data.type ~= "toggle" then
        return false
    end
    
    CheatSystem.toggle_states[code] = not CheatSystem.toggle_states[code]
    local enabled = CheatSystem.toggle_states[code]
    
    -- Call the callback with new state
    cheat_data.callback(enabled)
    
    save_discovered()
    log.info("cheat:toggled", { code = code, name = cheat_data.name, enabled = enabled })
    
    return true
end

-- Execute a button cheat
-- @param code string: Cheat code
function CheatSystem.execute(code)
    local cheat_data = CheatSystem.cheats[code]
    if not cheat_data or cheat_data.type ~= "button" then
        return false
    end
    
    -- Call the callback
    cheat_data.callback()
    
    log.info("cheat:executed", { code = code, name = cheat_data.name })
    
    return true
end

-- Process a key press and check for cheat codes
-- Call this from love.keypressed
-- @param key string: The key that was pressed
function CheatSystem.on_keypressed(key)
    -- Add key to history
    table.insert(CheatSystem.key_history, key)
    
    -- Keep only last N keys
    if #CheatSystem.key_history > CheatSystem.KEY_HISTORY_SIZE then
        table.remove(CheatSystem.key_history, 1)
    end
    
    -- Build current sequence from history
    local sequence = table.concat(CheatSystem.key_history, "")
    
    -- Check each registered cheat
    for code, cheat_data in pairs(CheatSystem.cheats) do
        if sequence:find(code, 1, true) then
            -- Cheat code found! Activate it
            log.info("cheat:activated", { code = code, name = cheat_data.name })
            
            -- Mark as discovered
            mark_discovered(code)
            
            -- Emit notification event
            bus.emit("cheat:activated", { code = code, name = cheat_data.name })
            
            -- Handle based on cheat type
            if cheat_data.type == "toggle" then
                -- Toggle the state
                CheatSystem.toggle_states[code] = not CheatSystem.toggle_states[code]
                local enabled = CheatSystem.toggle_states[code]
                cheat_data.callback(enabled)
                save_discovered()
            else
                -- Button type - execute immediately
                cheat_data.callback()
            end
            
            -- Clear history to prevent re-triggering
            CheatSystem.key_history = {}
            
            return true
        end
    end
    
    return false
end

-- Clear the key history (useful after cheat activation)
function CheatSystem.clear_history()
    CheatSystem.key_history = {}
end

return CheatSystem

