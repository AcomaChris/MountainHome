-- Love2D Configuration File
-- This file runs before main.lua and sets up the game window

function love.conf(t)
    -- Set the window title
    t.title = "Mountain Home"
    -- Set identity for save directory (used by logger for log files)
    t.identity = "MountainHome"
    
    -- Set initial window size
    t.window.width = 1280
    t.window.height = 720
    
    -- Allow the window to be resizable (optional, but useful for development)
    t.window.resizable = true
    
    -- Enable vsync (limits FPS to monitor refresh rate)
    t.window.vsync = true
end




