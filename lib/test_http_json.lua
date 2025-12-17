-- Test module for HTTP and JSON libraries
-- Verifies both libraries work and can be used together
-- Routes test results through event bus and logs all activity

local bus = require('lib.event_bus')
local log = require('lib.logger')

local TestHttpJson = {
    _json_available = false,
    _http_available = false,
    _test_results = {},
}

-- Check if JSON library is available
function TestHttpJson.check_json()
    local success, json = pcall(require, 'lunajson')
    if success and json then
        TestHttpJson._json_available = true
        TestHttpJson._json = json
        log.info("test:json_available", { status = "success" })
        return true
    else
        log.info("test:json_available", { status = "failed", error = tostring(json) })
        return false
    end
end

-- Check if HTTP library is available
-- Note: lua-http requires lpeg (C extension) which doesn't work in Love2D
-- We'll use a custom HTTP client instead (lib/http_client.lua)
function TestHttpJson.check_http()
    -- Skip trying to load lua-http since it requires lpeg
    -- Instead, check if our custom HTTP client is available
    local success, http_client = pcall(require, 'lib.http_client')
    if success and http_client then
        TestHttpJson._http_available = true
        TestHttpJson._http_client = http_client
        log.info("test:http_available", { status = "using_custom_client", note = "lua-http skipped (requires lpeg), using custom http_client" })
        return true
    else
        log.info("test:http_available", { status = "custom_client_not_found", error = tostring(http_client) })
        return false
    end
end

-- Test JSON encoding/decoding
function TestHttpJson.test_json()
    if not TestHttpJson._json_available then
        log.info("test:json_test", { status = "skipped", reason = "json_not_available" })
        bus.emit("test:json_result", { success = false, reason = "json_not_available" })
        return false
    end

    local test_data = {
        name = "test",
        value = 123,
        items = { "a", "b", "c" },
        nested = { x = 1, y = 2 }
    }

    local success, encoded = pcall(TestHttpJson._json.encode, test_data)
    if not success then
        log.info("test:json_encode", { status = "failed", error = tostring(encoded) })
        bus.emit("test:json_result", { success = false, operation = "encode", error = tostring(encoded) })
        return false
    end

    log.info("test:json_encode", { status = "success", encoded = encoded })

    local success2, decoded = pcall(TestHttpJson._json.decode, encoded)
    if not success2 then
        log.info("test:json_decode", { status = "failed", error = tostring(decoded) })
        bus.emit("test:json_result", { success = false, operation = "decode", error = tostring(decoded) })
        return false
    end

    log.info("test:json_decode", { status = "success", decoded = decoded })
    bus.emit("test:json_result", { 
        success = true, 
        original = test_data,
        encoded = encoded,
        decoded = decoded
    })
    return true
end

-- Test HTTP request (simple GET to a test endpoint)
function TestHttpJson.test_http()
    if not TestHttpJson._http_available then
        log.info("test:http_test", { status = "skipped", reason = "http_not_available" })
        bus.emit("test:http_result", { success = false, reason = "http_not_available" })
        return false
    end

    -- Test with our custom HTTP client
    local url = "https://httpbin.org/json"
    
    log.info("test:http_request", { url = url, method = "GET", client = "custom" })
    
    -- Use custom HTTP client (will be implemented in next step)
    local success, result = pcall(TestHttpJson._http_client.get, url)
    if not success then
        log.info("test:http_request", { status = "failed", error = tostring(result) })
        bus.emit("test:http_result", { 
            success = false, 
            operation = "get_request", 
            error = tostring(result),
            note = "custom_http_client_not_yet_implemented"
        })
        return false
    end

    log.info("test:http_request", { status = "success", result = result })
    bus.emit("test:http_result", { 
        success = true, 
        url = url,
        result = result
    })
    return true
end

-- Run all tests
function TestHttpJson.run_all()
    log.info("test:start", { module = "http_json" })
    bus.emit("test:start", { module = "http_json" })
    
    TestHttpJson.check_json()
    TestHttpJson.check_http()
    
    if TestHttpJson._json_available then
        TestHttpJson.test_json()
    end
    
    if TestHttpJson._http_available then
        TestHttpJson.test_http()
    end
    
    log.info("test:complete", { module = "http_json" })
    bus.emit("test:complete", { module = "http_json" })
end

-- Get availability status
function TestHttpJson.get_status()
    return {
        json_available = TestHttpJson._json_available,
        http_available = TestHttpJson._http_available,
    }
end

return TestHttpJson

