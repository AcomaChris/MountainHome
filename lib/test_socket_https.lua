-- Test if socket.https is available and works better than socket.http for HTTPS
-- This might solve our redirect/port issues

local log = require('lib.logger')

local function test_socket_https()
    log.info("test:socket_https_check", { step = "checking_availability" })
    
    -- Try to require socket.https
    local https_available, socket_https = pcall(require, 'socket.https')
    
    if https_available and socket_https then
        log.info("test:socket_https_check", { 
            status = "available", 
            step = "socket_https_found",
            note = "socket.https is available! This might handle HTTPS redirects better than socket.http" 
        })
        
        -- Check if it has a request function
        if socket_https.request then
            log.info("test:socket_https_check", { 
                step = "socket_https_api_check",
                has_request_function = true,
                note = "socket.https.request() function is available" 
            })
            return true, socket_https
        else
            log.info("test:socket_https_check", { 
                step = "socket_https_api_check",
                has_request_function = false,
                note = "socket.https.request() function not found" 
            })
            return false, "socket.https module found but request() not available"
        end
    else
        log.info("test:socket_https_check", { 
            status = "unavailable", 
            step = "socket_https_not_found",
            error = tostring(socket_https),
            note = "socket.https is not available. Only socket.http is available." 
        })
        return false, tostring(socket_https)
    end
end

return {
    test = test_socket_https
}

