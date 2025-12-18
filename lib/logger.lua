-- Simple logger with timestamped info messages.
-- Writes to console and to a dated log file under Love2D's save directory.
-- Use for player actions, screen transitions, and events that should be visible to the AI pipeline later.
-- Example:
--   local log = require('lib.logger')
--   log.info("menu:continue", { from = "menu" })

local Logger = {}
local log_file_path = nil
local log_dir = "saved/logs" -- under Love save directory (respects t.identity)

local function timestamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end

-- Format tables into a compact string; fallback to tostring for other types.
-- String values are quoted for readability.
local function format_payload(payload)
    if type(payload) == "table" then
        local parts = {}
        for k, v in pairs(payload) do
            local key = tostring(k)
            local value
            if type(v) == "string" then
                -- Quote string values for clarity
                value = '"' .. v .. '"'
            elseif type(v) == "table" then
                -- For tables, show a summary (e.g., "table(3 keys)")
                local count = 0
                for _ in pairs(v) do count = count + 1 end
                value = "table(" .. count .. " keys)"
            else
                value = tostring(v)
            end
            table.insert(parts, key .. "=" .. value)
        end
        table.sort(parts)
        return table.concat(parts, ", ")
    end
    return tostring(payload)
end

local function ensure_log_dir()
    -- Always use save directory (Love2D sandbox)
    love.filesystem.createDirectory(log_dir)
end

local function ensure_log_file()
    if log_file_path then return end
    ensure_log_dir()
    local filename = os.date("%Y-%m-%d_%H-%M-%S.log")
    log_file_path = log_dir .. "/" .. filename
end

local function write_line(line)
    ensure_log_file()
    local ok = love.filesystem.append(log_file_path, line .. "\n")
    if not ok then
        print("[LOGGER] failed to write log line: " .. tostring(log_file_path))
    end
end

function Logger.info(event_name, payload)
    local stamp = timestamp()
    local payload_text = payload and format_payload(payload) or ""
    if payload_text ~= "" then
        local line = ("[INFO %s] %s | %s"):format(stamp, event_name, payload_text)
        print(line)
        write_line(line)
    else
        local line = ("[INFO %s] %s"):format(stamp, event_name)
        print(line)
        write_line(line)
    end
end

return Logger

