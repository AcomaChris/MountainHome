-- API Test Screen for Phase 1
-- Simple UI to test Artificial Agency API integration
-- Allows creating session, agent, and sending test messages

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')
local api_client = require('lib.api_client')
local log = require('lib.logger')

-- Load local configuration (gitignored file)
-- Copy local_config.example.lua to local_config.lua and fill in your credentials
local local_config = nil
local config_load_success, config_result = pcall(function()
    return require('local_config')
end)
if config_load_success and config_result then
    local_config = config_result
    log.info("api_test:config_loaded", { has_api_key = local_config.api_key ~= nil, has_project_id = local_config.project_id ~= nil })
else
    log.info("api_test:config_not_found", { note = "local_config.lua not found or has errors. Copy local_config.example.lua to local_config.lua and configure." })
end

local ApiTestScreen = {
    buttons = {},
    status_text = "Ready to test API",
    status_color = { 0.8, 0.8, 0.9 },
    session_id = nil,
    agent_id = nil,
    -- API configuration loaded from local_config.lua (gitignored)
    api_key = local_config and local_config.api_key or nil,
    project_id = local_config and local_config.project_id or nil,
}

function ApiTestScreen.enter(ctx)
    ApiTestScreen.last_transition = ctx
    ApiTestScreen.status_text = "Ready to test API"
    ApiTestScreen.status_color = { 0.8, 0.8, 0.9 }
    ApiTestScreen.session_id = nil
    ApiTestScreen.agent_id = nil
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 240, 44
    local start_y = h * 0.4
    local spacing = 60
    
    ApiTestScreen.buttons = {
        UIButton.new("1. Create Session", (w - btn_w) / 2, start_y, btn_w, btn_h, function()
            ApiTestScreen.create_session()
        end),
        UIButton.new("2. Create Agent", (w - btn_w) / 2, start_y + spacing, btn_w, btn_h, function()
            ApiTestScreen.create_agent()
        end),
        UIButton.new("3. Send Test Message", (w - btn_w) / 2, start_y + spacing * 2, btn_w, btn_h, function()
            ApiTestScreen.send_test_message()
        end),
        UIButton.new("Back to Options", (w - btn_w) / 2, h - 80, btn_w, btn_h, function()
            bus.emit("api_test:back", { from = "api_test" })
        end),
    }
end

function ApiTestScreen.create_session()
    if not ApiTestScreen.api_key then
        ApiTestScreen.status_text = "Error: API key not configured"
        ApiTestScreen.status_color = { 1, 0.5, 0.5 }
        log.info("api_test:create_session", { status = "error", reason = "api_key_not_configured" })
        return
    end
    
    if not ApiTestScreen.project_id then
        ApiTestScreen.status_text = "Error: Project ID not configured"
        ApiTestScreen.status_color = { 1, 0.5, 0.5 }
        log.info("api_test:create_session", { status = "error", reason = "project_id_not_configured" })
        return
    end
    
    ApiTestScreen.status_text = "Creating session..."
    ApiTestScreen.status_color = { 0.9, 0.9, 0.7 }
    
    -- Configure API client
    api_client.configure(ApiTestScreen.api_key)
    
    -- Create session
    -- Try with metadata first, if that fails we can test with empty metadata
    local success, result = api_client.create_session(ApiTestScreen.project_id, {
        ["test-source"] = "mountain-home-phase1",
        ["game-version"] = "0.1"
    })
    
    if success then
        ApiTestScreen.session_id = result.id
        ApiTestScreen.status_text = "Session created: " .. result.id:sub(1, 20) .. "..."
        ApiTestScreen.status_color = { 0.5, 1, 0.5 }
        log.info("api_test:create_session", { status = "success", session_id = result.id })
    else
        ApiTestScreen.status_text = "Failed: " .. tostring(result)
        ApiTestScreen.status_color = { 1, 0.5, 0.5 }
        log.info("api_test:create_session", { status = "failed", error = result })
    end
end

