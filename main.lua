-- Mountain Home - Main Game File
-- Entry point for Love2D; wires screen manager and initial screen.

-- Extend Lua search path for local libs and screens
-- Supports nested modules like lunajson.decoder and http.request
-- Pattern: lib/?.lua matches lib/module.lua
-- Pattern: lib/?/?.lua matches lib/module/submodule.lua (for lunajson.decoder)
-- Pattern: lib/?/?/?.lua matches lib/module/module/submodule.lua (for lunajson structure)
-- Pattern: lib/lua-http/?.lua matches lib/lua-http/http/request.lua (for lua-http)
package.path = package.path .. ";lib/?.lua;lib/?/init.lua;lib/?/?.lua;lib/?/?/?.lua;lib/lua-http/?.lua;?.lua;?/init.lua;?/?.lua"

local screen_manager = require('lib.screen_manager')
local menu_screen = require('screens.menu')
local intro_screen = require('screens.intro')
local new_game_location_screen = require('screens.new_game_location')
local load_game_screen = require('screens.load_game')
local game_screen = require('screens.game')
local trade_screen = require('screens.trade')
local achievements_screen = require('screens.achievements')
local options_screen = require('screens.options')
local api_test_screen = require('screens.api_test')
local cheats_screen = require('screens.cheats')
local quit_screen = require('screens.quit')
local bus = require('lib.event_bus')
local log = require('lib.logger')
local cheat_system = require('lib.cheat_system')
local notification = require('lib.notification')
local SaveSystem = require('lib.save_system')

-- Test module for HTTP/JSON (will gracefully handle missing libraries)
local test_http_json_available, test_http_json = pcall(require, 'lib.test_http_json')

