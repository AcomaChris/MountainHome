-- HTTP client wrapper for Love2D
-- Prefers lua-https (Love2D 12.0+) for native HTTPS support
-- Falls back to socket.http for older Love2D versions
-- For Phase 1: Basic GET/POST requests to Artificial Agency API

local log = require('lib.logger')

local HttpClient = {
    _available = false,
    _use_lua_https = false,  -- Whether to use lua-https (Love2D 12.0+)
    _lua_https = nil,  -- lua-https module (if available)
    _socket_http = nil,  -- socket.http module (fallback)
    _socket_https = nil,  -- socket.https module (if available in Love2D)
    _ltn12 = nil,  -- ltn12 module (for socket.http fallback)
    _proxy_client = nil,  -- HTTP proxy client (workaround for lua-https POST bug)
    _use_proxy = false,  -- Whether to use proxy for POST requests
}

-- Check which HTTP library is available
-- Priority: socket.https > HTTP proxy (for POST) > lua-https (GET only) > socket.http
function HttpClient.check_available()
    -- Always try to load socket modules and ltn12
    local success_ltn12, ltn12 = pcall(require, 'ltn12')
    if success_ltn12 then
        HttpClient._ltn12 = ltn12
    end
    
    local success_http, socket_http = pcall(require, 'socket.http')
    if success_http and socket_http then
        HttpClient._socket_http = socket_http
    end
    
    -- Try socket.https first - it might be available in Love2D 12.0
    local success_socket_https, socket_https = pcall(require, 'socket.https')
    if success_socket_https and socket_https and socket_https.request then
        HttpClient._available = true
        HttpClient._use_lua_https = false
        HttpClient._socket_https = socket_https
        log.info("http_client:check", { 
            status = "available", 
            method = "socket.https", 
            note = "socket.https is available! This should handle HTTPS POST requests correctly." 
        })
        return true
    end
    
    -- Try HTTP proxy client for POST requests (workaround for lua-https bug)
    local success_proxy, proxy_client = pcall(require, 'lib.http_proxy_client')
    if success_proxy and proxy_client then
        HttpClient._proxy_client = proxy_client
        if proxy_client.check_available() then
            HttpClient._use_proxy = true
            log.info("http_client:check", { 
                status = "available", 
                method = "HTTP proxy (POST), lua-https (GET)", 
                note = "HTTP proxy is available! Using proxy for POST requests (workaround for lua-https bug)." 
            })
        end
    end
    
    -- Try lua-https (Love2D 12.0+) for GET requests
    local success_https, lua_https = pcall(require, 'https')
    if success_https and lua_https and lua_https.request then
        HttpClient._available = true
        HttpClient._use_lua_https = true
        HttpClient._lua_https = lua_https
        if HttpClient._use_proxy then
            log.info("http_client:check", { 
                status = "available", 
                method = "HTTP proxy (POST), lua-https (GET)", 
                note = "Using HTTP proxy for POST requests and lua-https for GET requests." 
            })
        else
            log.info("http_client:check", { 
                status = "available", 
                method = "lua-https (GET only, POST has bug)", 
                note = "Using lua-https for GET requests. POST requests have a bug on Windows (body not sent). Start http_proxy.py to enable POST requests." 
            })
        end
        return true
    end
    
    -- Fall back to socket.http only (older Love2D versions, HTTP only)
    if HttpClient._socket_http and HttpClient._ltn12 then
        HttpClient._available = true
        HttpClient._use_lua_https = false
        log.info("http_client:check", { 
            status = "available", 
            method = "socket.http (HTTP only, no HTTPS)", 
            note = "lua-https and socket.https not available, using socket.http (HTTP only, may have redirect/port issues)" 
        })
        return true
    else
        log.info("http_client:check", { status = "unavailable", error = "No HTTP client available" })
        return false
    end
end