function ApiTestScreen.create_agent()
    if not ApiTestScreen.session_id then
        ApiTestScreen.status_text = "Error: Create session first"
        ApiTestScreen.status_color = { 1, 0.5, 0.5 }
        return
    end
    
    ApiTestScreen.status_text = "Creating agent..."
    ApiTestScreen.status_color = { 0.9, 0.9, 0.7 }
    
    -- Simple agent configuration for testing
    local agent_config = {
        ui_config = {
            friendly_name = "Test Agent",
            emoji = "🏔️",
            metadata = {
                ["test-agent"] = "true"
            }
        },
        role_config = {
            core = "You are a helpful assistant in a mountain homestead game.",
            characterization = "You help players manage their homestead and make decisions.",
            max_size = 0
        },
        presentation_config = {
            token_limits = {
                cue = 100,
                ["function"] = 1000,
                history = 10000
            },
            -- presentation_order must be an array of arrays
            -- Example format: [["history","items"],["facts","data"]]
            -- For our test, we'll provide a simple structure matching the example
            presentation_order = {
                {"history", "items"}  -- Array of arrays format
            }
        },
        component_configs = {
            {
                type = "limited_list",
                id = "history",
                max_entries = 10000,
                token_category = "history",
                accept_generation = true
            }
        },
        service_configs = {
            {
                id = "openai_llm",
                type = "openai/llm",
                model = "gpt_5"  -- Using OpenAI GPT 5
            }
        },
        agent_llm = "openai_llm"
    }
    
    local success, result = api_client.create_agent(ApiTestScreen.session_id, agent_config)
    
    if success then
        ApiTestScreen.agent_id = result.id
        ApiTestScreen.status_text = "Agent created: " .. result.id:sub(1, 20) .. "..."
        ApiTestScreen.status_color = { 0.5, 1, 0.5 }
        log.info("api_test:create_agent", { status = "success", agent_id = result.id, session_id = ApiTestScreen.session_id })
    else
        ApiTestScreen.status_text = "Failed: " .. tostring(result)
        ApiTestScreen.status_color = { 1, 0.5, 0.5 }
        log.info("api_test:create_agent", { status = "failed", error = result })
    end
end

function ApiTestScreen.send_test_message()
    if not ApiTestScreen.session_id or not ApiTestScreen.agent_id then
        ApiTestScreen.status_text = "Error: Create session and agent first"
        ApiTestScreen.status_color = { 1, 0.5, 0.5 }
        return
    end
    
    ApiTestScreen.status_text = "Sending test message..."
    ApiTestScreen.status_color = { 0.9, 0.9, 0.7 }
    
    local messages = {
        {
            message_type = "ContentMessage",
            content = "This is a test message from Mountain Home Phase 1 integration. The player has started a new game."
        }
    }
    
    local success, result = api_client.add_messages(ApiTestScreen.session_id, ApiTestScreen.agent_id, messages)
    
    if success then
        ApiTestScreen.status_text = "Message sent! Moment ID: " .. tostring(result.moment_id)
        ApiTestScreen.status_color = { 0.5, 1, 0.5 }
        log.info("api_test:send_test_message", { status = "success", moment_id = result.moment_id })
    else
        ApiTestScreen.status_text = "Failed: " .. tostring(result)
        ApiTestScreen.status_color = { 1, 0.5, 0.5 }
        log.info("api_test:send_test_message", { status = "failed", error = result })
    end
end

function ApiTestScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.12, 0.1, 0.15)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("API Test Screen", 0, h * 0.2, w, "center")
    
    love.graphics.setColor(0.7, 0.7, 0.9)
    love.graphics.printf("Phase 1: AI Behavior Engine Integration", 0, h * 0.25, w, "center")
    
    -- Status display
    love.graphics.setColor(ApiTestScreen.status_color[1], ApiTestScreen.status_color[2], ApiTestScreen.status_color[3])
    love.graphics.printf(ApiTestScreen.status_text, 0, h * 0.32, w, "center")
    
    -- Instructions
    love.graphics.setColor(0.6, 0.6, 0.7)
    local instructions = "Click buttons in order to test API integration.\n"
    if not ApiTestScreen.api_key or not ApiTestScreen.project_id then
        instructions = instructions .. "Note: Copy local_config.example.lua to local_config.lua and configure your API credentials."
    end
    love.graphics.printf(instructions, 0, h * 0.7, w, "center")
    
    -- Display current IDs if available
    if ApiTestScreen.session_id then
        love.graphics.setColor(0.7, 0.9, 0.7)
        love.graphics.printf("Session: " .. ApiTestScreen.session_id:sub(1, 30) .. "...", 0, h * 0.75, w, "center")
    end
    if ApiTestScreen.agent_id then
        love.graphics.setColor(0.7, 0.9, 0.7)
        love.graphics.printf("Agent: " .. ApiTestScreen.agent_id:sub(1, 30) .. "...", 0, h * 0.78, w, "center")
    end
    
    for _, btn in ipairs(ApiTestScreen.buttons) do
        btn:draw()
    end
end

function ApiTestScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    for _, btn in ipairs(ApiTestScreen.buttons) do
        if btn:mousepressed(x, y) then
            return
        end
    end
end

return ApiTestScreen

