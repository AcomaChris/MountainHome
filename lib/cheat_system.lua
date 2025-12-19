-- Cheat system that tracks key presses and activates cheats when codes are typed.
-- Tracks the last 30 key presses and checks for cheat code patterns.
-- Example:
--   local cheat = require('lib.cheat_system')
--   cheat.register("nosaves", function() ... end)
--   cheat.on_keypressed(key) -- Call this from love.keypressed

local bus = require('lib.event_bus')
local log = require('lib.logger')

local CheatSystem = {
    KEY_HISTORY_SIZE = 30,
    key_history = {},
    cheats = {},
}

-- Register a cheat code
-- @param code string: The key sequence to type (e.g., "nosaves")
-- @param name string: Display name for the cheat
-- @param callback function: Function to call when cheat is activated
function CheatSystem.register(code, name, callback)
    assert(type(code) == "string" and code ~= "", "code must be non-empty string")
    assert(type(name) == "string" and name ~= "", "name must be non-empty string")
    assert(type(callback) == "function", "callback must be a function")
    
    CheatSystem.cheats[code] = {
        name = name,
        callback = callback,
    }
    
    log.info("cheat:registered", { code = code, name = name })
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
            
            -- Emit notification event
            bus.emit("cheat:activated", { code = code, name = cheat_data.name })
            
            -- Call the cheat callback
            cheat_data.callback()
            
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

