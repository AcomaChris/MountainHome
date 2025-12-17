-- Simple pub/sub event bus for screen transitions and UI signals.
-- Keeps UI, screens, and systems loosely coupled by passing events instead of direct calls.
-- Usage:
--   local bus = require('lib.event_bus')
--   local unsubscribe = bus.subscribe('screen:entered', function(payload) ... end)
--   bus.emit('screen:entered', { from = 'menu', to = 'game' })
--   unsubscribe() -- remove handler

local EventBus = {}

-- Internal storage: handlers[event] = { [token] = fn }
local handlers = {}
local next_token = 1

-- Subscribe to an event; returns an unsubscribe function.
-- @param event_name string: name of the event channel
-- @param fn function: callback receiving (payload)
-- @return function: call to remove the handler
function EventBus.subscribe(event_name, fn)
    assert(type(event_name) == 'string' and event_name ~= '', 'event_name must be a non-empty string')
    assert(type(fn) == 'function', 'fn must be a function')

    handlers[event_name] = handlers[event_name] or {}
    local token = next_token
    next_token = next_token + 1
    handlers[event_name][token] = fn

    return function()
        if handlers[event_name] then
            handlers[event_name][token] = nil
            if next(handlers[event_name]) == nil then
                handlers[event_name] = nil
            end
        end
    end
end

-- Emit an event with optional payload table.
-- @param event_name string
-- @param payload any
function EventBus.emit(event_name, payload)
    local bucket = handlers[event_name]
    if not bucket then return end
    for _, fn in pairs(bucket) do
        fn(payload)
    end
end

-- Unsubscribe a specific handler by token (optional helper).
-- @param event_name string
-- @param token number
function EventBus.unsubscribe(event_name, token)
    if handlers[event_name] and token then
        handlers[event_name][token] = nil
        if next(handlers[event_name]) == nil then
            handlers[event_name] = nil
        end
    end
end

return EventBus

