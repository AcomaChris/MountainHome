-- HTTP Proxy Client for Love2D
-- Workaround for lua-https POST body bug on Windows
-- This client sends requests to a local HTTP proxy that handles HTTPS

local log = require('lib.logger')
local json = require('lunajson')

local HttpProxyClient = {
    proxy_url = "http://localhost:8080/proxy",
    enabled = false
}

-- Check if proxy is available
function HttpProxyClient.check_available()
    -- Try to make a simple GET request to the proxy health endpoint
    local socket_http = require('socket.http')
    local ltn12 = require('ltn12')
    
    local sink = {}
    local result, code = socket_http.request({
        url = "http://localhost:8080/health",
        sink = ltn12.sink.table(sink),
        timeout = 2  -- Short timeout for health check
    })
    
    if result and code == 200 then
        HttpProxyClient.enabled = true
        log.info("http_proxy_client:check", { status = "available", note = "HTTP proxy is running and available" })
        return true
    else
        HttpProxyClient.enabled = false
        log.info("http_proxy_client:check", { 
            status = "unavailable", 
            code = code,
            note = "HTTP proxy not available. Start http_proxy.py to enable." 
        })
        return false
    end
end

-- Make HTTP POST request via proxy
-- @param url string: The target HTTPS URL
-- @param body string or table: Request body (if table, will be JSON encoded)
-- @param headers table (optional): Request headers
-- @return success boolean, response table { status_code, headers, body } or error string
function HttpProxyClient.post(url, body, headers)
    if not HttpProxyClient.enabled then
        local available = HttpProxyClient.check_available()
        if not available then
            return false, "HTTP proxy not available. Start http_proxy.py first."
        end
    end
    
    -- Convert body to string if it's a table
    local body_str = body
    if type(body) == "table" then
        local json_available, json_module = pcall(require, 'lunajson')
        if json_available then
            body_str = json_module.encode(body)
            headers = headers or {}
            headers["Content-Type"] = headers["Content-Type"] or "application/json"
        else
            return false, "Cannot encode body to JSON (lunajson not available)"
        end
    end
    
    -- Build proxy request
    local proxy_request = {
        url = url,
        method = "POST",
        headers = headers or {},
        body = body_str or ""
    }
    
    local proxy_body = json.encode(proxy_request)
    
    -- Send request to proxy using socket.http (HTTP to localhost works fine)
    local socket_http = require('socket.http')
    local ltn12 = require('ltn12')
    
    local sink = {}
    local result, code, response_headers = socket_http.request({
        url = HttpProxyClient.proxy_url,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#proxy_body)
        },
        source = ltn12.source.string(proxy_body),
        sink = ltn12.sink.table(sink)
    })
    
    if not result then
        log.info("http_proxy_client:post", { step = "request_failed", error = tostring(code) })
        return false, tostring(code)
    end
    
    local response_body = table.concat(sink)
    
    log.info("http_proxy_client:post", { 
        url = url, 
        status = code >= 200 and code < 300 and "success" or "error",
        status_code = code,
        body_length = #response_body
    })
    
    return true, {
        status_code = code,
        headers = response_headers or {},
        body = response_body
    }
end

return HttpProxyClient

