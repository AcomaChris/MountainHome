-- Mountain Home - Main Game File
-- Entry point for Love2D; wires screen manager and initial screen.

-- Extend Lua search path for local libs and screens
-- Supports nested modules like lunajson.decoder and http.request
-- Pattern: lib/?.lua matches lib/module.lua
-- Pattern: lib/?/?.lua matches lib/module/submodule.lua (for lunajson.decoder)
-- Pattern: lib/?/?/?.lua matches lib/module/module/submodule.lua (for lunajson structure)
-- Pattern: lib/lua-http/?.lua matches lib/lua-http/http/request.lua (for lua-http)
package.path = package.path .. ";lib/?.lua;lib/?/init.lua;lib/?/?.lua;lib/?/?/?.lua;lib/lua-http/?.lua;?/init.lua;?/?.lua"

local screen_manager = require('lib.screen_manager')
local menu_screen = require('screens.menu')
local intro_screen = require('screens.intro')
local new_game_location_screen = require('screens.new_game_location')
local load_game_screen = require('screens.load_game')
local game_screen = require('screens.game')
local achievements_screen = require('screens.achievements')
local options_screen = require('screens.options')
local cheats_screen = require('screens.cheats')
local quit_screen = require('screens.quit')
local bus = require('lib.event_bus')
local log = require('lib.logger')

-- Test module for HTTP/JSON (will gracefully handle missing libraries)
local test_http_json_available, test_http_json = pcall(require, 'lib.test_http_json')

-- Called once when the game starts
function love.load()
    love.window.setTitle("Mountain Home")
    
    -- Set pixel-perfect filtering for pixel art (no anti-aliasing)
    -- "nearest" keeps hard edges instead of smooth interpolation
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Register all screens
    screen_manager.register_screen("menu", menu_screen)
    screen_manager.register_screen("intro", intro_screen)
    screen_manager.register_screen("new_game_location", new_game_location_screen)
    screen_manager.register_screen("load_game", load_game_screen)
    screen_manager.register_screen("game", game_screen)
    screen_manager.register_screen("achievements", achievements_screen)
    screen_manager.register_screen("options", options_screen)
    screen_manager.register_screen("cheats", cheats_screen)
    screen_manager.register_screen("quit", quit_screen)

    -- Wire navigation events from menu
    bus.subscribe("menu:new_game", function()
        log.info("menu:new_game")
        screen_manager.go_to("new_game_location")
    end)
    bus.subscribe("menu:load_game", function()
        log.info("menu:load_game")
        screen_manager.go_to("load_game")
    end)
    bus.subscribe("menu:achievements", function()
        log.info("menu:achievements")
        screen_manager.go_to("achievements")
    end)
    bus.subscribe("menu:options", function()
        log.info("menu:options")
        screen_manager.go_to("options")
    end)
    bus.subscribe("menu:cheats", function()
        log.info("menu:cheats")
        screen_manager.go_to("cheats")
    end)
    bus.subscribe("menu:quit", function()
        log.info("menu:quit")
        screen_manager.go_to("quit")
    end)
    
    -- Wire navigation events back to menu
    bus.subscribe("intro:done", function()
        log.info("intro:done")
        screen_manager.go_to("menu")
    end)
    bus.subscribe("new_game_location:back", function()
        log.info("new_game_location:back")
        screen_manager.go_to("menu")
    end)
    bus.subscribe("load_game:back", function()
        log.info("load_game:back")
        screen_manager.go_to("menu")
    end)
    bus.subscribe("game:back", function()
        log.info("game:back")
        screen_manager.go_to("menu")
    end)
    bus.subscribe("achievements:back", function()
        log.info("achievements:back")
        screen_manager.go_to("menu")
    end)
    bus.subscribe("options:back", function()
        log.info("options:back")
        screen_manager.go_to("menu")
    end)
    bus.subscribe("cheats:back", function()
        log.info("cheats:back")
        screen_manager.go_to("menu")
    end)
    bus.subscribe("quit:cancel", function()
        log.info("quit:cancel")
        screen_manager.go_to("menu")
    end)
    
    -- Wire test events for HTTP/JSON testing
    if test_http_json_available then
        bus.subscribe("test:start", function(payload)
            log.info("test:start", payload)
        end)
        bus.subscribe("test:json_result", function(payload)
            log.info("test:json_result", payload)
        end)
        bus.subscribe("test:http_result", function(payload)
            log.info("test:http_result", payload)
        end)
        bus.subscribe("test:complete", function(payload)
            log.info("test:complete", payload)
        end)
        bus.subscribe("options:test_libraries", function()
            log.info("options:test_libraries")
            if test_http_json then
                test_http_json.run_all()
            end
        end)
        
        -- Run test on startup (will log results)
        test_http_json.run_all()
    else
        log.info("test:module_unavailable", { note = "lib/test_http_json.lua not found or has errors" })
    end

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




