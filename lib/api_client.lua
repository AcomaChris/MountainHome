-- API client for Artificial Agency Behavior Engine
-- Wraps HTTP requests to the Artificial Agency API with authentication and versioning
-- For Phase 1: Basic session/agent/message operations

local http_client = require('lib.http_client')
local log = require('lib.logger')

local ApiClient = {
    -- Configuration
    base_url = "https://api.artificial.agency",
    api_key = nil, -- Must be set via configure()
    api_version = "2025-05-15", -- Default API version
}

-- Configure the API client with API key and optional settings
-- @param api_key string: Your Artificial Agency API key
-- @param base_url string (optional): Override base URL (default: https://api.artificial.agency)
-- @param api_version string (optional): Override API version (default: 2025-05-15)
function ApiClient.configure(api_key, base_url, api_version)
    ApiClient.api_key = api_key
    if base_url then
        ApiClient.base_url = base_url
    end
    if api_version then
        ApiClient.api_version = api_version
    end
    log.info("api_client:configure", { base_url = ApiClient.base_url, api_version = ApiClient.api_version, has_key = api_key ~= nil })
end

-- Build standard headers for API requests
-- @return table: Headers with Authorization and AA-API-Version
local function build_headers()
    local headers = {
        ["Authorization"] = "Bearer " .. (ApiClient.api_key or ""),
        ["AA-API-Version"] = ApiClient.api_version,
        ["Content-Type"] = "application/json"
    }
    return headers
end


-- Parse JSON response body
-- @param body string: JSON response body
-- @return success boolean, parsed table or error string
local function parse_json_response(body)
    local json_available, json = pcall(require, 'lunajson')
    if not json_available then
        return false, "lunajson not available"
    end
    
    local success, parsed = pcall(json.decode, body)
    if not success then
        return false, "Failed to parse JSON: " .. tostring(parsed)
    end
    
    return true, parsed
end

-- Create a new session
-- @param project_id string: The project ID to attribute the session to
-- @param metadata table (optional): Key-value pairs to attach to the session
-- @param expires_in number (optional): Seconds until session expires (nil = not set, will use API default)
-- @param max_requests number (optional): Maximum number of requests (nil = not set, will use API default)
-- @return success boolean, session table { id, latest_moment_id, created_at, ... } or error string
function ApiClient.create_session(project_id, metadata, expires_in, max_requests)
    if not ApiClient.api_key then
        return false, "API key not configured. Call ApiClient.configure(api_key) first."
    end
    
    local url = ApiClient.base_url .. "/v1/sessions"
    
    -- Build request body, only including fields that are explicitly provided
    -- This matches the Python client's behavior of excluding unset fields
    local body = {
        project_id = project_id,
        metadata = metadata or {}
    }
    
    -- Only include optional fields if they are explicitly provided (not nil)
    if expires_in ~= nil then
        body.expires_in = expires_in
    end
    
    if max_requests ~= nil then
        body.max_requests = max_requests
    end
    
    -- Log the body structure before encoding
    local body_keys = {}
    for k, v in pairs(body) do
        local value_preview = type(v) == "table" and "table(" .. tostring(#v) .. " keys)" or tostring(v)
        table.insert(body_keys, tostring(k) .. "=" .. value_preview)
    end
    log.info("api_client:create_session", { 
        project_id = project_id, 
        has_expires_in = expires_in ~= nil,
        has_max_requests = max_requests ~= nil,
        expires_in = expires_in,
        max_requests = max_requests,
        body_fields = table.concat(body_keys, ", ")
    })
    
    local success, response = http_client.post(url, body, build_headers())
    if not success then
        log.info("api_client:create_session", { status = "failed", error = response })
        return false, response
    end
    
    if response.status_code ~= 200 then
        -- Log the full response body for debugging
        log.info("api_client:create_session", { 
            step = "error_response", 
            status_code = response.status_code, 
            response_body = response.body,
            response_body_length = #response.body
        })
        
        local parse_success, parsed = parse_json_response(response.body)
        if parse_success then
            log.info("api_client:create_session", { 
                step = "error_parsed", 
                error_type = parsed.error and parsed.error.type or "unknown",
                error_message = parsed.error and parsed.error.message or "unknown",
                error_trace = parsed.error and parsed.error.trace or "unknown",
                full_error = parsed
            })
        else
            log.info("api_client:create_session", { 
                step = "error_parse_failed", 
                parse_error = parsed 
            })
        end
        
        local error_msg = parse_success and (parsed.error and parsed.error.message or "Unknown error") or response.body
        log.info("api_client:create_session", { status = "error", status_code = response.status_code, error = error_msg })
        return false, "HTTP " .. response.status_code .. ": " .. error_msg
    end
    
    local parse_success, parsed = parse_json_response(response.body)
    if not parse_success then
        log.info("api_client:create_session", { status = "parse_error", error = parsed })
        return false, parsed
    end
    
    log.info("api_client:create_session", { status = "success", session_id = parsed.id })
    return true, parsed
end

-- Create an agent within a session
-- @param session_id string: The session ID to create the agent in
-- @param agent_config table: Agent configuration (role_config, presentation_config, component_configs, service_configs, agent_llm, ui_config)
-- @return success boolean, agent table { id, session_id, moment_id, ... } or error string
function ApiClient.create_agent(session_id, agent_config)
    if not ApiClient.api_key then
        return false, "API key not configured. Call ApiClient.configure(api_key) first."
    end
    
    local url = ApiClient.base_url .. "/v1/advanced/sessions/" .. session_id .. "/agents"
    
    log.info("api_client:create_agent", { session_id = session_id })
    
    local success, response = http_client.post(url, agent_config, build_headers())
    if not success then
        log.info("api_client:create_agent", { status = "failed", error = response })
        return false, response
    end
    
    if response.status_code ~= 200 then
        local parse_success, parsed = parse_json_response(response.body)
        local error_msg = parse_success and (parsed.error and parsed.error.message or "Unknown error") or response.body
        log.info("api_client:create_agent", { status = "error", status_code = response.status_code, error = error_msg })
        return false, "HTTP " .. response.status_code .. ": " .. error_msg
    end
    
    local parse_success, parsed = parse_json_response(response.body)
    if not parse_success then
        log.info("api_client:create_agent", { status = "parse_error", error = parsed })
        return false, parsed
    end
    
    log.info("api_client:create_agent", { status = "success", agent_id = parsed.id, session_id = session_id })
    return true, parsed
end

-- Add messages to an agent's message stream
-- @param session_id string: The session ID
-- @param agent_id string: The agent ID
-- @param messages table: Array of message objects (ContentMessage, KVMessage, etc.)
-- @return success boolean, result table { moment_id } or error string
function ApiClient.add_messages(session_id, agent_id, messages)
    if not ApiClient.api_key then
        return false, "API key not configured. Call ApiClient.configure(api_key) first."
    end
    
    local url = ApiClient.base_url .. "/v1/sessions/" .. session_id .. "/agents/" .. agent_id .. "/messages"
    local body = {
        messages = messages
    }
    
    log.info("api_client:add_messages", { session_id = session_id, agent_id = agent_id, message_count = #messages })
    
    local success, response = http_client.post(url, body, build_headers())
    if not success then
        log.info("api_client:add_messages", { status = "failed", error = response })
        return false, response
    end
    
    if response.status_code ~= 200 then
        local parse_success, parsed = parse_json_response(response.body)
        local error_msg = parse_success and (parsed.error and parsed.error.message or "Unknown error") or response.body
        log.info("api_client:add_messages", { status = "error", status_code = response.status_code, error = error_msg })
        return false, "HTTP " .. response.status_code .. ": " .. error_msg
    end
    
    local parse_success, parsed = parse_json_response(response.body)
    if not parse_success then
        log.info("api_client:add_messages", { status = "parse_error", error = parsed })
        return false, parsed
    end
    
    log.info("api_client:add_messages", { status = "success", moment_id = parsed.moment_id, session_id = session_id, agent_id = agent_id })
    return true, parsed
end

return ApiClient

