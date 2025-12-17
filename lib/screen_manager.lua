-- Screen manager to coordinate Love2D callbacks and screen transitions.
-- Keeps screens modular and forwards all Love callbacks to the active screen.
-- Each screen is a table with optional functions: enter(ctx), exit(ctx), update(dt), draw(),
-- keypressed(key), mousepressed(x, y, button), mousereleased(x, y, button),
-- mousemoved(x, y, dx, dy), wheelmoved(x, y), textinput(text).
-- Transitions emit events via the event bus so other systems can prepare/cleanup:
--   screen:pre_exit, screen:pre_enter, screen:entered
-- ctx passed to screens includes { from, to, data } to describe the transition.

local bus = require('lib.event_bus')
local log = require('lib.logger')

local ScreenManager = {
    _screens = {},
    _current = nil,
    _current_name = nil,
}

-- Register a screen module by name.
-- @param name string
-- @param screen table
function ScreenManager.register_screen(name, screen)
    assert(type(name) == 'string' and name ~= '', 'screen name must be non-empty string')
    assert(type(screen) == 'table', 'screen must be a table')
    ScreenManager._screens[name] = screen
end

-- Get the active screen name.
function ScreenManager.current_name()
    return ScreenManager._current_name
end

-- Transition to a screen by name. Emits transition events through the bus.
-- @param name string
-- @param data any (optional transition payload)
function ScreenManager.go_to(name, data)
    local next_screen = ScreenManager._screens[name]
    assert(next_screen, ('screen not found: %s'):format(name))

    local from_name = ScreenManager._current_name
    local ctx = { from = from_name, to = name, data = data }

    -- Notify listeners a transition is about to happen (cleanup/save).
    log.info('screen:pre_exit', ctx)
    bus.emit('screen:pre_exit', ctx)

    -- Run exit on current screen.
    if ScreenManager._current and ScreenManager._current.exit then
        ScreenManager._current.exit(ctx)
    end

    -- Notify listeners before entering next screen (preload/setup).
    log.info('screen:pre_enter', ctx)
    bus.emit('screen:pre_enter', ctx)

    -- Activate next screen.
    ScreenManager._current = next_screen
    ScreenManager._current_name = name

    if next_screen.enter then
        next_screen.enter(ctx)
    end

    -- Notify listeners after screen is ready (UI spawn, audio cues).
    log.info('screen:entered', ctx)
    bus.emit('screen:entered', ctx)
end

-- Forward Love2D lifecycle functions to the current screen if they exist.
function ScreenManager.update(dt)
    if ScreenManager._current and ScreenManager._current.update then
        ScreenManager._current.update(dt)
    end
end

function ScreenManager.draw()
    if ScreenManager._current and ScreenManager._current.draw then
        ScreenManager._current.draw()
    end
end

function ScreenManager.keypressed(key, scancode, isrepeat)
    if ScreenManager._current and ScreenManager._current.keypressed then
        ScreenManager._current.keypressed(key, scancode, isrepeat)
    end
end

function ScreenManager.textinput(text)
    if ScreenManager._current and ScreenManager._current.textinput then
        ScreenManager._current.textinput(text)
    end
end

function ScreenManager.mousepressed(x, y, button, istouch, presses)
    if ScreenManager._current and ScreenManager._current.mousepressed then
        ScreenManager._current.mousepressed(x, y, button, istouch, presses)
    end
end

function ScreenManager.mousereleased(x, y, button, istouch, presses)
    if ScreenManager._current and ScreenManager._current.mousereleased then
        ScreenManager._current.mousereleased(x, y, button, istouch, presses)
    end
end

function ScreenManager.mousemoved(x, y, dx, dy, istouch)
    if ScreenManager._current and ScreenManager._current.mousemoved then
        ScreenManager._current.mousemoved(x, y, dx, dy, istouch)
    end
end

function ScreenManager.wheelmoved(x, y)
    if ScreenManager._current and ScreenManager._current.wheelmoved then
        ScreenManager._current.wheelmoved(x, y)
    end
end

return ScreenManager