-- Make HTTP GET request
-- @param url string: The URL to request
-- @param headers table (optional): Request headers
-- @param max_redirects number (optional): Maximum redirects to follow (default: 5, only used for socket.http fallback)
-- @return success boolean, response table { status_code, headers, body } or error string
function HttpClient.get(url, headers, max_redirects)
    max_redirects = max_redirects or 5
    
    if not HttpClient._available then
        local available = HttpClient.check_available()
        if not available then
            return false, "HTTP client not available"
        end
    end
    
    log.info("http_client:get", { url = url, method = HttpClient._use_lua_https and "lua-https" or "socket.http" })
    
    if HttpClient._use_lua_https then
        -- Use lua-https (Love2D 12.0+)
        -- lua-https handles redirects automatically, so we don't need to implement them
        -- API: https.request(url, options) returns: body, status_code, headers, status_message
        local options = {
            headers = headers or {}
        }
        
        local ret1, ret2, ret3, ret4 = HttpClient._lua_https.request(url, options)
        
        -- Determine which return value is the body vs status code
        -- If first return is a number, it's likely the status code, so swap the order
        local body, status_code, response_headers, status_message
        if type(ret1) == "number" then
            -- Return order is: status_code, body, headers, status_message
            status_code = ret1
            body = ret2
            response_headers = ret3
            status_message = ret4
        else
            -- Return order is: body, status_code, headers, status_message
            body = ret1
            status_code = ret2
            response_headers = ret3
            status_message = ret4
        end
        
        -- Check if request completely failed (no body at all)
        if not body then
            log.info("http_client:get", { url = url, status = "failed", status_code = status_code, error = tostring(status_message or "No response body") })
            return false, tostring(status_message or "Request failed: no response body")
        end
        
        -- Ensure body is a string
        local body_str = type(body) == "string" and body or tostring(body)
        
        -- Always return the response object, even for error status codes
        -- The API client can then parse the error message from the JSON body
        local log_status = (status_code and status_code >= 200 and status_code < 300) and "success" or "error"
        log.info("http_client:get", { 
            url = url, 
            status = log_status, 
            status_code = status_code, 
            body_length = #body_str,
            note = "lua-https handled redirects automatically" 
        })
        
        return true, {
            status_code = status_code or 200,
            headers = response_headers or {},
            body = body_str
        }
    else
        -- Fallback to socket.http (older Love2D versions)
        -- This path includes redirect handling for compatibility
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
        
        -- Handle redirects (3xx status codes) for socket.http fallback
        if status_code >= 300 and status_code < 400 and max_redirects > 0 then
            local location = nil
            if response_headers then
                for k, v in pairs(response_headers) do
                    if string.lower(tostring(k)) == "location" then
                        location = tostring(v)
                        break
                    end
                end
            end
            
            if location then
                -- Make location absolute if relative
                if not string.match(location, "^https?://") then
                    local protocol, host = string.match(url, "^(https?://)([^/]+)")
                    if protocol and host then
                        if string.sub(location, 1, 1) == "/" then
                            location = protocol .. host .. location
                        else
                            local path = string.match(url, "^(https?://[^/]+)(.*)$")
                            local current_dir = string.match(path or "", "^(.*/)[^/]*$") or "/"
                            location = protocol .. host .. current_dir .. location
                        end
                    end
                end
                
                log.info("http_client:get", { 
                    url = url, 
                    status = "redirect", 
                    status_code = status_code, 
                    redirect_to = location, 
                    redirects_remaining = max_redirects - 1 
                })
                return HttpClient.get(location, headers, max_redirects - 1)
            end
        end
        
        log.info("http_client:get", { url = url, status = "success", status_code = status_code, body_length = #body })
        
        return true, {
            status_code = status_code,
            headers = response_headers or {},
            body = body
        }
    end
end

-- Make HTTP POST request
-- @param url string: The URL to request
-- @param body string or table: Request body (if table, will be JSON encoded)
-- @param headers table (optional): Request headers
-- @param max_redirects number (optional): Maximum redirects to follow (default: 5, only used for socket.http fallback)
-- @return success boolean, response table { status_code, headers, body } or error string
function HttpClient.post(url, body, headers, max_redirects)
    max_redirects = max_redirects or 5
    
    if not HttpClient._available then
        local available = HttpClient.check_available()
        if not available then
            return false, "HTTP client not available"
        end
    end
    
    log.info("http_client:post", { 
        step = "start", 
        url = url, 
        body_type = type(body),
        method = HttpClient._use_lua_https and "lua-https" or "socket.http"
    })
    
    -- Convert body to string if it's a table (assume JSON)
    local body_str = body
    if type(body) == "table" then
        log.info("http_client:post", { step = "encoding_json" })
        local json_available, json = pcall(require, 'lunajson')
        if json_available then
            body_str = json.encode(body)
            headers = headers or {}
            headers["Content-Type"] = headers["Content-Type"] or "application/json"
            -- Log a preview of the JSON (first 200 chars) for debugging
            local json_preview = #body_str > 200 and (body_str:sub(1, 200) .. "...") or body_str
            log.info("http_client:post", { 
                step = "json_encoded", 
                body_length = #body_str,
                json_preview = json_preview,
                body_type = type(body_str)
            })
        else
            log.info("http_client:post", { step = "json_encode_failed" })
            return false, "Cannot encode body to JSON (lunajson not available)"
        end
    elseif type(body) == "string" then
        -- Body is already a string, ensure Content-Type is set if not already
        headers = headers or {}
        if not headers["Content-Type"] then
            headers["Content-Type"] = "application/json"
        end
    end
    
    -- Ensure body_str is definitely a string (not nil)
    if not body_str then
        body_str = ""
    end
    body_str = tostring(body_str)
    
    -- Log headers (but not sensitive data like API keys)
    local header_keys = {}
    if headers then
        for k, _ in pairs(headers) do
            table.insert(header_keys, tostring(k))
        end
    end
    log.info("http_client:post", { 
        step = "pre_request", 
        url = url, 
        header_count = #header_keys, 
        header_keys = table.concat(header_keys, ", ") 
    })
    
    -- Priority order for POST requests:
    -- 1. socket.https (if available in Love2D) - should work for HTTPS POST
    -- 2. lua-https (has bug on Windows - POST body not sent)
    -- 3. socket.http (HTTP only, no HTTPS)
    
    if HttpClient._socket_https then
        -- Use socket.https for POST requests - this should work correctly
        log.info("http_client:post", { step = "using_socket_https", url = url })
        
        local sink = {}
        local result, status_code, response_headers = HttpClient._socket_https.request({
            url = url,
            method = "POST",
            headers = headers or {},
            source = HttpClient._ltn12.source.string(body_str),
            sink = HttpClient._ltn12.sink.table(sink)
        })
        
        if not result then
            log.info("http_client:post", { step = "request_failed", url = url, error = tostring(status_code) })
            return false, tostring(status_code)
        end
        
        local response_body = table.concat(sink)
        
        log.info("http_client:post", { 
            url = url, 
            status = status_code >= 200 and status_code < 300 and "success" or "error",
            status_code = status_code, 
            body_length = #response_body,
            method = "socket.https"
        })
        
        return true, {
            status_code = status_code,
            headers = response_headers or {},
            body = response_body
        }
    elseif HttpClient._use_proxy and HttpClient._proxy_client then
        -- Use HTTP proxy for POST requests (workaround for lua-https bug)
        log.info("http_client:post", { step = "using_http_proxy", url = url })
        
        local success, result = HttpClient._proxy_client.post(url, body_str, headers)
        if not success then
            log.info("http_client:post", { step = "proxy_request_failed", url = url, error = tostring(result) })
            return false, tostring(result)
        end
        
        log.info("http_client:post", { 
            url = url, 
            status = result.status_code >= 200 and result.status_code < 300 and "success" or "error",
            status_code = result.status_code, 
            body_length = result.body and #result.body or 0,
            method = "HTTP proxy"
        })
        
        return true, result
    elseif HttpClient._use_lua_https then
        -- Use lua-https (Love2D 12.0+)
        -- lua-https handles redirects automatically, so we don't need to implement them
        -- API: https.request(url, options) returns: body, status_code, headers, status_message
        local request_headers = headers or {}
        
        -- Explicitly set Content-Length for POST requests with body
        -- Some APIs are strict about this header being present
        if body_str and #body_str > 0 then
            request_headers["Content-Length"] = tostring(#body_str)
        end
        
        -- Ensure Content-Type is set for JSON
        if not request_headers["Content-Type"] and body_str and #body_str > 0 then
            request_headers["Content-Type"] = "application/json"
        end
        
        -- Don't set Content-Length manually - let lua-https handle it automatically
        -- Setting it manually might be causing the hang
        local options_headers = {}
        for k, v in pairs(request_headers) do
            if k ~= "Content-Length" then
                options_headers[k] = v
            end
        end
        
        -- Try multiple body formats to see which one works
        -- Format 1: Direct string (what we're currently using)
        -- NOTE: This matches the lua-https documentation, but body may not be sent on Windows
        assert(body_str ~= nil, "Body must not be nil")
        assert(type(body_str) == "string", "Body must be a string, got: " .. type(body_str))
        assert(#body_str > 0, "Body must not be empty, length: " .. tostring(#body_str))
        
        local options = {
            method = "POST",
            headers = options_headers,
            body = body_str
        }
        
        -- Log the EXACT JSON request body being sent
        log.info("http_client:post", {
            step = "exact_json_request_body",
            exact_json_body = body_str,  -- The complete JSON string
            body_length = body_str and #body_str or 0,
            note = "This is the EXACT JSON request body being sent to the API"
        })
        
        -- Log the exact options structure (without sensitive data)
        local options_debug = {
            method = options.method,
            has_headers = options.headers ~= nil,
            header_count = 0,
            has_body = options.body ~= nil,
            body_type = type(options.body),
            body_length = options.body and #tostring(options.body) or 0
        }
        if options.headers then
            for _ in pairs(options.headers) do
                options_debug.header_count = options_debug.header_count + 1
            end
        end
        
        log.info("http_client:post", {
            step = "lua_https_options_prepared",
            has_content_length = options_headers["Content-Length"] ~= nil,
            content_type = options_headers["Content-Type"],
            body_length = body_str and #body_str or 0,
            options_debug = options_debug
        })
        
        -- Log the EXACT request being sent
        log.info("http_client:post", { 
            step = "exact_request_being_sent",
            url = url,
            method = options.method,
            headers = options_headers,
            body_exact = body_str,  -- The EXACT JSON string being sent
            body_length = body_str and #body_str or 0,
            body_type = type(body_str),
            note = "This is the EXACT JSON request body being sent to the API"
        })
        
        log.info("http_client:post", { 
            step = "calling_lua_https_request", 
            url = url,
            options_method = options.method,
            options_body_length = body_str and #body_str or 0,
            content_type = request_headers["Content-Type"],
            content_length = request_headers["Content-Length"],
            has_body = body_str ~= nil and #body_str > 0,
            body_preview = body_str and body_str:sub(1, 100) or "nil",
            warning = "lua-https POST may hang on Windows - if it does, we need an alternative"
        })
        
        -- Try to call lua-https.request - this may hang on Windows
        -- If it hangs, the user will need to kill the process
        -- NOTE: pcall won't help with hangs, but it will catch actual errors
        log.info("http_client:post", { step = "about_to_call_lua_https", warning = "This may hang - if it does, kill the process" })
        local ret1, ret2, ret3, ret4 = HttpClient._lua_https.request(url, options)
        
        -- Determine which return value is the body vs status code
        -- If first return is a number, it's likely the status code, so swap the order
        local body, status_code, response_headers, status_message
        if type(ret1) == "number" then
            -- Return order is: status_code, body, headers, status_message
            status_code = ret1
            body = ret2
            response_headers = ret3
            status_message = ret4
        else
            -- Return order is: body, status_code, headers, status_message
            body = ret1
            status_code = ret2
            response_headers = ret3
            status_message = ret4
        end
        
        -- Check if request completely failed (no body at all)
        if not body then
            log.info("http_client:post", { step = "request_failed", url = url, status_code = status_code, error = tostring(status_message or "No response body") })
            return false, tostring(status_message or "Request failed: no response body")
        end
        
        -- Ensure body is a string
        local body_str_result = type(body) == "string" and body or tostring(body)
        
        -- Always return the response object, even for error status codes
        -- The API client can then parse the error message from the JSON body
        local log_status = (status_code and status_code >= 200 and status_code < 300) and "success" or "error"
        log.info("http_client:post", { 
            url = url, 
            status = log_status, 
            status_code = status_code, 
            body_length = #body_str_result,
            note = "lua-https handled redirects automatically" 
        })
        
        return true, {
            status_code = status_code or 200,
            headers = response_headers or {},
            body = body_str_result
        }
    else
        -- Fallback to socket.http (older Love2D versions)
        -- This path includes redirect handling for compatibility
        log.info("http_client:post", { step = "calling_socket_request", url = url })
        local sink = {}
        local result, status_code, response_headers = HttpClient._socket_http.request({
            url = url,
            method = "POST",
            headers = headers or {},
            source = HttpClient._ltn12.source.string(body_str),
            sink = HttpClient._ltn12.sink.table(sink)
        })
        
        if not result then
            log.info("http_client:post", { step = "request_failed", url = url, error = tostring(status_code) })
            return false, tostring(status_code)
        end
        
        local response_body = table.concat(sink)
        
        -- Handle redirects (3xx status codes) for socket.http fallback
        if status_code >= 300 and status_code < 400 and max_redirects > 0 then
            local location = nil
            if response_headers then
                for k, v in pairs(response_headers) do
                    if string.lower(tostring(k)) == "location" then
                        location = tostring(v)
                        break
                    end
                end
            end
            
            if location then
                -- Make location absolute if relative
                if not string.match(location, "^https?://") then
                    local protocol, host = string.match(url, "^(https?://)([^/]+)")
                    if protocol and host then
                        if string.sub(location, 1, 1) == "/" then
                            location = protocol .. host .. location
                        else
                            local path = string.match(url, "^(https?://[^/]+)(.*)$")
                            local current_dir = string.match(path or "", "^(.*/)[^/]*$") or "/"
                            location = protocol .. host .. current_dir .. location
                        end
                    end
                end
                
                log.info("http_client:post", { 
                    step = "redirect_found", 
                    url = url, 
                    status_code = status_code, 
                    redirect_to = location, 
                    redirects_remaining = max_redirects - 1 
                })
                -- For POST redirects, we'll keep it as POST (many APIs expect this)
                return HttpClient.post(location, body_str, headers, max_redirects - 1)
            end
        end
        
        log.info("http_client:post", { url = url, status = "success", status_code = status_code, body_length = #response_body })
        
        return true, {
            status_code = status_code,
            headers = response_headers or {},
            body = response_body
        }
    end
end

-- Initialize on load
HttpClient.check_available()

return HttpClient
