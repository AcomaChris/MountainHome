-- Quick test to check if lua-https is available in this Love2D version
-- Run this to determine which HTTP library we should use

local log = require('lib.logger')

local function test_lua_https()
    log.info("test:lua_https_check", { step = "checking_availability" })
    
    -- Check Love2D version
    local version = love.getVersion()
    log.info("test:lua_https_check", { step = "love_version", major = version, note = "Love2D version" })
    
    -- Try to require lua-https
    local https_available, https = pcall(require, 'https')
    
    if https_available and https then
        log.info("test:lua_https_check", { 
            status = "available", 
            step = "lua_https_found",
            note = "lua-https is available! We can use this instead of socket.http" 
        })
        
        -- Test basic functionality
        if https.request then
            log.info("test:lua_https_check", { 
                step = "lua_https_api_check",
                has_request_function = true,
                note = "https.request() function is available" 
            })
            return true, https
        else
            log.info("test:lua_https_check", { 
                step = "lua_https_api_check",
                has_request_function = false,
                note = "https.request() function not found" 
            })
            return false, "lua-https module found but https.request() not available"
        end
    else
        log.info("test:lua_https_check", { 
            status = "unavailable", 
            step = "lua_https_not_found",
            error = tostring(https),
            note = "lua-https is not available. Love2D version may be < 12.0, or module not loaded." 
        })
        return false, tostring(https)
    end
end

return {
    test = test_lua_https
}

