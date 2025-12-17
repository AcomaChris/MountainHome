-- Simple HTTP client wrapper for Love2D using LuaSocket
-- Uses socket.http for synchronous HTTP requests (Love2D includes LuaSocket)
-- For Phase 1: Basic GET/POST requests to Artificial Agency API

local log = require('lib.logger')

local HttpClient = {
    _available = false,
    _socket_http = nil,
}

-- Check if socket.http and ltn12 are available (Love2D includes LuaSocket)
function HttpClient.check_available()
    local success_http, socket_http = pcall(require, 'socket.http')
    local success_ltn12, ltn12 = pcall(require, 'ltn12')
    
    if success_http and socket_http and success_ltn12 and ltn12 then
        HttpClient._available = true
        HttpClient._socket_http = socket_http
        HttpClient._ltn12 = ltn12
        log.info("http_client:check", { status = "available", method = "socket.http" })
        return true
    else
        local errors = {}
        if not success_http then table.insert(errors, "socket.http: " .. tostring(socket_http)) end
        if not success_ltn12 then table.insert(errors, "ltn12: " .. tostring(ltn12)) end
        log.info("http_client:check", { status = "unavailable", errors = errors })
        return false
    end
end

-- Make HTTP GET request
-- @param url string
-- @param headers table (optional) - e.g., { ["Authorization"] = "Bearer token", ["AA-API-Version"] = "2025-05-15" }
-- @return success boolean, response table { status_code, headers, body } or error string
function HttpClient.get(url, headers)
    if not HttpClient._available then
        local available = HttpClient.check_available()
        if not available then
            return false, "HTTP client not available (socket.http not found)"
        end
    end
    
    log.info("http_client:get", { url = url })
    
    -- socket.http.request for GET
    local sink = {}
    local result, status_code, response_headers = HttpClient._socket_http.request({
        url = url,
        headers = headers or {},
        sink = HttpClient._ltn12.sink.table(sink)
    })
    
    if not result then
        log.info("http_client:get", { url = url, status = "failed", error = tostring(status_code) })
        return false, tostring(status_code)
    end
    
    local body = table.concat(sink)
    log.info("http_client:get", { url = url, status = "success", status_code = status_code, body_length = #body })
    
    return true, {
        status_code = status_code,
        headers = response_headers or {},
        body = body
    }
end

-- Make HTTP POST request
-- @param url string
-- @param body string or table (if table, will be JSON encoded using lunajson)
-- @param headers table (optional)
-- @return success boolean, response table { status_code, headers, body } or error string
function HttpClient.post(url, body, headers)
    if not HttpClient._available then
        local available = HttpClient.check_available()
        if not available then
            return false, "HTTP client not available (socket.http not found)"
        end
    end
    
    log.info("http_client:post", { url = url })
    
    -- Convert body to string if it's a table (assume JSON)
    local body_str = body
    if type(body) == "table" then
        local json_available, json = pcall(require, 'lunajson')
        if json_available then
            body_str = json.encode(body)
            headers = headers or {}
            headers["Content-Type"] = headers["Content-Type"] or "application/json"
        else
            return false, "Cannot encode body to JSON (lunajson not available)"
        end
    end
    
    -- socket.http.request for POST
    local sink = {}
    local result, status_code, response_headers = HttpClient._socket_http.request({
        url = url,
        method = "POST",
        headers = headers or {},
        source = HttpClient._ltn12.source.string(body_str),
        sink = HttpClient._ltn12.sink.table(sink)
    })
    
    if not result then
        log.info("http_client:post", { url = url, status = "failed", error = tostring(status_code) })
        return false, tostring(status_code)
    end
    
    local response_body = table.concat(sink)
    log.info("http_client:post", { url = url, status = "success", status_code = status_code, body_length = #response_body })
    
    return true, {
        status_code = status_code,
        headers = response_headers or {},
        body = response_body
    }
end

-- Initialize on load
HttpClient.check_available()

return HttpClient

