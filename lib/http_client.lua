-- Simple HTTP client wrapper for Love2D
-- Works around lpeg dependency issue by using a minimal HTTP implementation
-- For Phase 1: Basic GET/POST requests to Artificial Agency API

local log = require('lib.logger')

local HttpClient = {
    _available = false,
    _note = "HTTP client not yet implemented - will use Love2D threads or sockets",
}

-- Check if we can use HTTP (will be implemented in next step)
function HttpClient.check_available()
    -- TODO: Implement HTTP using Love2D's socket library or love.thread
    -- For now, mark as unavailable but log the intent
    log.info("http_client:check", { status = "pending_implementation", note = "Will implement using Love2D sockets or threads" })
    return false
end

-- Placeholder for future HTTP GET request
-- @param url string
-- @param headers table (optional)
-- @return success boolean, response table or error string
function HttpClient.get(url, headers)
    log.info("http_client:get", { url = url, status = "not_implemented" })
    return false, "HTTP client not yet implemented"
end

-- Placeholder for future HTTP POST request
-- @param url string
-- @param body string or table (if table, will be JSON encoded)
-- @param headers table (optional)
-- @return success boolean, response table or error string
function HttpClient.post(url, body, headers)
    log.info("http_client:post", { url = url, status = "not_implemented" })
    return false, "HTTP client not yet implemented"
end

return HttpClient

