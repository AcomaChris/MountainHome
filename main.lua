-- Mountain Home - Main Game File
-- Entry point for Love2D; wires screen manager and initial screen.

-- Extend Lua search path for local libs and screens
package.path = package.path .. ";lib/?.lua;lib/?/init.lua;lib/?/?.lua;?/init.lua;?/?.lua"

local screen_manager = require('lib.screen_manager')
local menu_screen = require('screens.menu')
local intro_screen = require('screens.intro')
local bus = require('lib.event_bus')
local log = require('lib.logger')

-- Called once when the game starts
function love.load()
    love.window.setTitle("Mountain Home")

    -- Register screens (expand as we add more)
    screen_manager.register_screen("menu", menu_screen)
    screen_manager.register_screen("intro", intro_screen)

    -- Wire simple nav: menu -> intro -> menu
    bus.subscribe("menu:continue", function()
        log.info("menu:continue")
        screen_manager.go_to("intro")
    end)
    bus.subscribe("intro:done", function()
        log.info("intro:done")
        screen_manager.go_to("menu")
    end)

    -- Start at intro
    screen_manager.go_to("intro")
end

-- Forward Love callbacks to the screen manager
function love.update(dt)
    screen_manager.update(dt)
end

function love.draw()
    screen_manager.draw()
end

function love.keypressed(key, scancode, isrepeat)
    screen_manager.keypressed(key, scancode, isrepeat)
end

function love.textinput(text)
    screen_manager.textinput(text)
end

function love.mousepressed(x, y, button, istouch, presses)
    screen_manager.mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    screen_manager.mousereleased(x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
    screen_manager.mousemoved(x, y, dx, dy, istouch)
end

function love.wheelmoved(x, y)
    screen_manager.wheelmoved(x, y)
end