-- Called once when the game starts
function love.load()
    love.window.setTitle("Mountain Home")
    
    -- Log Love2D version information for debugging and compatibility checks
    local major, minor, revision, codename = love.getVersion()
    log.info("system:love2d_version", { 
        major = major, 
        minor = minor, 
        revision = revision, 
        codename = codename,
        version_string = string.format("%d.%d.%d (%s)", major, minor, revision, codename),
        note = "Love2D version detected at startup"
    })
    
    -- Check if lua-https is available (Love2D 12.0+)
    -- This is the preferred HTTP client for HTTPS requests
    local https_available, https = pcall(require, 'https')
    if https_available and https and https.request then
        log.info("system:lua_https", { 
            status = "available", 
            note = "lua-https module is available (Love2D 12.0+). Using native HTTPS client with automatic redirect handling." 
        })
    else
        log.info("system:lua_https", { 
            status = "unavailable", 
            error = tostring(https),
            note = "lua-https not available. HTTP client will fall back to socket.http (may have redirect/port issues)." 
        })
    end
    
    -- Set pixel-perfect filtering for pixel art (no anti-aliasing)
    -- "nearest" keeps hard edges instead of smooth interpolation
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Load Star Crush font as the default font for the entire game
    -- Font size 18 provides good readability for UI elements
    local default_font_size = 18
    local star_crush_font, font_error = love.graphics.newFont("assets/star-crush.regular.ttf", default_font_size)
    if star_crush_font then
        love.graphics.setFont(star_crush_font)
        log.info("system:font_loaded", { 
            font = "Star Crush", 
            size = default_font_size,
            note = "Default font set successfully" 
        })
    else
        log.info("system:font_load_failed", { 
            font_path = "assets/star-crush.regular.ttf",
            error = tostring(font_error),
            note = "Using Love2D default font instead" 
        })
    end

    -- Register all screens
    screen_manager.register_screen("menu", menu_screen)
    screen_manager.register_screen("intro", intro_screen)
    screen_manager.register_screen("new_game_location", new_game_location_screen)
    screen_manager.register_screen("load_game", load_game_screen)
    screen_manager.register_screen("game", game_screen)
    screen_manager.register_screen("trade", trade_screen)
    screen_manager.register_screen("achievements", achievements_screen)
    screen_manager.register_screen("options", options_screen)
    screen_manager.register_screen("api_test", api_test_screen)
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
    bus.subscribe("options:api_test", function()
        log.info("options:api_test")
        screen_manager.go_to("api_test")
    end)
    bus.subscribe("api_test:back", function()
        log.info("api_test:back")
        screen_manager.go_to("options")
    end)
    bus.subscribe("cheats:back", function()
        log.info("cheats:back")
        screen_manager.go_to("menu")
    end)
    bus.subscribe("quit:cancel", function()
        log.info("quit:cancel")
        screen_manager.go_to("menu")
    end)
    
    -- Wire world map to game screen
    bus.subscribe("world_map:start_game", function(payload)
        log.info("world_map:start_game", payload)
        screen_manager.go_to("game", { data = { slot = payload.slot, location = payload.location } })
    end)
    
    -- Wire load game to game screen
    bus.subscribe("load_game:load_slot", function(payload)
        log.info("load_game:load_slot", payload)
        screen_manager.go_to("game", { slot = payload.slot })
    end)
    
    -- Wire trade screen navigation
    bus.subscribe("game:trade", function(payload)
        log.info("game:trade", payload)
        screen_manager.go_to("trade", { slot = payload.slot })
    end)
    bus.subscribe("trade:back", function(payload)
        log.info("trade:back", payload)
        screen_manager.go_to("game", { slot = payload.slot })
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

    -- Initialize cheat system (loads discovered cheats)
    cheat_system.init()
    
    -- Register cheat codes
    cheat_system.register("nosaves", "No Saves", "button", function()
        -- Delete all save slots
        for slot = 1, SaveSystem.MAX_SLOTS do
            SaveSystem.delete_slot(slot)
        end
        log.info("cheat:nosaves_executed", { note = "All save slots deleted" })
    end)
    
    -- Register HoboDev Resources toggle cheat (unlocked by hobodev)
    cheat_system.register("hobodevresources", "HoboDev Resources", "toggle", function(enabled)
        -- Give resources periodically when enabled (can be extended later)
        if enabled then
            log.info("cheat:hobodevresources_enabled", { note = "HoboDev resources cheat enabled" })
        else
            log.info("cheat:hobodevresources_disabled", { note = "HoboDev resources cheat disabled" })
        end
    end)
    
    -- Register McJaggy cheat (toggle)
    local HexCharacters = require('lib.hex_characters')
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
    cheat_system.register("mcjaggy", "McJaggy", "toggle", function(enabled)
        if enabled then
            HexCharacters.spawn("RAW/Sprites/Char_McJaggy_Idle00.png", "McJaggy", MCJAGGY_MESSAGES, 2.0, 2.0)
            log.info("cheat:mcjaggy_spawned", { note = "McJaggy spawned on hex map" })
        else
            HexCharacters.remove("McJaggy")
            log.info("cheat:mcjaggy_removed", { note = "McJaggy removed from hex map" })
        end
    end)
    
    -- Register Disapproval cheat (toggle)
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
    cheat_system.register("disapproval", "Disapproval", "toggle", function(enabled)
        if enabled then
            HexCharacters.spawn("RAW/Sprites/Char_DMeowchi_Idle00.png", "Disapproval Meowchi", DISAPPROVAL_MESSAGES, 0.5, 4.0)
            log.info("cheat:disapproval_spawned", { note = "Disapproval Meowchi spawned on hex map" })
        else
            HexCharacters.remove("Disapproval Meowchi")
            log.info("cheat:disapproval_removed", { note = "Disapproval Meowchi removed from hex map" })
        end
    end)
    
    -- Register hobodev cheat code (button that activates everything)
    local KyleCharacter = require('lib.kyle_character')
    cheat_system.register("hobodev", "HoboDev", "button", function()
        -- Give 100 of each resource if in game
        local screen_manager = require('lib.screen_manager')
        local current_screen = screen_manager.current_name()
        
        if current_screen == "game" then
            local game_screen = require('screens.game')
            if game_screen.game_data and game_screen.game_data.resources then
                local resources = game_screen.game_data.resources
                resources.wood = (resources.wood or 0) + 100
                resources.money = (resources.money or 0) + 100
                resources.stone = (resources.stone or 0) + 100
                resources.fruit = (resources.fruit or 0) + 100
                resources.vegetables = (resources.vegetables or 0) + 100
                resources.meat = (resources.meat or 0) + 100
                
                -- Save game if slot exists
                if game_screen.current_slot then
                    SaveSystem.save_game(game_screen.current_slot, game_screen.game_data)
                end
                
                log.info("cheat:hobodev_resources", { note = "Added 100 of each resource" })
            end
        end
        
        -- Unlock the HoboDev Resources toggle cheat (mark as discovered)
        if not cheat_system.is_discovered("hobodevresources") then
            -- Mark as discovered by directly updating the cheat system
            local discovered_file = "saved/cheats.json"
            local json = require('lunajson')
            local info = love.filesystem.getInfo(discovered_file)
            local discovered = {}
            local toggles = {}
            if info then
                local contents = love.filesystem.read(discovered_file)
                if contents then
                    local ok, data = pcall(json.decode, contents)
                    if ok and data then
                        discovered = data.discovered or {}
                        toggles = data.toggles or {}
                    end
                end
            end
            discovered["hobodevresources"] = true
            toggles["hobodevresources"] = false  -- Start disabled
            love.filesystem.createDirectory("saved")
            local data = {
                discovered = discovered,
                toggles = toggles,
            }
            love.filesystem.write(discovered_file, json.encode(data))
            -- Reload discovered cheats
            cheat_system.init()
            log.info("cheat:hobodevresources_unlocked", { note = "HoboDev Resources cheat unlocked" })
        end
        
        -- Spawn Kyle
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()
        KyleCharacter.spawn(w, h)
        
        log.info("cheat:hobodev_executed", { note = "HoboDev cheat activated" })
    end)
    
    -- Subscribe to cheat activation events to show notifications
    bus.subscribe("cheat:activated", function(payload)
        notification.show("Cheat " .. payload.name .. " activated!", 3.0, {0.9, 0.7, 0.3})
        -- Note: Cheats screen will refresh when entered, showing newly discovered cheats
    end)
    
    -- Start at intro
    screen_manager.go_to("intro")
end

-- Forward Love callbacks to the screen manager
function love.update(dt)
    screen_manager.update(dt)
    notification.update(dt)
    
    -- Update Kyle character if active
    local KyleCharacter = require('lib.kyle_character')
    KyleCharacter.update(dt)
end

function love.draw()
    screen_manager.draw()
    notification.draw()
    
    -- Draw Kyle character if active (on top of everything)
    local KyleCharacter = require('lib.kyle_character')
    KyleCharacter.draw()
end

function love.keypressed(key, scancode, isrepeat)
    -- Check for cheat codes first (before screen handles input)
    cheat_system.on_keypressed(key)
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




